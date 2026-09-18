<?php

namespace App\Services\Commerce;

use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class AttributeOrderToSession
{
    /**
     * Attribute order revenue to a live session without allowing
     * cross-tenant references, currency drift, or over-attribution.
     *
     * The unique database key on (organization_id, live_session_id, order_id)
     * makes an exact retry idempotent. Conflicting retries fail closed.
     */
    public function execute(
        string $organizationId,
        string $liveSessionId,
        string $orderId,
        string $attributionId,
        string $currency,
        int $amountMinor,
    ): object {
        if ($amountMinor <= 0) {
            throw ValidationException::withMessages([
                'amount_minor' => 'Attribution amount must be positive.',
            ]);
        }

        $currency = strtoupper($currency);

        if (! preg_match('/^[A-Z]{3}$/', $currency)) {
            throw ValidationException::withMessages([
                'currency' => 'Currency must be a three-letter ISO code.',
            ]);
        }

        return DB::transaction(function () use (
            $organizationId,
            $liveSessionId,
            $orderId,
            $attributionId,
            $currency,
            $amountMinor,
        ) {
            // Lock in a stable order: order first, then session, then attribution rows.
            $order = DB::table('orders')
                ->where('organization_id', $organizationId)
                ->where('id', $orderId)
                ->lockForUpdate()
                ->first();

            if (! $order) {
                throw ValidationException::withMessages([
                    'order_id' => 'Order is not available in this organization.',
                ]);
            }

            $session = DB::table('live_sessions')
                ->where('organization_id', $organizationId)
                ->where('id', $liveSessionId)
                ->lockForUpdate()
                ->first();

            if (! $session) {
                throw ValidationException::withMessages([
                    'live_session_id' => 'Live session is not available in this organization.',
                ]);
            }

            if (strtoupper($order->currency) !== $currency) {
                throw ValidationException::withMessages([
                    'currency' => 'Attribution currency must match order currency.',
                ]);
            }

            $existing = DB::table('attributions')
                ->where('organization_id', $organizationId)
                ->where('live_session_id', $liveSessionId)
                ->where('order_id', $orderId)
                ->lockForUpdate()
                ->first();

            if ($existing) {
                if (strtoupper($existing->currency) === $currency
                    && (int) $existing->amount_minor === $amountMinor) {
                    return $existing;
                }

                throw ValidationException::withMessages([
                    'order_id' => 'Order already has a different attribution for this session.',
                ]);
            }

            $alreadyAttributed = (int) DB::table('attributions')
                ->where('organization_id', $organizationId)
                ->where('order_id', $orderId)
                ->lockForUpdate()
                ->sum('amount_minor');

            if ($alreadyAttributed + $amountMinor > (int) $order->amount_minor) {
                throw ValidationException::withMessages([
                    'amount_minor' => 'Attribution exceeds the order amount remaining.',
                ]);
            }

            $now = now();

            DB::table('attributions')->insert([
                'id' => $attributionId,
                'organization_id' => $organizationId,
                'live_session_id' => $liveSessionId,
                'order_id' => $orderId,
                'currency' => $currency,
                'amount_minor' => $amountMinor,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            return DB::table('attributions')
                ->where('organization_id', $organizationId)
                ->where('id', $attributionId)
                ->firstOrFail();
        }, 3);
    }
}

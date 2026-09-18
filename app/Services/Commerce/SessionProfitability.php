<?php

namespace App\Services\Commerce;

use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class SessionProfitability
{
    /**
     * Return deterministic session-level revenue, cost, and profit in minor units.
     * All reads are tenant scoped and currency consistent.
     */
    public function calculate(string $organizationId, string $liveSessionId, string $currency): array
    {
        $currency = strtoupper($currency);

        if (! preg_match('/^[A-Z]{3}$/', $currency)) {
            throw ValidationException::withMessages([
                'currency' => 'Currency must be a three-letter ISO code.',
            ]);
        }

        $sessionExists = DB::table('live_sessions')
            ->where('organization_id', $organizationId)
            ->where('id', $liveSessionId)
            ->exists();

        if (! $sessionExists) {
            throw ValidationException::withMessages([
                'live_session_id' => 'Live session is not available in this organization.',
            ]);
        }

        $otherAttributionCurrencyExists = DB::table('attributions')
            ->where('organization_id', $organizationId)
            ->where('live_session_id', $liveSessionId)
            ->where('currency', '<>', $currency)
            ->exists();

        $otherCostCurrencyExists = DB::table('costs')
            ->where('organization_id', $organizationId)
            ->where('live_session_id', $liveSessionId)
            ->where('currency', '<>', $currency)
            ->exists();

        if ($otherAttributionCurrencyExists || $otherCostCurrencyExists) {
            throw ValidationException::withMessages([
                'currency' => 'Session profitability cannot mix currencies.',
            ]);
        }

        $revenueMinor = (int) DB::table('attributions')
            ->where('organization_id', $organizationId)
            ->where('live_session_id', $liveSessionId)
            ->where('currency', $currency)
            ->sum('amount_minor');

        $costMinor = (int) DB::table('costs')
            ->where('organization_id', $organizationId)
            ->where('live_session_id', $liveSessionId)
            ->where('currency', $currency)
            ->sum('amount_minor');

        return [
            'organization_id' => $organizationId,
            'live_session_id' => $liveSessionId,
            'currency' => $currency,
            'revenue_minor' => $revenueMinor,
            'cost_minor' => $costMinor,
            'profit_minor' => $revenueMinor - $costMinor,
        ];
    }
}

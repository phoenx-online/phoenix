<?php

namespace Tests\Feature\Commerce;

use App\Services\Commerce\AttributeOrderToSession;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

final class AttributeOrderToSessionTest extends TestCase
{
    use RefreshDatabase;

    public function test_exact_retry_is_idempotent(): void
    {
        [$organizationId, $sessionId, $orderId] = $this->seedCommerce(15000, 'PHP');
        $service = app(AttributeOrderToSession::class);
        $attributionId = (string) str()->uuid();

        $first = $service->execute($organizationId, $sessionId, $orderId, $attributionId, 'php', 10000);
        $second = $service->execute($organizationId, $sessionId, $orderId, (string) str()->uuid(), 'PHP', 10000);

        $this->assertSame($first->id, $second->id);
        $this->assertSame(1, DB::table('attributions')->where('organization_id', $organizationId)->where('order_id', $orderId)->count());
    }

    public function test_conflicting_retry_is_rejected(): void
    {
        [$organizationId, $sessionId, $orderId] = $this->seedCommerce(15000, 'PHP');
        $service = app(AttributeOrderToSession::class);
        $service->execute($organizationId, $sessionId, $orderId, (string) str()->uuid(), 'PHP', 10000);

        $this->expectException(ValidationException::class);
        $service->execute($organizationId, $sessionId, $orderId, (string) str()->uuid(), 'PHP', 9000);
    }

    public function test_over_attribution_across_sessions_is_rejected(): void
    {
        [$organizationId, $sessionId, $orderId, $storeId, $hostId] = $this->seedCommerce(15000, 'PHP');
        $otherSessionId = $this->seedSession($organizationId, $storeId, $hostId);
        $service = app(AttributeOrderToSession::class);
        $service->execute($organizationId, $sessionId, $orderId, (string) str()->uuid(), 'PHP', 10000);

        try {
            $service->execute($organizationId, $otherSessionId, $orderId, (string) str()->uuid(), 'PHP', 6000);
            $this->fail('Expected over-attribution to be rejected.');
        } catch (ValidationException) {
            $this->assertSame(10000, (int) DB::table('attributions')->where('organization_id', $organizationId)->where('order_id', $orderId)->sum('amount_minor'));
        }
    }

    public function test_cross_tenant_order_is_denied(): void
    {
        [$organizationId, $sessionId, $orderId] = $this->seedCommerce(15000, 'PHP');

        $this->expectException(ValidationException::class);
        app(AttributeOrderToSession::class)->execute((string) str()->uuid(), $sessionId, $orderId, (string) str()->uuid(), 'PHP', 1000);
    }

    public function test_currency_mismatch_is_rejected(): void
    {
        [$organizationId, $sessionId, $orderId] = $this->seedCommerce(15000, 'PHP');

        $this->expectException(ValidationException::class);
        app(AttributeOrderToSession::class)->execute($organizationId, $sessionId, $orderId, (string) str()->uuid(), 'USD', 1000);
    }

    public function test_non_positive_amount_is_rejected_without_writing(): void
    {
        [$organizationId, $sessionId, $orderId] = $this->seedCommerce(15000, 'PHP');

        try {
            app(AttributeOrderToSession::class)->execute($organizationId, $sessionId, $orderId, (string) str()->uuid(), 'PHP', 0);
            $this->fail('Expected non-positive attribution to be rejected.');
        } catch (ValidationException) {
            $this->assertSame(0, DB::table('attributions')->where('organization_id', $organizationId)->count());
        }
    }

    private function seedCommerce(int $amountMinor, string $currency): array
    {
        $organizationId = (string) str()->uuid();
        $brandId = (string) str()->uuid();
        $storeId = (string) str()->uuid();
        $hostId = (string) str()->uuid();
        $orderId = (string) str()->uuid();
        $now = now();

        DB::table('organizations')->insert(['id' => $organizationId, 'name' => 'PHX Test', 'slug' => 'phx-'.str()->random(8), 'created_at' => $now, 'updated_at' => $now]);
        DB::table('brands')->insert(['id' => $brandId, 'organization_id' => $organizationId, 'name' => 'Brand', 'slug' => 'brand-'.str()->random(8), 'created_at' => $now, 'updated_at' => $now]);
        DB::table('stores')->insert(['id' => $storeId, 'organization_id' => $organizationId, 'brand_id' => $brandId, 'name' => 'Store', 'platform' => 'manual', 'external_store_id' => 'store-'.str()->random(8), 'created_at' => $now, 'updated_at' => $now]);
        DB::table('hosts')->insert(['id' => $hostId, 'organization_id' => $organizationId, 'name' => 'Host', 'created_at' => $now, 'updated_at' => $now]);
        $sessionId = $this->seedSession($organizationId, $storeId, $hostId);
        DB::table('orders')->insert(['id' => $orderId, 'organization_id' => $organizationId, 'store_id' => $storeId, 'external_order_id' => 'order-'.str()->uuid(), 'amount_minor' => $amountMinor, 'currency' => $currency, 'ordered_at' => $now, 'created_at' => $now, 'updated_at' => $now]);

        return [$organizationId, $sessionId, $orderId, $storeId, $hostId];
    }

    private function seedSession(string $organizationId, string $storeId, string $hostId): string
    {
        $sessionId = (string) str()->uuid();
        $now = now();
        DB::table('live_sessions')->insert(['id' => $sessionId, 'organization_id' => $organizationId, 'store_id' => $storeId, 'host_id' => $hostId, 'status' => 'draft', 'title' => 'Test Live', 'created_at' => $now, 'updated_at' => $now]);

        return $sessionId;
    }
}

<?php

namespace Tests\Feature\Commerce;

use App\Services\Commerce\SessionProfitability;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

final class SessionProfitabilityTest extends TestCase
{
    use RefreshDatabase;

    public function test_profit_is_attributed_revenue_minus_session_costs_in_minor_units(): void
    {
        [$organizationId, $sessionId] = $this->seedSession();

        DB::table('attributions')->insert([
            'id' => (string) str()->uuid(),
            'organization_id' => $organizationId,
            'live_session_id' => $sessionId,
            'order_id' => $this->seedOrder($organizationId),
            'amount_minor' => 15000,
            'currency' => 'PHP',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('costs')->insert([
            'id' => (string) str()->uuid(),
            'organization_id' => $organizationId,
            'live_session_id' => $sessionId,
            'kind' => 'host_fee',
            'amount_minor' => 4000,
            'currency' => 'PHP',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $result = app(SessionProfitability::class)->calculate($organizationId, $sessionId, 'php');

        $this->assertSame(15000, $result['revenue_minor']);
        $this->assertSame(4000, $result['cost_minor']);
        $this->assertSame(11000, $result['profit_minor']);
        $this->assertSame('PHP', $result['currency']);
    }

    public function test_cross_tenant_session_is_denied(): void
    {
        [$organizationId, $sessionId] = $this->seedSession();
        $otherOrganizationId = (string) str()->uuid();

        $this->expectException(ValidationException::class);
        app(SessionProfitability::class)->calculate($otherOrganizationId, $sessionId, 'PHP');
    }

    public function test_mixed_currency_session_is_rejected(): void
    {
        [$organizationId, $sessionId] = $this->seedSession();

        DB::table('costs')->insert([
            'id' => (string) str()->uuid(),
            'organization_id' => $organizationId,
            'live_session_id' => $sessionId,
            'kind' => 'platform_fee',
            'amount_minor' => 100,
            'currency' => 'USD',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->expectException(ValidationException::class);
        app(SessionProfitability::class)->calculate($organizationId, $sessionId, 'PHP');
    }

    private function seedSession(): array
    {
        $organizationId = (string) str()->uuid();
        $brandId = (string) str()->uuid();
        $storeId = (string) str()->uuid();
        $hostId = (string) str()->uuid();
        $sessionId = (string) str()->uuid();
        $now = now();

        DB::table('organizations')->insert(['id' => $organizationId, 'name' => 'PHX Test', 'slug' => 'phx-'.str()->random(8), 'created_at' => $now, 'updated_at' => $now]);
        DB::table('brands')->insert(['id' => $brandId, 'organization_id' => $organizationId, 'name' => 'Brand', 'slug' => 'brand-'.str()->random(8), 'created_at' => $now, 'updated_at' => $now]);
        DB::table('stores')->insert(['id' => $storeId, 'organization_id' => $organizationId, 'brand_id' => $brandId, 'name' => 'Store', 'platform' => 'manual', 'external_store_id' => 'store-'.str()->random(8), 'created_at' => $now, 'updated_at' => $now]);
        DB::table('hosts')->insert(['id' => $hostId, 'organization_id' => $organizationId, 'name' => 'Host', 'created_at' => $now, 'updated_at' => $now]);
        DB::table('live_sessions')->insert(['id' => $sessionId, 'organization_id' => $organizationId, 'store_id' => $storeId, 'host_id' => $hostId, 'status' => 'draft', 'title' => 'Test Live', 'created_at' => $now, 'updated_at' => $now]);

        return [$organizationId, $sessionId];
    }

    private function seedOrder(string $organizationId): string
    {
        $storeId = DB::table('live_sessions')->where('organization_id', $organizationId)->value('store_id');
        $orderId = (string) str()->uuid();
        $now = now();

        DB::table('orders')->insert([
            'id' => $orderId,
            'organization_id' => $organizationId,
            'store_id' => $storeId,
            'external_order_id' => 'order-'.str()->uuid(),
            'amount_minor' => 15000,
            'currency' => 'PHP',
            'ordered_at' => $now,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        return $orderId;
    }
}

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('live_session_products', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('organization_id')->constrained()->cascadeOnDelete();
            $table->uuid('live_session_id');
            $table->uuid('product_id');
            $table->timestampsTz();
            $table->foreign(['organization_id', 'live_session_id'])->references(['organization_id', 'id'])->on('live_sessions')->cascadeOnDelete();
            $table->foreign(['organization_id', 'product_id'])->references(['organization_id', 'id'])->on('products')->restrictOnDelete();
            $table->unique(['organization_id', 'live_session_id', 'product_id']);
        });

        Schema::create('orders', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('organization_id')->constrained()->cascadeOnDelete();
            $table->uuid('store_id');
            $table->string('external_ref');
            $table->string('status', 32)->default('accepted');
            $table->char('currency', 3);
            $table->bigInteger('amount_minor');
            $table->timestampTz('accepted_at')->nullable();
            $table->timestampsTz();
            $table->foreign(['organization_id', 'store_id'])->references(['organization_id', 'id'])->on('stores')->restrictOnDelete();
            $table->unique(['organization_id', 'id']);
            $table->unique(['organization_id', 'store_id', 'external_ref']);
        });

        Schema::create('attributions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('organization_id')->constrained()->cascadeOnDelete();
            $table->uuid('live_session_id');
            $table->uuid('order_id');
            $table->char('currency', 3);
            $table->bigInteger('amount_minor');
            $table->timestampsTz();
            $table->foreign(['organization_id', 'live_session_id'])->references(['organization_id', 'id'])->on('live_sessions')->restrictOnDelete();
            $table->foreign(['organization_id', 'order_id'])->references(['organization_id', 'id'])->on('orders')->restrictOnDelete();
            $table->unique(['organization_id', 'live_session_id', 'order_id']);
        });

        Schema::create('costs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('organization_id')->constrained()->cascadeOnDelete();
            $table->uuid('live_session_id');
            $table->string('category', 64);
            $table->string('description')->nullable();
            $table->char('currency', 3);
            $table->bigInteger('amount_minor');
            $table->timestampsTz();
            $table->foreign(['organization_id', 'live_session_id'])->references(['organization_id', 'id'])->on('live_sessions')->cascadeOnDelete();
            $table->index(['organization_id', 'live_session_id']);
        });

        DB::statement('ALTER TABLE orders ADD CONSTRAINT orders_amount_nonnegative CHECK (amount_minor >= 0)');
        DB::statement('ALTER TABLE attributions ADD CONSTRAINT attributions_amount_positive CHECK (amount_minor > 0)');
        DB::statement('ALTER TABLE costs ADD CONSTRAINT costs_amount_nonnegative CHECK (amount_minor >= 0)');
    }

    public function down(): void
    {
        Schema::dropIfExists('costs');
        Schema::dropIfExists('attributions');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('live_session_products');
    }
};

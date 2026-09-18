<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('live_sessions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('organization_id')->constrained()->cascadeOnDelete();
            $table->uuid('store_id');
            $table->uuid('host_id');
            $table->string('title');
            $table->string('status', 32)->default('draft');
            $table->timestampTz('scheduled_at')->nullable();
            $table->timestampTz('started_at')->nullable();
            $table->timestampTz('ended_at')->nullable();
            $table->string('external_ref')->nullable();
            $table->timestampsTz();

            $table->foreign(['organization_id', 'store_id'])
                ->references(['organization_id', 'id'])->on('stores')->cascadeOnDelete();
            $table->foreign(['organization_id', 'host_id'])
                ->references(['organization_id', 'id'])->on('hosts')->restrictOnDelete();
            $table->unique(['organization_id', 'id']);
            $table->unique(['organization_id', 'store_id', 'external_ref']);
            $table->index(['organization_id', 'status', 'scheduled_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('live_sessions');
    }
};

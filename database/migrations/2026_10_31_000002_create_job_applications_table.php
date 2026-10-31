<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('job_applications', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('job_slug', 120);
            $table->string('phone', 32);
            $table->string('location', 120);
            $table->text('experience_summary');
            $table->string('portfolio_url', 2000)->nullable();
            $table->unsignedInteger('salary_expectation_php')->nullable();
            $table->date('available_from')->nullable();
            $table->string('resume_path', 255);
            $table->string('status', 24)->default('submitted');
            $table->timestamp('privacy_accepted_at');
            $table->timestamps();
            $table->unique(['user_id', 'job_slug']);
            $table->index(['status', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('job_applications');
    }
};

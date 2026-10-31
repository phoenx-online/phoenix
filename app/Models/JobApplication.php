<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class JobApplication extends Model
{
    protected $fillable = [
        'user_id', 'job_slug', 'phone', 'location', 'experience_summary',
        'portfolio_url', 'salary_expectation_php', 'available_from',
        'resume_path', 'privacy_accepted_at',
    ];

    protected $casts = [
        'available_from' => 'date',
        'privacy_accepted_at' => 'datetime',
        'salary_expectation_php' => 'integer',
    ];

    protected $hidden = ['resume_path'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

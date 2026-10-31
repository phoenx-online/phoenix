<?php

return [
    // Fail closed until private storage, verified outbound mail and release gates pass.
    'accepting' => (bool) env('RECRUITMENT_ACCEPTING_APPLICATIONS', false),
    'jobs' => [
        'videographer-video-editor-ortigas' => [
            'title' => 'Videographer / Video Editor',
            'location' => 'Ortigas, Pasig City',
            'type' => 'Full-time · On-site',
            'intro' => 'Create videos and professional live-selling frames that help products sell.',
            'requirements' => [
                'Shoot and edit TikTok, Reels, product demonstrations and paid advertisements',
                'Design live-selling frames, product overlays, price tags and live layouts',
                'Set up OBS Studio or TikTok LIVE Studio, cameras, lighting and sound',
                'Share previous video edits and livestream design samples',
                'Work full-time on-site in Ortigas',
            ],
        ],
    ],
];

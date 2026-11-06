<?php

return [
    // Fail closed until private storage, verified outbound mail and release gates pass.
    'accepting' => (bool) env('RECRUITMENT_ACCEPTING_APPLICATIONS', false),
    'jobs' => [
        'live-seller-ortigas' => [
            'title' => 'Live Seller / Live Commerce Host',
            'location' => 'Ortigas, Pasig City',
            'type' => 'Full-time · On-site',
            'intro' => 'Present health, beauty and wellness products on camera. Starting basic salary of ₱25,000 per month, plus sales incentives and performance bonuses.',
            'requirements' => [
                'Work on-site for a 6-hour office shift: 4.5 hours live selling and 1.5 hours creating content or assisting/moderating live sessions',
                'Present products clearly, confidently and responsibly on camera',
                'Engage viewers, answer product questions and communicate offers accurately',
                'Collaborate with producers, account handlers, creatives and moderators',
                'Interest in health, beauty or wellness products; training is provided for applicants with or without live-selling experience',
                'In-person interviews are scheduled between 4 PM and 10 PM by invitation',
            ],
        ],
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

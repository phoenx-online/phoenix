<?php

use Illuminate\Support\Facades\Artisan;

Artisan::command('phoenix:about', function (): void {
    $this->info('PHOENIX — Live Commerce Growth Operating System');
    $this->line('Canonical repository: phoenx-online/phoenix');
    $this->line('Primary domain: phoenx.online');
})->purpose('Show canonical PHOENIX application identity');

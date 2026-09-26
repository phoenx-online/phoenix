<?php

namespace Tests\Feature;

use Tests\TestCase;

class HealthTest extends TestCase
{
    public function test_health_endpoint_is_available(): void
    {
        $this->get('/healthz')->assertOk();
    }

    public function test_home_page_identifies_phoenix(): void
    {
        $this->get('/')
            ->assertOk()
            ->assertSee('PHOENIX')
            ->assertSee('Live Commerce Growth Operating System');
    }
}

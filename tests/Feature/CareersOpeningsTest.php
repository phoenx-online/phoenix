<?php

namespace Tests\Feature;

use Tests\TestCase;

class CareersOpeningsTest extends TestCase
{
    public function test_current_ortigas_openings_are_visible_while_intake_is_disabled(): void
    {
        config()->set('recruitment.accepting', false);

        $this->get('/careers')
            ->assertOk()
            ->assertSee('Live Seller / Live Commerce Host')
            ->assertSee('Videographer / Video Editor')
            ->assertSee('Ortigas, Pasig City')
            ->assertSee('4.5 hours live selling')
            ->assertSee('₱25,000')
            ->assertSee('Applications are not being accepted')
            ->assertDontSee('Create account to apply');

        $this->get('/careers/register')->assertStatus(503);
    }

    public function test_applicant_intake_is_off_by_default(): void
    {
        $this->assertFalse(config('recruitment.accepting'));
        $this->assertArrayHasKey('live-seller-ortigas', config('recruitment.jobs'));
        $this->assertArrayHasKey('videographer-video-editor-ortigas', config('recruitment.jobs'));
    }
}

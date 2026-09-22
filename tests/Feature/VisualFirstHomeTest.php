<?php

namespace Tests\Feature;

use Tests\TestCase;

class VisualFirstHomeTest extends TestCase
{
    public function test_homepage_is_truthful_visual_first_foundation(): void
    {
        $response = $this->get('/');

        $response
            ->assertOk()
            ->assertSee('PHOENIX')
            ->assertSee('Live Commerce Growth Operating System')
            ->assertSee('Product foundation preview')
            ->assertSee('Live Selling Operations')
            ->assertSee('Planned capability')
            ->assertSee('Show what exists. Label what does not.')
            ->assertDontSee('Phoenix Creator Team');

        $html = $response->getContent();
        $withoutCode = preg_replace('/<(style|script)\\b[^>]*>.*?<\\/\\1>/is', ' ', $html);
        $visible = html_entity_decode(strip_tags($withoutCode ?? $html));
        $words = preg_split('/\\s+/u', trim($visible), -1, PREG_SPLIT_NO_EMPTY);

        $this->assertLessThanOrEqual(
            230,
            count($words ?: []),
            'PHOENIX foundation homepage exceeded the visual-first reading-load budget.',
        );
    }
}

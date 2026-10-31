<?php

namespace Tests\Feature;

use App\Models\JobApplication;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class RecruitmentPortalTest extends TestCase
{
    use RefreshDatabase;

    private function user(string $email, bool $verified = true): User
    {
        $user = User::create([
            'name' => 'Recruitment Test',
            'email' => $email,
            'password' => 'long-password-123',
        ]);
        if ($verified) {
            $user->forceFill(['email_verified_at' => now()])->save();
        }
        return $user;
    }

    public function test_registration_is_disabled_until_launch_gate(): void
    {
        config()->set('recruitment.accepting', false);
        $this->get('/careers/register')->assertStatus(503);
        $this->post('/careers/register', [
            'name' => 'Test', 'email' => 'test@example.com',
            'password' => 'long-password-123', 'password_confirmation' => 'long-password-123',
        ])->assertStatus(503);
        $this->assertDatabaseCount('users', 0);
    }

    public function test_registration_ignores_client_supplied_admin_role(): void
    {
        config()->set('recruitment.accepting', true);
        Notification::fake();
        $this->post('/careers/register', [
            'name' => 'Applicant Example',
            'email' => ' APPLICANT@EXAMPLE.COM ',
            'password' => 'long-password-123',
            'password_confirmation' => 'long-password-123',
            'role' => 'admin',
        ])->assertRedirect(route('careers.verification.notice'));
        $this->assertDatabaseHas('users', [
            'email' => 'applicant@example.com', 'role' => 'applicant', 'email_verified_at' => null,
        ]);
        $this->get('/careers/dashboard')->assertRedirect('/email/verify');
    }

    public function test_applicant_can_submit_private_cv_without_recruiter_privileges(): void
    {
        config()->set('recruitment.accepting', true);
        Storage::fake('local');
        $user = $this->user('a@example.com');
        $other = $this->user('b@example.com');

        $this->actingAs($user)->post('/careers/apply/videographer-video-editor-ortigas', [
            'phone' => '09171234567', 'location' => 'Pasig City',
            'experience_summary' => 'Experienced with OBS, video editing, product ads, live overlays and studio lighting.',
            'portfolio_url' => 'https://example.com/portfolio',
            'salary_expectation_php' => '30000',
            'resume' => UploadedFile::fake()->create('resume.pdf', 100, 'application/pdf'),
            'privacy_consent' => '1',
        ])->assertRedirect(route('careers.dashboard'));

        $application = JobApplication::firstOrFail();
        $this->assertSame($user->id, $application->user_id);
        $this->assertSame('submitted', $application->status);
        Storage::disk('local')->assertExists($application->getRawOriginal('resume_path'));
        $this->get('/careers/recruiter')->assertForbidden();
        $this->get('/careers/recruiter/applications/'.$application->id.'/resume')->assertForbidden();
        $this->actingAs($other)->get('/careers/dashboard')->assertOk()->assertDontSee('09171234567');
    }

    public function test_recruiter_status_change_is_audited(): void
    {
        $applicant = $this->user('app@example.com');
        $recruiter = $this->user('staff@example.com');
        $recruiter->forceFill(['role' => 'recruiter'])->save();
        $application = JobApplication::create([
            'user_id' => $applicant->id,
            'job_slug' => 'videographer-video-editor-ortigas',
            'phone' => '09171234567', 'location' => 'Ortigas',
            'experience_summary' => 'Editing live commerce content and livestream frames.',
            'resume_path' => 'recruitment/resumes/fake.pdf',
            'privacy_accepted_at' => now(),
        ]);
        $this->actingAs($recruiter)->patch('/careers/recruiter/applications/'.$application->id.'/status', [
            'status' => 'shortlisted',
        ])->assertRedirect();
        $this->assertDatabaseHas('job_applications', ['id' => $application->id, 'status' => 'shortlisted']);
        $this->assertDatabaseHas('application_status_events', [
            'job_application_id' => $application->id,
            'actor_user_id' => $recruiter->id,
            'from_status' => 'submitted',
            'to_status' => 'shortlisted',
        ]);
    }
}

<?php

namespace App\Http\Controllers\Recruitment;

use App\Http\Controllers\Controller;
use App\Models\JobApplication;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class RecruiterController extends Controller
{
    private const STATUSES = ['submitted', 'screening', 'shortlisted', 'interview', 'hired', 'rejected'];

    private function authorizeRecruiter(Request $request): void
    {
        abort_unless($request->user()?->canReviewApplications(), 403);
    }

    public function index(Request $request): View
    {
        $this->authorizeRecruiter($request);

        return view('recruitment.admin', [
            'applications' => JobApplication::query()->with('user')->latest()->paginate(30),
            'statuses' => self::STATUSES,
        ]);
    }

    public function updateStatus(Request $request, JobApplication $application): RedirectResponse
    {
        $this->authorizeRecruiter($request);

        $validated = $request->validate(['status' => ['required', Rule::in(self::STATUSES)]]);

        DB::transaction(function () use ($application, $validated, $request): void {
            $locked = JobApplication::query()->lockForUpdate()->findOrFail($application->id);
            $previous = $locked->status;

            if ($previous === $validated['status']) {
                return;
            }

            $locked->status = $validated['status'];
            $locked->save();

            DB::table('application_status_events')->insert([
                'job_application_id' => $locked->id,
                'actor_user_id' => $request->user()->id,
                'from_status' => $previous,
                'to_status' => $validated['status'],
                'created_at' => now(),
            ]);
        });

        return back()->with('message', 'Application status updated.');
    }

    public function downloadResume(Request $request, JobApplication $application): BinaryFileResponse
    {
        $this->authorizeRecruiter($request);

        // The local disk is PHOENIX-only and never exposed by a public storage symlink.
        abort_unless(Storage::disk('local')->exists($application->getRawOriginal('resume_path')), 404);

        return response()->download(
            Storage::disk('local')->path($application->getRawOriginal('resume_path')),
            'application-'.$application->id.'-resume.pdf',
            ['X-Content-Type-Options' => 'nosniff', 'Cache-Control' => 'private, no-store'],
        );
    }
}

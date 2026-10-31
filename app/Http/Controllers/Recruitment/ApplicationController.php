<?php

namespace App\Http\Controllers\Recruitment;

use App\Http\Controllers\Controller;
use App\Models\JobApplication;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rules\File;
use Illuminate\View\View;
use Throwable;

class ApplicationController extends Controller
{
    public function index(): View
    {
        return view('recruitment.careers', [
            'jobs' => config('recruitment.jobs', []),
            'accepting' => config('recruitment.accepting', false),
        ]);
    }

    public function dashboard(Request $request): View
    {
        return view('recruitment.dashboard', [
            'applications' => $request->user()->applications()->latest()->get(),
        ]);
    }

    public function showApply(Request $request, string $job): View|RedirectResponse
    {
        $position = config("recruitment.jobs.{$job}");
        abort_unless($position, 404);
        abort_unless(config('recruitment.accepting'), 503);

        if ($request->user()->applications()->where('job_slug', $job)->exists()) {
            return redirect()->route('careers.dashboard')->with('message', 'You already applied for this position.');
        }

        return view('recruitment.apply', compact('position', 'job'));
    }

    public function submit(Request $request, string $job): RedirectResponse
    {
        abort_unless(config("recruitment.jobs.{$job}"), 404);
        abort_unless(config('recruitment.accepting'), 503);

        if ($request->user()->applications()->where('job_slug', $job)->exists()) {
            return redirect()->route('careers.dashboard')->with('message', 'You already applied for this position.');
        }

        $data = $request->validate([
            'phone' => ['required', 'string', 'max:32'],
            'location' => ['required', 'string', 'max:120'],
            'experience_summary' => ['required', 'string', 'min:30', 'max:4000'],
            'portfolio_url' => ['nullable', 'url:http,https', 'max:2000'],
            'salary_expectation_php' => ['nullable', 'integer', 'between:0,2000000'],
            'available_from' => ['nullable', 'date'],
            'resume' => ['required', File::types(['pdf'])->max('5mb')],
            'privacy_consent' => ['accepted'],
        ]);

        $path = $request->file('resume')->store('recruitment/resumes', 'local');

        try {
            JobApplication::create([
                'user_id' => $request->user()->id,
                'job_slug' => $job,
                'phone' => $data['phone'],
                'location' => $data['location'],
                'experience_summary' => $data['experience_summary'],
                'portfolio_url' => $data['portfolio_url'] ?? null,
                'salary_expectation_php' => $data['salary_expectation_php'] ?? null,
                'available_from' => $data['available_from'] ?? null,
                'resume_path' => $path,
                'privacy_accepted_at' => now(),
            ]);
        } catch (Throwable $exception) {
            Storage::disk('local')->delete($path);
            throw $exception;
        }

        return redirect()->route('careers.dashboard')->with('message', 'Application submitted successfully.');
    }
}

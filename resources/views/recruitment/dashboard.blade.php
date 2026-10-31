@extends('recruitment.layout')
@section('title', 'My applications')
@section('content')
<p class="eyebrow">Applicant portal</p><h1>My applications</h1>
<p class="muted">View the status of applications submitted with your verified email address.</p>
@forelse($applications as $application)
<article class="panel">
    <div class="row"><h2>{{ config('recruitment.jobs.'.$application->job_slug.'.title', $application->job_slug) }}</h2><span class="pill">{{ ucfirst($application->status) }}</span></div>
    <p class="muted">Submitted {{ $application->created_at->format('M j, Y') }} · Ortigas, Pasig City</p>
    <p>Your application is recorded. PHOENIX will contact you using your registered email or mobile number if you are shortlisted.</p>
</article>
@empty
<div class="panel"><p>You have not submitted an application yet.</p><a class="button" href="{{ route('careers.index') }}">Browse open positions</a></div>
@endforelse
@endsection

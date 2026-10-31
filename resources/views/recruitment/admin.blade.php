@extends('recruitment.layout')
@section('title', 'Recruitment management')
@section('content')
<p class="eyebrow">Restricted · Recruiter access</p><h1>Applicant management</h1>
<p class="muted">Private applicant records. Only authorized PHOENIX recruiters and admins may review résumés or update hiring decisions.</p>
<div class="panel tablebox">
<table>
    <thead><tr><th>Applicant</th><th>Position</th><th>Details</th><th>Résumé</th><th>Status</th></tr></thead>
    <tbody>
    @forelse($applications as $application)
    <tr>
        <td><strong>{{ $application->user->name }}</strong><br><small>{{ $application->user->email }}</small><br><small>{{ $application->phone }}</small></td>
        <td>{{ config('recruitment.jobs.'.$application->job_slug.'.title', $application->job_slug) }}<br><small>{{ $application->created_at->format('Y-m-d') }}</small></td>
        <td><strong>{{ $application->location }}</strong><p>{{ $application->experience_summary }}</p>
            @if($application->portfolio_url)<a href="{{ $application->portfolio_url }}" target="_blank" rel="noopener noreferrer">Portfolio</a>@endif
            @if($application->salary_expectation_php !== null)<p><small>Expected PHP {{ number_format($application->salary_expectation_php) }}/month</small></p>@endif
            @if($application->available_from)<small>Available: {{ $application->available_from->format('Y-m-d') }}</small>@endif
        </td>
        <td><a href="{{ route('careers.recruiter.resume', $application) }}">Download private PDF</a></td>
        <td><form method="post" action="{{ route('careers.recruiter.status', $application) }}">@csrf @method('PATCH')
            <label for="status-{{ $application->id }}">Application status</label>
            <select id="status-{{ $application->id }}" name="status">@foreach($statuses as $status)<option value="{{ $status }}" @selected($application->status === $status)>{{ ucfirst($status) }}</option>@endforeach</select>
            <button type="submit" class="quiet">Update</button></form>
        </td>
    </tr>
    @empty<tr><td colspan="5">No applications yet.</td></tr>
    @endforelse
    </tbody>
</table>
</div>
{{ $applications->links() }}
@endsection

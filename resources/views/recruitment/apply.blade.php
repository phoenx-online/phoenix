@extends('recruitment.layout')
@section('title', 'Apply: '.$position['title'])
@section('content')
<p class="eyebrow">PHOENIX · {{ $position['location'] }}</p><h1>Apply for {{ $position['title'] }}</h1>
<p class="muted">Full-time, on-site. Please tell us about your experience with video editing and live-selling frames, overlays or studio setups.</p>
<form method="post" action="{{ route('careers.apply.submit', $job) }}" enctype="multipart/form-data" class="panel">
    @csrf
    <div class="two">
        <div><label for="phone">Mobile number</label><input id="phone" name="phone" value="{{ old('phone') }}" required maxlength="32" autocomplete="tel"></div>
        <div><label for="location">Current city / location</label><input id="location" name="location" value="{{ old('location') }}" required maxlength="120"></div>
    </div>
    <label for="experience_summary">Describe your videography, editing, live-selling frames and livestream experience</label>
    <textarea id="experience_summary" name="experience_summary" required minlength="30" maxlength="4000">{{ old('experience_summary') }}</textarea>
    <label for="portfolio_url">Portfolio / sample work link (optional)</label>
    <input id="portfolio_url" name="portfolio_url" type="url" value="{{ old('portfolio_url') }}" placeholder="https://...">
    <div class="two">
        <div><label for="salary_expectation_php">Expected monthly salary (PHP, optional)</label><input id="salary_expectation_php" name="salary_expectation_php" type="number" min="0" max="2000000" value="{{ old('salary_expectation_php') }}"></div>
        <div><label for="available_from">Earliest start date (optional)</label><input id="available_from" name="available_from" type="date" value="{{ old('available_from') }}"></div>
    </div>
    <label for="resume">CV / résumé (PDF, up to 5 MB)</label><input id="resume" name="resume" type="file" accept=".pdf,application/pdf" required>
    <p><label><input type="checkbox" name="privacy_consent" value="1" required> I have read the <a href="{{ route('careers.privacy') }}">applicant privacy notice</a> and agree to PHOENIX processing my application information for recruitment.</label></p>
    <button type="submit">Submit application</button>
</form>
@endsection

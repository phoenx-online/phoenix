@extends('recruitment.layout')
@section('title', 'Applicant registration')
@section('content')
<p class="eyebrow">New applicant</p><h1>Create your account</h1>
<p class="muted">Use your own email address. We'll send an email verification link before you submit an application.</p>
<form method="post" action="{{ route('careers.register.submit') }}" class="panel" style="max-width:650px">
    @csrf
    <label for="name">Full name</label><input id="name" name="name" value="{{ old('name') }}" required maxlength="120" autocomplete="name">
    <label for="email">Email address</label><input id="email" name="email" type="email" value="{{ old('email') }}" required maxlength="254" autocomplete="email">
    <label for="password">Password (12+ characters, letters and numbers)</label><input id="password" name="password" type="password" required minlength="12" autocomplete="new-password">
    <label for="password_confirmation">Confirm password</label><input id="password_confirmation" name="password_confirmation" type="password" required minlength="12" autocomplete="new-password">
    <p class="muted"><small>Read our <a href="{{ route('careers.privacy') }}">applicant privacy notice</a> before sharing your information.</small></p>
    <button type="submit">Create account</button>
</form>
@endsection

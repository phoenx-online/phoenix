@extends('recruitment.layout')
@section('title', 'Applicant sign in')
@section('content')
<p class="eyebrow">Welcome back</p><h1>Applicant sign in</h1>
<form method="post" action="{{ route('careers.login.submit') }}" class="panel" style="max-width:600px">
    @csrf
    <label for="email">Email address</label><input id="email" name="email" type="email" required value="{{ old('email') }}" autocomplete="email">
    <label for="password">Password</label><input id="password" name="password" type="password" required autocomplete="current-password">
    <p><a href="{{ route('careers.password.request') }}">Forgot your password?</a></p>
    <button type="submit">Sign in</button>
</form>
@if(config('recruitment.accepting'))<p>New to PHOENIX? <a href="{{ route('careers.register') }}">Create an applicant account.</a></p>@endif
@endsection

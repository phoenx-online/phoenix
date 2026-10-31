@extends('recruitment.layout')
@section('title', 'Reset password')
@section('content')
<p class="eyebrow">Account recovery</p><h1>Forgot your password?</h1>
<form method="post" action="{{ route('careers.password.email') }}" class="panel" style="max-width:600px">
    @csrf
    <p class="muted">Enter your account email. If it exists, a password reset link will be sent.</p>
    <label for="email">Email</label><input id="email" name="email" type="email" required value="{{ old('email') }}">
    <p><button type="submit">Send reset link</button></p>
</form>
@endsection

@extends('recruitment.layout')
@section('title', 'Choose a new password')
@section('content')
<p class="eyebrow">Account recovery</p><h1>Choose a new password</h1>
<form method="post" action="{{ route('careers.password.update') }}" class="panel" style="max-width:600px">
    @csrf
    <input type="hidden" name="token" value="{{ $token }}">
    <label for="email">Account email</label><input id="email" name="email" type="email" required value="{{ old('email', $email) }}">
    <label for="password">New password (12+ characters, letters and numbers)</label><input id="password" name="password" type="password" required minlength="12">
    <label for="password_confirmation">Confirm new password</label><input id="password_confirmation" name="password_confirmation" type="password" required minlength="12">
    <p><button type="submit">Update password</button></p>
</form>
@endsection

@extends('recruitment.layout')
@section('title', 'Verify your email')
@section('content')
<p class="eyebrow">One more step</p><h1>Verify your email address</h1>
<div class="panel" style="max-width:700px">
    <p>Check your inbox for an email from PHOENIX Careers, then open the verification link. Check Spam if you don't see it.</p>
    <form method="post" action="{{ route('careers.verification.send') }}">@csrf<button type="submit">Resend verification link</button></form>
</div>
@endsection

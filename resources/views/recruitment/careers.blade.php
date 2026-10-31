@extends('recruitment.layout')
@section('title', 'Join our team')
@section('content')
<p class="eyebrow">Careers · Ortigas</p>
<h1>Build content that sells.</h1>
<p class="muted">Join PHOENIX's live commerce, e-commerce and performance creative team.</p>
@if(!$accepting)<div class="flash"><strong>Application portal preview.</strong> We are preparing secure applicant registration. Applications are not being accepted through this page yet.</div>@endif
@foreach($jobs as $slug => $job)
<article class="panel">
    <div class="row"><h2>{{ $job['title'] }}</h2><span class="pill">{{ $job['type'] }}</span></div>
    <p><strong>{{ $job['location'] }}</strong></p>
    <p class="muted">{{ $job['intro'] }}</p>
    <ul>@foreach($job['requirements'] as $requirement)<li>{{ $requirement }}</li>@endforeach</ul>
    @if($accepting)
        @auth
            <a class="button" href="{{ route('careers.apply', $slug) }}">Apply for this role</a>
        @else
            <a class="button" href="{{ route('careers.register') }}">Create account to apply</a>
        @endauth
    @endif
</article>
@endforeach
@endsection

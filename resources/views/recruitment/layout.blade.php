<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex,nofollow">
    <meta name="theme-color" content="#101014">
    <title>@yield('title', 'Careers') | PHOENIX</title>
    <style>
        :root{font-family:Inter,ui-sans-serif,system-ui,sans-serif;color:#f6f5f2;background:#101014}
        *{box-sizing:border-box}body{margin:0;line-height:1.55;background:radial-gradient(circle at 80% 0%,#37241855,transparent 38%),#101014}
        a{color:#ffbf80}a:hover{color:#fff}header{border-bottom:1px solid #2c2c31}
        .wrap{width:min(1060px,calc(100% - 36px));margin:auto}.nav{min-height:74px;display:flex;align-items:center;gap:18px;justify-content:space-between;flex-wrap:wrap;padding:12px 0}
        .brand{font-size:1.3rem;font-weight:900;letter-spacing:.18em;color:#fff;text-decoration:none}.links{display:flex;gap:16px;align-items:center;flex-wrap:wrap}
        main{min-height:70vh;padding:52px 0 80px}h1{font-size:clamp(2.3rem,6vw,4.1rem);letter-spacing:-.06em;line-height:1.05}h2{letter-spacing:-.035em}
        p.muted,.muted{color:#b1b1b9}.eyebrow{color:#ffad62;letter-spacing:.16em;text-transform:uppercase;font-weight:800;font-size:.78rem}
        .panel{background:#19191e;border:1px solid #33333a;padding:28px;border-radius:22px;margin:22px 0}.two{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px}
        label{display:block;margin:16px 0 6px;font-weight:700}input,textarea,select{width:100%;background:#101014;border:1px solid #55555d;color:#fff;border-radius:10px;padding:12px 14px;font:inherit}
        input:focus,textarea:focus,select:focus{outline:2px solid #ff9f55;outline-offset:2px}textarea{min-height:120px}input[type=checkbox]{width:auto;margin-right:8px}
        button,.button{display:inline-block;background:#ff9946;color:#1b1109;border:0;border-radius:999px;padding:13px 22px;text-decoration:none;font-weight:900;cursor:pointer;font:inherit;font-weight:800}
        button:hover,.button:hover{background:#ffd2aa;color:#1b1109}.quiet{background:#2e2e36;color:#fff}.quiet:hover{background:#44444b;color:#fff}
        .flash{border:1px solid #b77a42;border-radius:12px;padding:14px 18px;background:#3a2517}.error{color:#ffb1ae}.pill{display:inline-block;padding:5px 11px;border:1px solid #55535a;border-radius:99px;font-size:.75rem;text-transform:uppercase;letter-spacing:.06em}
        .row{display:flex;gap:12px;align-items:center;flex-wrap:wrap}.spacer{flex:1}ul{padding-left:22px}li{margin:8px 0}small{color:#b1b1b9}
        footer{padding:28px 0;border-top:1px solid #2c2c31;color:#b1b1b9}.tablebox{overflow-x:auto}table{width:100%;border-collapse:collapse;min-width:780px}th,td{padding:13px;text-align:left;border-bottom:1px solid #34343b;vertical-align:top}
        @media(max-width:700px){.two{grid-template-columns:1fr}.panel{padding:20px}main{padding:30px 0 56px}}
    </style>
</head>
<body>
<header><div class="wrap nav">
    <a class="brand" href="{{ route('careers.index') }}">PHOENIX</a>
    <nav class="links" aria-label="Careers navigation">
        <a href="{{ route('careers.index') }}">Careers</a>
        @auth
            <a href="{{ route('careers.dashboard') }}">My applications</a>
            @if(auth()->user()->canReviewApplications())<a href="{{ route('careers.recruiter.index') }}">Recruiter</a>@endif
            <form method="post" action="{{ route('careers.logout') }}">@csrf<button type="submit" class="quiet">Sign out</button></form>
        @else
            <a href="{{ route('careers.login') }}">Sign in</a>
            @if(config('recruitment.accepting'))<a href="{{ route('careers.register') }}">Create account</a>@endif
        @endauth
    </nav>
</div></header>
<main class="wrap">
    @if(session('message'))<div class="flash" role="status">{{ session('message') }}</div>@endif
    @if($errors->any())<div class="panel error" role="alert"><strong>Please correct the following:</strong><ul>@foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>@endif
    @yield('content')
</main>
<footer><div class="wrap"><strong>PHOENIX Careers</strong> · <a href="{{ route('careers.privacy') }}">Applicant privacy notice</a> · Ortigas, Pasig City</div></footer>
</body>
</html>

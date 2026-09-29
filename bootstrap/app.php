<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/healthz',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // PHX-M1: keep the initial DEV baseline minimal and explicit.
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // PHX-M1: default Laravel exception handling for DEV baseline.
    })
    ->create();

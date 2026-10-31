<?php

use App\Http\Controllers\Recruitment\ApplicantAuthController;
use App\Http\Controllers\Recruitment\ApplicationController;
use App\Http\Controllers\Recruitment\PasswordResetController;
use App\Http\Controllers\Recruitment\RecruiterController;
use Illuminate\Foundation\Auth\EmailVerificationRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// Framework notifications require the global route names below.
Route::get('/email/verify', fn () => redirect()->route('careers.verification.notice'))
    ->middleware('auth')->name('verification.notice');

Route::get('/email/verify/{id}/{hash}', function (EmailVerificationRequest $request) {
    $request->fulfill();
    return redirect()->route('careers.dashboard');
})->middleware(['auth', 'signed', 'throttle:6,1'])->name('verification.verify');

Route::get('/reset-password/{token}', [PasswordResetController::class, 'resetForm'])
    ->middleware('guest')->name('password.reset');

Route::prefix('careers')->name('careers.')->group(function (): void {
    Route::get('/', [ApplicationController::class, 'index'])->name('index');
    Route::view('/privacy', 'recruitment.privacy')->name('privacy');

    Route::middleware('guest')->group(function (): void {
        Route::get('/register', [ApplicantAuthController::class, 'showRegister'])->name('register');
        Route::post('/register', [ApplicantAuthController::class, 'register'])->middleware('throttle:5,60')->name('register.submit');
        Route::get('/login', [ApplicantAuthController::class, 'showLogin'])->name('login');
        Route::post('/login', [ApplicantAuthController::class, 'login'])->middleware('throttle:10,1')->name('login.submit');
        Route::get('/forgot-password', [PasswordResetController::class, 'requestForm'])->name('password.request');
        Route::post('/forgot-password', [PasswordResetController::class, 'sendLink'])->middleware('throttle:3,10')->name('password.email');
        Route::post('/reset-password', [PasswordResetController::class, 'reset'])->middleware('throttle:5,10')->name('password.update');
    });

    Route::middleware('auth')->group(function (): void {
        Route::post('/logout', [ApplicantAuthController::class, 'logout'])->name('logout');
        Route::get('/verify-email', fn () => view('recruitment.verify'))->name('verification.notice');
        Route::post('/verification-notification', function (Request $request) {
            $request->user()->sendEmailVerificationNotification();
            return back()->with('message', 'Verification email requested.');
        })->middleware('throttle:3,10')->name('verification.send');
    });

    Route::middleware(['auth', 'verified'])->group(function (): void {
        Route::get('/dashboard', [ApplicationController::class, 'dashboard'])->name('dashboard');
        Route::get('/apply/{job}', [ApplicationController::class, 'showApply'])->name('apply');
        Route::post('/apply/{job}', [ApplicationController::class, 'submit'])->middleware('throttle:5,60')->name('apply.submit');

        Route::prefix('recruiter')->name('recruiter.')->group(function (): void {
            Route::get('/', [RecruiterController::class, 'index'])->name('index');
            Route::patch('/applications/{application}/status', [RecruiterController::class, 'updateStatus'])->name('status');
            Route::get('/applications/{application}/resume', [RecruiterController::class, 'downloadResume'])->name('resume');
        });
    });
});

<?php

use Illuminate\Support\Facades\Route;

Route::view('/', 'welcome')->name('home');

require __DIR__.'/recruitment.php';

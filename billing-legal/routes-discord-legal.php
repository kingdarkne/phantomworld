<?php

use Illuminate\Support\Facades\Route;

// Add to routes/store.php (or include this file from there)

Route::get('/discord/terms', function () {
    return view('store.legal.bot-terms');
})->name('discord.bot.terms');

Route::get('/discord/privacy', function () {
    return view('store.legal.bot-privacy');
})->name('discord.bot.privacy');

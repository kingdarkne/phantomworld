<?php

use App\Models\Client;
use Illuminate\Auth\Events\Verified;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Route;

/**
 * Store Pages
 */

// Home Page
Route::get('/', 'StoreController@pages')->name('home');
// Contact Page
Route::get('/contact', 'StoreController@contact')->name('contact');
// System Status Page
Route::get('/status', 'StoreController@pages')->name('status');
// Terms of Service Page
Route::get('/terms', 'StoreController@pages')->name('terms');
// Privacy Policy Page

// Discord Bot legal (Developer Portal verification)
Route::get('/discord/terms', function () {
    return view('store.legal.bot-terms');
})->name('discord.terms');
Route::get('/discord/privacy', function () {
    return view('store.legal.bot-privacy');
})->name('discord.privacy');

Route::get('/privacy', 'StoreController@pages')->name('privacy');

// Plans Page
Route::get('/plans/{id?}', 'StoreController@plans')->name('plans');

// Order Server Pages
Route::prefix('/order/{id}')->middleware(['check.store.order'])->group(function () {
    Route::get('/', 'StoreController@order')->name('order');
    Route::get('/checkout', 'StoreController@checkout')->name('checkout');
});

// Affiliate Link
Route::get('/a/{id}', 'StoreController@affiliate')->middleware('check.store.affiliate')->name('affiliate');

// Changing Currency
Route::get('/currency/{id}', 'StoreController@currency')->name('currency');

// Changing Country (Tax)
Route::get('/country/{id}', 'StoreController@country')->name('country');

// Changing Language (coming soon...)
Route::get('/lang/{id}', 'StoreController@lang')->name('lang');

// Knowledge Base
Route::get('/kb/{id?}', 'StoreController@kb')->name('kb');

// Email Verification
// Verify links must work from the mail client without an existing session.
// Signed URL + email hash prove ownership; then we log the client in.
Route::prefix('/email')->name('verification.')->group(function () {
    Route::get('/notice', function () {
        return view('client.verify', ['title' => 'Account Verification']);
    })->middleware('auth')->withoutMiddleware('verified')->name('notice');

    Route::get('/verify/{id}/{hash}', function (Request $request, $id, $hash) {
        $client = Client::findOrFail($id);

        if (!hash_equals(sha1($client->getEmailForVerification()), (string) $hash)) {
            abort(403, 'Invalid verification link.');
        }

        if (!$client->hasVerifiedEmail()) {
            $client->markEmailAsVerified();
            event(new Verified($client));
        }

        Auth::login($client);
        $request->session()->regenerate();

        $url = session('after_login_url', null);
        $request->session()->forget('after_login_url');

        return ($url ? redirect($url) : redirect()->route('client.dash'))
            ->with('success_msg', 'Your account has been verified!');
    })->middleware(['signed', 'throttle:6,1'])->withoutMiddleware('verified')->name('verify');

    Route::get('/send', function (Request $request) {
        $request->user()->sendEmailVerificationNotification();
        return back()->with('success_msg', 'We have sent you an email. Please click the link inside to verify your account.');
    })->middleware(['auth', 'throttle:6,1'])->withoutMiddleware('verified')->name('send');
});

Route::prefix('/auth')->name('client.')->middleware('guest')->group(function () {
    Route::get('/reset/{token}', 'StoreController@reset')->name('reset');
});

Route::any('/redirect/login', function () {
    return redirect()->route('home')->with('success_msg', 'You have logged out successfully!');
})->name('login');

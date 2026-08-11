@extends('layouts.store')
@switch(Route::currentRouteName())
    @case('home')
        @section('title', 'Home')
        @break
    @case('status')
        @section('title', 'System Status')
        @break
    @case('terms')
        @section('title', 'Terms of Service')
        @break
    @case('privacy')
        @section('title', 'Privacy Policy')
        @break
    @default
@endswitch
@section('content')
    @if (Route::currentRouteName() === 'home')
        @php
            $logo = config('app.logo_file_path');
            $panelUrl = config('app.panel_url');
        @endphp
        <section class="ph-hero">
            <div class="ph-hero-inner">
                <div class="ph-brand-mark">
                    <img src="{{ $logo }}" alt="Phantom Hosting" width="56" height="56">
                    <span>Phantom Hosting</span>
                </div>
                <h1>Servers that feel <em>instant</em>.</h1>
                <p class="ph-hero-lead">High-performance game hosting with DDoS protection, instant setup, and support that actually answers.</p>
                <div class="ph-cta-row">
                    <a {!! to_page('plans') !!} class="ph-btn ph-btn-primary">Browse plans</a>
                    @if ($panelUrl)
                        <a href="{{ $panelUrl }}" class="ph-btn ph-btn-ghost" target="_blank" rel="noopener">Open game panel</a>
                    @endif
                </div>
                <div class="ph-trust">
                    <span><i class="fas fa-bolt"></i> Ultra-low latency</span>
                    <span><i class="fas fa-shield-alt"></i> Enterprise DDoS shield</span>
                    <span><i class="fas fa-headset"></i> 24/7 human support</span>
                </div>
            </div>
        </section>

        <section class="ph-features">
            <div class="ph-features-head">
                <h2>Built for players who hate lag</h2>
                <p>Every plan ships ready for Minecraft, bots, and custom game stacks — no waiting around for tickets to start your server.</p>
            </div>
            <div class="ph-feature-grid">
                <div class="ph-feature">
                    <strong>Instant deploy</strong>
                    <span>Spin up in seconds after checkout. No queue, no mystery delays.</span>
                </div>
                <div class="ph-feature">
                    <strong>Protected network</strong>
                    <span>Stay online when attacks hit — protection is included, not an upsell.</span>
                </div>
                <div class="ph-feature">
                    <strong>Panel control</strong>
                    <span>Full Pterodactyl access for files, consoles, backups, and databases.</span>
                </div>
                <div class="ph-feature">
                    <strong>Fair pricing</strong>
                    <span>From starter bots to heavy dedicated-feel plans — scale when you need it.</span>
                </div>
            </div>
        </section>
    @else
        <div class="row">
            <div class="col-lg-12">
                <div class="card">
                    <div class="card-body">
                        @php
                            $page_content = \App\Models\Page::where('name', Route::currentRouteName())->value('content');
                        @endphp
                        {!! $page_content ?? config('page.' . Route::currentRouteName()) !!}
                    </div>
                </div>
            </div>
        </div>
    @endif
@endsection

@php $header_route = 'client.server.index'; @endphp

@extends('layouts.client')

@inject('plan_model', 'App\Models\Plan')
@inject('plan_cycle_model', 'App\Models\PlanCycle')

@php
    $plan = $plan_model->find($server->plan_id);
    $cycle = $plan_cycle_model->find($server->plan_cycle);
    $renewPrice = $cycle ? (float) $cycle->renew_price : 0;
    $panelUrl = rtrim((string) (\App\Models\Setting::where('key', 'panel_url')->value('value') ?: config('app.panel_url')), '/');
    $panelServerUrl = $server->identifier ? ($panelUrl . '/server/' . $server->identifier) : $panelUrl . '/auth/login';
@endphp

@section('title', 'Server Info')
@section('header', 'My Servers')
@section('subheader', "Server #${id}")

@section('content')
    <div class="row mb-3">
        <div class="col-12">
            <a href="{{ $panelServerUrl }}" class="btn btn-primary btn-lg" target="_blank" rel="noopener">
                <i class="fas fa-gamepad"></i>
                @if ($server->identifier)
                    Open Server in Game Panel
                @else
                    Login to Game Panel
                @endif
            </a>
            <a href="{{ $panelUrl }}/auth/login" class="btn btn-outline-secondary btn-lg ml-2" target="_blank" rel="noopener">
                Panel Login
            </a>
        </div>
    </div>
    <div class="row">
        <div class="col-lg-6">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title m-0">Server Information</h5>
                </div>
                <div class="card-body text-nowrap row">
                    <p class="card-text col-5">
                        <b>Plan Name</b><br>
                        <b>Server Name</b><br>
                        <b>Panel ID</b><br>
                        <b>Server Status</b>
                    </p>
                    <p class="card-text col-7">
                        {{ optional($plan)->name }}<br>
                        {{ $server->server_name }}<br>
                        {{ $server->identifier ?: 'Provisioning…' }}<br>
                        <span id="server_status"><span class="badge bg-{{ $server->identifier ? 'success' : 'warning' }}">{{ $server->identifier ? 'Active' : 'Pending' }}</span></span>
                    </p>
                    <a href="{{ route('client.server.plan.show', ['id'=>$id]) }}" class="btn btn-primary btn-sm col-12">Plan <i class="fas fa-arrow-circle-right"></i></a>
                </div>
            </div>
        </div>
        <div class="col-lg-6">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title m-0">Billing Overview</h5>
                </div>
                <div class="card-body text-nowrap row">
                    <p class="card-text col-7">
                        <b>Recurring Amount</b><br>
                        <b>Billing Cycle</b><br>
                        <b>Server Creation Date</b><br>
                        <b>Due / Renew Date</b><br>
                        <b>Payment Method</b><br>
                        <b>Backup Payment Method</b>
                    </p>
                    <p class="card-text col-5">
                        {!! session('currency')->symbol !!}{{ number_format($renewPrice * session('currency')->rate, 2) }} {{ session('currency')->name }}<br>
                        {{ optional($cycle)->id ? $plan_cycle_model->type_name($cycle->cycle_length, $cycle->cycle_type) : $server->plan_cycle }}<br>
                        {{ $server->created_at }}<br>
                        {{ $server->due_date }}<br>
                        {{ $server->payment_method }}<br>
                        Account Credit
                    </p>
                </div>
            </div>
        </div>
    </div>
    <div class="row">
        <div class="col-lg-4">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title m-0">Resources</h5>
                </div>
                <div class="card-body text-nowrap row">
                    <p class="card-text col-5">
                        <b>RAM</b><br>
                        <b>CPU</b><br>
                        <b>Disk</b><br>
                        <b>Databases</b><br>
                        <b>Backups</b><br>
                        <b>Extra Ports</b>
                    </p>
                    <p class="card-text col-7">
                        <span id="memory_usage"></span>{{ optional($plan)->ram }} MB<br>
                        <span id="cpu_usage"></span>{{ optional($plan)->cpu }}%<br>
                        <span id="disk_usage"></span>{{ optional($plan)->disk }} MB<br>
                        <span id="database_usage"></span>{{ optional($plan)->databases }}<br>
                        <span id="backup_usage"></span>{{ optional($plan)->backups }}<br>
                        <span id="extra_port_usage"></span>{{ optional($plan)->extra_ports }}
                    </p>
                </div>
            </div>
        </div>
        <div class="col-lg-8">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title m-0">Quick Shortcuts (Game Panel)</h5>
                </div>
                <div class="card-body text-nowrap row">
                    @if ($server->identifier)
                    <p class="card-text col-lg-4 col-6">
                        <a href="{{ $panelUrl }}/server/{{ $server->identifier }}" target="_blank" rel="noopener"><i class="fas fa-terminal"></i> Console</a><br>
                        <a href="{{ $panelUrl }}/server/{{ $server->identifier }}/files" target="_blank" rel="noopener"><i class="fas fa-folder-open"></i> Files</a><br>
                        <a href="{{ $panelUrl }}/server/{{ $server->identifier }}/databases" target="_blank" rel="noopener"><i class="fas fa-database"></i> Databases</a><br>
                        <a href="{{ $panelUrl }}/server/{{ $server->identifier }}/schedules" target="_blank" rel="noopener"><i class="fas fa-table"></i> Schedules</a>
                    </p>
                    <p class="card-text col-lg-4 col-6">
                        <a href="{{ $panelUrl }}/server/{{ $server->identifier }}/users" target="_blank" rel="noopener"><i class="fas fa-users"></i> Users</a><br>
                        <a href="{{ $panelUrl }}/server/{{ $server->identifier }}/backups" target="_blank" rel="noopener"><i class="fas fa-file-archive"></i> Backups</a><br>
                        <a href="{{ $panelUrl }}/server/{{ $server->identifier }}/network" target="_blank" rel="noopener"><i class="fas fa-network-wired"></i> Network</a><br>
                        <a href="{{ $panelUrl }}/server/{{ $server->identifier }}/startup" target="_blank" rel="noopener"><i class="fas fa-play"></i> Startup</a>
                    </p>
                    <p class="card-text col-lg-4 col-6">
                        <a href="{{ $panelUrl }}/server/{{ $server->identifier }}/settings" target="_blank" rel="noopener"><i class="fas fa-cogs"></i> Settings</a><br>
                        @if (config('app.phpmyadmin_url')) <a href="{{ config('app.phpmyadmin_url') }}" target="_blank" rel="noopener"><i class="fas fa-tools"></i> phpMyAdmin</a> @endif
                    </p>
                    @else
                    <p class="card-text col-12">This server is still provisioning on Main Node. Refresh in a minute, then use <strong>Open Server in Game Panel</strong>.</p>
                    @endif
                </div>
            </div>
        </div>
    </div>
@endsection

@section('scripts')
@endsection

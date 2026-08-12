@extends('layouts.client')

@inject('server_model', 'App\Models\Server')
@inject('plan_model', 'App\Models\Plan')

@php
    $panelUrl = rtrim((string) (\App\Models\Setting::where('key', 'panel_url')->value('value') ?: config('app.panel_url')), '/');
@endphp

@section('title', 'My Servers')

@section('content')
    <div class="row">
        <div class="col-lg-12">
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Active Servers</h3>
                    <div class="card-tools">
                        <a href="{{ $panelUrl }}" class="btn btn-primary btn-sm" target="_blank" rel="noopener">
                            Login to Game Panel <i class="fas fa-external-link-alt"></i>
                        </a>
                        <button type="button" class="btn btn-tool" data-card-widget="collapse"><i class="fas fa-minus"></i></button>
                    </div>
                </div>
                <div class="card-body table-responsive p-0">
                    <table class="table table-hover text-nowrap">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Plan</th>
                                <th>Server Name</th>
                                <th>RAM (MB)</th>
                                <th>CPU (%)</th>
                                <th>Disk (MB)</th>
                                <th>Status</th>
                                <th>Panel</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($server_model->where(['client_id' => auth()->user()->id, 'status' => 0])->get() as $server)
                                <tr>
                                    <td><a href="{{ route('client.server.show', ['id' => $server->id]) }}">{{ $server->id }}</a></td>
                                    <td>{{ optional($plan_model->find($server->plan_id))->name }}</td>
                                    <td>{{ $server->server_name }}</td>
                                    <td><span id="memory_usage_{{ $server->identifier }}">{{ optional($plan_model->find($server->plan_id))->ram }}</span></td>
                                    <td><span id="cpu_usage_{{ $server->identifier }}">{{ optional($plan_model->find($server->plan_id))->cpu }}</span></td>
                                    <td><span id="disk_usage_{{ $server->identifier }}">{{ optional($plan_model->find($server->plan_id))->disk }}</span></td>
                                    <td><span id="server_status_{{ $server->identifier }}"><span class="badge bg-success">Active</span></span></td>
                                    <td>
                                        @if ($server->identifier)
                                            <a class="btn btn-sm btn-primary" href="{{ $panelUrl }}/server/{{ $server->identifier }}" target="_blank" rel="noopener">
                                                Open Console
                                            </a>
                                        @else
                                            <span class="text-muted">Provisioning…</span>
                                        @endif
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        <div class="col-lg-6">
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Pending Servers</h3>
                    <div class="card-tools">
                        <button type="button" class="btn btn-tool" data-card-widget="collapse"><i class="fas fa-minus"></i></button>
                    </div>
                </div>
                <div class="card-body table-responsive p-0">
                    <table class="table table-hover text-nowrap">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Plan</th>
                                <th>Server Name</th>
                                <th>Order Date</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($server_model->where(['client_id' => auth()->user()->id, 'status' => 1])->get() as $server)
                                <tr>
                                    <td>{{ $server->id }}</td>
                                    <td>{{ optional($plan_model->find($server->plan_id))->name }}</td>
                                    <td>{{ $server->server_name }}</td>
                                    <td>{{ $server->created_at }}</td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        <div class="col-lg-6">
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Game Panel Access</h3>
                </div>
                <div class="card-body">
                    <p class="mb-2">Your servers are created on <strong>Main Node</strong> (<code>wings.phantom-chicken.com</code>) and managed in the hosting panel.</p>
                    <p class="mb-3">Use the same email as your billing account. Check your welcome email for the panel password (or use Forgot Password on the panel).</p>
                    <a href="{{ $panelUrl }}/auth/login" class="btn btn-primary" target="_blank" rel="noopener">
                        Go to Panel Login <i class="fas fa-sign-in-alt"></i>
                    </a>
                </div>
            </div>
        </div>
    </div>
@endsection

@php $header_route = "plans"; @endphp

@extends('layouts.store')

@section('title', $plan->name)
@section('header', 'Server Plans')

@inject('plan_cycle_model', 'App\Models\PlanCycle')
@inject('extension_model', 'App\Models\Extension')
@inject('extension_manager', 'Extensions\ExtensionManager')
@inject('carbon', 'Carbon\Carbon')

@php
    $enabledGateways = [];
    foreach ($extension_manager::$gateways as $gateway) {
        if ($extension_model->where(['extension' => $gateway::$display_name, 'key' => 'enabled'])->value('value') === '1') {
            $enabledGateways[] = $gateway;
        }
    }
@endphp

@section('content')
    <div class="row">
        <div class="col-lg-12">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title m-0">Billing Overview</h5>
                </div>
                <div class="card-body row">
                    <div class="col-lg-3 col-md-6 mb-1">
                        <h6 class="card-title">Total Due Today</h6>
                        <p class="card-text">{!! session('currency')->symbol !!}{{ session("order_server_$id")['summary']['due_today'] }} {{ session('currency')->name }}</p>
                    </div>
                    <div class="col-lg-3 col-md-6 mb-1">
                        <h6 class="card-title">Billing Cycle</h6>
                        <p class="card-text">{{ session("order_server_$id")['cycle']['name'] }}</p>
                    </div>
                    <div class="col-lg-3 col-md-6 mb-1">
                        <h6 class="card-title">Recurring Amount</h6>
                        <p class="card-text">
                            @if (session("order_server_$id")['cycle']['data']['cycle_type'] === 0)
                                N/A
                            @else
                                {!! session('currency')->symbol !!}{{ session("order_server_$id")['summary']['due_next'] }} {{ session('currency')->name }}
                            @endif
                        </p>
                    </div>
                    <div class="col-lg-3 col-md-6 mb-1">
                        <h6 class="card-title">Next Due Date</h6>
                        <p class="card-text">
                            @if (session("order_server_$id")['cycle']['data']['cycle_type'] === 0)
                                N/A
                            @else
                                {{ $carbon->now()->addSeconds($plan_cycle_model->type_sec(
                                    session("order_server_$id")['cycle']['data']['cycle_length'], session("order_server_$id")['cycle']['data']['cycle_type'])) }}
                            @endif
                        </p>
                    </div>
                    <div class="col-lg-3 col-md-6 mb-1">
                        <a href="{{ route('order', ['id' => $id]) }}" class="card-link"><i class="fas fa-arrow-left text-sm"></i> Configure plan</a>
                    </div>
                </div>
            </div>
            <form action="{{ route('api.store.checkout', ['id' => $id]) }}" method="POST" data-callback="checkoutForm" id="checkout-form">
                @csrf

                @guest
                <div class="form-group row">
                    <label class="col-lg-3 col-form-label" for="checkout-email">Account email</label>
                    <div class="col-lg-7">
                        <input type="email" class="form-control" name="email" id="checkout-email" required maxlength="255" placeholder="you@example.com" autocomplete="email">
                        <small class="form-text text-muted">We email your billing + game panel login, invoice amount, and renew date here.</small>
                    </div>
                </div>
                @endguest

                <div class="form-group row">
                    <label class="col-lg-3 col-form-label">Payment Method</label>
                    <div class="col-lg-7">
                        @forelse ($enabledGateways as $index => $gateway)
                            <div class="form-check mb-2">
                                <input
                                    class="form-check-input"
                                    type="radio"
                                    name="gateway"
                                    id="gateway-{{ $gateway::$display_name }}"
                                    value="{{ $gateway::$display_name }}"
                                    @if ($index === 0) checked required @endif
                                >
                                <label class="form-check-label" for="gateway-{{ $gateway::$display_name }}">
                                    {{ $gateway::$display_name }}
                                </label>
                            </div>
                        @empty
                            <div class="alert alert-warning mb-0">
                                No payment gateway is enabled. Ask an admin to enable <strong>PayPal</strong> under Extensions.
                            </div>
                        @endforelse
                    </div>
                </div>
                <div class="form-group row">
                    <div class="col-lg-5"></div>
                    <button type="submit" class="btn btn-primary col-lg-2" @if (empty($enabledGateways)) disabled @endif>
                        Checkout <i class="fas fa-arrow-circle-right"></i>
                    </button>
                </div>
            </form>
        </div>
    </div>
@endsection

@section('store_scripts')
    <script>
        function checkoutForm(data) {
            if (data.success) {
                toastr.info(data.success)
                waitRedirect('{{ route('client.server.index') }}')
            } else if (data.info) {
                toastr.info(data.info)
                waitRedirect(data.url)
            } else if (data.error) {
                toastr.error(data.error)
            } else if (data.errors) {
                data.errors.forEach(error => { toastr.error(error) });
            } else {
                wentWrong()
            }
        }

        $('#checkout-form').on('submit', function () {
            if (!$('input[name="gateway"]:checked').length) {
                toastr.error('Please select a payment method (PayPal).');
                return false;
            }
        });
    </script>
@endsection

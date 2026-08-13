@php $header_route = "plans"; @endphp

@extends('layouts.store')

@php
use App\Models\Server;
use App\Models\Plan;
use App\Models\Category;
@endphp

@inject('plan_model', 'App\Models\Plan')
@inject('plan_cycle_model', 'App\Models\PlanCycle')
@inject('category_model', 'App\Models\Category')
@inject('addon_model', 'App\Models\Addon')
@inject('addon_cycle_model', 'App\Models\AddonCycle')
@inject('discount_model', 'App\Models\Discount')
@inject('pterodactyl', 'App\Services\Pterodactyl')

@section('title', $plan->name)
@section('header', 'Server Plans')

@section('content')
    @php
        $plan_find = Plan::find($plan->id);
        if(is_null($plan_find->global_limit)) {
            $global_all_limit = NULL;
        } else {
            $servers = Server::where('plan_id', $plan_find->id)
                ->where(function ($query) {
                    $query->where('status', 0)
                          ->orWhere('status', 1);
                })->count();
            $global_all_limit = $plan_find->global_limit - $servers;
            if ($global_all_limit < 0) {
                $global_all_limit = 0;
            }
        }
        if (!is_null($global_all_limit) && $global_all_limit == 0) {
            echo '<script>window.location.href = "/"</script>';
        }
    @endphp
    <div class="row">
        <div class="col-lg-9">
            <div class="card">
                <div class="card-body">
                    <h5 class="card-title"><i>{{ $category_model->find($plan->category_id)->name }}: {{ $plan->name }}</i></h5>
                    <p class="card-text">
                        <ul>
                            <li>{{ $plan->ram }} GB RAM</li>
                            <li>{{ $plan->cpu }}% CPU</li>
                            <li>{{ $plan->disk }} GB Disk</li>
                            <li>{{ $plan->databases }} Databases</li>
                            <li>{{ $plan->backups }} Backups</li>
                            <li>{{ $plan->extra_ports }} Extra Ports</li>
                        </ul>
                    </p>
                    <a {!! to_page('plans') !!} class="card-link"><i class="fas fa-arrow-left text-sm"></i> Choose another server plan</a>
                </div>
            </div>
            <form action="{{ route('api.store.order', ['id' => $id]) }}" method="POST" id="order-form" data-callback="orderForm">
                @csrf

                <div class="form-group row">
                    <label for="serverNameInput" class="col-lg-4 col-form-label">Server Name</label>
                    <div class="col-lg-6">
                        <input type="text" name="server_name" class="form-control" id="serverNameInput" placeholder="This option can be changed later in the panel">
                    </div>
                </div>
                <div class="form-group row">
                    <label class="col-lg-4 col-form-label">Billing Cycle</label>
                    <div class="col-lg-6">
                        <select class="form-control" name="cycle" id="billing-cycle" onchange="updatePage($('form').serialize())">
                            @foreach ($plan_cycle_model->where('plan_id', $id)->get() as $plan_cycle)
                                @php $plan_percent_off = 1; @endphp
                                @foreach ($discount_model->getValidDiscounts() as $discount)
                                    @if ($plan->discount === $discount->id || $discount->is_global)
                                        @php $plan_percent_off = 1 - ($discount->percent_off / 100); @endphp
                                        @break
                                    @endif
                                @endforeach
                                <option value="{{ $plan_cycle->id }}">
                                    {!! price($plan_cycle->init_price * $plan_percent_off) !!}
                                    / {{ $plan_cycle_model->type_name($plan_cycle->cycle_length, $plan_cycle->cycle_type) }}
                                    @if ($plan_cycle->setup_fee > 0)
                                        ({!! session('currency')->symbol !!}{{ $plan_cycle->setup_fee * session('currency')->rate * $plan_percent_off }} Setup)
                                    @endif
                                    @unless ($plan_cycle->init_price === $plan_cycle->renew_price || $plan_cycle->cycle_type === 0)
                                        [ Renew: {!! session('currency')->symbol !!}{{ $plan_cycle->renew_price * session('currency')->rate }} ]
                                    @endunless
                                </option>
                            @endforeach
                        </select>
                    </div>
                </div>
                <hr>
                <div class="form-group row">
                    <label class="col-lg-2 col-form-label">Add-ons</label>
                    <div class="col-lg-9"> <div id="addons"></div> </div>
                </div>
                <hr>
                <div class="form-group row">
                    <label class="col-lg-4 col-form-label" for="order-egg">Game / Software</label>
                    <div class="col-lg-6">
                        <select class="form-control" name="egg" id="order-egg" required>
                            @php
                                $allowedEggs = is_array($decoded = json_decode($plan->nests_eggs_id, true)) ? $decoded : [];
                                $nest_api = $pterodactyl->getNests();
                                // Prefer unique, modern eggs (skip duplicate Node/FiveM generics)
                                $skipEggIds = [15, 17, 18];
                                $defaultEgg = null;
                                $planName = strtolower((string) $plan->name);
                                $categoryName = strtolower((string) optional($category_model->find($plan->category_id))->name);
                                $guessMap = [
                                    'discord.js' => '8:20', 'discord.py' => '8:21', 'bot' => '8:20',
                                    'python' => '8:23', 'node' => '8:22',
                                    'fivem' => '6:16', 'gta' => '6:16', 'free plan' => '6:16',
                                    'paper' => '1:3', 'dirt' => '1:3', 'stone' => '1:3', 'iron' => '1:3',
                                    'diamond' => '1:3', 'netherite' => '1:3',
                                    'vanilla' => '1:1', 'forge' => '1:4', 'bungee' => '1:2', 'sponge' => '1:5',
                                    'cs:go' => '2:7', 'csgo' => '2:7', 'ark' => '2:8', 'team fortress' => '2:9', 'tf2' => '2:9',
                                    "garry" => '2:11', 'gmod' => '2:11', 'insurgency' => '2:10',
                                    'rust' => '4:14', 'mumble' => '3:12', 'teamspeak' => '3:13', 'lavalink' => '3:19',
                                ];
                                foreach ($guessMap as $needle => $eggKey) {
                                    if (str_contains($planName, $needle) || str_contains($categoryName, $needle)) {
                                        if (in_array($eggKey, $allowedEggs, true)) {
                                            $defaultEgg = $eggKey;
                                            break;
                                        }
                                    }
                                }
                                if (!$defaultEgg && str_contains($categoryName, 'bot') && in_array('8:20', $allowedEggs, true)) {
                                    $defaultEgg = '8:20';
                                }
                            @endphp
                            @foreach ($nest_api['data'] as $nest)
                                @php
                                    $nestEggs = [];
                                    foreach ($nest['attributes']['relationships']['eggs']['data'] as $egg) {
                                        $eggId = (int) $egg['attributes']['id'];
                                        $key = $nest['attributes']['id'].':'.$eggId;
                                        if (in_array($eggId, $skipEggIds, true)) continue;
                                        if (!in_array($key, $allowedEggs, true)) continue;
                                        $nestEggs[] = [$key, $egg['attributes']['name']];
                                    }
                                @endphp
                                @continue(empty($nestEggs))
                                <option value="" disabled>— {{ $nest['attributes']['name'] }} —</option>
                                @foreach ($nestEggs as [$eggKey, $eggName])
                                    <option value="{{ $eggKey }}" @selected($defaultEgg === $eggKey)>{{ $eggName }}</option>
                                @endforeach
                            @endforeach
                        </select>
                        <small class="form-text text-muted">Pick the game or software egg. Runtimes (Node/Python versions) are chosen later in the game panel.</small>
                    </div>
                </div>
                <div class="form-group row">
                    <label class="col-lg-4 col-form-label" for="order-node">Hosting Node</label>
                    <div class="col-lg-6">
                        <select class="form-control" name="node" id="order-node" required>
                            @php $location_api = $pterodactyl->getLocations(); @endphp
                            @foreach ($location_api['data'] as $location)
                                @foreach ($location['attributes']['relationships']['nodes']['data'] as $node)
                                    @php
                                        $nodeKey = $location['attributes']['id'].':'.$node['attributes']['id'];
                                        $allowedNodes = is_array($decodedNodes = json_decode($plan->locations_nodes_id, true)) ? $decodedNodes : [];
                                        $isMain = (int) $node['attributes']['id'] === 1;
                                    @endphp
                                    @if (in_array($nodeKey, $allowedNodes, true) || $isMain)
                                        <option value="{{ $nodeKey }}" @selected($isMain)>
                                            {{ $node['attributes']['name'] }}
                                            — {{ $location['attributes']['long'] }}
                                            ({{ $node['attributes']['fqdn'] }})
                                        </option>
                                    @endif
                                @endforeach
                            @endforeach
                        </select>
                        <small class="form-text text-muted">Servers are created on this node in the hosting panel (Main Node).</small>
                    </div>
                </div>
                <div class="form-group row">
                    <label for="couponCodeInput" class="col-lg-4 col-form-label">Coupon Code</label>
                    <div class="col-lg-4 col-9">
                        <input type="text" name="coupon" class="form-control" id="couponCodeInput" placeholder="Coupon Code">
                    </div>
                    <div class="col-lg-3 col-3">
                        <button type="button" class="btn btn-primary" onclick="updatePage($('form').serialize())">Apply <i class="fas fa-arrow-circle-right"></i></button>
                    </div>
                </div>
            </form>
        </div>
        <div class="col-lg-3">
            <div class="card card-primary card-outline">
                <div class="card-header">
                    <h5 class="card-title m-0">Order Summary</h5>
                </div>
                <div class="card-body">
                    <h6>Server <span class="float-right">{{ $plan->name }}</span></h6>
                    <small>
                        <span id="plan-cycle"></span> <span class="float-right">{!! session('currency')->symbol !!}<span id="plan-init"></span> {{ session('currency')->name }}</span><br>
                        Setup Fee <span class="float-right">{!! session('currency')->symbol !!}<span id="plan-setup"></span> {{ session('currency')->name }}</span>
                    </small>
                    <hr>
                    <div id="addons-summary"></div>
                    <h6>Subtotal <span class="float-right">{!! session('currency')->symbol !!}<span id="subtotal"></span> {{ session('currency')->name }}</span></h6>
                    <div id="promotion-summary"></div>
                    <small>
                        <div id="tax-summary"></div>
                        <div id="credit-summary"></div>
                    </small>
                    <hr>
                    <h6>Due Today <span class="float-right">{!! session('currency')->symbol !!}<span id="due-today"></span> {{ session('currency')->name }}</span></h6>
                    @if (auth()->check() && $plan_model->verifyPlanTrial($plan, auth()->user()))
                        <small class="card-title">{{ $plan->trial }}-day free trial</small><br>
                    @endif
                    <small><div id="next-summary"></div></small><br>
                    <button type="submit" form="order-form" class="btn btn-primary float-right">Continue <i class="fas fa-arrow-circle-right"></i></button>
                </div>
            </div>
        </div>
    </div>
@endsection

@section('store_scripts')
    <script>
        const currencyRate = {{ session('currency')->rate }}
        const addons = document.getElementById("addons")
        const billingCycle = document.getElementById("billing-cycle")
        const planCycle = document.getElementById("plan-cycle")
        const planInit = document.getElementById("plan-init")
        const planSetup = document.getElementById("plan-setup")
        const addonsSummary = document.getElementById("addons-summary")
        const promotionSummary = document.getElementById("promotion-summary")
        const taxSummary = document.getElementById("tax-summary")
        const creditSummary = document.getElementById("credit-summary")
        const subtotal = document.getElementById("subtotal")
        const couponDiscount = document.getElementById("coupon-discount")
        const creditDiscount = document.getElementById("credit-discount")
        const dueToday = document.getElementById("due-today")
        const nextSummary = document.getElementById("next-summary")

        const taxPercent = {{ session('tax')->percent }}
        const taxAmount = {{ session('tax')->amount }}

        var last_updated = 0
        var pending = null

        function updatePage(form) {
            if (pending) {
                pending = form
                return
            }
            var mills = Date.now() - last_updated
            if (mills < 1000 * 2) {
                pending = form
                setTimeout(function() {
                    last_updated = Date.now()
                    pageUpdateAPI(pending)
                    pending = null
                }, mills)
            } else {
                last_updated = Date.now()
                pageUpdateAPI(form)
            }
        }

        function pageUpdateAPI(form) {
            const link = '{{ route('api.store.order.summary', ['id' => $id]) }}'
            $.ajax({
                'url': link,
                'data': form,
                'headers': {
                    'Accept': 'application/json; charset=UTF-8',
                    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                },
                'method': 'POST',
                'success': function(data) {
                    if (data.success) {
                        addons.innerHTML = addonsSummary.innerHTML = ''
                        if (data.success.addons.length > 0) {
                            data.success.addons.forEach(addon => {
                                addon_html = `
                                    <div class="form-group">
                                        <label for="addon-${addon[0].id}-range">${addon[0].name}</label>
                                        <span class="float-right">{!! session('currency')->symbol !!}${addon[1].init_price * currencyRate} {{ session('currency')->name }} / ${data.success.cycle.name}
                                `
                                if (addon[1].setup_fee > 0) addon_html += ` ({!! session('currency')->symbol !!}${addon[1].setup_fee * currencyRate} Setup)`
                                if (addon[1].renew_price > 0 && data.success.cycle.data.cycle_type > 0) addon_html += ` [ Renew: {!! session('currency')->symbol !!}${addon[1].renew_price * currencyRate} ]`
                                addon_html += `
                                        </span>
                                        <input type="text" name="addon[${addon[0].id}]" value="" id="addon-${addon[0].id}-range" onchange="updatePage($('form').serialize())">
                                        <small>${addon[0].description}</small>
                                    </div>
                                `
                                addons.innerHTML += addon_html

                                if (addon[2] > 0) {
                                    const div = document.createElement("div")
                                    div.setAttribute("id", `addon_${addon.id}`)
                                    div.innerHTML = `
                                        <h6>Add-on <span class="float-right">${addon[2]} x ${addon[0].name}</span></h6>
                                        <small>
                                            ${data.success.cycle.name} <span class="float-right">$${addon[1].init_price * currencyRate * addon[2]}</span><br>
                                            Setup Fee <span class="float-right">$${addon[1].setup_fee * currencyRate * addon[2]}</span>
                                        </small>
                                        <hr>
                                    `;
                                    addonsSummary.appendChild(div)
                                }

                                $(function () {
                                    $(`#addon-${addon[0].id}-range`).ionRangeSlider({
                                        min     : 0,
                                        max     : addon[0].resource == 'dedicated_ip' ? 1 : (addon[0].per_server_limit ? addon[0].per_server_limit : 500),
                                        type    : 'single',
                                        step    : 1,
                                        from    : addon[2],
                                        prettify: false,
                                        hasGrid : true
                                    })
                                })
                            })
                        } else {
                            addons.innerHTML = '<label>No add-ons are available for this server plan or billing cycle.</label>'
                        }

                        planCycle.innerHTML = data.success.cycle.name
                        planInit.innerHTML = data.success.cycle.data.init_price * currencyRate
                        planSetup.innerHTML = data.success.cycle.data.setup_fee * currencyRate
                        subtotal.innerHTML = data.success.subtotal * currencyRate
                        dueToday.innerHTML = data.success.summary.due_today * currencyRate

                        if (data.success.discount) {
                            promotionSummary.innerHTML = `
                                <hr>
                                <h6>
                                    Discount <span class="float-right">-{!! session('currency')->symbol !!}${data.success.promotion_off * currencyRate} {{ session('currency')->name }}</span>
                                </h6>
                                <small>
                                    ${data.success.discount.name} <span class="float-right">${data.success.discount.percent_off}% Off</span><br>
                                </small>
                                <hr>
                            `
                        } else if (data.success.coupon) {
                            const onetime = data.success.coupon.one_time ? ' [One-time]' : ''
                            promotionSummary.innerHTML = `
                                <hr>
                                <h6>
                                    Coupon <span class="float-right">-{!! session('currency')->symbol !!}${data.success.promotion_off * currencyRate} {{ session('currency')->name }}</span>
                                </h6>
                                <small>
                                    ${data.success.coupon.code}${onetime} <span class="float-right">${data.success.coupon.percent_off}% Off</span><br>
                                </small>
                                <hr>
                            `
                        }

                        if (taxPercent > 0 || taxAmount > 0) {
                            var taxVar = taxPercent > 0 ? `${taxPercent}%` : `{!! session('currency')->symbol !!}${taxAmount * currencyRate} {{ session('currency')->name }}`
                            taxSummary.innerHTML = `
                                Tax <span class="float-right">+${taxVar}</span><br>
                            `
                        }

                        if (data.success.credit > 0) {
                            creditSummary.innerHTML = `
                                Credit <span class="float-right">{!! session('currency')->symbol !!}${data.success.credit * currencyRate} {{ session('currency')->name }}</span>
                            `
                        }

                        if (data.success.cycle.data.cycle_type > 0) {
                            nextSummary.innerHTML = `Next ${data.success.cycle.name} <span class="float-right">{!! session('currency')->symbol !!}${data.success.summary.due_next * currencyRate} {{ session('currency')->name }}</span>`
                        }
                    } else if (data.error) {
                        toastr.error(data.error)
                    } else if (data.errors) {
                        data.errors.forEach(error => { toastr.error(error) });
                    } else {
                        wentWrong()
                    }
                },
                'error': function() { wentWrong() }
            })
        }

        function orderForm(data) {
            if (data.success) {
                toastr.success(data.success)
                waitRedirect('{{ route('checkout', ['id' => $id]) }}')
            } else if (data.error) {
                toastr.error(data.error)
            } else if (data.errors) {
                data.errors.forEach(error => { toastr.error(error) })
            } else {
                wentWrong()
            }
        }

    </script>

    <!-- Ion Slider -->
    <script>lazyLoadCss('/plugins/ion-rangeslider/css/ion.rangeSlider.min.css')</script>
    <script src="/plugins/ion-rangeslider/js/ion.rangeSlider.min.js"></script>
@endsection

<script>
function selectFirstOrderOptions() {
    const egg = document.getElementById('order-egg');
    const node = document.getElementById('order-node');
    if (egg && !egg.value) {
        for (const opt of egg.options) {
            if (opt.value && !opt.disabled) { egg.value = opt.value; break; }
        }
    }
    if (node) {
        let picked = false;
        for (const opt of node.options) {
            if (opt.value === '1:1' || (opt.value && /(^|:)1$/.test(opt.value) && opt.text.toLowerCase().includes('main'))) {
                node.value = opt.value;
                picked = true;
                break;
            }
        }
        if (!picked) {
            for (const opt of node.options) {
                if (opt.value === '1:1') { node.value = opt.value; picked = true; break; }
            }
        }
        if (!picked && !node.value) {
            for (const opt of node.options) {
                if (opt.value && !opt.disabled) { node.value = opt.value; break; }
            }
        }
    }
}
document.addEventListener('DOMContentLoaded', function() {
    selectFirstOrderOptions();
    if (typeof updatePage === 'function') updatePage($('form').serialize());
});
</script>

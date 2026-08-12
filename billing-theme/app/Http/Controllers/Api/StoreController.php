<?php

namespace App\Http\Controllers\Api;

use App\Jobs\CreatePanelUser;
use App\Jobs\InvoicePaid;
use App\Jobs\IssueServerInvoice;
use App\Models\Client;
use App\Models\Contact;
use App\Models\Invoice;
use App\Models\Plan;
use App\Models\PlanCycle;
use App\Models\Server;
use App\Models\ServerAddon;
use App\Models\UsedCoupon;
use App\Notifications\ContactForm;
use App\Rules\Captcha;
use Carbon\Carbon;
use Extensions\ExtensionManager;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class StoreController extends ApiController
{
    public function contact(Request $request)
    {
        if (!$receiver = config('page.contact')) {
            return $this->respondJson(['error' => 'Contact form disabled'], 403);
        }

        $validator = Validator::make($request->all(), [
            'email' => 'required|email|max:255',
            'name' => 'required|string|min:3|max:255',
            'subject' => 'required|string|min:20|max:255',
            'message' => 'required|string|min:50|max:5000',
            'h-captcha-response' => new Captcha,
        ]);

        if ($validator->fails()) {
            return $this->respondJson(['errors' => $validator->errors()->all()]);
        }

        $sender = Contact::create([
            'email' => $request->input('email'),
            'name' => $request->input('name'),
            'subject' => $request->input('subject'),
            'message' => $request->input('message'),
        ]);

        Notification::route('mail', $receiver)->notify(new ContactForm($sender->id));

        return $this->respondJson(['success' => 'Your message has been sent!']);
    }

    private $order_rules = [
        'cycle' => 'required|integer|exists:plan_cycles,id',
        'addon' => 'nullable|array',
        'addon.*' => 'nullable|integer|gte:0',
        'egg' => 'required|string',
        'node' => 'required|string',
        'coupon' => 'nullable|string|max:255|exists:coupons,code',
    ];

    /**
     * Enforce stock / per-client caps (Free Plan max 2 per person).
     * Free / capped plans require a logged-in account.
     */
    private function assertCanOrderPlan($id)
    {
        $plan = Plan::find($id);
        if (!$plan) {
            return $this->respondJson(['error' => 'That server plan was not found.'], 404);
        }

        if (!Plan::verifyPlan($plan)) {
            return $this->respondJson(['error' => 'This server plan is currently out of stock.']);
        }

        if ($plan->per_client_limit) {
            if (!auth()->check()) {
                return $this->respondJson([
                    'error' => 'Please log in or create an account to order this plan (max '
                        . (int) $plan->per_client_limit . ' per person).',
                ]);
            }

            if (!Plan::verifyPlan($plan, auth()->user())) {
                return $this->respondJson([
                    'error' => 'You already have the maximum of '
                        . (int) $plan->per_client_limit
                        . ' free/limited server(s) on this plan.',
                ]);
            }
        }

        return null;
    }

    public function summary(Request $request, $id)
    {
        if ($deny = $this->assertCanOrderPlan($id)) {
            return $deny;
        }

        $validator = Validator::make($request->all(), $this->order_rules);

        if ($validator->fails()) {
            return $this->respondJson(['errors' => $validator->errors()->all()]);
        }

        $resp = Server::genOrder($id, $request->input('cycle'), $request->input('addon'), $request->input('coupon'));

        return $this->respondJson([(is_string($resp) ? 'error' : 'success') => $resp]);
    }

    public function order(Request $request, $id)
    {
        if ($deny = $this->assertCanOrderPlan($id)) {
            return $deny;
        }

        $rules = array_merge(['server_name' => 'required|string|max:150'], $this->order_rules);
        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            return $this->respondJson(['errors' => $validator->errors()->all()]);
        }

        $order = Server::genOrder($id, $request->input('cycle'), $request->input('addon'), $request->input('coupon'));
        if (is_string($order)) {
            return $this->respondJson(['error' => $order]);
        }

        session(["order_server_$id" => array_merge($order, [
            'server_name' => $request->input('server_name'),
            'egg' => $request->input('egg'),
            'node' => $request->input('node'),
        ])]);

        return $this->respondJson(['success' => 'Redirecting you to the checkout page...']);
    }

    public function checkout(Request $request, $id)
    {
        if (!session()->has("order_server_$id")) {
            return redirect()->route('order', ['id' => $id]);
        }

        if ($deny = $this->assertCanOrderPlan($id)) {
            return $deny;
        }

        if (is_null($extension = ExtensionManager::getExtension($gateway = $request->input('gateway')))) {
            return $this->respondJson(['error' => 'The payment gateway is invalid!']);
        }

        $order_data = session("order_server_$id");
        session()->forget("order_server_$id");

        // Free / capped plans never use guest checkout
        $plan = Plan::find($id);
        if ($plan && $plan->per_client_limit && !auth()->check()) {
            return $this->respondJson([
                'error' => 'Please log in to claim a free server (max '
                    . (int) $plan->per_client_limit . ' per person).',
            ]);
        }

        $clientId = auth()->check() ? auth()->user()->id : $this->createGuestAccount();

        // Logged-in buyers still need a Pterodactyl user before provisioning.
        if (auth()->check() && empty(auth()->user()->user_id)) {
            try {
                CreatePanelUser::dispatchSync(auth()->user());
            } catch (\Throwable $e) {
                Log::error('[checkout] CreatePanelUser sync failed: ' . $e->getMessage());
            }
        }

        // Re-check after resolving the client (race-safe for free plan)
        if ($plan && $plan->per_client_limit) {
            $owned = Server::where('client_id', $clientId)
                ->where('plan_id', $plan->id)
                ->where(function ($query) {
                    $query->where('status', 0)->orWhere('status', 1);
                })
                ->count();
            if ($owned >= (int) $plan->per_client_limit) {
                return $this->respondJson([
                    'error' => 'You already have the maximum of '
                        . (int) $plan->per_client_limit
                        . ' free server(s).',
                ]);
            }
        }

        $nest_egg_id = explode(':', $order_data['egg']);
        $location_node_id = explode(':', $order_data['node']);
        $server = Server::create([
            'client_id' => $clientId,
            'plan_id' => $id,
            'plan_cycle' => $order_data['cycle']['data']['id'],
            'due_date' => $order_data['cycle']['data']['cycle_type'] === 0 ? null : Carbon::now()->addSeconds(PlanCycle::type_sec(
                $order_data['cycle']['data']['cycle_length'], $order_data['cycle']['data']['cycle_type'])),
            'payment_method' => $gateway,
            'server_name' => $order_data['server_name'],
            'nest_id' => $nest_egg_id[0],
            'egg_id' => $nest_egg_id[1],
            'location_id' => $location_node_id[0],
            'node_id' => $location_node_id[1],
        ]);

        foreach ($order_data['addons'] as $addon) {
            $value = null;
            if ($addon[0]->resource == 'dedicated_ip') {
                foreach (explode(',', $addon[0]->amount) as $ip) {
                    if (ServerAddon::where('addon_id', $addon[0]->id)->where('value', $ip)->exists()) {
                        continue;
                    } else {
                        $value = $ip;
                        break;
                    }
                }

                if (is_null($value)) {
                    return $this->respondJson(['error' => 'No dedicated IP addresses are available! Please try again later.']);
                }
            } else {
                $value = $addon[2];
            }

            ServerAddon::create([
                'addon_id' => $addon[0]->id,
                'cycle_id' => $addon[1]->id,
                'server_id' => $server->id,
                'client_id' => $clientId,
                'value' => $value,
            ]);
        }

        if ($order_data['coupon']) {
            UsedCoupon::create([
                'coupon_id' => $order_data['coupon']['id'],
                'client_id' => $clientId,
                'server_id' => $server->id,
            ]);
        }

        if (auth()->check() && Plan::verifyPlanTrial(Plan::find($id), auth()->user())) {
            return $this->respondJson(['success' => 'You have activated your free trial successfully! Redirecting...']);
        }

        IssueServerInvoice::dispatchSync($server, $order_data['summary']['due_today'], $order_data['credit']);

        $invoice = Invoice::where('server_id', $server->id)->latest()->first();
        if ($order_data['summary']['due_today'] === 0.000000) {
            InvoicePaid::dispatchSync($invoice);

            return $this->respondJson(['success' => 'You have ordered a free server successfully! Redirecting...']);
        }

        session(['payment_invoice' => $invoice]);

        $fallbackUrl = route('client.server.index');
        $link_pay = $extension::checkout($invoice, $fallbackUrl);

        if (empty($link_pay) || $link_pay === $fallbackUrl) {
            Log::error('[checkout] Payment gateway did not return an approval URL for invoice ' . $invoice->id);

            return $this->respondJson([
                'error' => 'Payment gateway failed to start checkout. Please try again in a moment, or contact support.',
            ]);
        }

        Invoice::where('server_id', $server->id)->update(['payment_link' => $link_pay]);

        return $this->respondJson([
            'info' => 'You\'re being redirected to a third-party payment gateway...',
            'url' => $link_pay,
        ]);
    }

    private function createGuestAccount()
    {
        if (auth()->check()) {
            return auth()->id();
        }

        $currency = session('currency');
        $tax = session('tax');
        $currencyName = (is_object($currency) && !empty($currency->name)) ? $currency->name : 'USD';
        $country = (is_object($tax) && !empty($tax->country)) ? $tax->country : 'Global';

        $email = 'guest_' . Str::random(10) . '@phantom-chicken.com';
        $password_raw = Str::random(16);
        $client = Client::create([
            'email' => $email,
            'password' => Hash::make($password_raw),
            'currency' => $currencyName,
            'country' => $country,
            'timezone' => 'UTC',
            'language' => 'EN',
            'is_active' => 1,
        ]);

        Auth::login($client);

        try {
            CreatePanelUser::dispatch($client)->onQueue('high');
        } catch (\Throwable $e) {
            Log::error('[checkout] CreatePanelUser dispatch failed: ' . $e->getMessage());
        }

        return $client->id;
    }

    public function payment(Request $request)
    {
        if (is_null($payment = session('payment_invoice'))) {
            return redirect()->route('client.invoice.index')->with('danger_msg', 'Invalid invoice! Please try again.');
        }

        session()->forget('payment_invoice');
        $url = $payment->server_id ? route('client.server.index') : route('client.credit.show');
        if (ExtensionManager::getGatewayExtension($payment->payment_method)::payment($request, $payment, $url)) {
            $invoice = Invoice::where('id', $payment->id)->first();
            if (!$invoice->paid) {
                InvoicePaid::dispatchSync($invoice);
            }

            return redirect($url)
                ->with('success_msg', 'You have paid the invoice successfully!');
        }

        return redirect($url)->with('danger_msg', 'We can\'t process your payment! Please try again.');
    }
}

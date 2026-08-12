<?php

namespace App\Http\Middleware\Store;

use App\Models\Plan;
use Closure;
use Illuminate\Http\Request;

class CheckPlanOrder
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle(Request $request, Closure $next)
    {
        if (is_null($plan = Plan::find($request->route('id')))) {
            return abort(404);
        }

        if (!Plan::verifyPlan($plan)) {
            return back()->with('warning_msg', 'The server plan is currently out of stock.');
        }

        // Plans with a per-client cap (e.g. Free Plan) require an account
        // so the limit cannot be bypassed via guest checkout.
        if ($plan->per_client_limit && !$request->user()) {
            return redirect()->route('home')->with(
                'warning_msg',
                'Please log in or create an account to order this plan (limit ' . (int) $plan->per_client_limit . ' per person).'
            );
        }

        if ($client = $request->user()) {
            if (!Plan::verifyPlan($plan, $client)) {
                return redirect()->route('plans')->with(
                    'danger_msg',
                    'You have reached the maximum of ' . (int) $plan->per_client_limit . ' server(s) on this plan.'
                );
            }
        }

        return $next($request);
    }
}

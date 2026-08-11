<?php

namespace App\Http\Middleware\Store;

use App\Models\Currency;
use App\Models\Tax;
use Closure;
use Illuminate\Http\Request;

class SetDefaultSession
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
        $defaultCurrency = Currency::where('default', true)->first();
        $sessionCurrency = session('currency');
        $currencyId = is_object($sessionCurrency) ? ($sessionCurrency->id ?? null) : null;
        $freshCurrency = $currencyId ? Currency::find($currencyId) : null;

        // Always refresh from DB so renamed/deleted currencies (e.g. "US Dollar")
        // cannot stick in the session forever.
        session(['currency' => $freshCurrency ?: $defaultCurrency]);

        $defaultTax = Tax::where('country', 'Global')->first() ?: Tax::where('country', '0')->first();
        $sessionTax = session('tax');
        $taxId = is_object($sessionTax) ? ($sessionTax->id ?? null) : null;
        $freshTax = $taxId ? Tax::find($taxId) : null;
        if (is_null(session('tax')) || is_null($freshTax)) {
            session(['tax' => $freshTax ?: $defaultTax]);
        }

        return $next($request);
    }
}

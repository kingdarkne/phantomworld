<!DOCTYPE html>
<html lang="en">
    <head>
        <title>@yield('title') - {{ config('app.company_name') }}</title>
        @include('layouts.styles')
    </head>
    <body class="hold-transition layout-top-nav @if(config('app.dark_mode')) dark-mode @endif @if(Route::currentRouteName() === 'home') ph-home @endif">
        <div class="wrapper">
            @include('layouts.preloader')

            @include('layouts.store.nav')

            <div class="content-wrapper" id="page-content">
                @include('layouts.store.header')

                <div class="content">
                    <div class="container" id="content-container">
                        @include('layouts.store.alerts')
                        @include('layouts.store.announcement')
                        @include('layouts.store.messages')
                        @yield('content')
                    </div>

                    @include('layouts.store.modals')
                </div>
            </div>

            @include('layouts.store.footer')
        </div>

        @include('layouts.scripts')
        @include('layouts.store.scripts')
    </body>
</html>

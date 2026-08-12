@if (true)
{{-- Always render so page chrome stays consistent across routes --}}
<div class="content-header @if(Route::currentRouteName() === 'home') ph-home-header @endif">
    @unless (Route::currentRouteName() === 'home')
    <div class="container">
        <div class="row mb-2">
            <div class="col-sm-6">
                <h1 class="m-0">@yield('title')</h1>
            </div>
            <div class="col-sm-6">
                <ol class="breadcrumb float-sm-right">
                    <li class="breadcrumb-item">Store</li>
                    <li class="breadcrumb-item active">@yield('title')</li>
                </ol>
            </div>
        </div>
    </div>
    @endunless
</div>
@endif

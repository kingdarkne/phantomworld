<footer class="main-footer">
    <div class="container">
        <div class="float-right d-none d-sm-inline">
            @if (config('page.status')) <a {!! to_page('status') !!}>System Status</a> | @endif<a {!! to_page('terms') !!}>Terms of Service</a> | <a {!! to_page('privacy') !!}>Privacy Policy</a> | <a href="{{ url('/discord/terms') }}">Bot Terms</a> | <a href="{{ url('/discord/privacy') }}">Bot Privacy</a>
        </div>
        <strong>Copyright &copy; {{ date('Y') }} <a {!! to_page('home') !!}>{{ config('app.company_name') }}</a>. All Rights Reserved.</strong>
    </div>
</footer>

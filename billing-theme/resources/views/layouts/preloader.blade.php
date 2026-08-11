<div class="preloader flex-column justify-content-center align-items-center">
    <img class="animation__shake" src="{{ config('app.logo_file_path') }}" alt="{{ config('app.company_name') }} Logo" height="72" width="72" decoding="async">
</div>
<script>
    // Hide preloader ASAP so first paint isn't stuck behind AdminLTE defaults
    window.addEventListener('DOMContentLoaded', function () {
        var el = document.querySelector('.preloader');
        if (!el) return;
        el.style.opacity = '0';
        el.style.visibility = 'hidden';
        setTimeout(function () { el.style.display = 'none'; }, 280);
    });
</script>

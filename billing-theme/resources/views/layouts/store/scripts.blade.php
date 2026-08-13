<!-- hCaptcha -->
<script src='https://js.hcaptcha.com/1/api.js' async defer></script>

<script>
    function loginForm(data) {
        if (data.success) {
            toastr.success(data.success)
            resetForms()
            waitRedirect(data.url ? data.url : '{{ route('client.dash') }}')
        } else if (data.error) {
            toastr.error(data.error)
        } else if (data.errors) {
            data.errors.forEach(error => { toastr.error(error) });
        } else {
            wentWrong()
        }
    }

    @if (config('app.open_registration'))
    function registerForm(data) {
        if (data.success) {
            toastr.success(data.success)
            resetForms()
            waitRedirect('{{ route('client.dash') }}')
        } else if (data.error) {
            toastr.error(data.error)
        } else if (data.errors) {
            data.errors.forEach(error => { toastr.error(error) });
        } else {
            wentWrong()
        }
    }
    @endif

    function forgotForm(data) {
        if (data.success) {
            toastr.success(data.success)
            resetForms()
        } else if (data.error) {
            toastr.error(data.error)
        } else if (data.errors) {
            data.errors.forEach(error => { toastr.error(error) });
        } else {
            wentWrong()
        }
    }

    function resetForm(data) {
        if (data.success) {
            toastr.success(data.success)
            resetForms()
            waitRedirect('{{ route('home', ['#login']) }}')
        } else if (data.error) {
            toastr.error(data.error)
        } else if (data.errors) {
            data.errors.forEach(error => { toastr.error(error) });
        } else {
            wentWrong()
        }
    }

    @if (config('page.contact'))
    function contactForm(data) {
        if (data.success) {
            toastr.success(data.success)
            resetForms()
        } else if (data.error) {
            toastr.error(data.error)
        } else if (data.errors) {
            data.errors.forEach(error => { toastr.error(error) });
        } else {
            wentWrong()
        }
    }
    @endif

    $(document).ready(function() {
        // Stale backdrops from earlier soft-nav / stacked modals block typing
        function clearStaleBackdrops() {
            $('.modal-backdrop').remove()
            $('body').removeClass('modal-open').css({ overflow: '', paddingRight: '' })
        }

        clearStaleBackdrops()

        // Keep a single backdrop; never leave an orphan layer over the dialog
        $(document).on('show.bs.modal', '.modal', function () {
            $('.modal-backdrop').not(':last').remove()
        })
        $(document).on('shown.bs.modal', '.modal', function () {
            $('.modal-backdrop').not(':last').remove()
            var $dialog = $(this).find('.modal-dialog')
            $dialog.css({ 'pointer-events': 'auto', 'z-index': 2020 })
            $(this).find('input:visible:first').trigger('focus')
        })
        $(document).on('hidden.bs.modal', '.modal', function () {
            if (!$('.modal.show').length) {
                clearStaleBackdrops()
            }
        })

        if (window.location.hash.toLowerCase() == '#login') {
            $('#login-modal').modal('show');
        } else if (window.location.hash.toLowerCase() == '#register') {
            $('#register-modal').modal('show');
        } else if (window.location.hash.toLowerCase() == '#forgot') {
            $('#forgot-modal').modal('show');
        }
    })
</script>

@yield('store_scripts')

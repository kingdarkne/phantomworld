# Billing site — bot legal pages (VPS manual deploy)

Upload these to `/var/www/billing/` on the VPS, then run:

```bash
cd /var/www/billing
php artisan route:clear
php artisan view:clear
php artisan cache:clear
```

## Footer fix (broken "Bot Terms" links → 404)

Edit `/var/www/billing/resources/views/layouts/store/footer.blade.php`.

**Wrong** (renders as literal `{ url(...) }` → 404):

```blade
<a href="{ url('/discord/terms') }">Bot Terms</a>
```

**Correct:**

```blade
<a href="{{ url('/discord/terms') }}">Bot Terms</a> | <a href="{{ url('/discord/privacy') }}">Bot Privacy</a>
```

## Working URLs (copy-paste for Discord Developer Portal)

| Field | URL |
|-------|-----|
| Terms of Service | `https://billing.phantom-chicken.com/discord/terms` |
| Privacy Policy | `https://billing.phantom-chicken.com/discord/privacy` |

GitHub Pages backup (after enabling Pages in repo settings):

| Field | URL |
|-------|-----|
| Terms | `https://kingdarkne.github.io/phantomworld/discord/terms/` |
| Privacy | `https://kingdarkne.github.io/phantomworld/discord/privacy/` |

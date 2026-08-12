# Billing panel theme (HedystiaBilling on VPS)

Custom storefront theme for **https://billing.phantom-chicken.com**.

Files under `public/` and `resources/views/` mirror paths on the VPS at `/var/www/billing/`.

## Deploy

```bash
VPS_PASSWORD='...' ./billing-theme/deploy.sh
```

## What changed

- Full-bleed Phantom landing (brand-first hero, CTAs, feature strip)
- Syne + Sora typography, teal/champagne on ink background
- Faster preloader, font preload, nginx gzip + 7-day static cache
- Optimized `galaxy_bg.webp` background
- Fixed Bot Terms / Bot Privacy footer links
- Checkout: import missing `Str`/`Hash`/`Auth`/`Client` so guest buy works
- Restored corrupted `CreatePanelUser` job (panel account creation)
- Client nav Discord link uses `client.bot.index`

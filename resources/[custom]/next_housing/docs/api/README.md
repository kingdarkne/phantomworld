# Next Housing API (External Integration)

This folder documents the public `next_housing` API for developers who want to:
- customize UI flows;
- integrate other scripts;
- read or trigger housing features without touching internal events.

Current API version: `1.1.0`.

## Branches

- `client-interfaces.md`: open/close UI and client context.
- `client-housing.md`: house, keys, garage actions and data.
- `client-job-pap.md`: dedicated Job and PAP endpoints.
- `server-housing.md`: server-side housing reads (houses, access, keys).
- `server-settings.md`: server-side public settings and marker bundle.
- `events.md`: realtime events (refresh/sync signals).

## Important Notes

- Client exports are async when a callback is required.
- Server exports return sync values (internally awaited).
- Export names in this folder are public/stable from API `1.1.0`.
- Premium Next Housing Extended (NHE) features are not exposed in this public API.

## Coverage

- All `server_exports` declared in `fxmanifest.lua` are documented.
- All client exports declared in `fxmanifest.lua` are documented, including compatibility export `TriggerOpenWardrobe`.

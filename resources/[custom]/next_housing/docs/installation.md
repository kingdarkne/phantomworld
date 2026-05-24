# Next Housing Installation Guide

This guide covers a safe and clean installation for next_housing (v1.8.x).

## 1. Requirements

- A running FiveM server (FXServer).
- One supported framework started before next_housing:
  - es_extended (ESX), or
  - qb-core (QBCore), or
  - qbx_core (Qbox).
- oxmysql installed and started.
- A MySQL/MariaDB database configured for your server.

## 2. Upload the Resource

1. Place the folder in your resources directory.
2. Keep the resource name as next_housing.

Important:
- Do not rename the resource (NUI/event paths are tied to next_housing).

## 3. Database Initialization

Do not import core/server/database/sql.sql manually.
next_housing initializes and migrates its database tables automatically at startup (via oxmysql), including tables such as:

- next_housing
- next_housing_keys
- next_housing_player_positions
- next_housing_settings
- next_housing_contracts
- next_housing_pap

## 4. Server.cfg Setup

Make sure dependencies start before next_housing.

Server.cfg example order:
- ensure oxmysql
- ensure es_extended
- ensure next_housing

If you use ACE-based admin access, add:

- add_ace group.admin command.nexthousing allow

## 5. First Start Validation

1. Start/restart the server.
2. Confirm there are no startup errors from next_housing or oxmysql.
3. In-game, test admin UI command:
   - /nexthousing (or /nh)
4. Confirm house markers/UI load and interactions work.

## 6. Updating From Older Versions

If you are upgrading from older branches (especially pre-1.8.0), read:
- READ THIS BEFORE UPDATING.md

Critical rule for old major versions:
- Remove the old next_housing folder completely before uploading the new one.

## 7. Common Issues

- No such export:
  - Resource order is wrong, or next_housing is not started.
- UI does not open:
  - Missing admin permission or framework not ready.
- Database errors:
  - oxmysql not started, wrong DB config, or SQL permissions/config prevent automatic table creation.

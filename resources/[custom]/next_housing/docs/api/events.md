# Useful Events (Realtime Sync)

These events can still be used for cache refresh and UI sync.
For business actions, prefer documented exports from this API folder.

## Client Events

- `next_housing:languageChanged`
- `next_housing:blipsEnabledChanged`
- `next_housing:spritesEnabledChanged`
- `next_housing:spriteHeightOffsetChanged`
- `next_housing:entranceDisplayDistanceChanged`
- `next_housing:chestDisplayDistanceChanged`
- `next_housing:stashesEnabledChanged`
- `next_housing:garagesEnabledChanged`
- `next_housing:housePreviewPlaceholdersEnabledChanged`
- `next_housing:housesUpdated`
- `next_housing:lockStatusChanged`
- `next_housing:job:updateHouses`
- `next_housing:pap:updateListings`
- `next_housing:pap:updateMyListings`
- `next_housing:pap:updateContracts`

## Recommendation

- Use exports as the primary integration contract.
- Use events only as realtime refresh signals.

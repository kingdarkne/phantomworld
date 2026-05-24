# Configuration Guide

> **⚠️ IMPORTANT:** This file is for documentation only! Do not use this file in-game.
> Edit `config.json` to change settings.
> Use Fivemanage for URL not YouTube !
---

## Color

The main text color for the loading screen.

- **Type:** Hex color code
- **Example:** `#FFFFFF`
- **Options:** Any hex color (e.g., `#FF0000` = red, `#00FF00` = green)

---

## Audio

### defaultVolume
Volume level for the background audio.

- **Type:** Number (0.0 to 1.0)
- **Example:** `0.05`
- **Options:** `0` = muted, `1` = max volume

### autoplay
Whether audio plays automatically when loading screen appears.

- **Type:** Boolean
- **Example:** `true`
- **Options:** `true` = plays automatically, `false` = requires user interaction

---

## Background

### type
Type of background content.

- **Type:** String
- **Example:** `video`
- **Options:** `video`, `image`, or `color`

### file
URL to the background file (video or image).

- **Type:** URL string
- **Example:** `https://example.com/video.mp4`
- **Note:** For videos, use `.mp4` format. For images, use `.png` or `.jpg`

---

## Locales

Text labels shown on the loading screen.

| Setting | Description | Example |
|---------|-------------|---------|
| `loading` | Main title text | `LOADING` |
| `loading_desc` | Description below title | `Downloading game data...` |
| `viewImage` | Button text to view full image | `View image` |
| `news` | Tab label for news section | `News` |
| `events` | Tab label for events section | `Events` |
| `gallery` | Tab label for gallery section | `Gallery` |
| `keybinds` | Tab label for keybinds section | `Keybinds` |

---

## Tabs

Enable or disable each tab in the loading screen.

| Setting | Description | Options |
|---------|-------------|---------|
| `news` | Show/hide news tab | `true` = enabled, `false` = disabled |
| `events` | Show/hide events tab | `true` = enabled, `false` = disabled |
| `gallery` | Show/hide gallery tab | `true` = enabled, `false` = disabled |
| `keybinds` | Show/hide keybinds tab | `true` = enabled, `false` = disabled |

---

## Navbuttons

Navigation buttons shown on the loading screen.

### website
- `text` - Button label
- `enabled` - Show/hide the button
- `url` - URL to open when clicked

### discord
- `text` - Button label
- `enabled` - Show/hide the button
- `url` - Discord invite link

### hideui
- `text` - Button to hide the UI overlay

### showui
- `text` - Button to show the UI overlay

---

## News

News items displayed in the news tab.

### Structure
```json
{
  "title": "Headline of the news item",
  "description": "Full description text",
  "image": "URL to thumbnail image",
  "date": "Date string (e.g., '2/2/2026')"
}
```

### Example
```json
{
  "title": "Your News Title Here",
  "description": "Your description here...",
  "image": "https://example.com/image.png",
  "date": "4/20/2026"
}
```

---

## Events

Event items displayed in the events tab.

### Structure
```json
{
  "title": "Event name",
  "description": "Event description",
  "image": "Image filename from assets folder or URL",
  "date": "Event date"
}
```

---

## Gallery

Gallery images displayed in the gallery tab.

### Structure
```json
{
  "image": "URL to image or filename from assets/gallery folder"
}
```

### Example
```json
{
  "image": "https://example.com/screenshot.png"
}
```

---

## Keybinds

Keybind items displayed in the keybinds tab.

### Structure
```json
{
  "key": "The keyboard key (e.g., 'E', 'F1', 'SPACE')",
  "description": "What the key does"
}
```

### Example
```json
{
  "key": "F1",
  "description": "Open menu"
}
```
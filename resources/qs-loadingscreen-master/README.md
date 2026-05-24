
![](https://img.shields.io/github/v/release/emanueldev1/qs-loadingscreen?logo=github)
![](https://img.shields.io/github/downloads/emanueldev1/qs-loadingscreen/total?logo=github)
![](https://img.shields.io/github/downloads/emanueldev1/qs-loadingscreen/latest/total?logo=github)
![](https://img.shields.io/github/contributors/emanueldev1/qs-loadingscreen?logo=github)

# Quasar Loading Screen


Quasar Loading Screen is a modern, customizable loading screen for FiveM servers, built with React, Tailwind CSS, and Vite. It provides a sleek, interactive interface with features like server status, rules, changelogs, keybinds, and dynamic audio/video backgrounds, enhancing the player experience during server connection. The project is highly customizable, allowing server owners to modify colors, text styles, and content via `config.json` and CSS.

## Features

- **Dynamic Loading Screen**: Displays real-time loading progress, server status, player count, and average ping.
- **Interactive Views**:
  - **Rules View**: Browse server rules with a searchable index.
  - **Changelogs View**: View update history with images and search functionality.
  - **Keybinds View**: Interactive keyboard layout with hover tooltips showing keybind details.
- **Customizable Configuration**: Configurable via `config.json` for server details, keybinds, rules, changelogs, audio, and background settings.
- **Text Styling**: Apply Tailwind CSS utility classes (e.g., `[Ctext-red-600 font-bold]`) to text in `config.json` for customized styling.
- **Responsive Design**: Optimized for various screen sizes using Tailwind CSS.
- **Audio/Video Support**: Supports YouTube or file-based video backgrounds and audio with volume controls.
- **Customizable Colors**: Modify UI and text colors via `web/src/index.css` and `config.json`.

## Visit Our Official Store

Discover the full range of premium FiveM scripts and tools at the [Quasar Store](https://www.quasar-store.com/). From immersive roleplay systems to cutting-edge server enhancements, our store offers everything you need to elevate your FiveM server. Shop now for instant delivery, regular updates, and top-tier support!

## Preview QS-LOADINGSCREEN

![qs-loadingscreen1](https://assets.quasar-store.com/qs-loadingscreen/image1.png)
![qs-loadingscreen2](https://assets.quasar-store.com/qs-loadingscreen/image2.png)
![qs-loadingscreen3](https://assets.quasar-store.com/qs-loadingscreen/image3.png)


## Prerequisites

To run or develop this project, ensure you have the following installed:

- **Node.js**: Version 20 or higher (recommended).
- **pnpm**: Package manager for installing dependencies and building the web app.
- **Git**: For version control and release automation.
- **FiveM Server**: The loading screen is designed to work with a FiveM server (tested with QBCore framework).

## Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/emanueldev1/qs-loadingscreen.git
   cd qs-loadingscreen
   ```

2. **Install Dependencies**:
   Navigate to the `web` directory and install dependencies using pnpm:
   ```bash
   cd web
   pnpm install
   ```

3. **Configure the Project**:
   - Edit `config.json` in the root directory to customize server details, keybinds, rules, changelogs, audio, and background settings. See [Configuration](#configuration) for details.
   - Ensure `fxmanifest.lua` is set up with the correct resource metadata for your FiveM server.

4. **Build the Web App**:
   Build the React app to generate the `/web/build` folder:
   ```bash
   cd web
   pnpm build
   ```

5. **Deploy to FiveM Server**:
   - Copy the entire project directory to your FiveM server's `resources` folder.
   - Ensure the resource is added to your server's configuration (`server.cfg`):
     ```lua
     ensure qs-loadingscreen
     ```

6. **Start the Server**:
   Start your FiveM server, and the loading screen will appear when clients connect.

## Downloading from GitHub Releases

Releases are available on the [GitHub Releases page](https://github.com/emanueldev1/qs-loadingscreen/releases). To use a release:

1. Visit the [Releases page](https://github.com/emanueldev1/qs-loadingscreen/releases).
2. Download the latest `release.zip` file for the desired version.
3. Extract the zip file, which contains:
   - `/web/build`: The built web assets.
   - `fxmanifest.lua`, `client.lua`, and other root files.
4. Copy the extracted files to your FiveM server's `resources` folder.
5. Add the resource to `server.cfg`:
   ```lua
   ensure qs-loadingscreen
   ```
6. Start or restart your FiveM server.

## Building the Project

To build the project manually:

1. **Install Dependencies**:
   ```bash
   cd web
   pnpm install
   ```

2. **Run the Build**:
   ```bash
   pnpm build
   ```
   This generates the production-ready assets in `web/build`.

3. **Copy Files**:
   - Copy the `web/build` folder, `fxmanifest.lua`, `client.lua`, and other root files to your FiveM server's `resources` folder.
   - Ensure the folder structure matches:
     ```
     resources/qs-loadingscreen/
     ├── web/build/
     ├── fxmanifest.lua
     ├── client.lua
     └── config.json
     ```

4. **Test the Build**:
   Start your FiveM server and connect to verify the loading screen works as expected.

## Customizing Colors

The Quasar Loading Screen allows customization of both UI colors and text-specific styling, enabling server owners to tailor the visual experience.

### Customizing UI Colors

UI colors are defined via CSS custom properties in `web/src/index.css`. These control the appearance of backgrounds, text, buttons, and custom elements like grid lines and particles.

#### Steps to Customize UI Colors (DARK, LIGHT changing not available default dark)

1. **Open `index.css`**:
   Navigate to `web/src/index.css`.

2. **Modify CSS Variables**:
   Edit the `:root` and `.dark` sections to change colors. Key variables include:
   - `--background`: Main background color (default: dark blue-gray, `240 10% 5%`).
   - `--foreground`: Main text color (default: light gray, `0 0% 95%`).
   - `--primary`: Primary color for buttons, highlights, and keybinds (default: vibrant blue, `199 100% 50%`).
   - `--secondary`: Secondary color for icons and accents (default: neon cyan, `180 100% 50%`).
   - `--custom-grid-line`: Grid overlay color (default: neon cyan, `#00f7ff`).
   - `--custom-glow-left` and `--custom-glow-right`: Glow effect colors (default: `#00b4ff`, `#00f7ff`).
   - `--custom-particle`: Particle animation color (default: `#00b4ff`).
   - `--custom-progress-bg`: Progress bar background (default: `#1e1e2e`).
   - `--custom-badge-bg` and `--custom-badge-border`: Badge colors (default: `#00b4ff`, `#00f7ff`).

   Example: To change the primary color to a green shade:
   ```css
   :root {
       --primary: 120 100% 50%; /* Green */
   }
   .dark {
       --primary: 120 100% 50%; /* Green for dark mode */
   }
   ```

3. **Rebuild the Project**:
   After editing `index.css`, rebuild the web app:
   ```bash
   cd web
   pnpm build
   ```

4. **Test Changes**:
   Copy the updated `web/build` to your FiveM server and restart to see the new colors.

5. **Optional: Preview Locally**:
   Run the development server to preview changes in real-time:
   ```bash
   cd web
   pnpm dev
   ```
   Open `http://localhost:5173` (or the port specified by Vite) to view the loading screen.

#### Notes on UI Color Customization
- Use HSL values (e.g., `199 100% 50%`) or HEX codes (e.g., `#00b4ff`) for consistency.
- Ensure sufficient contrast between `--foreground` and `--background` for readability.
- Test custom colors in both light and dark modes (though the project primarily uses dark mode).
- The `--custom-*` variables are specific to Quasar Loading Screen elements like grid lines, particles, and badges.

### Customizing Text Colors and Styles in `config.json`

Text colors and styles can be customized directly in `config.json` using a special `[C]` tag syntax to apply Tailwind CSS utility classes. This allows dynamic styling of text in fields like `server.title`, `keybinds.description`, and `rules.items.title`.

#### How Text Styling Works
- **Syntax**: Use `[C<class1 class2 ...>]Text[/C]` to apply Tailwind CSS classes to specific text.
  - `<class1 class2 ...>`: Space-separated Tailwind utility classes (e.g., `text-red-600`, `font-bold`).
  - `Text`: The text to style.
  - Example: `[Ctext-red-600 font-bold]Cheating[/C]` renders "Cheating" in red (`text-red-600`) and bold (`font-bold`).
- **Processing**: The `parseText` function in `web/src/lib/utils.js` parses these tags, and `renderParsedText` (in components like `KeybindsView.jsx`) renders them as `motion.span` elements with the specified classes.
- **Supported Classes**: Any Tailwind utility class available in your project, such as:
  - **Colors**: `text-red-600`, `text-blue-400`, `text-primary`, `text-secondary`.
  - **Typography**: `font-bold`, `font-semibold`, `text-sm`, `text-xl`, `underline`, `italic`.
  - **Other**: `uppercase`, `inline-block` (if applicable).

#### Steps to Customize Text Colors and Styles

1. **Edit `config.json`**:
   Add `[C]` tags to any text field (e.g., `server.title`, `keybinds.description`, `rules.items.content`).
   Example:
   ```json
   {
       "server": {
           "title": "QUASAR [Ctext-primary font-bold]LOADING SCREEN[/C]",
           "subtitle": "Join the [Ctext-blue-400 underline]Adventure[/C] today!"
       },
       "keybinds": [
           {
               "key": "[Ctext-secondary font-semibold]F1[/C]",
               "title": "Open [Ctext-blue-400]Inventory[/C]",
               "description": "Press [Ctext-secondary]F1[/C] to manage items."
           },
           {
               "key": "[Ctext-red-600]E[/C]",
               "title": "Interact with [Ctext-green-500]Environment[/C]",
               "description": "Use [Ctext-red-600]E[/C] to interact with objects."
           }
       ],
       "strings": {
           "proTipLabel": "🌟 [Ctext-secondary font-semibold]Pro Tip[/C]"
       }
   }
   ```

2. **Use Tailwind Classes**:
   - **Standard Colors**: Use classes like `text-red-600`, `text-blue-400`, `text-green-500`.
   - **Custom Colors**: Use `text-primary`, `text-secondary` (map to `--primary`, `--secondary` in `index.css`).
   - **Typography**: Combine with `font-bold`, `font-semibold`, `text-sm`, etc.
   - Example: `[Ctext-primary font-bold]` applies the vibrant blue color (`--primary`) and bold font.

3. **Create Custom Classes (Optional)**:
   To use a new color, define it in `web/src/index.css`:
   ```css
   :root {
       --custom-accent: #ff00ff; /* Magenta */
   }
   @layer utilities {
       .text-custom-accent {
           color: var(--custom-accent);
       }
   }
   ```
   Then use in `config.json`:
   ```json
   "proTips": [
       "Check out our [Ctext-custom-accent font-bold]new feature[/C]!"
   ]
   ```

4. **Rebuild the Project**:
   After editing `config.json` or `index.css`, rebuild the web app:
   ```bash
   cd web
   pnpm build
   ```

5. **Test Changes**:
   Copy the updated `web/build` to your FiveM server’s `resources/qs-loadingscreen` directory and restart the server.

#### Notes on Text Styling
- **Case Sensitivity**: For `keybinds.key` (e.g., `[Ctext-primary font-bold]F1[/C]`), ensure the key matches the keyboard layout in `KeybindsView.jsx` (case-insensitive due to `stripTags(k.key).toLowerCase()`).
- **Supported Classes**: Any Tailwind utility class in your `tailwind.config.js` can be used. Extend the Tailwind configuration if needed for additional classes.
- **Performance**: Avoid excessive `[C]` tag nesting to maintain rendering performance.
- **Preview Locally**: Use `pnpm dev` to preview text styling changes:
  ```bash
  cd web
  pnpm dev
  ```

## Usage

- **Loading Screen**: Appears automatically when players connect to the FiveM server, showing progress, server status, and tips.
- **Navigation**:
  - Click "View Server Rules" to browse rules.
  - Click "View Change Logs" to view update history.
  - Click "View Keybinds" to explore keybinds with an interactive keyboard layout.
  - Use the search bar in Rules, Changelogs, and Keybinds views to filter content.
- **Audio Controls**: Adjust volume or mute the video/audio background using controls in the bottom-left corner.
- **Release Process**:
  - Run `release.bat` (Windows) to update the version in `fxmanifest.lua`, build the web app, commit all changes, and push a release tag.
  - GitHub Actions will create a release with `/web/build`, `fxmanifest.lua`, `client.lua`, and other root files.

## Configuration

The `config.json` file in the root directory allows customization of the loading screen. Key sections include:

- **server**: Defines server ID, title, logo, name, subtitle, and description.
- **loadingPhases**: Customizes labels and icons for loading phases (e.g., startup, systems, assets).
- **strings**: Defines UI text strings with support for `[C]` tag formatting.
- **proTips**: Array of tips displayed during loading, supporting `[C]` tags.
- **rules**: Array of rule categories with titles, descriptions, and items, supporting `[C]` tags.
- **changeLogs**: Array of changelog entries with titles, dates, content, and optional images, supporting `[C]` tags.
- **keybinds**: Array of keybind objects with `key`, `title`, and `description` fields, supporting `[C]` tags.
- **audio**: Configures audio source, volume, loop, and whether to use video audio.
- **background**: Configures video background, loop, and start time.
- **particles**: Enables/disables particle effects and sets the count.
- **gridOverlay**: Configures an optional grid overlay.
- **blobs**: Defines decorative background blobs.

Example `keybinds` configuration:
```json
"keybinds": [
    {
        "key": "[Ctext-primary font-bold]F1[/C]",
        "title": "Open [Ctext-blue-400]Inventory[/C]",
        "description": "Opens the [Ctext-blue-400]inventory[/C] to manage your items and equipment."
    }
]
```

## Development

To develop locally:

1. **Run Development Server**:
   ```bash
   cd web
   pnpm dev
   ```
   This starts a Vite development server at `http://localhost:5173`.

2. **Modify Components**:
   - Components are in `web/src/components/` (e.g., `KeybindsView.jsx`, `RulesView.jsx`).
   - Main app logic is in `web/src/index.jsx`.
   - Utility functions are in `web/src/lib/utils.js`.
   - Styles are in `web/src/index.css`.

3. **Test in FiveM**:
   - Build the app (`pnpm build`) and copy `web/build` to your FiveM server resource.
   - Restart the server to test changes.

## Dependencies

This project relies on the following dependencies, with gratitude to their maintainers:

- **[React](https://reactjs.org/)**: JavaScript library for building user interfaces. Licensed under MIT.
- **[pnpm](https://pnpm.io/)**: Fast, disk space-efficient package manager. Licensed under MIT.
- **[Tailwind CSS](https://tailwindcss.com/)**: Utility-first CSS framework for styling. Licensed under MIT.
- **[Vite](https://vitejs.dev/)**: Frontend tooling for building and development. Licensed under MIT.
- **[Framer Motion](https://www.framer.com/motion/)**: Animation library for React (used as `motion/react`). Licensed under MIT.
- **[React Player](https://github.com/CookPete/react-player)**: Media player for video and audio playback. Licensed under MIT.
- **[Lucide React](https://lucide.dev/)**: Icon library for React. Licensed under ISC.
- **[Shadcn/UI](https://ui.shadcn.com/)**: Reusable UI components (e.g., `Card`, `Button`, `Input`). Licensed under MIT.
- **[Clsx](https://github.com/lukeed/clsx)**: Utility for constructing className strings. Licensed under MIT.
- **[Tailwind Merge](https://github.com/dcastil/tailwind-merge)**: Utility for merging Tailwind CSS classes. Licensed under MIT.

## Credits

- **Emanueldev1**: For designing and developing the Quasar Loading Screen.
- **FiveM Community**: For providing the platform and inspiration for custom loading screens.
- **Open Source Contributors**: Thanks to the maintainers of the above dependencies for their excellent work.

## License

This project is licensed under the LGPLv3 License. See the `LICENSE` file for details.

## Contributing

Contributions are welcome! Please open an issue or pull request on the [GitHub repository](https://github.com/emanueldev1/qs-loadingscreen) to suggest improvements or report bugs.

## Contact

For support or inquiries, open an issue on the [GitHub repository](https://github.com/emanueldev1/qs-loadingscreen).

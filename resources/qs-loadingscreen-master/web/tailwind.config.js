/** @type {import('tailwindcss').Config} */
import tailwindanimate from "tailwindcss-animate";

export default {
    darkMode: ["class"],
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    safelist: [
        // Custom color classes
        { pattern: /^text-(primary|secondary|foreground|muted-foreground|accent|popover|card|destructive)$/ },
        { pattern: /^bg-(primary|secondary|foreground|muted-foreground|accent|popover|card|destructive)$/ },
        { pattern: /^border-(primary|secondary|foreground|muted-foreground|accent|popover|card|destructive)$/ },
        // Tailwind default color palette
        { pattern: /^(text|bg|border)-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-[1-9]00$/ },
        // Opacity modifiers for all colors
        { pattern: /^(text|bg|border)-(primary|secondary|foreground|muted-foreground|accent|popover|card|destructive|slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-[1-9]00\/[0-9]+$/ },
        // Font utilities
        { pattern: /^font-(bold|semibold|medium|normal|light|extralight|thin|extrabold|black)$/ },
        // Text size utilities
        { pattern: /^text-(xs|sm|base|lg|xl|2xl|3xl|4xl|5xl|6xl|7xl|8xl|9xl)$/ },
        // Padding utilities
        { pattern: /^(p|px|py|pt|pb|pl|pr)-(0|px|0.5|1|1.5|2|2.5|3|3.5|4|5|6|7|8|9|10|11|12|14|16|20|24|28|32|36|40|44|48|52|56|60|64|72|80|96)$/ },
        // Margin utilities
        { pattern: /^(m|mx|my|mt|mb|ml|mr)-(auto|0|px|0.5|1|1.5|2|2.5|3|3.5|4|5|6|7|8|9|10|11|12|14|16|20|24|28|32|36|40|44|48|52|56|60|64|72|80|96)$/ },
        // Border utilities
        { pattern: /^border-(0|px|1|2|4|8)$/ },
        { pattern: /^border-(l|r|t|b)-(0|px|1|2|4|8)$/ },
        // Rounded utilities
        { pattern: /^rounded-(none|sm|md|lg|xl|2xl|3xl|full)$/ },
        // Shadow utilities
        { pattern: /^shadow-(none|sm|md|lg|xl|2xl|inner)$/ },
        // Flex and grid utilities
        { pattern: /^flex-(1|auto|initial|none)$/ },
        { pattern: /^flex-(row|col|row-reverse|col-reverse)$/ },
        { pattern: /^items-(start|end|center|baseline|stretch)$/ },
        { pattern: /^justify-(start|end|center|between|around|evenly)$/ },
        { pattern: /^gap-(0|px|0.5|1|1.5|2|2.5|3|3.5|4|5|6|7|8|9|10|11|12|14|16|20|24|28|32|36|40|44|48|52|56|60|64|72|80|96)$/ },
        // Spacing utilities
        { pattern: /^space-(x|y)-(0|px|0.5|1|1.5|2|2.5|3|3.5|4|5|6|7|8|9|10|11|12|14|16|20|24|28|32|36|40|44|48|52|56|60|64|72|80|96)$/ },
        // Width and height utilities
        { pattern: /^(w|h)-(0|px|0.5|1|1.5|2|2.5|3|3.5|4|5|6|7|8|9|10|11|12|14|16|20|24|28|32|36|40|44|48|52|56|60|64|72|80|96|auto|full|screen|min|max|fit)$/ },
    ],
    theme: {
        fontFamily: {
            'poppins': ['Poppins'],
        },
        extend: {
            borderRadius: {
                lg: 'var(--radius)',
                md: 'calc(var(--radius) - 2px)',
                sm: 'calc(var(--radius) - 4px)'
            },
            colors: {
                background: 'hsl(var(--background))',
                foreground: 'hsl(var(--foreground))',
                card: {
                    DEFAULT: 'hsl(var(--card))',
                    foreground: 'hsl(var(--card-foreground))'
                },
                popover: {
                    DEFAULT: 'hsl(var(--popover))',
                    foreground: 'hsl(var(--popover-foreground))'
                },
                primary: {
                    DEFAULT: 'hsl(var(--primary))',
                    foreground: 'hsl(var(--primary-foreground))'
                },
                secondary: {
                    DEFAULT: 'hsl(var(--secondary))',
                    foreground: 'hsl(var(--secondary-foreground))'
                },
                muted: {
                    DEFAULT: 'hsl(var(--muted))',
                    foreground: 'hsl(var(--muted-foreground))'
                },
                accent: {
                    DEFAULT: 'hsl(var(--accent))',
                    foreground: 'hsl(var(--accent-foreground))'
                },
                destructive: {
                    DEFAULT: 'hsl(var(--destructive))',
                    foreground: 'hsl(var(--destructive-foreground))'
                },
                border: 'hsl(var(--border))',
                input: 'hsl(var(--input))',
                ring: 'hsl(var(--ring))',
                chart: {
                    '1': 'hsl(var(--chart-1))',
                    '2': 'hsl(var(--chart-2))',
                    '3': 'hsl(var(--chart-3))',
                    '4': 'hsl(var(--chart-4))',
                    '5': 'hsl(var(--chart-5))'
                },
                custom: {
                    gridLine: 'var(--custom-grid-line)',
                    glowLeft: 'var(--custom-glow-left)',
                    glowRight: 'var(--custom-glow-right)',
                    particle: 'var(--custom-particle)',
                    progressBg: 'var(--custom-progress-bg)',
                    badgeBg: 'var(--custom-badge-bg)',
                    badgeBorder: 'var(--custom-badge-border)',
                }
            },
            keyframes: {
                'accordion-down': {
                    from: { height: '0' },
                    to: { height: 'var(--radix-accordion-content-height)' }
                },
                'accordion-up': {
                    from: { height: 'var(--radix-accordion-content-height)' },
                    to: { height: '0' }
                },
                'collapsible-down': {
                    from: { height: '0' },
                    to: { height: 'var(--radix-collapsible-content-height)' }
                },
                'collapsible-up': {
                    from: { height: 'var(--radix-collapsible-content-height)' },
                    to: { height: '0' }
                },
            },
            animation: {
                'accordion-down': 'accordion-down 0.2s ease-out',
                'accordion-up': 'accordion-up 0.2s ease-out',
                'collapsible-down': 'collapsible-down 0.2s ease-out',
                'collapsible-up': 'collapsible-up 0.2s ease-out',
            }
        }
    },
    plugins: [tailwindanimate],
}
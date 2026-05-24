import { clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs) {
    return twMerge(clsx(inputs));
}

export function parseText(text) {
    const parts = [];
    let currentIndex = 0;
    const tagRegex = /\[C([a-zA-Z-]+(?:-[a-zA-Z0-9]+)*(?:\/[0-9]+)?(?:\s[a-zA-Z-]+(?:-[a-zA-Z0-9]+)*(?:\/[0-9]+)?)*)\](.*?)\[\/C\]/g;

    let lastIndex = 0;
    let match;
    while ((match = tagRegex.exec(text)) !== null) {
        const [fullMatch, classNames, content] = match;
        const matchIndex = match.index;

        if (matchIndex > lastIndex) {
            parts.push({ type: 'text', content: text.slice(lastIndex, matchIndex) });
        }

        parts.push({ type: 'element', tag: 'span', props: { className: classNames }, children: content });
        lastIndex = matchIndex + fullMatch.length;
    }

    if (lastIndex < text.length) {
        parts.push({ type: 'text', content: text.slice(lastIndex) });
    }

    return parts;
}

export function stripTags(text) {
    return text.replace(/\[C.*?\](.*?)\[\/C\]/g, '$1');
}
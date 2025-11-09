# Forkfolio Branding (MVP)

## Name
- Forkfolio

## Tone
- Clean, modern, approachable. Value is organization and speed.

## Colors (proposed)
- Primary: System accent (adapts to user’s device theme)
- Background: iOS system background
- Secondary background: iOS secondary system background
- Tag chips: use system tint with low opacity backgrounds

You can later replace the accent with a custom brand color via Asset named `AccentColor`.

## Typography
- Use San Francisco (system font) for MVP.
- Titles: largeTitle → title2
- Metadata (creator, tags): subheadline/caption with secondary color

## Icon (temporary guidance)
- Concept: Minimal fork silhouette inside a rounded square, solid primary color background.
- Colors: White fork on accent-colored background.
- Asset sizes: Provide a single 1024×1024 PNG source; Xcode will generate app icon sizes.
- Safe area: Keep 80% of the canvas for the fork shape; 10% padding all around.

## App UI cues
- Use `.tint(Theme.primary)` for interactive elements.
- Keep UI minimal: strong focus on the Library list and quick Add flow.

## Later polish ideas
- Custom `AccentColor` asset and AppIcon set.
- Motion: subtle fade/slide transitions between Library and Details.
- Tag chips with pill shapes and subtle shadows.

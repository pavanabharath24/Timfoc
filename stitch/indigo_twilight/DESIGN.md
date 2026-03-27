# Design System Strategy: The Lo-Fi Sanctum

This design system is engineered to transform a standard productivity tool into a digital sanctuary. We are moving away from the "industrial" efficiency of traditional Pomodoro apps toward a "Lo-Fi Sanctum" aesthetic—an editorial-inspired, cozy environment that prioritizes emotional resonance over rigid utility.

## 1. Creative North Star: The Analog Dreamscape
The "Analog Dreamscape" is our guiding principle. It represents a shift from sharp, cold digital interfaces to something that feels tactile, weathered, and lived-in. 

To break the "template" look, we employ **Intentional Asymmetry**. Do not center-align everything. Use the `spacing-12` and `spacing-16` tokens to create wide, breathable gutters that push content into unexpected, elegant positions. Overlap elements—let a pixel-art illustration break the container of a card—to create a sense of three-dimensional "clutter" that feels intentional and cozy rather than messy.

## 2. Color & Atmospheric Depth
Our palette is a transition from the twilight of `surface` (#111125) to the soft dawn of `secondary` (#ffb954).

*   **The "No-Line" Rule:** 1px solid borders are strictly prohibited for layout sectioning. Separation must be achieved through tonal shifts. A task list should not be "outlined"; it should sit as a `surface-container-low` (#1a1a2e) block against the `surface` (#111125) background.
*   **Surface Hierarchy:** Use nesting to define focus. 
    *   *Base:* `surface`
    *   *Section:* `surface-container-low`
    *   *Active Component:* `surface-container-high`
*   **The Glass & Gradient Rule:** For the main timer or floating action buttons, use `surface-variant` at 60% opacity with a `backdrop-blur` of 20px. Apply a subtle linear gradient from `primary` (#d4bbff) to `primary-container` (#412175) for high-importance CTAs to give them a "lit from within" glow.
*   **Signature Textures:** All surfaces should feature a "film grain" overlay (SVG noise at 3% opacity) to eliminate the sterile digital finish and reinforce the Lo-Fi aesthetic.

## 3. Typography: Editorial Meets Retro
The system utilizes a high-contrast typographic scale to create a "Zine" feel.

*   **Display & Headline (Space Grotesk):** These are your "vibe" setters. Use `display-lg` for the timer digits. The wide apertures of Space Grotesk provide a modern, architectural feel that contrasts with the "soft" colors.
*   **Body & Labels (Manrope):** Manrope provides the functional backbone. It is clean and highly readable at small sizes (`body-sm`), ensuring that even in a "moody" interface, the user never struggles to read their task list.
*   **Pixel Accents:** For gamified elements (levels, streaks, or "coins"), use a monospaced pixel font (not listed in primary tokens, to be used sparingly) to inject the "retro" charm requested in the brief.

## 4. Elevation & Tonal Layering
We do not use shadows to simulate height; we use light.

*   **The Layering Principle:** Instead of a shadow, a "raised" card is simply a `surface-container-highest` (#333348) element placed on a `surface-dim` background.
*   **Ambient Shadows:** If an element must "float" (like a modal), use a shadow tinted with `surface-tint` (#d4bbff) at 5% opacity. The blur should be no less than `spacing-8` (2.75rem) to ensure a soft, environmental glow rather than a hard drop shadow.
*   **The Ghost Border:** If accessibility requires a stroke, use `outline-variant` (#474553) at 15% opacity. It should be felt, not seen.

## 5. Component Guidelines

### Buttons
*   **Primary:** `secondary` (#ffb954) background with `on-secondary` (#452b00) text. Shape: `rounded-md` (1.5rem). No border.
*   **Tertiary:** Ghost style. No background, `primary` text. Use `spacing-2` for horizontal padding.

### Cards (The "Container" Rule)
*   Forbid dividers. Separate task items using `spacing-3` (1rem) vertical gaps.
*   Use `rounded-lg` (2rem) for all main containers to maintain the "cozy" softness.

### Timer Progress
*   Do not use a thin, technical line. Use a thick, `secondary-container` (#c3841b) track with a `secondary` (#ffb954) progress fill, featuring `rounded-full` caps.

### Inputs
*   Background: `surface-container-lowest` (#0c0c1f).
*   Focus State: A soft 2px outer glow of `surface-tint` (#d4bbff) at 30% opacity, rather than a harsh border change.

### Custom Component: The "Focus Totem"
*   A central, charming illustration (e.g., a pixel-art plant or cat) that sits on a `tertiary-container` (#1b2b7f) circular base with `rounded-full`. This element uses `glassmorphism` to feel like a physical object sitting on the screen.

## 6. Do’s and Don’ts

### Do
*   **Do** use asymmetrical margins (e.g., `spacing-10` on the left, `spacing-6` on the right) for header text to create an editorial look.
*   **Do** lean into the "Muted Orange" (`secondary`) for moments of success or completion.
*   **Do** allow illustrations to bleed over the edges of their containers (`overflow: visible`).

### Don't
*   **Don't** use pure black (#000000) or pure white (#FFFFFF). Use the provided `surface` and `on-surface` tokens.
*   **Don't** use 100% opaque dividers. If you must separate, use a `surface-variant` color shift.
*   **Don't** use "Default" rounded corners (4px-8px). Stick to the scale: `md` (1.5rem) or `lg` (2rem) to ensure the "soft/charming" vibe is maintained.
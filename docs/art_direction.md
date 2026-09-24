# Range Club art direction

Aim for original, SNES-inspired pixel art throughout the game. The current
shape-drawn range and text screens are a playable foundation, not the finished
visual treatment. Kevin wants to make the art; the first finished piece should
set the palette and pixel scale for the rest.

## First art slice

Draw **Maera's character-select portrait** on a 96 × 96 pixel canvas. Show her
shoulders, face, and gyro brace in one readable silhouette. Use a limited
palette (roughly 12 colors) and a few strong value groups. Keep her design
original rather than recreating a character from a reference game. Export a
transparent PNG; keep the editable source beside it. Display at an integer
multiple with nearest-neighbor filtering.

The current character cards use generated **concept portraits** in
`assets/art/concepts/`. They establish a shared bust crop and palette for all
three marksmen. Each has a visible arrow quiver; Maera faces her braced bow arm,
with the quiver over the opposite shoulder. The cards focus on character and
rig details, leaving the full bows for a larger action pose where their shape
and single string can read clearly.

These are high-resolution pixel-art styled drafts, not finished 96 × 96 sprites.
Redraw or refine them as original game assets before treating the portrait
style as final. The Natural's plain clothes, glasses, and unshowy confidence
preserve the Yusuf Dikeç reference; his eventual bow should remain simple.

Use these concepts to settle the shared palette and redraw the portraits at
game resolution. Each marksman now has a static range concept placed below the
Safe target. The Natural uses a plain wooden bow, Maera a copper gyro bow with
a gold string, and Vey a black composite bow with a glowing blue string. Maera
is **left-handed**: her right arm holds the bow and wears the gyro shoulder
brace, while her left hand draws the string. Her headpiece sits on the opposite
side of her head. Vey keeps a small temple eyepiece matching the portrait.
Keep those details in any redraw or animation. Test the still poses before
animating the draw. Then draw one **32 × 32 module icon** and one
**48 × 48 trial emblem** to test how the style reads at smaller sizes. Complete
those sets before replacing the range backdrop and the case-file/result art.

## Asset coverage

| Surface | Art needed |
| --- | --- |
| Character selection | Portrait and small rig silhouette for each marksman |
| Rig rewards and details | Distinct icon for each module |
| Trials | Emblem for each scenario; target and backstop treatment |
| Case file and results | Range Authority seal, document ornament, outcome stamp |
| Range | Background, lane furniture, hit effects, and small environmental signs |

Keep the art readable against the existing dark green, parchment, gold, cyan,
and rust interface colors. Adjust that palette after the first portrait if the
art calls for it. Do not force a strict historical SNES color limit; the goal
is cohesive pixel art with clear gameplay information.

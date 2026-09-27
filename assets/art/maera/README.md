# Maera shooting atlas

`maera_shooting_v1.png` is a transparent 1774 × 887 PNG with a 4 × 2 grid.
It was generated and revised with the built-in imagegen tool on 26 September
2026, using the repository's Maera range concept as the character reference.
The source PNG is retained at its generated resolution; Godot AtlasTextures
define the 443.5 × 443.5 cells without destructively cutting the image.

Frames, left to right and top to bottom: rest/nock, draw, full draw, focused
hold, release, follow-through, recovery, alternate full draw. The last frame is
retained in the source sheet but is not used by the current animation.

The defining constraint is a **left-handed archer shooting toward screen
right, mostly seen from behind**. The copper right arm holds the bow in the
foreground. Her left drawing arm stays on the far side, naturally occluded by
her torso/head, with the elbow visible beyond the silhouette. The right thumb
belongs behind the bow/riser, hidden on the far side of the grip from this rear
camera. The visible side shows the glove back and four curled fingers. At every
pre-release pose, the drawing fingers, bowstring vertex, and arrow nock must meet.

The atlas is the first animation pass, not a finished hand-authored pixel-art
set. Review anatomy, frame alignment, and silhouette together when refining it.
Named animations, timing, scale, and bow socket are editable in
`features/range/maera_archer.tscn`.

## Latest correction

The full-draw, focused-hold, and alternate-draw poses were corrected to remove
the oversized glove from the visible neck. The far-side drawing hand is now
occluded by the head/jaw, with only a small visible fingertip edge at the anchor.
The exact built-in imagegen prompt is in `neck_correction_prompt.txt`.

All eight right bow-hand grips were then corrected to conceal the thumb behind
the bow/riser. Enlarged views of every grip were checked in Godot, including
release and recovery. The exact built-in imagegen edit prompt is in
`grip_correction_prompt.txt`.

## Earlier edit prompt

The preceding edit used the rear-view correction as its input:

> Single targeted correction on this rear-three-quarter LEFT-HANDED archer animation atlas. Keep the established far-side LEFT drawing arm occluded behind the torso, near-side armored RIGHT bow arm, anatomical right bow hand grip with thumb toward target, camera, all eight aligned cells, transparent background. Preserve cells 3,4,5,6,7,8. ONLY FIX CELLS 1 and 2 in the top row so LEFT HAND, ARROW NOCK and GOLD STRING ALL MEET physically. At present top-left string is straight by the bow but her drawing hand/arrow nock incorrectly remain near her face. TOP-LEFT REST: left drawing hand must be moved FORWARD to touch the nearly straight gold bowstring at its middle (approximately local x300,y205 in that 444px cell), a long distance in front of her face, but still behind the foreground copper bow arm. Arrow nock starts exactly at that hand/string point, its shaft extends RIGHT toward the existing arrow point beyond bow. Shorten visible shaft at rear accordingly. The far left forearm extends from far shoulder toward this hand, mostly occluded by torso and copper arm; do not paint a near-side sleeve. TOP SECOND HALF-DRAW: hand AND arrow nock AND vertex of string V at local x255,y205 in its cell, halfway from the straight-string point toward face; string bends to that point. Fully drawn cells 3/4 already have string/hand at cheek and should stay as-is. No floating hands separated from string, no arrow butt behind a string it is supposed to be nocked onto, no switching which hand holds bow. EXACT 4x2 regular grid, transparent alpha, no text. Keep every other detail unchanged.

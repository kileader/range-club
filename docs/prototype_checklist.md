# Prototype checklist

## Now — first target

Definition of Done: a Godot project under Git opens to a visible target and
exports a launchable Windows build.

- [x] Pin Godot 4.7.2 Standard and Compatibility rendering.
- [x] Create a main scene with a ten-ring target drawn from 2D shapes.
- [x] Import/parse and start the project headlessly without reported errors.
- [x] Inspect actual rendered viewports at 1280 × 800 and 960 × 720; target
      proportions and text layout remain intact. The 4:3 window uses letterboxing.
- [x] Export Windows x86_64 and launch the exported executable outside the editor.
- [x] Document setup, validation, and export commands.

Verified on 23 September 2026 with Godot `4.7.2.stable.official.ed1daf0bf` and an
AMD Radeon RX 6600 using OpenGL Compatibility. The exported process rendered
60 frames and exited with code 0, without reported runtime errors.

This slice has no shooting interaction to playtest. No web export was tested.

## Next — one satisfying shot

Aim, hold to draw, show readiness and sway, release at the displayed reticle,
score the hit, and retry. Include scoring boundary/miss tests. Playtest early
cancellation and reticle/impact agreement before adding more content.

Suggested commit: `Add draw and release shooting with ring scoring`.

## Later

Five-arrow sandbox and two contrasting builds; then the tiny three-round run.
Kevin's playtest determines when the shooting mechanic is ready to expand.

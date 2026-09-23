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

No web export was tested.

## Earlier — compare two shot methods

Definition of Done: five arrows can be shot in each mode on the same target;
each accepted shot scores the presented impact, and the player can switch modes
or retry without carrying over arrows or score.

- [x] Hold, steer, settle, fatigue, and release loop.
- [x] Three-press aim, draw, and release loop.
- [x] Ring scoring, visible impact marks, five-arrow total, mode switch, retry.
- [x] Scoring boundary, cancellation, shot progression, fifth-arrow, and reset assertions.
- [x] Rendered release check: impact equals the reticle shown in both modes.
- [x] Simulated board and gauge mouse clicks through Godot's input path.
- [x] Inspected the interface at 1280 × 800 and 960 × 720; exported and
      launched a Windows build outside the editor.
- [x] Kevin tried both and preferred aiming over the timing bars.

Follow-up feedback: passive sway was not fun. Both sway and the timing mode
were removed from the current playable slice; their experiment remains in Git
history.

## Now — fantasy-tech target strategy

Definition of Done: five-shot play offers a target choice, the starter rig is
challenging, and the player can compare two upgrades against a bare rig.

- [x] Three target sizes and score ceilings, with a goal above five safe centers.
- [x] Fixed rest point, moving targets, and build tradeoffs for focus or speed.
- [x] Three character/build presets; bare rig remains selectable and choices
      are locked during each trial.
- [x] Rule assertions for motion, scoring, focus, unlock, selection, and retry.
- [ ] Kevin plays the range and reports whether target choice feels strategic.
- [x] Inspect final UI at 1280 × 800 and 960 × 720, including completed and
      Maera-selected states; verify mouse input and launch Windows export.

## Later

Tune from playtest feedback, then consider a tiny three-round run. Do not add
progression just to disguise a weak shooting loop.

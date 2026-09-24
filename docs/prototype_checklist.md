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

The first target milestone was Windows-only. The current trial was later
exported for web and opened locally in a browser; the rules, character select,
and range screens rendered and responded to clicks.

## Earlier — compare two shot methods

Definition of Done: five arrows can be shot in each mode on the same target;
each accepted shot scores the presented impact, and the player can switch modes
or retry without carrying over arrows or score.

- [x] Hold, steer, settle, fatigue, and release loop.
- [x] Three-press aim, draw, and release loop.
- [x] Ring scoring, visible impact marks, five-arrow total, mode switch, retry.
- [x] Scoring boundary, cancellation, shot progression, fifth-arrow, and reset assertions.
- [x] Rendered release check: impact equals the reticle shown in both modes.
- [x] Simulated board mouse clicks and hold/release through Godot's input path.
- [x] Inspected the interface at 1280 × 800 and 960 × 720; exported and
      launched a Windows build outside the editor.
- [x] Kevin tried both and preferred aiming over the timing bars.

Follow-up feedback: passive sway was not fun. Both sway and the timing mode
were removed from the current playable slice; their experiment remains in Git
history.

## Now — fantasy-tech target strategy

Definition of Done: up-to-five-shot play offers a target choice, the starter rig is
challenging, and the player can compare two upgrades against a bare rig.

- [x] Three target sizes and score ceilings, with a goal above five safe centers.
- [x] Moving targets and build tradeoffs for Focus or speed. Shots start at the
      mouse position, so travel from a fixed rest point cannot eat the best
      precision window.
- [x] Three character/build presets; bare rig remains selectable and choices
      are locked during each trial.
- [x] Hit marks remain attached to their moving targets.
- [x] Full-screen rules and character-choice screens separate target economy
      from each character's bonus and drawback.
- [x] Five-shot Focus economy: earn on Safe, spend for a tighter circle, and
      pursue Natural precision, Maera's extra-tight Focus without target
      slowdown, or Vey quick-hit bonuses.
- [x] Replace perfect lock-on with visible random spread. Holding shrinks the
      landing circle to a peak, then it blooms and pulses; impact is sampled
      only inside the last displayed circle.
- [x] Preview the minimum spread with a cyan ring and cue the tightest release
      window in the in-round status.
- [x] Move Vey's precision peak inside his bonus window and remove the
      redundant ready gauge.
- [x] Add a darts-style score window: clear on entering it, bust above the
      cap, or fail below it after five shots. The first test used 55–60.
- [x] Rule assertions for motion, scoring, Focus, selection, and retry.
- [x] Inspect the strategy and in-round UI at 1280 × 800 and 960 × 720;
      verify character selection, Focus, and board mouse input.
- [x] Export and launch the current Windows build (60 frames, exit code 0).
- [x] Export the current trial for web and verify its opening flow in a browser.
- [x] Playtest the narrower 58–60 window. Kevin found four Bold shots followed
      by a focused Standard or Safe finish was still the easiest route.
- [x] Playtest 48–52 with Bold radius 24. After Maera gained a focused
      Standard route, Kevin found the three character strategies distinct
      and worth building a run around.

## Now — first short run

- [x] Three five-shot score windows with run-ending failure and final victory.
- [x] Two different later target rules drawn per run and previewed before
      choosing a rig module.
- [x] Three random nonduplicate module offers after each nonfinal clear;
      choices alter shot handling, scoring, or Focus rules and remain for the run.
- [x] Character and modules carry; Focus starts each trial at one, while score
      and shots reset. A new run clears temporary modules and reshuffles scenarios.
- [x] Assertions cover offers, stacking, a full win, failure, bust, and reset.
- [x] Replace one score-only module with a Stabilizing Sight that extends the
      smallest-circle release window without changing its best precision.
- [x] Replace two more score modules with Quickset String and Recovery Cell;
      four of five offers now affect handling or Focus instead of adding points.
- [x] Add an in-trial rig menu showing installed modules and their effects.
- [x] Inspect the opening and range in a local browser, and render the reward
      and result screens at 1280 × 800. Export and launch the Windows build.
- [ ] Kevin playtests whether the module choice changes plans rather than
      merely adding points to the usual route.

## Later

Tune the second and third windows from complete-run results before adding
more content, permanent progression, or persistence.

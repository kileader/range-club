# Range Club

A small fantasy-tech target-range prototype about choosing risk and handling
for each five-shot trial. Read the brief rules screen, choose a character on
the next screen, then score 55 points in five shots. Safe scores up to 6,
Standard up to 10, and Bold up to 15. Five Standard centers yield only 50
without a bonus, so clearing the trial requires stronger targets or a
character-specific advantage.

## Stack

- **Godot 4.7.2 Standard**, pinned through the first playable milestone.
- Typed GDScript, native Godot scenes, and the Compatibility renderer.
- Windows x86_64 is the first export target. Browser export is deferred.
- Procedural 2D shapes and Godot's bundled font; no external art dependencies.

## Open and run

1. Download and extract [Godot 4.7.2 Standard for Windows x86_64](https://godotengine.org/download/archive/4.7.2-stable/).
2. Import this repository's `project.godot` in the Godot Project Manager.
3. Open the project and press **F6** to run the selected scene, or **F5** to run the project.
4. Choose a character and play a five-shot trial; close the window to exit.

The targets move on predictable paths. Aim with the mouse before holding left
mouse; the shot starts at that position. The visible landing circle shrinks until 1.5
seconds, then widens and pulses as a penalty for holding longer. Release after
**READY**; the shot lands at a random point inside the last circle actually
shown. A miss still spends a shot. Releasing early or pressing **Esc** cancels
without spending one. There is no passive aim sway.

You start with one **Focus** and can hold at most two. Press **F** or the Focus
button before a shot to arm it. Focus makes the landing circle smaller.
It also halves target speed for The Natural and Vey; Maera's targets keep
moving at full speed. Focus is spent when you release a ready shot.
A Safe inner hit (ring 6–10) restores
one Focus. An early release or **Esc** cancels without spending a shot or Focus.

Each build turns the same rules into a different plan:

- **The Natural / Bare Rig:** balanced aim speed. A Standard or
  Bold bullseye without Focus adds 2 points.
- **Maera / Gyro Brace:** spending Focus makes the landing circle 40% smaller,
  but her targets keep moving at full speed. It improves her odds without
  guaranteeing a hit.
- **Vey / Pulse Sight:** faster aim. Hit near the center of
  Standard or Bold within 1.2 seconds of starting the shot to add 3 points.

The character screen shows each bonus and drawback before play; the rules
screen can be revisited from there. Both reopen between trials. Character
choices are locked during an active trial. **Retry** keeps the current choice
and resets Focus to one.

The gold circle is the full possible landing area. The footer records your
best score. Hit marks stay on the moving target; misses stay on the backstop.
The earlier sway and three-press timing experiments remain in Git history.

For this local checkout, the portable editor is already in `.tools/godot/`:

```powershell
$godot = '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe'
& $godot --path . --editor
```

Run these commands from the repository root. In another checkout, set `$godot`
to the location of your Godot console executable. `.tools/` is local and ignored
by Git; put a `.gdignore` file inside it if you keep tools there yourself.

## Verify

```powershell
& $godot --version
& $godot --headless --path . --editor --import
& $godot --headless --path . --quit-after 3
& $godot --headless --path . --script tests/run_rules.gd
```

The version must start with `4.7.2.stable`. Check the output for errors as well as
the exit code. The assertions cover ring boundaries, moving target positions,
shot phases, dispersion bounds, Focus costs and bonuses, five accepted shots,
and retry. They
cannot judge feel.
Current visual and export checks are recorded in
[the prototype checklist](docs/prototype_checklist.md).

## Export for Windows

Install the **4.7.2 Standard export templates** through **Editor > Manage Export
Templates**. The matching Windows x86_64 templates are already installed for this
machine. The checked-in `Windows Desktop` preset uses Godot's normal template
directory, with no machine-specific paths.

```powershell
New-Item -ItemType Directory -Force builds/windows | Out-Null
New-Item -ItemType File -Force builds/.gdignore | Out-Null
& $godot --headless --path . --export-release 'Windows Desktop'
& '.\builds\windows\RangeClub.exe'
```

Keep `RangeClub.exe` and `RangeClub.pck` together when copying the build. The
executable is an unsigned development build. Generated exports are ignored by
Git. The `.gdignore` prevents Godot from importing local build output.

## Project layout and decisions

- `app/` owns the main scene and five-shot session controller.
- `features/range/` holds range input, labels, and target drawing.
- `rules/` holds shot behavior and target scoring without scene dependencies.
- `content/` holds read-only character/build preset definitions.
- `tests/` holds the Godot headless assertion runner.
- `docs/technical_foundation.md` preserves the original design proposal.
- `docs/prototype_checklist.md` tracks the immediate acceptance checks and next step.
- `docs/reference_ideas.md` records the small references already in the range
  and the character/build direction for later slices.

The presentation uses a 1280 × 800 design canvas, scaled proportionally with
letterboxing at other aspect ratios. Scoring uses target-local coordinates with
the target radius normalized to 1, so window size cannot change the ring score.
The controller samples inside the last landing circle that was actually drawn
and scores against those displayed target positions, avoiding a one-frame
input/render mismatch.

## Next decision

Play a few trials with each character. Note whether the visible landing circle
makes misses understandable, whether the late-hold penalty changes release
decisions, and whether Maera still feels automatic. Tune the spread curve and
score goal before adding longer-run progression.

The current opening screen selects a character with a fixed signature rig.
A future run can retain that opening choice and add rig building, distinct
encounters, and run-ending failure once the five-shot trial is satisfying.

No remote repository or source license has been selected yet.

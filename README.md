# Range Club

A small fantasy-tech target-range prototype about choosing risk and handling
for each five-shot trial. Three targets compete for your attention: Safe scores
up to 6, Standard up to 10, and Bold up to 15. Five safe center hits yield only
30, so the 40-point goal asks you to attempt riskier shots.

## Stack

- **Godot 4.7.2 Standard**, pinned through the first playable milestone.
- Typed GDScript, native Godot scenes, and the Compatibility renderer.
- Windows x86_64 is the first export target. Browser export is deferred.
- Procedural 2D shapes and Godot's bundled font; no external art dependencies.

## Open and run

1. Download and extract [Godot 4.7.2 Standard for Windows x86_64](https://godotengine.org/download/archive/4.7.2-stable/).
2. Import this repository's `project.godot` in the Godot Project Manager.
3. Open the project and press **F6** to run the selected scene, or **F5** to run the project.
4. Play a five-shot trial; close the window to exit.

The targets move on predictable paths. Aim at one with the mouse, hold left
mouse to draw and steer from the fixed rest point, then release when the gold
impact reticle is on the moving mark. Releasing before **READY** cancels
without spending a shot. There is no random sway. Press **Esc** to cancel a
draw.

The initial trial uses **The Natural** with a Bare Rig. Completing it unlocks
three character/build presets: The Natural steers at a balanced speed with a
small focus lock; **Maera**, a rune smith, uses a Gyro Brace that tethers near
targets but steers slowly; and **Vey**, an arc scout, uses a Pulse Sight that
steers quickly without a lock. A cyan ring shows an active focus lock. Choices
are locked during a trial. **Retry** keeps the current preset.

The gold reticle is the exact impact point. The footer records your best score.
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
shot phases, focus locks, five accepted shots, and retry. They cannot judge feel.
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
No hidden random error is added after release. The controller records the last
reticle sample that was actually drawn, avoiding a one-frame input/render mismatch.

## Next decision

Play a few trials with each character/build preset. Note whether tracking a
moving target feels strategic, whether misses feel fair, and whether one build
dominates. Tune the motion and scoring before adding longer-run progression.

No remote repository or source license has been selected yet.

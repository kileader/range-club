# Range Club

A small 2D archery prototype testing two ways to make five arrows worth another
attempt. Equipment tradeoffs come after the shot mechanic is playtested.

The current slice has a five-arrow range, ten-ring scoring, two shooting modes,
and immediate retry. Equipment and run progression are not implemented yet.

## Stack

- **Godot 4.7.2 Standard**, pinned through the first playable milestone.
- Typed GDScript, native Godot scenes, and the Compatibility renderer.
- Windows x86_64 is the first export target. Browser export is deferred.
- Procedural 2D shapes and Godot's bundled font; no external art dependencies.

## Open and run

1. Download and extract [Godot 4.7.2 Standard for Windows x86_64](https://godotengine.org/download/archive/4.7.2-stable/).
2. Import this repository's `project.godot` in the Godot Project Manager.
3. Open the project and press **F6** to run the selected scene, or **F5** to run the project.
4. Try five arrows with each mode; close the window to exit.

**Hold & Sway:** Move the mouse over the range, hold left mouse to draw, steer
toward the target, then release when the gold impact reticle is where you want
it. Releasing before **READY** cancels without spending an arrow. Waiting lets
the sway settle at first, then fatigue increases it.

**3-Press Timing:** Point at a spot on the target and click once to lock your
aim and start the draw gauge. Click near the gold gauge mark to set the draw;
this determines vertical placement. Click a third time when the gold reticle
sweeps over your chosen spot; this determines horizontal placement. The second
click also works on the gauge itself. Press **Esc** to cancel either shot.

The gold reticle is the exact impact position in both modes. Each mode records
its best five-arrow score in the footer. Switching modes or pressing **Retry**
starts a fresh five-arrow round.

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
the exit code. The assertions cover ring boundaries, shot phases, cancellation,
exactly five accepted shots, and retry. They cannot judge how shooting feels.
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

- `app/` owns the main scene and five-arrow session controller.
- `features/range/` holds range input, labels, and target drawing.
- `rules/` holds shot timing and ring scoring without scene dependencies.
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

Play several five-arrow rounds of each mode and note which makes you want
another attempt, whether a miss feels explainable, and whether the controls
stay enjoyable across fifteen shots. Tune or combine the methods based on that
feedback before adding equipment definitions.

No remote repository or source license has been selected yet.

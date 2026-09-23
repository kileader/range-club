# Range Club

A small 2D archery prototype exploring whether mouse steering, draw timing, and
equipment tradeoffs can make five arrows worth another attempt.

The current slice is a launchable practice range with a ten-ring target. Shooting,
scoring, equipment, and run progression are not implemented yet.

## Stack

- **Godot 4.7.2 Standard**, pinned through the first playable milestone.
- Typed GDScript, native Godot scenes, and the Compatibility renderer.
- Windows x86_64 is the first export target. Browser export is deferred.
- Procedural 2D shapes and Godot's bundled font; no external art dependencies.

## Open and run

1. Download and extract [Godot 4.7.2 Standard for Windows x86_64](https://godotengine.org/download/archive/4.7.2-stable/).
2. Import this repository's `project.godot` in the Godot Project Manager.
3. Open the project and press **F6** to run the selected scene, or **F5** to run the project.
4. Resize the game window to inspect the layout; close the window to exit.

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
```

The version must start with `4.7.2.stable`. Check the output for errors as well as
the exit code. These commands check import and startup, not visual correctness.
There are no gameplay rules to unit-test yet; scoring boundary tests arrive with
the first shot. Current visual and export checks are recorded in
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

- `app/main.tscn` is the entry scene.
- `features/range/` holds the range scene, labels, and target drawing.
- `docs/technical_foundation.md` preserves the original design proposal.
- `docs/prototype_checklist.md` tracks the immediate acceptance checks and next step.
- `docs/reference_ideas.md` records the small references already in the range
  and the character/build direction for later slices.

The presentation uses a 1280 × 800 design canvas, scaled proportionally with
letterboxing at other aspect ratios. Target rings are drawn using fractions of
one target radius. Future scoring will use target-local normalized coordinates
so window size cannot change the result. There is no controller or rules layer
yet because this slice has no gameplay state to own.

## Next playable slice

One shot: mouse aiming, hold to draw, visible impact reticle, release, ring score,
and immediate retry. Releasing before ready cancels without spending an arrow.
Release must hit the displayed reticle with no hidden random error. Only after
that interaction works do we add five arrows and two contrasting builds.

No remote repository or source license has been selected yet.

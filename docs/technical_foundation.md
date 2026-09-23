# Range Club — Technical Foundation

Working recommendation • 23 September 2026

This is a proposed implementation baseline, not an existing codebase. Kevin's concept supplies the goals; the stack, architecture, and mechanics below are proposals to test. Assume Windows desktop, solo development, mouse input, and a 2D presentation. Browser playtesting is useful but is not the primary platform requirement.

## 1. Stack decision

Use **Godot 4.7.2 Standard, typed GDScript, the Compatibility renderer, and Git**. Pin this version through the first playable milestone; use matching export templates. The official Windows download page lists 4.7.2 stable as of this review [1].

| Option | Fit for this project | Decision |
| --- | --- | --- |
| Godot + typed GDScript | Integrated scene/UI/content workflow; small 2D experiments; desktop development with a browser export option | Recommended |
| Godot + C# | Familiar structure coming from Java; access to .NET tooling; current Godot 4 C# projects cannot export to web [2] | Credible alternative if C# comfort outweighs browser sharing |
| Unity + C# | Supports 2D and browser builds [7]; attractive if existing Unity expertise or a specific package becomes decisive | No demonstrated need to take on its workflow for this prototype |
| Phaser + TypeScript | Browser-native 2D framework [8]; attractive if a web-first game becomes the primary goal | Alternative if browser integration becomes more important than Godot's editor workflow |

These fit judgments are recommendations, not engine benchmarks. The game's systems complexity does not by itself require C#, C++, or a custom engine. There is no measured performance bottleneck yet.

GDScript is a separate language, despite its Python-like syntax. Use typed parameters, returns, state fields, and collections where supported. Its static typing helps catch errors and improves completion, but does not offer the entire C# type system [3]. Do not mix C# and GDScript in the first prototype or plan an automatic rewrite later.

Compatibility is appropriate for simple 2D work and supports web export [4]. Start with Godot's built-in script editor; an external editor is optional. No paid editor, art package, backend, database, or external game framework is required for the proposed prototype.

## 2. Presentation and shot model

Use a fixed, face-on target view. Draw rings, reticle, arrow marks, and meters with 2D shapes. Surround the target with compact UI for the loadout, score, remaining arrows, and current round. One reusable theme and small impact animations are sufficient. A visible animated archer is not required to test the shooting mechanic.

Proposed input loop:

1. Move the mouse to steer an aim point. Apply a bounded response rate so equipment can meaningfully affect steering.
2. Hold the shoot input to draw. A visible meter identifies when the bow is ready; releasing earlier cancels without spending an arrow.
3. Once ready, the impact reticle sways around the steered point. Holding longer initially settles it, then increases sway through fatigue. Show these transitions clearly.
4. Release to place the arrow at the displayed impact reticle. Score distance from the target center. Do not add invisible random error after release.
5. Show the hit, ring score, and brief feedback, then reset for the next arrow.

This is an arcade design hypothesis, not a simulation of real archery. Treat the flight animation as presentation; calculate the impact mathematically. Do not use a rigid-body projectile as the scoring authority. Use target-local coordinates, with target radius normalized to 1, so resolution changes cannot alter scoring.

Advance steering, sway, and draw state with a fixed simulation step. Record release against the reticle sample currently presented to the player; explicitly playtest for a visible-reticle/impact mismatch. Do not promise cross-platform deterministic replays.

The experiment asks whether steering and release timing feel satisfying, and whether different builds change the player's technique. If the result feels like merely clicking a circle, revise this mechanic before adding a run map or more content.

## 3. Architecture

Use one Godot project with three modest boundaries: presentation, session control, and rules/data. These are directories and responsibilities, not separate services or separately deployable packages.

| Component | Responsibility | Godot form |
| --- | --- | --- |
| Main / RunController | Own the current run, choose the active screen, accept shot/reward actions, and advance phases | Root scene and one controller script |
| RangeView | Input sampling, target drawing, reticle display, sound, and hit feedback | Node2D scene with child UI |
| RewardView / ResultsView | Display choices and results; emit user selections | Control scenes |
| RunState | Round, phase, score, loadout, run seed, shot history | Typed RefCounted object |
| ShotModel | Draw/settle/fatigue state and reticle motion | Typed RefCounted object |
| BuildResolver / Scoring | Derive effective shot parameters; calculate ring score and explicit bonuses if added later | Small typed scripts without scene dependencies |
| EquipmentDef / TechniqueDef | Authored identifiers, text, tuning values, and small supported effect choices | Custom Resource classes and .tres files |

Rules may use Godot value types such as Vector2. They should not access the scene tree, UI nodes, input devices, audio, or wall-clock time. Passing explicit input/state makes them testable through Godot's headless runtime; an engine-independent library is unnecessary.

**Ownership:** Main owns RunController; RunController owns RunState and gives views the data they need. Views report actions; the controller validates the current phase, calls the rules, updates state, and refreshes the view. UI must not independently calculate authoritative scores or mutate the loadout.

Use direct function calls for queries/actions and local signals for view events. Start with a short phase enum: RANGE, REWARD, RESULTS. ShotModel can have its own IDLE, DRAWING, READY progression. No general state-machine framework or global event bus is needed.

**Content definitions are read-only by convention.** Godot Resources are shared when loaded [5]; changing an equipment definition during a run can accidentally change every user of it. Keep mutable counters and derived values in runtime state. Calculate a new effective build from the base values plus the equipped definitions whenever the loadout changes.

Start with a small, explicit combination rule: base values, then additive adjustments, then multiplicative adjustments, then safety clamps. Apply conditional technique effects afterward in a documented order. Derive displayed build values through the same resolver. Validate positive durations and speeds and unique stable content IDs.

Keep unusual behavior in a few named functions or explicit effect cases. Introduce reusable effect objects only when several real items need the same behavior. Do not build a universal ability language, deep item inheritance hierarchy, or entity-component-system framework.

Use seeded random generators for reward selection and sway initialization, with separate generators so UI/visual changes cannot consume gameplay randomness. Seed + build version aids debugging; a seed alone is not a complete action replay. During the sandbox, allow a fixed seed and immediate build switching for fair comparisons.

## 4. Repository structure

Create one repository named `range-club`, with `project.godot` at its root. The following is the target organization as features appear; do not generate empty scaffolding for future systems.

| Path | Contents |
| --- | --- |
| `project.godot` | Engine settings, main scene, input actions |
| `app/` | Main scene and run controller |
| `features/range/` | Range scene, view script, and range-only presentation helpers |
| `features/rewards/` | Reward screen scene and script |
| `features/results/` | Results screen scene and script |
| `rules/` | RunState, ShotModel, build resolution, scoring |
| `content/definitions/` | EquipmentDef and TechniqueDef scripts |
| `content/equipment/` | Authored equipment .tres files |
| `content/techniques/` | Authored technique .tres files |
| `ui/` | Shared theme and genuinely reused controls |
| `assets/` | Small source assets and attribution records |
| `tests/` | Rule tests and a headless runner |
| `docs/` | Foundation, prototype checklist, short decision notes, idea bank |
| `README.md` | Exact engine version, setup/run/test/export instructions |
| `AGENTS.md` | Constraints for coding assistance and required verification |
| `.gitignore`, `.gitattributes` | Generated Godot Git defaults plus ignored local build output |

Keep each scene beside its view script. Use snake_case paths and scripts, PascalCase named classes, and stable IDs independent of display names. Avoid an undifferentiated global `scripts/` folder or a growing `utils/` dumping ground.

Commit text scenes/resources, source scripts/assets, generated script/shader .uid sidecars, project settings, and non-secret export presets. Godot's UID sidecars preserve resource references [9]. Ignore `.godot/`, local export output, credentials, and editor-specific personal settings. Start with Godot's generated Git metadata, which also handles line endings [6]. Add Git LFS only when large binary source assets actually enter the project, before their first commit.

No remote repository has been created by this document. Use a private remote initially if desired; public distribution and source licensing can be decided separately.

## 5. Solo development workflow

Keep `main` playable. Use a short branch for a mechanic experiment or substantial change; small verified fixes can go directly to main. Commit coherent working slices with imperative messages such as `Add release timing and ring scoring`.

Each work session should answer one small question:

1. Pick one visible outcome and write its acceptance condition.
2. Implement it in the smallest existing set of components.
3. Run affected rule tests and play the changed interaction.
4. Review the diff, commit, and record the next small action.

Maintain only a short Now / Next / Later list. Keep speculative ideas in the idea bank. Avoid a large prewritten backlog.

For AI-assisted implementation, use tasks such as: “Add five-arrow scoring. Use the current ShotModel. Done when exactly five valid releases produce a total and a retry button; no new content or architecture.” Ask for changed files, verification results, and any untested behavior. Do not request the entire roguelite in one generation.

Pin the engine in README and automation. Add a small headless assertion runner when scoring and build rules appear, then a single continuous-integration job that imports/parses the project and runs those tests. The runner must exit nonzero on failures. Export a Windows build at each playable milestone and open it outside the editor. If browser sharing is retained, test an actual web export early, before significant UI polish.

High-value automated checks: ring boundaries and misses; additive/multiplicative effect order; empty accessory behavior; source definitions remaining unchanged; resetting a run; valid and nonduplicate reward offers; exactly one arrow/transition per accepted release.

High-value manual checks: reticle/impact agreement; feel across builds; resizing; input cancellation on focus loss; one full win, one loss, and restart in an exported build. Tests can protect rules, but cannot establish whether shooting is fun.

Save files are unnecessary for a three-minute run. When persistence becomes necessary, add a versioned, explicit format under user data, using stable content IDs rather than serializing the live scene tree. Do not prebuild migrations, cloud saves, or a persistence framework.

## 6. Smallest playable prototype

### Milestone A: shooting and build sandbox

One target, one player, one five-arrow round, mouse aiming, draw/release input, visible reticle, ring scoring, and immediate retry. Provide developer buttons to switch between two contrasting preset builds under the same conditions.

**Exit condition:** both builds work, feel recognizably different, and make Kevin want another five arrows. If not, change aiming/timing before proceeding.

### Milestone B: the first tiny run

Scope the first roguelite slice to:

- One range and one playable character.
- Three rounds of five arrows each; a run aims to take roughly three to five minutes, subject to playtesting.
- One score gate per round, displayed before shooting. Start by testing 25 / 32 / 38 out of 50; these are provisional tuning values, not balanced difficulty claims.
- One choice from three valid offers before round one and after each successful nonfinal round. Offers replace the item/technique in their slot; allow keeping the existing build. Exclude currently equipped definitions and duplicate offers.
- Three loadout slots: bow, optional accessory, technique. One technique active at a time; no inventory, currency, shop, or item stacking.
- Six authored definitions total: two bows, two accessories, and two techniques. The ordinary bow is starter content; the remaining five definitions form the initial offer pool.
- Failure below a gate; victory after the third gate; a result screen showing score, build, and restart. A new run resets gameplay state.

Proposed six-definition content experiment:

| Definition | Role / tradeoff |
| --- | --- |
| Club Bow | Baseline bow with a longer settling opportunity |
| Snap Bow | Ready sooner; fatigue escalates sooner |
| Counterweight | Less sway; slower steering |
| Spring Sight | Faster steering; greater sway |
| Stillness | Greater settling benefit after holding; weaker benefit while an accessory is equipped |
| First Instinct | Brief steadiness benefit just after becoming ready; gives up late settling benefit |

All effects and names are gameplay proposals. Empty accessory means no accessory effect or penalty, and supports Stillness; it is a legitimate build choice. Test Snap Bow + First Instinct against Club Bow + Stillness + empty accessory. Counterweight should offer a distinct way to cope with sway, not automatically dominate both.

Use numerical tuning fields for draw time, steering speed, sway amplitude, settling, fatigue, and technique windows. Keep the first score system based on target position; add score-modifying items only after aiming tradeoffs work.

Club identity can be suggested through a range sign, loadout names, and a short result nickname. Functional recruitment, personalities, and rival simulation are deferred. Static gates are a deliberately limited tournament stand-in, not a claim that the full competition/club fantasy is proven.

**Prototype acceptance:** a player can finish or lose a complete run, understand each shot, notice the equipment change, and choose a different build for a reason. At least two builds support different release habits; there is no obvious item that improves every relevant parameter. Restart cannot retain the previous run's modifiers. Adding an item using existing effect types should require a content definition, not a rewrite of the screens.

This slice tests shooting and buildcraft. It cannot yet establish long-term content variety, community attachment, or meta-progression quality.

## 7. Implementation order and scope boundary

1. Create the Godot project and Git repository; draw a target and export a launchable Windows build.
2. Implement one shot, scoring, and retry. Add the first scoring boundary tests.
3. Add the two sandbox builds through definitions plus the shared resolver. Playtest and revise the mechanic.
4. Add the remaining small content pool, rewards, three-round flow, and full state reset tests.
5. Export and play complete runs. Record what makes another attempt appealing before adding content.

**Core now:** readable shot execution, equipment tradeoffs, short run choices, reliable reset, minimal debugging/testing.

**Later:** eccentric rivals, recruitment, club identity systems, more effects, sound/presentation polish, save/resume, possibility-unlocking progression.

**Idea bank:** other target sports, club building/decorating, extensive character creation, daily challenges, asynchronous competition.

The next implementation task is only step 1 plus a visible target. The subsequent task is one satisfying shot. The architecture should grow in response to those playable slices.

## Sources checked

1. [Godot Windows download](https://godotengine.org/download/windows/) — stable version and Standard/.NET downloads.
2. [Godot C# platform support](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/index.html) — .NET editor requirement and current web limitation.
3. [Static typing in GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html).
4. [Godot renderer overview](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).
5. [Godot Resources](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html) — custom data, text serialization, Inspector support, shared instances.
6. [Godot version control guidance](https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html).
7. [Unity 2D learning resources](https://learn.unity.com/collection/create-a-2d-game) and [Unity web development](https://learn.unity.com/tutorial/getting-started-with-unity-web?uv=6).
8. [Phaser documentation](https://docs.phaser.io/).
9. [Godot UID sidecars](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/).

Engine facts are sourced above. Architecture, tuning, project scope, and fit judgments are recommendations for Range Club and remain revisable through playtesting.

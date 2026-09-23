# Range Club implementation constraints

- Read `docs/technical_foundation.md` and inspect the current implementation before substantial work.
- Work in small playable slices. The proposal's future directories are not a scaffolding checklist.
- Use Godot 4.7.2 Standard, typed GDScript, and the Compatibility renderer.
- Keep scenes beside their view scripts, use snake_case paths, and give named classes PascalCase names.
- Keep input and drawing in views. Add controller-owned state and scene-independent rules when gameplay requires them.
- Score in target-local coordinates with radius normalized to 1. The released shot lands randomly inside the dispersion circle last presented to the player, never outside it; score against the target positions shown in that same frame. Do not use physics-authoritative scoring.
- Keep authored Resources read-only and runtime values separate when content is introduced.
- Track script `.uid` files. Ignore `.godot/`, `.tools/`, `builds/`, and credentials.
- Before committing, import the project headlessly, check startup output for errors, and visually inspect changed presentation. Run meaningful rule tests once rules exist.
- At playable milestones, export a Windows build and launch it outside the editor. Report anything that was not verified.
- Use concise imperative commit messages starting with a verb, without Conventional Commit prefixes.
- Keep `docs/prototype_checklist.md` short. Do not add rewards, progression, persistence, or infrastructure before the current mechanic needs them.

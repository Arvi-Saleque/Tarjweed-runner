# Full Asset Migration Plan

## Goal

Replace the current visual asset pipeline with the packs inside `new-assets` and move the project to a curated Quaternius + Kenney art direction.

This plan assumes:

- We replace current visual assets completely.
- We keep current audio for now.
- We keep the current menu flow, but improve it only if a change clearly makes it better.
- We focus most of the work on gameplay visuals, world theming, player presentation, HUD, prompts, and gameplay readability.
- We use all relevant categories from `new-assets`, but we do not force every single file into the game. We curate a clean subset so the game feels authored instead of random.

## Core Art Direction Rules

These rules must be followed in every phase:

1. The road is custom-authored in Godot and remains gameplay-first.
2. Quaternius Stylized Nature MegaKit is used around the road, not as the road itself.
3. Quaternius Universal Base Characters + Universal Animation Library 2 become the only supported player visual pipeline.
4. Kenney Adventure becomes the main HUD/panel/button visual language.
5. Kenney Input Prompts becomes the main tutorial/prompt/icon source.
6. Kenney Mobile Controls is used only for tutorial/accessibility/mobile helper overlays, not permanent polished gameplay buttons.
7. Visual variety stays controlled:
   - 2 tree families
   - 2 bush/plant families
   - 2 rock families
   - 1 flower family
   - 1 dead tree or silhouette family
8. The world must read clearly from gameplay camera distance before it looks decorative up close.

## Migration Strategy

We will use a staged migration:

1. Import and wire new assets first.
2. Validate each phase in Godot.
3. Commit after each small completed portion.
4. Delete old replaced visual assets only near the end.

This avoids a half-broken project during the transition.

## Commit Rule

After each small completed portion:

- Make sure the game still opens.
- Make sure the relevant scene loads.
- Commit only that focused unit of work.

Commit message style:

- `chore(assets): ...`
- `feat(world): ...`
- `feat(player): ...`
- `feat(ui): ...`
- `fix(gameplay): ...`
- `chore(cleanup): ...`

Do not mix unrelated work into one commit.

## Canonical Folder Target

The project should end up using this structure:

```text
assets/
  world/
    quaternius_nature/
      trees/
      rocks/
      plants/
      background/
      road_kit/
  characters/
    base_character/
    hairstyles/
    animations/
    materials/
  ui/
    kenney_adventure/
    kenney_mobile_controls/
    kenney_input_prompts/
  gameplay/
    obstacles/
    bridge/
    pickups/
    vfx/
```

Legacy folders can exist temporarily during migration, but the final active references should point only to the new structure.

---

# Phase 1: Asset Intake and Production Structure

## Objective

Create a clean production asset structure and import the new packs into usable in-project locations.

## Work To Do

1. Create the canonical target folders under `assets/`.
2. Bring in only the gameplay-relevant and UI-relevant files from `new-assets`.
3. Keep original pack naming visible enough for traceability, but normalize runtime folders for code readability.
4. Decide the curated subset that will actually be used in-game:
   - Trees: choose 2 families from `CommonTree_*`, `Pine_*`, or `TwistedTree_*`
   - Bushes/plants: choose 2 from `Bush_Common`, `Fern_1`, `Plant_1`, `Plant_7`, `Grass_*`
   - Rocks: choose 2 from `Rock_Medium_*`, `Pebble_*`, `RockPath_*`
   - Flowers: choose 1 from `Flower_3_*` or `Flower_4_*`
   - Background silhouettes: choose 1 large tree/cliff-like family plus dead tree variant
5. Import the Quaternius Godot-friendly formats:
   - Nature pack: prefer `glTF`
   - Character pack: prefer `Godot - UE`
   - Hair pack: prefer `Rigged to Head Bone\glTF (Godot -Unreal)`
   - Animation pack: use `Unreal-Godot\UAL2_Standard.glb`
6. Import the Kenney packs:
   - Kenney Adventure: use PNG or SVG depending on what works best in Godot UI
   - Input Prompts: use touch prompt assets and flair assets
   - Mobile Controls: use a small curated subset only
7. Add a short internal manifest section to this file or a follow-up doc if needed listing the chosen curated assets.

## Deliverables

- New asset directory structure exists in the repo.
- New packs are imported into production folders.
- Curated runtime subset is selected.
- No gameplay references are changed yet.

## Recommended Small Commits

1. `chore(assets): create canonical asset folders for quaternius and kenney content`
2. `chore(assets): import curated quaternius nature character and animation sources`
3. `chore(assets): import kenney adventure prompts and mobile control sources`

## What To Check In Godot

After this phase, check:

1. The imported assets appear correctly in the FileSystem dock.
2. The selected GLTF/GLB files open without missing textures.
3. The selected UI PNG/SVG files preview correctly.
4. There are no import errors in the Godot output panel.

---

# Phase 2: World Theme Replacement

## Objective

Replace the current world decoration and environment presentation with the new Quaternius nature art set while preserving gameplay readability.

## Work To Do

1. Stop using old environment decoration assets as the main runtime source.
2. Rebuild the world decoration selection logic to point only to the curated Quaternius subsets.
3. Keep the road custom and clean:
   - straight road segment
   - cracked/broken variation
   - obstacle-ready variation
   - bridge/gap-ready variation
   - test/finish segment
4. Apply the roadside placement rule:
   - Near road: grass, pebbles, tiny bushes
   - Mid distance: medium bushes, one tree family, one rock family
   - Far distance: tall trees, dead tree variation, large silhouettes, distant rocks
5. Simplify decoration density so the world feels authored, not noisy.
6. Make sure background layers are decorative only and do not confuse obstacle readability.
7. Tune materials, fog, and scale so the player stands out clearly against the environment.

## Deliverables

- The game world visually reads as Quaternius nature.
- The road remains controlled and readable.
- Background depth feels intentional.
- Old environment assets are no longer the active source for runtime decoration.

## Recommended Small Commits

1. `feat(world): replace decoration source set with curated quaternius nature assets`
2. `feat(world): add custom road segment kit for the runner track`
3. `feat(world): tune background depth fog and decoration density for gameplay clarity`

## What To Check In Godot

After this phase, check:

1. Start a run and verify lane readability is still strong.
2. Verify the player is not visually blending into the environment.
3. Verify the camera does not get visually blocked by oversized trees or rocks.
4. Verify the background feels deep but not distracting.
5. Verify repetition feels controlled, not chaotic.

---

# Phase 3: Obstacle, Gap, Bridge, and Gameplay Prop Replacement

## Objective

Replace current obstacle visuals and gameplay prop visuals with a coherent set built from the new environment art direction.

## Work To Do

1. Re-theme obstacles with the new packs:
   - jump obstacle = short rock / stump / low natural prop
   - slide obstacle = authored low branch or hanging barrier
   - lane block = larger rock or rooted barrier
   - gap/bridge zone = custom road break presentation
2. Do not use random decorative props as critical gameplay blockers if they reduce readability.
3. Rework giant rock presentation so it matches the Quaternius world palette.
4. Rebuild river/gap visuals so they look like part of the same world.
5. Rebuild bridge appearance as a hero gameplay asset:
   - stylized wood plank bridge or
   - magical light bridge or
   - stylized stone slab bridge
6. Rebuild blast visual presentation using custom VFX plus themed breakable object visuals.
7. Keep collision behavior unchanged unless a visual change requires collision tuning.

## Deliverables

- Obstacles match the new world theme.
- Bridge mechanic looks intentional, not like a reused prop.
- Giant rock and gap/river sections feel integrated into the new environment.

## Recommended Small Commits

1. `feat(obstacles): remap runner obstacles to curated quaternius gameplay props`
2. `feat(gameplay): replace gap and river visuals with authored themed segments`
3. `feat(gameplay): rebuild bridge and blast presentation as hero gameplay assets`

## What To Check In Godot

After this phase, check:

1. Every obstacle type is readable from a distance.
2. Jump, slide, lane block, bridge zone, and giant rock all look visually different.
3. The bridge appears cleanly and feels part of the world.
4. Blast targets look breakable and the effect feels satisfying.
5. Collision still matches the visible obstacle size.

---

# Phase 4: Player Character Replacement

## Objective

Replace the current player model pipeline with Quaternius Universal Base Characters and a fixed curated player look.

## Default Character Choice

Unless a later change is explicitly requested:

- Body: `Superhero_Male_FullBody.gltf`
- Hair: `Hair_SimpleParted`
- Palette: muted traveler colors using beige, green, brown, white, dark blue

This is still the best available default in the provided pack even though the pack naming says "superhero".

## Work To Do

1. Create one stable player scene or player visual subtree using:
   - one body
   - one hairstyle
   - one material setup
2. Replace the old runtime mesh-loading/debug-loading approach.
3. Keep one consistent character for the whole game.
4. Ensure the character scale works with the runner camera.
5. Ensure the silhouette remains readable in motion.
6. If needed, create one simplified material override path for consistent in-game colors.

## Deliverables

- One stable new player visual setup is in the game.
- Old player visual assets are no longer the runtime source.
- The character matches the new environment.

## Recommended Small Commits

1. `feat(player): replace legacy runner visual with quaternius base character`
2. `feat(player): add curated hairstyle and material setup for final player look`
3. `refactor(player): remove old dynamic model-loading path`

## What To Check In Godot

After this phase, check:

1. The character spawns correctly in the game scene.
2. The hair attaches properly and does not float or clip badly.
3. Scale looks correct relative to road, obstacles, and camera.
4. The player remains readable against bright grass and dark rocks.

---

# Phase 5: Animation Pipeline Replacement

## Objective

Replace the current mixed animation setup with a stable Universal Animation Library 2 integration.

## Required Animation Set

Only these need to be production-ready first:

- idle
- run / sprint
- jump start
- jump loop / fall
- land
- slide / crouch
- stumble / hit
- death / fail
- optional short cast or reach-forward motion for special ability presentation

## Work To Do

1. Replace the current animation source assumptions with the UAL2 source file.
2. Build a stable animation mapping for the actual gameplay states.
3. Remove old animation debug output and temporary merge logic once the new flow is proven.
4. Ensure transitions match gameplay timing:
   - run to jump
   - jump to fall
   - fall to land
   - run to slide
   - hit to fail
5. Keep animation naming and mapping centralized so future changes are easy.

## Deliverables

- Player states use the new animation pack.
- The player no longer depends on the old animation GLTF pack for runtime presentation.
- Motion looks consistent with the new character body.

## Recommended Small Commits

1. `feat(player): integrate universal animation library core movement set`
2. `feat(player): map gameplay states to stable run jump slide hit and death animations`
3. `refactor(player): remove legacy animation merge and debug workflow`

## What To Check In Godot

After this phase, check:

1. Run animation loops cleanly.
2. Jump arc visually matches the actual physics.
3. Slide starts and ends at the correct time.
4. Death and stumble states do not snap awkwardly.
5. The skeleton does not distort when switching states.

---

# Phase 6: HUD, In-Game UI, and Prompt Replacement

## Objective

Reskin gameplay UI using Kenney Adventure and replace gameplay prompts with Kenney Input Prompts.

## Work To Do

1. Re-theme the gameplay HUD using Kenney Adventure:
   - score/distance frame
   - coin frame
   - pause button
   - settings popup visuals
   - game over panel visuals
2. Keep the menu flow mostly the same unless a stronger visual improvement is obvious.
3. Improve the menu only if the new visual language can make it cleaner and better.
4. Re-theme tutorial/help prompts using Kenney Input Prompts:
   - tap
   - hold
   - double tap
   - swipe
5. Keep prompts simple and remove clutter once the player learns the action.
6. Use Kenney Mobile Controls only for:
   - tutorial mode
   - accessibility mode
   - optional mobile helper overlay
7. Do not make giant permanent on-screen mobile buttons part of the polished normal HUD.

## Deliverables

- Gameplay HUD matches the new UI style.
- Prompt system uses the new icon/prompt assets.
- Menu still works and fits the updated visual direction.

## Recommended Small Commits

1. `feat(ui): reskin gameplay hud pause settings and game over panels with kenney adventure`
2. `feat(ui): replace tutorial prompts with kenney input prompt assets`
3. `feat(ui): add optional mobile helper overlay using curated kenney mobile controls`
4. `feat(menu): polish menu visuals to better match the updated gameplay presentation`

## What To Check In Godot

After this phase, check:

1. HUD is readable in 16:9 and mobile-like aspect ratios.
2. Prompt icons are visible and understandable.
3. UI panels are not oversized or cluttered.
4. Menu, pause, settings, and game over screens still function correctly.
5. Mobile helper controls do not permanently pollute the polished game screen.

---

# Phase 7: Theme-Mode Stabilization and Gameplay Logic Fixes

## Objective

Fix the logic issues that will become more obvious once the visual migration is complete.

## Required Fixes

1. Preserve coin score bonuses instead of overwriting score from distance every frame.
2. Align quiz question types with the obstacle action they are meant to teach.
3. Prevent blast input from also forcing an unintended extra jump.
4. Reset pronunciation obstacle spacing state between runs.
5. Fix "NEW BEST" behavior so ties are not treated like a new high score.

## Work To Do

1. Fix score logic in the game manager.
2. Fix quiz question generation/action mapping so the mode matches its own design.
3. Fix player blast input behavior.
4. Fix pronunciation round reset metadata.
5. Fix final score/high-score display logic.
6. Re-test all three current modes after the asset migration.

## Deliverables

- The game plays correctly after the art replacement.
- New visuals do not hide old logic bugs.

## Recommended Small Commits

1. `fix(gameplay): preserve coin bonus scoring and correct final high-score presentation`
2. `fix(quiz): align question generation with intended obstacle action mapping`
3. `fix(player): prevent blast action from triggering unintended jump behavior`
4. `fix(pronunciation): reset pronunciation obstacle state between runs`

## What To Check In Godot

After this phase, check:

1. Final score includes both distance and coin value.
2. Quiz mode questions consistently match the action needed.
3. Double tap blast no longer causes a weird extra jump.
4. Pronunciation mode restarts cleanly.
5. High score UI behaves correctly when tying the best score.

---

# Phase 8: Legacy Asset Purge and Reference Cleanup

## Objective

Remove the old replaced visual assets and dead references so the project truly runs on the new pipeline.

## Work To Do

1. Identify all legacy visual assets no longer used by runtime scenes/scripts.
2. Delete replaced old visual assets in controlled batches.
3. Remove dead references in:
   - scenes
   - scripts
   - autoload setup helpers
   - UI theme loaders
4. Keep audio intact.
5. Keep only the final active asset references in production code.
6. Confirm there are no missing-resource warnings during project load or play.

## Deliverables

- Old replaced visual assets are removed.
- Runtime references now point only to the new production asset structure.
- The repo is cleaner and easier to maintain.

## Recommended Small Commits

1. `chore(cleanup): remove replaced legacy environment and obstacle visuals`
2. `chore(cleanup): remove replaced legacy player and ui visuals`
3. `chore(cleanup): remove dead asset references after migration completion`

## What To Check In Godot

After this phase, check:

1. Open the main scenes and confirm there are no missing file references.
2. Run the game and look for missing-resource errors in the output panel.
3. Verify all modes still load correctly.
4. Verify exported builds still package the required assets.

---

# Final Acceptance Checklist

Before calling the migration complete, verify all of the following:

1. The world uses Quaternius nature assets consistently.
2. The player uses Quaternius base character + UAL2 animation pipeline only.
3. The gameplay HUD and prompts use Kenney packs.
4. The road remains custom and gameplay-readable.
5. The bridge and blast mechanics look like hero features.
6. Natural mode, quiz mode, and pronunciation mode all still function.
7. Old replaced visual assets are removed.
8. Audio still works.
9. No missing-resource errors appear on startup or during gameplay.

# Explicit Out Of Scope For This Plan

These are not part of the current migration unless requested later:

- Full audio replacement
- New sourced music/sfx packs
- A brand-new invisibility gameplay system
- Major game design expansion beyond the current mechanics
- Forcing every single file from `new-assets` into runtime usage

# Implementation Reminder

At the end of each small portion:

1. Open Godot.
2. Run the affected scene or flow.
3. Verify the checklist for that portion.
4. Commit immediately with a focused message.

That is the safest way to complete this migration without breaking the project.

# Asset Migration Manifest

## Purpose

This manifest defines the curated Phase 1 runtime subset imported from `new-assets`.

The rule for this migration is:

- use all relevant new asset categories
- keep the runtime subset curated and repeatable
- avoid flooding the game with too many unrelated props

This document is the source of truth for Phases 2 through 8.

## Runtime Art Direction

- 3D world source: Quaternius Stylized Nature MegaKit
- player source: Quaternius Universal Base Characters
- animation source: Quaternius Universal Animation Library 2
- HUD and menu source: Kenney UI Pack Adventure
- gameplay prompts source: Kenney Input Prompts
- mobile/accessibility helper source: Kenney Mobile Controls
- audio source: existing project audio is kept for now

## Imported World Subset

### Trees

Imported to `assets/world/quaternius_nature/trees`

- `CommonTree_2`
- `CommonTree_4`
- `Pine_2`
- `Pine_4`

Usage intent:

- `CommonTree_*` for readable mid-distance nature silhouettes
- `Pine_*` for vertical variation and clearer far-line depth

### Rocks

Imported to `assets/world/quaternius_nature/rocks`

- `Rock_Medium_1`
- `Rock_Medium_2`
- `RockPath_Round_Small_2`
- `RockPath_Round_Wide`

Usage intent:

- `Rock_Medium_*` for major roadside blockers and lane-side visual weight
- `RockPath_*` for edge dressing, path breakup, and obstacle-adjacent dressing

### Plants

Imported to `assets/world/quaternius_nature/plants`

- `Bush_Common`
- `Fern_1`
- `Grass_Common_Short`
- `Grass_Common_Tall`
- `Flower_4_Group`

Usage intent:

- short grass near the road
- tall grass in the mid edge zone
- bush and fern clusters for controlled density
- one flower family only for color accent

### Background

Imported to `assets/world/quaternius_nature/background`

- `DeadTree_3`
- `TwistedTree_4`

Usage intent:

- distant silhouettes
- variation in horizon and environmental mood
- not for primary obstacle readability

### Shared Nature Textures

Imported to `assets/world/quaternius_nature`

- bark textures
- leaf textures
- grass textures
- flower texture
- rock textures
- path rock texture

These were copied because the selected GLTF files depend on shared texture references.

## Imported Character Subset

### Base Character

Imported to `assets/Characters/base_character`

- `Superhero_Male_FullBody.gltf`
- matching `.bin`
- eye, hair, body, normal, and roughness textures required by the model

Default runtime choice:

- body: `Superhero_Male_FullBody`

Reason:

- it is the most practical stable default in the provided pack for the first migration pass
- it gives a single consistent body while later phases focus on animation and in-game presentation

### Hair and Brows

Imported to `assets/Characters/hairstyles`

- `Hair_SimpleParted.gltf`
- `Eyebrows_Regular.gltf`
- matching `.bin`
- required hair textures

Default runtime choice:

- hair: `Hair_SimpleParted`
- eyebrows: `Eyebrows_Regular`

### Animation Source

Imported to `assets/Characters/animations`

- `UAL2_Standard.glb`

Usage intent:

- this becomes the single incoming source for the replacement gameplay animation pipeline

## Imported Kenney UI Subset

### Adventure UI

Imported to `assets/UI/kenney_adventure`

- banners
- brown, grey, and red button states
- brown panel variants
- progress bar variants
- round brown elements
- yellow jewel/star/exclamation icons

Usage intent:

- HUD framing
- pause/settings/game over panels
- theme selection polish
- tutorial banners

### Input Prompts

Imported to `assets/UI/kenney_input_prompts`

- tap
- double tap
- hold
- swipe left/right/up/down
- horizontal and vertical swipe helpers
- open/closed hand icons
- directional flair overlays

Usage intent:

- tutorial prompts
- action teaching
- gesture callouts for bridge, blast, jump, and movement

### Mobile Controls

Imported to `assets/UI/kenney_mobile_controls`

- gameplay helper icons
- a small button subset
- one joystick subset
- one dpad helper

Usage intent:

- optional tutorial and accessibility overlay
- not permanent default HUD chrome

## Reserved But Not Yet Built

These folders exist but do not have authored content yet:

- `assets/world/quaternius_nature/road_kit`
- `assets/Characters/materials`
- `assets/gameplay/obstacles`
- `assets/gameplay/bridge`
- `assets/gameplay/pickups`
- `assets/gameplay/vfx`

These will be populated in later phases.

## Explicit Notes For Later Phases

1. Do not pull more world assets into runtime unless a phase explicitly needs them.
2. Do not reintroduce old environment art into the active source lists.
3. Keep the curated subset stable unless a specific gameplay readability issue requires a change.
4. Audio remains intentionally unchanged during this phase.

## Cleanup Status

Completed cleanup:

- removed the unused legacy river and bridge model assets after the procedural crossing system replaced them
- removed the unused legacy UI button texture set after the Kenney Adventure theme became the active UI source

Active runtime dependencies still kept intentionally:

- `assets/Characters/Animations_GLTF/Rig_Medium/*`
- `assets/Characters/RunnerMannequin/*`
- `assets/UI/Icons/*`
- `assets/UI/Fonts/*`
- `assets/Environment/Sky/qwantani_noon_puresky_4k.exr`

Why they remain:

- the current live runner still depends on the animation-safe `Rig_Medium` path for stable runtime playback
- the shared icons, fonts, and skybox are still referenced by the active menu, HUD, and game scene

Guardrail:

- do not delete the remaining runner/mannequin assets until the player is fully migrated off that fallback path without breaking animation playback

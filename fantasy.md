# Fantasy Theme Implementation Plan

## Goal

Use the assets in `new-assets/Fantasy Props MegaKit[Standard]` to add a new `fantasy` visual theme to the game.

This theme should feel like a scholar-market / medieval adventure layer on top of the existing runner systems, not a full world rebuild.

The implementation should:

- keep the current gameplay systems intact
- reuse the existing terrain and world generation pipeline
- improve visual variety, obstacle readability, and mode presentation
- support `normal`, `quiz`, and `pronunciation` modes

## Core Direction

The new pack is best used for:

- side-of-road decoration
- obstacle reskins
- collectible reskins
- themed quiz / pronunciation presentation

The new pack is not strong enough by itself for:

- full terrain replacement
- full environment architecture replacement
- a completely new gameplay pipeline

So the correct implementation strategy is:

1. Keep the current nature world foundation.
2. Add a new `fantasy` theme profile.
3. Layer fantasy props into decorations, obstacles, and pickups.
4. Upgrade quiz and pronunciation visuals with fantasy-specific assets.

## Art Direction Rules

These rules should guide every phase:

1. The road stays gameplay-first and easy to read.
2. The base terrain can remain derived from the current `nature` setup.
3. The fantasy theme should feel warm, readable, and adventurous.
4. The visual identity should lean toward scholar-market / library / workshop fantasy, not dark combat fantasy.
5. Decorative props must never reduce lane readability.
6. Interior-only props should be used carefully and only where they make sense.
7. Larger props should remain outside the road and never create accidental gameplay collisions.

## Best Asset Groups To Use

### Decoration-friendly assets

- `Banner_1`, `Banner_1_Cloth`, `Banner_2`, `Banner_2_Cloth`
- `Barrel`, `Barrel_Apples`, `Barrel_Holder`
- `Bench`
- `Book_*`, `BookGroup_*`, `BookStand`, `Bookcase_2`
- `Bottle_1`, `SmallBottle`, `SmallBottles_1`
- `Bucket_Metal`, `Bucket_Wooden_1`
- `Candle_*`, `CandleStick*`, `Lantern_Wall`, `Torch_Metal`, `Chandelier`
- `Cabinet`, `Nightstand_Shelf`, `Shelf_*`, `Workbench*`
- `FarmCrate_*`, `Crate_Wooden`, `Chest_Wood`
- `Potion_*`, `Scroll_*`, `Pot_*`, `Vase_*`
- `Stall_Empty`, `Stall_Cart_Empty`

### Obstacle-friendly assets

- `Crate_Wooden`
- `Barrel`
- `Chest_Wood`
- `Bench`
- `Stool`
- `Bag`, `Pouch_Large`
- `FarmCrate_Apple`, `FarmCrate_Carrot`, `FarmCrate_Empty`
- `Chandelier`
- `Banner_*`
- `Rope_*`

### Collectible / reward-friendly assets

- `Coin`
- `Coin_Pile`
- `Coin_Pile_2`
- `Key_Gold`
- `Key_Metal`
- `Scroll_1`, `Scroll_2`

### Use sparingly

- `Anvil`, `Anvil_Log`
- `Dummy`
- `WeaponStand`
- `Sword_Bronze`, `Axe_Bronze`, `Pickaxe_Bronze`, `Shield_Wooden`

These are good for special zones or rare obstacle sets, but should not dominate the theme.

### Avoid for roadside world dressing

- `Bed_Twin1`, `Bed_Twin2`
- `Chair_1`
- `Table_*` dining props unless placed in a clear authored set

These are more interior-specific and can make the roadside feel random if overused.

## Recommended Files To Update

- `scripts/theme/theme_registry.gd`
- `scripts/world/world_generator.gd`
- `scripts/world/decoration_spawner.gd`
- `scripts/world/obstacle_spawner.gd`
- `scripts/ui/theme_select.gd`
- any asset-import or scene-reference files needed to expose the new `.gltf` props

## Phase 1 - Theme Foundation

### Objective

Add the `fantasy` theme as a real first-class visual theme.

### Tasks

1. Add a new `FANTASY_PROFILE` in `scripts/theme/theme_registry.gd`.
2. Base it on the structure already used by `NATURE_PROFILE` and `CYBERPRANK_PROFILE`.
3. Keep the player profile simple for v1:
   - reuse the current nature player setup
   - do not invent a new player art pipeline yet
4. Set up a warm fantasy atmosphere:
   - warmer sunlight
   - slightly richer fog color
   - wood / stone / moss-inspired road colors
   - lower-tech look than `cyberprank`
5. Add `fantasy` to the theme selection flow in `scripts/ui/theme_select.gd`.
6. Make it available for:
   - `normal`
   - `quiz`
   - `pronunciation`

### Defaults

- Reuse nature terrain behavior for v1.
- Reuse current player character for v1.
- Focus the first pass on world and obstacle theming, not character replacement.

### Validation

- `fantasy` appears in theme selection.
- Selecting it starts the game correctly.
- The world loads without falling back unexpectedly.

## Phase 2 - Import And Curate Fantasy Props

### Objective

Prepare a curated subset of the new assets for gameplay use.

### Tasks

1. Review the `Exports/glTF` assets and choose a clean subset.
2. Prefer a curated list over using the entire pack.
3. Group the selected assets into these categories:
   - near-road decoration
   - mid-ground decoration
   - far-background decoration
   - ground obstacles
   - overhead obstacles
   - collectibles / rewards
4. Verify the selected `.gltf` files import cleanly in Godot.
5. Confirm their scale and pivot behavior before wiring them into gameplay.

### Recommended curated categories

#### Near-road decoration

- bottles
- scrolls
- books
- pots
- candles
- sacks
- crates
- barrels

#### Mid-ground decoration

- stalls
- benches
- shelves
- bookcases
- workbenches
- banner clusters
- lanterns

#### Far-background decoration

- sparse stall silhouettes
- banner silhouettes
- shelves / bookcases only if they read clearly from distance
- continue mixing with existing nature background assets

### Validation

- Every selected asset loads as a `PackedScene`.
- Large props are not absurdly scaled.
- The curated list is small enough to keep the theme authored and consistent.

## Phase 3 - Fantasy Decoration Pass

### Objective

Use the new assets to make the roadside and background feel like a fantasy market / scholar route.

### Tasks

1. Extend the `decorations` section of the theme registry for `fantasy`.
2. Add categories compatible with the current decoration spawning system.
3. Reuse the existing decoration band logic in `scripts/world/decoration_spawner.gd`.
4. Map fantasy props into the existing band system:
   - near band
   - mid band
   - far band

### Recommended mapping

#### Near band

- `books`
- `scrolls`
- `pots`
- `small bottles`
- `candles`
- `small crates`
- `small barrels`

These should stay low to the ground and easy to read.

#### Mid band

- `Stall_Empty`
- `Stall_Cart_Empty`
- `Bench`
- `Workbench`
- `Workbench_Drawers`
- `Shelf_*`
- `Bookcase_2`
- `Banner_*`
- `Lantern_Wall`

These should create the strongest fantasy identity.

#### Far band

- selected stalls
- selected shelves / bookcases
- banners
- continued tree/background support from the existing nature theme

### Important rules

- Decorative props must have collisions disabled.
- Large props should stay away from lane space.
- Far-band shadows can be disabled if needed for performance.

### Validation

- The runner path remains readable.
- The world looks intentionally themed, not cluttered.
- Decorative density feels controlled on both sides of the path.

## Phase 4 - Normal Mode Obstacle Reskin

### Objective

Replace the current generic / nature obstacle presentation with fantasy-appropriate props.

### Tasks

1. Add a `fantasy` obstacle list in the theme registry.
2. Keep the current obstacle logic and collision behavior.
3. Swap only the visual scenes used by the spawner.
4. Preserve readability between:
   - jump / dodge obstacles
   - slide obstacles
   - giant blockers

### Recommended ground obstacles

- `Crate_Wooden`
- `Barrel`
- `Chest_Wood`
- `Bench`
- `Stool`
- `Bag`
- `Pouch_Large`
- `FarmCrate_*`

### Recommended overhead obstacles

- `Chandelier`
- `Banner_1_Cloth`
- `Banner_2_Cloth`
- `Rope_*`
- lantern / hanging prop combinations if scale works

### Giant obstacle guidance

For v1:

- keep the current giant rock system if fantasy replacements do not read well enough

Optional later improvement:

- create special multi-prop fantasy blockers such as a cart barricade or dummy-and-crate barricade

### Validation

- Ground obstacles clearly read as jump / dodge hazards.
- Overhead obstacles clearly read as slide hazards.
- No imported obstacle creates broken collision or bad pivot placement.

## Phase 5 - Quiz Mode Fantasy Pass

### Objective

Make quiz mode feel intentionally themed instead of using generic placeholders.

### Tasks

1. Replace the current placeholder quiz blocks with fantasy-themed props.
2. Keep the same obstacle-type logic and answer mapping.
3. Ensure each quiz obstacle type remains visually distinct.

### Recommended visual mapping

#### Jump obstacle

- stack of crates
- book stack
- barrel cluster

#### Slide obstacle

- chandelier
- hanging banner
- rope crossing

#### Blast obstacle

- training dummy
- weapon stand barricade
- crate-and-bench barricade

#### Bridge / river obstacle

- keep the current bridge / river mechanic
- add fantasy dressing such as banners, torch-like accents, and better bank visuals

### Important rule

Do not sacrifice readability for theme. Quiz mode must stay instantly understandable.

### Validation

- The player can still instantly tell which obstacle action is required.
- Quiz mode visuals feel connected to the fantasy theme.
- Answer flow remains unchanged and functional.

## Phase 6 - Pronunciation Mode Fantasy Pass

### Objective

Use the new props to make pronunciation mode feel more like a scholar / reading route.

### Tasks

1. Replace the plain pronunciation jump blocks with fantasy props.
2. Prefer props that fit a reading / learning identity.
3. Keep the HUD behavior unchanged in the first pass.

### Recommended pronunciation visuals

- `Book_Stack_*`
- `BookStand`
- `Chest_Wood`
- `Scroll_*`
- `Shelf_*` as side dressing
- `Candle_*` and `Potion_*` as side ambiance

### Theme direction

Pronunciation mode should feel like:

- a scholar path
- a reading route
- a magical study trail

This is a better fit for the educational side of the game than combat-heavy fantasy props.

### Validation

- The new obstacle visuals do not disrupt jump timing.
- Pronunciation mode still feels clean and readable.
- Side dressing supports the mode instead of distracting from the microphone prompt.

## Phase 7 - Collectible And Reward Pass

### Objective

Make pickups visually match the fantasy theme.

### Tasks

1. Add fantasy collectible visuals while preserving current collectible logic.
2. Use `Coin` as the main collectible model for the first pass.
3. Reserve `Coin_Pile`, `Coin_Pile_2`, and `Key_Gold` for:
   - rare rewards
   - milestone props
   - future bonus content
4. Keep scoring values unchanged unless there is a separate balancing pass.

### Validation

- Pickups are readable from gameplay distance.
- Pickup visuals fit the fantasy theme without creating confusion.

## Phase 8 - Menu And UI Flavor Pass

### Objective

Expose the fantasy theme cleanly in the menu flow.

### Tasks

1. Add a fantasy card in `scripts/ui/theme_select.gd`.
2. Use title and subtitle text that fits the tone.
3. Keep the current flow and interaction model unless a change is clearly necessary.

### Recommended theme card copy

- Title: `FANTASY`
- Subtitle: `Scholar market adventure`
- Icon text ideas:
  - `TOME`
  - `QUEST`
  - `MYTH`

### Optional later improvements

- fantasy-themed background accent colors
- banner-inspired panel styling
- warm parchment / brass accent palette

Do not block the feature on UI redesign.

### Validation

- The theme select screen communicates the new theme clearly.
- The user can enter the theme without extra friction.

## Phase 9 - Polish And Performance

### Objective

Make the fantasy theme stable, readable, and efficient.

### Tasks

1. Reduce decoration density if the scene becomes noisy.
2. Disable shadows on far or unimportant props where needed.
3. Remove props that look too interior-only or random on the roadside.
4. Rebalance scale ranges if some props dominate the frame.
5. Check that obstacles remain visible at increasing speed.

### Performance priorities

1. Lane readability
2. stable frame rate
3. obstacle clarity
4. thematic richness

### Validation

- The game remains playable at high speed.
- The fantasy theme looks deliberate instead of overfilled.
- The new assets do not create obvious performance regressions.

## Phase 10 - Final QA Checklist

Before calling the feature complete, verify:

1. `fantasy` launches in `normal`, `quiz`, and `pronunciation`.
2. Theme selection works without fallback bugs.
3. Decorations never collide with the player.
4. Ground and overhead obstacles remain easy to read.
5. Quiz obstacle types are visually distinct.
6. Pronunciation mode still works correctly with the new visuals.
7. Pickups remain readable and collectible.
8. No broken imports or missing `PackedScene` references remain.
9. The overall look feels like one coherent theme.

## Implementation Priority Order

Follow this order unless a technical blocker forces a change:

1. Phase 1 - Theme Foundation
2. Phase 2 - Import And Curate Fantasy Props
3. Phase 3 - Fantasy Decoration Pass
4. Phase 4 - Normal Mode Obstacle Reskin
5. Phase 5 - Quiz Mode Fantasy Pass
6. Phase 6 - Pronunciation Mode Fantasy Pass
7. Phase 7 - Collectible And Reward Pass
8. Phase 8 - Menu And UI Flavor Pass
9. Phase 9 - Polish And Performance
10. Phase 10 - Final QA Checklist

## Final Recommendation

The highest-value version of this feature is not "replace the whole game with fantasy assets."

The highest-value version is:

- keep the existing runner systems
- keep the readable nature foundation
- add a strong fantasy scholar-market layer
- use books, scrolls, stalls, banners, candles, crates, and barrels as the main identity

That approach gives the game a meaningful upgrade while staying realistic to implement.

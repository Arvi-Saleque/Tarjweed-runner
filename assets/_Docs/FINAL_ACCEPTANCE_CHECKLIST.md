# Final Acceptance Checklist

Use this after the migration cleanup passes are complete.

## Startup

1. Open the project in Godot and let imports finish.
2. Check the Output panel for missing-resource warnings.
3. Open the main menu, theme select, settings, pause, and game over flows once.

## World And Visual Readability

1. Start a natural run and confirm the world uses the curated Quaternius nature set.
2. Confirm trees, bushes, rocks, flowers, and background silhouettes all load with real textures.
3. Confirm the road remains readable and lane markers are easy to track at speed.
4. Confirm large props do not block obstacle readability.

## Player

1. Confirm the runner still animates immediately at run start.
2. Confirm jump, fall, land, slide, stumble, and fail states all play without T-pose or freeze.
3. Confirm the runner keeps the nature-gradient finish and stays readable against the environment.

Note:
- the current accepted build still uses the animation-safe `Rig_Medium` runtime path
- the imported Quaternius body, hair, and `UAL2_Standard` assets remain in the project for future player migration work

## Obstacles And Core Actions

1. Confirm jump, slide, lane block, giant rock, and river crossings all remain visually distinct.
2. Confirm giant rock double-tap blast does not trigger an extra jump.
3. Confirm hold-to-build bridge still creates the stylized bridge and collision works.
4. Confirm river crossings no longer depend on the deleted legacy river/bridge assets.

## Modes

1. Natural mode: run through coins, obstacles, bridge, blast, fail, retry.
2. Quiz mode: confirm question type matches the required action.
3. Pronunciation mode: confirm restart spacing is clean and no old state leaks into the next run.

## UI

1. Confirm the HUD uses the themed Kenney Adventure visuals.
2. Confirm button text remains readable in menu and overlays.
3. Confirm giant rock gesture prompt still appears correctly.
4. Confirm menu, settings, pause, retry, home, and game over buttons all work.

## Score And Save Behavior

1. Collect coins and confirm final score keeps bonus points.
2. Confirm a tied best score does not show `NEW BEST!`.
3. Confirm a true higher score does show the best-score celebration.

## Final Call

The migration is functionally accepted if:
- no missing-resource errors appear during startup or gameplay
- all three modes remain playable
- removed legacy assets are not referenced anymore
- the current retained runtime dependencies match `ASSET_MIGRATION_MANIFEST.md`


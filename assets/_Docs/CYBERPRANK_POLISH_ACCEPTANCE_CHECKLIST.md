# Cyberprank Polish Acceptance Checklist

Use this after the Cyberprank professional polish phases are complete.

## Startup

1. Open the project in Godot and let imports finish.
2. Check the Output panel for missing-resource warnings.
3. Open main menu, mode select, theme select, runner select, settings, pause, and game over once.

## Theme Routing

1. `Play -> Normal -> Nature` should still start normally with the stable nature presentation.
2. `Play -> Normal -> Cyberprank` should start with the full cyber presentation.
3. `Play -> Quiz` should still fall back safely to nature for V1.
4. `Play -> Pronunciation` should still fall back safely to nature for V1.

## Cyber World

1. The scene should feel darker and moodier than before while keeping the road readable.
2. Neon lane edges and track accents should stay brighter than side scenery.
3. Roadside districts should feel varied over a longer run instead of repeating the same setup.
4. Far skyline, mid structures, and near props should read as layered depth.
5. Decorative scenery must not block the playable road.

## Cyber Motion

1. Signs, service props, and scenic overhead pieces should have subtle motion or light life.
2. Floating atmosphere particles and light streaks should be visible in motion, especially at higher speed.
3. Ambient motion should add life without making obstacle reads harder.

## Cyber Track And Obstacles

1. The track should feel richer with lane rhythm, accents, and trench buildup.
2. Ground blockers should stay bypassable.
3. Overhead obstacles should remain clearly readable as slide-under obstacles.
4. Blast targets should remain the medium cyber robots, not giant scenery or unfair silhouettes.
5. Rivers/trenches should still be readable before the player reaches them.

## Bridge And Blast

1. Hold-to-build bridge should still show the progressive hologram build.
2. Partial live bridge support should keep the player alive while they are visibly on built bridge and still holding.
3. Releasing too early over unsupported river should still fail.
4. Cyber blast should still fire the laser effect and destroy the correct obstacles.

## Runner Feel

1. Lane changes should show clearer lean and feel sharper than before.
2. Jump should show anticipation and landing should show impact feedback.
3. Runner shadow should help ground the player.
4. Cyber motion trail should be visible but subtle.
5. No T-pose, frozen animation, or collision oddities should appear.

## UI Consistency

1. Main menu, theme select, runner select, HUD, pause, settings, and game over should feel like one visual family.
2. The runner select screen should feel focused rather than a flat grid.
3. Button text should remain readable.
4. The menu footer should show the final Cyberprank polish label instead of an old phase number.

## Audio

1. Cyber UI sounds should feel distinct from nature.
2. Lane change should use the simple tick sound.
3. Jump and slide-down should share the same short cyber movement sound.
4. Coin pickup should sound crisp, not odd or overly long.
5. Blast and bridge audio should still match the cyber visuals.

## Controls And Saves

1. Rebound controls should persist after closing settings.
2. Rebound controls should still work after restarting the game.
3. Score, coin bonus, and best-score behavior should still remain correct.

## Final Call

Cyberprank polish is accepted if:

- `Normal + Cyberprank` feels meaningfully more premium than the earlier prototype
- `Normal + Nature` still behaves and looks stable
- center-lane readability remains strong
- no missing-resource errors appear during startup or gameplay
- no major gameplay regressions were introduced during the polish pass

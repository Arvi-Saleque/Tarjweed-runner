Nature Runner Migration Notes

This folder tracks the current post-migration asset state.

Active visual pipeline:
- World: Quaternius nature subset under `assets/world/quaternius_nature`
- UI: Kenney Adventure + Kenney Input Prompts
- River and bridge crossings: procedural themed presentation
- Player: current live build still uses the animation-safe `Rig_Medium` path

Important retained legacy dependencies:
- `assets/Characters/Animations_GLTF/Rig_Medium`
- `assets/Characters/RunnerMannequin`
- `assets/UI/Icons`
- `assets/UI/Fonts`
- `assets/Environment/Sky/qwantani_noon_puresky_4k.exr`

Important removed legacy dependencies:
- old river and bridge model assets
- old UI button texture set
- unused Kenney mobile helper assets
- unused extra `Rig_Medium` clip packs

For the curated retained runtime set, see:
- `ASSET_MIGRATION_MANIFEST.md`

For the Cyberprank polish verification pass, see:
- `CYBERPRANK_POLISH_ACCEPTANCE_CHECKLIST.md`

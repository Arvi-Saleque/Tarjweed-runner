# Cyberprank Professional Polish Update Plan

## Summary

This plan upgrades the current `cyberprank` normal-mode experience from a strong prototype into a more polished indie-quality runner without replacing the whole game. The core direction stays the same because the theme, road readability, runner selection, and gameplay identity are already working. The focus now is on presentation polish: lighting, atmosphere, UI consistency, environment variety, runner juice, and ambient world motion.

The safest approach is:

1. polish Cyberprank first
2. keep Nature stable
3. only touch shared UI where it improves consistency
4. avoid risky rewrites of the stable animation/gameplay systems

## Target Outcome

After this pass, Cyberprank should feel:

- darker and more cinematic
- more alive and less repetitive
- more unified between gameplay and menus
- more premium in the runner feel
- more dramatic in the lane space and obstacle presentation

It should feel like a designed game world, not just a procedurally assembled asset mix.

---

## Phase 1 — Lighting and Atmosphere Foundation

### Goal

Get the biggest visual upgrade first by improving mood, depth, contrast, and scene cohesion.

### Implementation

- Add a dedicated Cyberprank lighting/atmosphere setup instead of relying mainly on material tint alone.
- Darken side-world materials and background props so the road remains the brightest guide.
- Push stronger contrast between:
  - dark road base
  - cyan lane lights
  - magenta special accents
  - muted warm support structures
- Add soft fog/depth haze so distant buildings and side objects blend into atmosphere instead of looking flat.
- Increase emissive intensity selectively on:
  - lane edges
  - road pulse panels
  - trench glow
  - hologram bridge
  - highlighted signs/props
- Improve grounding by strengthening:
  - shadow/readability under the runner
  - obstacle grounding on the road
  - contact feel for props near the track
- Keep the result colorful and kids-friendly, not grim or horror-dark.

### Files Likely Involved

- `scripts/world/world_generator.gd`
- `scripts/world/chunk.gd`
- `scripts/theme/theme_registry.gd`

### What To Check In Godot

- Cyberprank should immediately look more dramatic on run start.
- The road must stay very readable at speed.
- Side structures should no longer overpower the neon track.
- Nature mode should still look stable.

### Commit Split

- `feat(cyberprank): add atmosphere and lighting profile for world presentation`
- `tune(cyberprank): increase neon contrast and scene depth`

---

## Phase 2 — UI Consistency and Visual Identity Merge

### Goal

Make menus, selection screens, and gameplay UI feel like one product instead of adjacent styles.

### Implementation

- Define one clear Cyberprank visual language:
  - cyan = primary action
  - magenta = special/highlight
  - yellow = currency/reward
  - dark navy / glass = background panels
- Apply the same shape language and border/glow logic across:
  - theme select
  - runner select
  - HUD
  - pause
  - settings
  - game over
- Improve spacing and hierarchy so screens feel more deliberate and less grid-heavy.
- Reduce the “prototype card wall” feeling in runner selection:
  - fewer visible choices per screen
  - one dominant selected preview
  - better selected-state emphasis
  - short runner tagline text
  - themed background behind the picker
- Keep the current menu flow, but align the presentation more tightly with in-game Cyberprank.

### Additional Professional Polish

- Add subtle panel glow sweeps or hover response for selection screens.
- Use one consistent font treatment across cyber UI instead of mixing visual moods.

### Files Likely Involved

- `scripts/ui/ui_theme.gd`
- `scripts/ui/theme_select.gd`
- gameplay-facing UI scripts already using `UITheme`

### What To Check In Godot

- Character selection should feel more premium and focused.
- HUD and menus should now feel like the same product family.
- Buttons, borders, spacing, and text hierarchy should look intentional.

### Commit Split

- `feat(ui): unify cyberprank screen language across menus and gameplay`
- `feat(ui): redesign cyber runner selection into a focused presentation flow`

---

## Phase 3 — Roadside Variety and Anti-Repetition Pass

### Goal

Stop the environment from feeling copy-pasted over long runs.

### Implementation

- Create 4-6 controlled roadside set families and rotate them intentionally:
  - pod buildings
  - broken machinery
  - neon sign poles
  - pipes and cables
  - futuristic containers/barriers
  - playful drone/scanner stations
- Separate the world into visual depth bands:
  - near props
  - mid structures
  - far silhouettes
- Add chunk composition rules so the same family cannot repeat too many times in sequence.
- Add occasional overhead scenic structures that do not affect gameplay:
  - support arches
  - sign bridges
  - cable spans
- Keep decorative density under control so obstacles remain readable.

### Additional Professional Polish

- Give each chunk family a silhouette identity so the player feels progression through different district slices instead of one static biome.

### Files Likely Involved

- `scripts/world/decoration_spawner.gd`
- `scripts/world/world_generator.gd`
- `scripts/theme/theme_registry.gd`

### What To Check In Godot

- Long runs should show visibly different side compositions.
- The world should feel bigger and more authored.
- Obstacles should still remain clear in the center play area.

### Commit Split

- `feat(world): add curated cyber roadside district families`
- `tune(world): reduce repetition and improve skyline layering`

---

## Phase 4 — Road Richness and Lane Drama

### Goal

Make the center gameplay strip feel more designed, more premium, and more exciting.

### Implementation

- Push the existing cyber road further with:
  - animated emissive flow
  - glowing panel strips
  - hazard markings
  - chunk transition accents
  - slightly richer gloss/material contrast
- Add controlled drama around the lane space:
  - stronger center-lane visual energy
  - better buildup near trench and bridge zones
  - stronger anticipation around blast obstacles
- Add occasional road-only decorative logic that supports speed but not clutter:
  - pulses
  - side nodes
  - warning bars
  - transition decals

### Additional Professional Polish

- If feasible, add subtle animated emissive scrolling rather than static glow so the track feels technologically alive.

### Files Likely Involved

- `scripts/world/chunk.gd`
- `scripts/world/obstacle_spawner.gd`
- `scripts/theme/theme_registry.gd`

### What To Check In Godot

- The road should feel more premium without becoming noisy.
- Center-lane drama should increase while readability stays strong.
- Trench, bridge, and special obstacles should feel more staged.

### Commit Split

- `feat(track): enrich cyber lane presentation with animated accents`
- `tune(gameplay): increase lane drama around traversal moments`

---

## Phase 5 — Runner Feel and Movement Juice

### Goal

Make movement feel more alive and commercial without destabilizing the current working runner setup.

### Implementation

- Improve lane-switch feel with stronger body lean and better response timing.
- Add small jump anticipation and stronger landing feedback.
- Add movement effects:
  - footstep sparks or dust
  - faint trail or glow ribbon
  - landing pulse / contact burst
- Improve the runner’s shadow/contact readability against the road.
- Keep the stable animation-safe setup; do not reopen large animation pipeline risk unless absolutely necessary.

### Additional Professional Polish

- If safe, add tiny camera response for lane switch and landing.
- Distinguish movement feel by selected cyber runner only through subtle FX color or trail identity, not full gameplay differences.

### Files Likely Involved

- `scripts/player/player_controller.gd`
- `scripts/player/player_animation.gd`
- existing VFX helpers if appropriate

### What To Check In Godot

- Lane switching should feel more intentional.
- Jumping and landing should feel stronger.
- The runner should visually pop from the darker world.

### Commit Split

- `feat(player): add movement anticipation and landing polish`
- `feat(vfx): add cyber runner motion effects and stronger grounding`

---

## Phase 6 — Ambient Motion and World Liveliness

### Goal

Remove the “frozen city” feeling and make the world feel inhabited.

### Implementation

- Add lightweight ambient motion:
  - blinking lights
  - emissive pulse cycles
  - floating particles
  - moving drones or scanner props
  - rotating fans / antenna parts
  - billboard glow sweeps
- Keep motion deterministic and cheap rather than simulation-heavy.
- Add occasional background-only motion moments to increase excitement without affecting play.

### Additional Professional Polish

- Use motion rhythms to reinforce speed and progression, not just random animation.
- Add a few “hero moments” like passing light streaks or overhead glow pulses every so often.

### Files Likely Involved

- `scripts/world/world_generator.gd`
- `scripts/world/decoration_spawner.gd`
- any helper VFX/prop scripts needed

### What To Check In Godot

- The world should feel alive even when no obstacle is directly in front.
- Motion should not distract from obstacles.
- Performance should remain stable enough for playtesting.

### Commit Split

- `feat(world): add animated cyber ambient props and sign motion`
- `feat(vfx): add lightweight atmospheric particles and light streaks`

---

## Phase 7 — Final Integration and Acceptance Polish

### Goal

Finish the pass cleanly, prevent regressions, and document what changed.

### Implementation

- Recheck all new Cyberprank profile keys and ensure Nature has safe defaults.
- Remove duplicated temporary styling introduced during the pass.
- Verify obstacle readability again after visual richness increases.
- Verify runner selection still works cleanly after UI redesign.
- Verify controls remapping and gameplay fixes still behave as expected.
- Add/update acceptance documentation for the final polish pass.

### What To Check In Godot

- `Normal + Cyberprank` should now feel significantly more premium.
- `Normal + Nature` should still behave and look stable.
- `Quiz` and `Pronunciation` should still safely use their current visual behavior.
- No missing-resource warnings.
- No major gameplay regressions.

### Commit Split

- `chore(polish): clean up shared presentation fallbacks and duplicate styling`
- `docs(polish): add final cyberprank acceptance checklist`

---

## Extra Ideas Worth Including If Time Allows

These are optional, but they would increase polish further without changing the game’s core identity:

- Add themed district transitions every few hundred meters so the cyber world feels like multiple sub-areas.
- Add a “hero obstacle framing” moment where special obstacles get stronger pre-approach lighting.
- Give selected runners unique accent trail colors in menus and gameplay.
- Add subtle music/ambient intensity ramp based on speed.
- Add a polished start-of-run reveal moment for Cyberprank.

---

## Final Acceptance Checklist

By the end of this update pass, Cyberprank should satisfy these points:

- Lighting is moodier and more cinematic.
- Roadside repetition is noticeably reduced.
- Background depth is stronger.
- The road feels more designed and animated.
- The runner feels more alive.
- The world has ambient motion.
- The UI and gameplay feel like one visual identity.
- Character selection feels premium instead of prototype-like.
- Gameplay readability remains strong.
- Nature mode remains stable.

---

## Defaults and Assumptions

- This pass is Cyberprank-first, not a full game-wide art overhaul.
- Nature mode is preserved and only receives safe fallback support.
- Existing stable gameplay and animation systems are preferred over risky rewrites.
- Professional polish here means improving:
  - lighting
  - atmosphere
  - variation
  - motion
  - runner juice
  - UI consistency
  - presentation focus

---

## Completion Note

The implementation phases in this plan have been completed in the current working branch through Phase 7. Use `assets/_Docs/CYBERPRANK_POLISH_ACCEPTANCE_CHECKLIST.md` as the final Godot verification pass for the Cyberprank professional polish update.

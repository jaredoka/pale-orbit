# Vertical Slice Acceptance Checklist (T24)

Date: 2026-07-12 · Build: develop @ M4. Automated = verified headless; Playtest = needs/has user confirmation.

| Req | Status | Evidence |
|---|---|---|
| PLR-1 movement | ✅ playtest (M0/M1 sessions) | 8-dir, normalized, wall slide |
| PLR-2 shooting | ✅ playtest | 4-dir hold-fire at stat rate; range/wall despawn |
| PLR-3 health | ✅ automated + playtest | test_game_state: clamps, `player_died` once |
| PLR-4 i-frames | ✅ playtest | 1 s blink, ≤1 hit/s confirmed after M3.1 fix |
| GEN-1..4 | ✅ automated | test_floor_generator: 100 seeds, 0 failures |
| RM-1 lock/clear | ✅ playtest | incl. Blob children (M1/M3.1) |
| RM-2 persistence | ✅ playtest | cleared registry |
| RM-3 transitions | ✅ playtest | deferred swap fix (m3.2); no dual-room frames |
| RM-4 spawn variety | ✅ automated (seeded) + playtest | 5 layouts, deterministic |
| ENM-1..4 | ✅ playtest | behaviors confirmed; tuning m3.1 |
| ENM-5 feedback | ✅ code + ⏳ playtest | white flash + death poof anim + SFX (T21/T23) |
| BOS-1/2 | ✅ playtest | phase once; 2.0 s charge telegraph |
| BOS-3 victory | ✅ playtest | winnable at 250 HP after tuning |
| ITM-1 cells | ✅ playtest | overheal impossible; pickup remains |
| ITM-2 modules | ✅ playtest | 3 items apply via apply_item |
| ITM-3 pipeline | ✅ automated | 3 `.tres` share one ItemDef script |
| UI-1 HUD | ✅ code + ⏳ playtest | heart textures, item icons, minimap |
| UI-2/3 win/lose | ✅ playtest | freeze + R restart resets fully |
| ART-1 sheets | ✅ automated | 41 PNGs, strip naming `<entity>_<anim>_<n>.png` |
| ART-2 style | ⏳ playtest | palette-locked, 16–24 px chars; needs final user style pass |
| ART-3 rendering | ✅ config + ⏳ playtest | 480×270, nearest, integer, snap; confirm crispness at 3× |
| NFR-1 perf | ⏳ playtest | pooled 64+64; needs 60 fps spot-check in boss fight |
| NFR-2 input | ✅ automated | grep: 0 raw-key hits |
| NFR-3 headless | ✅ automated | import + run error-free |
| NFR-4 determinism | ✅ automated | all gameplay RNG seeded from rng_seed |

**Definition of done:** full run spawn → item → Hive Queen kill with final art, no crashes — pending the user's final playthrough (⏳ rows above).

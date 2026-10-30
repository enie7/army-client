# World rendering rebuild

Plan for the `render-decoupling` branch: draw the game world entirely on the
GPU, from data, so world objects stop being Flash display objects.

## Why

The `stage3d` branch draws the world on the GPU by **mirroring** a hidden
Flash display list (`src/game/render`): the game still builds and animates
every world MovieClip, and each object's current look is snapshotted into a
cached texture. That removed Flash's full-window repaint and made light
scenes run at the game's full 40 fps, but heavy scenes are still slow.

Measurements (release runtime, `--profile`, quiet machine):

| scene | display objects in the hidden world | fps | our code / frame | runtime / frame | allocation |
|---|---|---|---|---|---|
| home base, few areas | ~2,000 objects, ~1,000 MovieClips | 36-40 | ~1-5 ms | ~20 ms | — |
| same map, most areas unlocked | ~9,800 objects, ~5,200 MovieClips | 6-13 | ~10-20 ms | 70-140 ms | 300-400 MB/s |

What the time goes to in the heavy scene:

- Not drawing: the texture cache is warm (almost nothing is rasterised), and
  the GPU present takes ~3.5 ms.
- The AIR runtime managing the hidden display list: advancing timelines and
  building their frames, per-object work every frame, and garbage collection
  of a 1-1.6 GB heap (2-4 collections every 3 s, ~1.2 GB each).
- The allocation sampler (`--alloc-sample`, debug launcher) attributes ~96%
  of allocation to `[execute-queued]`, i.e. timelines constructing display
  objects (MovieClips, Shapes, frame-script Functions, TextFields), about half
  of it inside `hint_health_enemy`.
- Taking the hidden world off the stage, and pausing timelines nobody can see,
  changed little. The cost comes from the number of Flash display objects
  that exist, not from where they are.

Every unit also owns a complete art tree for each of its animation states
(idle, move, aim, shoot, hit, die, ...), of which only one is ever shown.

## Goal

World objects (units, buildings, decorations, debris, effects) are drawn by
Starling from texture atlases, driven by game state. No per-object Flash
display trees, no snapshot mirror. The HUD stays in Flash.

Requirements:

- **No loss in visual quality.** Art is rasterised from the original vectors
  at the actual screen scale (2x on Retina), at the highest quality setting.
- **Same behaviour.** Game logic keeps its classes and state; only how objects
  are drawn changes. Anything the logic reads from timelines (frame labels,
  stop frames) is reproduced from playback data.
- **Playable at every step.** Object types move over one at a time; anything
  not converted yet keeps using the mirror. `--cpu-render` keeps working.
- **40 fps animation.** The art is authored for the game's 40 fps; atlas
  playback runs on a 40 fps clock regardless of the display rate.

## Constraints learned so far

- Game logic polls Flash timelines: popups close when an outro reaches its
  last frame, dying units / spawning beacons / enemy installations finish on
  an `"end"` label, fire missions trigger on `"start_flash"`, `"debris"`,
  `"start_shake"`. Fixed-step logic broke this (a tutorial prompt never
  closed), so logic stays per-frame until the world no longer depends on
  timelines (M7).
- Game code writes into named children of unit art: `Hint_Health_Friendly`
  (text `Text_Value`, `Text_Power_Value`, badge `Badge_Fire_Power`), the
  attention hint (`Hint_Health_Friendly_Attention` > `Hint_Friendly` /
  `Hint_Enemy`), and `Unit_Container` (flipped to face left/right).
- Looping hint animations rebuild their children at keyframes, which resets
  their text to the art's "99/99 x99" placeholder.
- Mouse picking is grid math (`FloorClicked`, `getTileUnderMouse`), except
  the move-target cells (`MapGUIEffectsLayer`), loot and a few icons.
- The ground and fog are already drawn from world-space GPU chunks
  (`GroundChunks`).
- Presents between Flash frames are possible (a pacing timer), but only when
  Flash frames leave idle time.
- The game loop and enemy turns are summarised below; they decide when
  objects change state.

## Game loop and enemy turns

Per frame (`GameMain.onEnterFrame` -> `logicUpdate(dt)` -> `StateMachine` ->
`GameState.logicUpdate`): server responses, HUD (`dt` clamped to 40 ms),
mission / level-up popups, then — unless a modal popup is open, which freezes
actions and the scene — `updateActions(dt)` and `mScene.update(dt)` with the
unclamped delta (characters, static objects, patrols, highlight, sort,
camera, fog, effects).

All actions, player and enemy, run through **one global serial queue**
(`GameState.mMainActionQueue`); enemy actions jump to the front. An action
that never finishes blocks everything after it.

"Turns" mean two different things:

- **Enemy units** are a hybrid: a real-time timer (minutes; `ReactionTime` /
  `next_action_at`) runs out, then the unit takes a place in a queue that
  advances by one each time the player spends energy (`reduceEnergy`: walk,
  attack, clean, build, fire mission...; not repairs or harvest). When its
  number reaches 0 it attacks in range or steps toward the player, for up to
  `MovementRange` steps. The attack warning shows when it is 3 or fewer
  energy actions away. Nearby enemies jump the line when the player attacks
  (`activateNearbyEnemies`).
- **Enemy installations** are either turn-based (`ReactionTurns`: counts
  `playerMoveMade()` — walking, attacking, fire missions; not harvest, build
  or clean) or real-time (`ReactionTime`), with a warning animation one turn
  or 3 s before acting.
- **PvP** is truly turn-based (`PvPMatch`: actions left, turn counter).

Timeline dependencies the rebuild must reproduce exactly — label events must
fire on the same frame, because several have no fallback and would stall the
global queue:

| Waits for | Where | Fallback |
|---|---|---|
| attacker's `"end"` (player unit attacks unit / installation) | `AttackEnemyAction:76`, `AttackEnemyInstallationAction:78` | none |
| enemy unit attack `"end"` | `EnemyAttackingAction:109` | `Shooting.Length` |
| spawning, two phases | `EnemySpawningAction:59,66` | 3000 / 300 ms |
| unit dying `"end"` | `IsometricCharacter:719` | `Explosion.Length` |
| paratrooper drop, installation / beacon wreck, hit effect `"end"` | `EnemyUnit:507`, `EnemyInstallationObject:268`, `SpawningBeaconObject:121`, `HitEffect:20` | none |
| fire mission frames + `"start_flash"`, `"debris"`, `"start_shake"` (advanced by `nextFrame()` per logic call) | `FireMissionObject:202-299` | — |

Labels are read via `AnimationController.getCurrentAnimationFrameLabel`, up
to 3 levels deep; `currentFrameLabel` is only set on the labelled frame
itself, so a skipped frame means a missed label.

## Architecture

```
game logic (unchanged classes)          drawing
-----------------------------          -------------------------------
Renderable / IsometricCharacter  --->  ObjectView (interface)
  position, state, direction,           |- FlashView    today's behaviour
  alpha, depth, hints                   |                (mirrored, as now)
                                        '- StarlingView  atlas playback
                                                         + overlays
AtlasBuilder (runtime)
  symbol class -> frames (textures, pivots), labels, stop frames
```

- **AtlasBuilder** — for a symbol, instantiates one offscreen copy and steps
  it frame by frame (nested timelines included), rasterising each frame with
  the existing `SnapshotCache` rasteriser at the current zoom x
  contentsScaleFactor. Records frame labels, stop frames and loop points.
  Packs frames into atlas textures; caches per symbol and zoom; builds
  lazily, with prewarming for the types present on the map during loading.
- **ObjectView** — what `Renderable` talks to instead of its
  `DisplayContainer`: `setPosition`, `setState(state, direction)`,
  `play/stop`, `setAlpha`, `setVisible`, depth, and label callbacks
  (`onLabel("end", ...)`).
- **StarlingView** — a Starling sprite playing atlas frames on a 40 fps clock,
  flipped with `scaleX`, firing label events from the playback data.
- **Overlays** — health / power / warning hints drawn by code (bitmap-font
  text, badge frames from the atlas) instead of living inside the art.

## Milestones

Each milestone ends with the game playable and a measurement of the heavy
base (`--profile`: fps, frame breakdown, allocation) against the table above.

| | Milestone | Done when |
|---|---|---|
| M1 | **AtlasBuilder.** Survey the world art first: which symbols, how deeply timelines nest, frame scripts, code-driven children. | A symbol's frames render identically to the Flash clip, side by side (debug view). |
| M2 | **ObjectView** interface; `FlashView` wraps today's container. | No behaviour change; all world objects go through the interface. |
| M3 | **Static objects** (decorations, debris, props) on `StarlingView`. | They no longer exist as Flash display objects; visuals identical. |
| M4 | **Buildings**, incl. production / harvest / construction states. | Same, plus state changes and timers behave as before. |
| M5 | **Units**: states, directions, label events, hint overlays. | Heavy base no longer allocates per unit; dying/spawning/attack flows unchanged. |
| M6 | **Effects layer**: projectiles, explosions, clouds, icons, fire-mission sequences. | Hidden world contains no world art. |
| M7 | **Remove the mirror**; decouple logic onto a fixed 40 Hz step and present at 60 Hz+ with interpolated motion. | Smooth panning and movement; heavy base at the display rate. |

## Testing

- Saves: `armyattack_2` (light), the expanded base (heavy). Load first, then
  Play (Play decides tutorial mode from the loaded state).
- `macos/build.sh` (add `PROFILE=1` for traces); `--profile` for the
  release-runtime profiler; `macos/run-debug.sh [--alloc-sample=N]` for the
  debug launcher; `--cpu-render` for the original renderer.
- Profiler hotkeys (packaged app with `--profile`): Shift+I unit inspector
  and scroll gates, Shift+C census, Shift+D dirty-object scan, Shift+L layer
  test, Shift+O off-stage world.
- Before measuring, check `uptime`: load from other apps (VMs, Stocks) has
  doubled frame times in earlier runs.

## Risks

- Nested timelines driven by code (e.g. `gotoAndStop` on a badge) cannot be
  baked into a flat frame list; each needs an overlay or a separate layer.
- Atlas memory: units x states x frames x zoom levels x Retina. Needs lazy
  building and eviction; budget to be measured in M1.
- First-use rasterisation hitches; mitigated by prewarming during loading.
- Behaviour that depends on timeline timing (labels reached on a given frame)
  must match exactly; label events come from the same frame counts.

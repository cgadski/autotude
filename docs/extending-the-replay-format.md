# extending the replay format

This document explains what you need to have in mind to update the replay format.
As an example, we consider the case of adding data on "turrets" in the game that shoot
at the planes.

A replay (`.pb`) is a gzipped sequence of length-delimited `Update`
messages, as defined in `proto/update.proto`. A bunch of other things
are generated from this schema:

- `just export-java-gen` -- copies protobuf classes into the Altitude
 source tree at `$ALTI_SRC/Altitude/src/main/java/em/altitude/game/protos/`,
so the bot client can record games.
- `make viewer/autotude/proto/` -- classes for the haxe replay viewer.
- `make rl/alti_rl/proto/` -- python classes, for the RL code (not necessary to rebuild)
- `make stats_db/proto/` -- a copy of the protobuf files so that Docker
can build stats_db (Rust app that indexes replays into a database)

For the turrets example: we define two new `ObjectType` values (`TURRET = 76`,
`TURRET_BULLET = 77`) and a new turret section/field in `game_objet.proto`:

    // # Turrets
    optional sint32 gun_angle = 63; // 1/10 degrees, turret gun's swivel from its mounted orientation

If you make a change to the format or the bot client code responsible for recording, bump the version recorded in each replay: edit `ProtobufWriter.java`'s `loadEvent` (`setProtocolVersion`) and note the change under `## version notes` in the main README.

## 1. Recording in the game

The bot client records data on objects through `ProtobufWriter.observeObject`, which
buffers one `GameObject` per object per frame to the protobuf update record. Existing examples to copy from, in `altitude/Altitude/src/main/java/em/altitude/game/`:

- `model/Base.java`, `model/Goal.java` -- a `ConcaveBody` from the level:
  hold an `Integer protobufUid`, call `recordProtobufObject()` from
  `update()`, allocate the uid with
  `game.getProtobufWriter().allocUid()`, and build the message inside
  `writer.observeObject((b) -> ...)`.
- `plane/Bullet.java` -- projectiles: just override
  `protected ObjectType protobufObjectType()` in the subclass and it
  records every frame it's active.
- `plane/Plane.java` -- planes, with the most fields.

Things that tend to matter:

- Gate recording on the object's state. Turrets and bases record only
  while `alive`, so a destroyed object disappears from the stream (which
  is itself replay data: see the viewer's `EffectTimeline`).
- Record health as a fraction times 1000, using a scale the viewer can
  divide back out.
- Positions are half-pixels relative to the map's min corner; angles are
  1/10 degrees; use the `ProtobufWriter.record*` helpers and don't roll
  your own conversions.
- Bodies placed by map XML (`Base`, `Goal`, `Turret`) record
  `pos + transformation.translate` as their position and the
  transformation's `rotate`/`scale`/`flipX`/`flipY` separately: keep this
  convention so the viewer can draw a single sprite at the recorded
  position.
- Sources that are not players (a turret is its bullets' damage source,
  with `PlayerScene.SERVER_PLAYER_ID = -1`) need care in `uint32` fields:
  set `owner` only for ids >= 0.

Note the recording only happens when a `ProtobufWriter` listener is
registered -- i.e. on the bot server and the headless bot client
(`BotClient` implements `IProtobufListener`, and writes the recording
when `record="true"` in its config).

## 2. Game resources

The viewer can't read the game's packed assets, so
`game_resources/bin/sprites.rs` extracts them into `out/sprites`
(sprites.json + texture page pngs) and `out/sounds`:

- `TYPES` maps `ObjectType` numbers to the poly the game draws for them
  (one entry per type; the `alfi_home/resources/dist/.poly` paths).
- `EXTRA_POLYS` lists polys the viewer wants without a type.
- `EXTRA_IMAGE_DIRS` lists image directories used without a poly (the
  game draws some images directly).
- `SOUND_DIRS` lists under `dist/.sound/sounds` to copy for the viewer.

Team colours follow the plane pattern: extract one poly and let the image
filename do the work. Team-coloured images are named by their `r_g_b`
string (e.g. `render/map/turret/0_128_5_base.png`) and every colour of
them is in the extracted texture pages; the viewer's
`Sprites.teamImage` swaps the colour in the name for the object's team.
Per-team poly *files* (like the game loads for turrets) don't need to be
extracted -- their geometry is identical modulo the image path.

Run extraction with `make game_resources` (needs `ALTI_INSTALL`).

## 3. The viewer

Generated bindings: `make viewer/autotude/proto/` (protohx), then
rebuild the javascript with `make viewer/out/viewer.js` (or just any make
target that depends on it).

Where a new type needs support, in `viewer/autotude/viewer/`:

- `ObjectLayer.hx` draws each object; special cases are dispatched at the
  top of `drawGameSprite`, default-drawn through the `TYPES` sprite of
  their type. If you need per-vertex placement beyond
  position/angle/scale/flip, do what the turret's gun does: transform
  each image corner through `placeVertex` yourself.
- `EffectTimeline.hx` infers implied effects from objects appearing,
  changing, and disappearing: new spawned things may need to be excluded
  from `Spawn`/`Fire` (e.g. `GOAL`, `BASE`, now `TURRET`), and new
  explosives need an entry in `EXPLOSIVES`.
- `Sound.hx` maps those effects to the game's sounds, by object type.
- `EffectLayer.hx` draws effects keyed on the `EffectKind`s above; add a
  new case here when the effect doesn't fit the generic ones, e.g. the
  explosion uses EXPLOSIVES' size vs. `BaseDestroyed` has its own kind.

## 4. Testing end to end

For the human operator:

- `just export-java-gen`
- Compile java, `just setup-from-src` to fetch the bot client
- `just client "Official #3 - TBD - maxPing=400"` -- spectate and record
  into `recordings/` 
- `just view $path` to run the viewer on the recorded file.

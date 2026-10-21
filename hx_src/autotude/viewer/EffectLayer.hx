package autotude.viewer;

import autotude.proto.GameObject;
import autotude.proto.ObjectType;
import autotude.viewer.EffectTimeline.TimedEffect;
import h2d.Graphics;
import h2d.RenderContext;
import h2d.Tile;

// Effect images, from the game's dist/.image/effects.
final BLAST = "effects/explosion/blast.png";
final SHOCKWAVE_RING = "effects/explosion/shockwave_ring.png";
final EXPLOSION_SMOKE = "effects/explosion/smoke.png";
final SPAWN_SHOCKWAVE = "effects/spawn/shockwave.png";
final INVULN_FRAMES = [for (i in 0...8) 'effects/invuln/invuln_merged_000$i.png'];
final SPARKS = ["effects/spark/spark1.png", "effects/spark/spark2.png", "effects/spark/spark3.png"];
final SMOKE_LIGHT = ["effects/smoke_white1.png", "effects/smoke_white2.png"];
final SMOKE_DARK = ["effects/smoke1.png", "effects/smoke2.png"];

// Durations in ticks (1/30 s), sizes as image scales.
final BLAST_TICKS = 12;
final RING_TICKS = 16;
final SMOKE_TICKS = 45;
final SPAWN_TICKS = 16;
final INVULN_TICKS = 60;
final SPARK_TICKS = 8;

// Damaged planes trail smoke: a puff every few ticks over the last second.
final TRAIL_SPACING = 3;
final TRAIL_TICKS = 30;
final SMOKE_BELOW_HEALTH = 500; // of 1000
final DARK_SMOKE_BELOW_HEALTH = 250;

final LONGEST_EFFECT = 60;

/**
	Effects worked out from the replay (see EffectTimeline), drawn either
	under the game objects (smoke) or over them (glowing blasts and sparks).
**/
class EffectLayer extends Graphics {
	final state:PlayerState;
	final timeline:EffectTimeline;
	final over:Bool;

	public var sprites:Null<Sprites>;

	public function new(state:PlayerState, timeline:EffectTimeline, over:Bool) {
		super();
		this.state = state;
		this.timeline = timeline;
		this.over = over;
		if (over)
			blendMode = Add;
	}

	override function draw(ctx:RenderContext) {
		clear();
		final sprites = this.sprites;
		if (sprites != null && state.showMapArt) {
			final tick = state.frameIdx;
			final update = state.replay.updates[state.replay.updateAt(tick)];
			if (!over)
				for (o in update.objects)
					if (o.type <= ObjectType.MIRANDA && o.health < SMOKE_BELOW_HEALTH)
						drawSmokeTrail(sprites, o, tick);
			for (e in timeline.between(tick - LONGEST_EFFECT, tick))
				drawEffect(sprites, e, tick - e.tick, update.objects);
		}
		super.draw(ctx);
	}

	function drawEffect(sprites:Sprites, e:TimedEffect, age:Int, objects:Array<GameObject>) {
		switch e.kind {
			case PlaneExplosion:
				explosion(sprites, e, age, 1);
			case Explosion(size):
				explosion(sprites, e, age, size);
			case Spawn if (over):
				image(sprites, SPAWN_SHOCKWAVE, e.x, e.y, age, SPAWN_TICKS, 0.2, 0.9, 0.9);
				// the invulnerability shield follows the plane
				final plane = planeOf(objects, e.owner);
				if (plane != null && age < INVULN_TICKS) {
					final tile = sprites.tile(INVULN_FRAMES[Std.int(age / 2) % INVULN_FRAMES.length]);
					if (tile != null)
						TexturePages.drawImage(this, tile, plane.positionX / 2, state.geom.maxY - plane.positionY / 2, 1.1, 0,
							age < INVULN_TICKS - 10 ? 0.8 : 0.8 * (INVULN_TICKS - age) / 10);
				}
			case Hit if (over && age < SPARK_TICKS):
				for (i in 0...3) {
					final tile = sprites.tile(SPARKS[i]);
					if (tile == null)
						continue;
					final angle = noise(e.tick, i) * Math.PI * 2;
					final dist = 4 + age * (2 + 3 * noise(e.tick, i + 7));
					TexturePages.drawImage(this, tile, e.x + Math.cos(angle) * dist, e.y + Math.sin(angle) * dist, 1.2, 0,
						1 - age / SPARK_TICKS);
				}
			default:
		}
	}

	// A blast and an expanding ring (glowing, over objects) and a smoke cloud
	// (under them).
	function explosion(sprites:Sprites, e:TimedEffect, age:Int, size:Float) {
		if (over) {
			image(sprites, BLAST, e.x, e.y, age, BLAST_TICKS, 0.25 * size, 0.55 * size, 1, noise(e.tick, 1) * Math.PI);
			image(sprites, SHOCKWAVE_RING, e.x, e.y, age, RING_TICKS, 0.3 * size, 1.6 * size, 0.8);
		} else {
			image(sprites, EXPLOSION_SMOKE, e.x, e.y, age, SMOKE_TICKS, 0.3 * size, 0.6 * size, 0.6, noise(e.tick, 2) * Math.PI);
		}
	}

	// An image growing from `scale0` to `scale1` and fading out over `ticks`.
	function image(sprites:Sprites, path:String, x:Float, y:Float, age:Int, ticks:Int, scale0:Float, scale1:Float, alpha:Float,
			rotation:Float = 0) {
		if (age >= ticks)
			return;
		final tile = sprites.tile(path);
		if (tile == null)
			return;
		final f = age / ticks;
		TexturePages.drawImage(this, tile, x, y, scale0 + (scale1 - scale0) * f, rotation, alpha * (1 - f));
	}

	// Puffs left behind along the plane's path over the last second.
	function drawSmokeTrail(sprites:Sprites, plane:GameObject, tick:Int) {
		final replay = state.replay;
		final images = plane.health < DARK_SMOKE_BELOW_HEALTH ? SMOKE_DARK : SMOKE_LIGHT;
		// puffs sit on fixed ticks so they stay put as time moves
		var t = tick - tick % TRAIL_SPACING;
		while (t > tick - TRAIL_TICKS && t >= 0) {
			final then = planeOf(replay.updates[replay.updateAt(t)].objects, plane.owner);
			if (then == null)
				break;
			final age = (tick - t) / TRAIL_TICKS;
			final tile = sprites.tile(images[Std.int(t / TRAIL_SPACING) % images.length]);
			if (tile != null)
				TexturePages.drawImage(this, tile, then.positionX / 2, state.geom.maxY - then.positionY / 2, 0.5 + age * 0.9,
					noise(t, 3) * Math.PI, 0.55 * (1 - age));
			t -= TRAIL_SPACING;
		}
	}

	static function planeOf(objects:Array<GameObject>, owner:Null<Int>):Null<GameObject> {
		if (owner == null)
			return null;
		for (o in objects)
			if (o.type <= ObjectType.MIRANDA && o.owner == owner)
				return o;
		return null;
	}

	// Deterministic pseudo-random number in [0, 1) for a tick and index.
	static function noise(tick:Int, i:Int):Float {
		var h = tick * 374761393 + i * 668265263;
		h = (h ^ (h >>> 13)) * 1274126177;
		return ((h ^ (h >>> 16)) & 0xFFFF) / 0x10000;
	}
}

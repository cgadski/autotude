package autotude.viewer;

import autotude.proto.GameObject;
import autotude.proto.ObjectType;
import h2d.RenderContext;

// A plane's EMP and acid states, as the game draws them: lightning arcs
// crackling around an EMPed plane (EmpDisableEffect, from Miranda's
// renderLightning) and green smoke rising off an acid-covered plane
// (AcidDisableEffect's SimpleSmokeEffect in AcidCloud's enemy colour). The
// smoke puffs are rebuilt from the replay each frame, so scrubbing (even
// backwards) stays right; the lightning is redrawn (deterministically
// jittered) each tick, as the game redraws it each render frame.
class EmpAcidLayer extends h2d.Graphics {
	final state:PlayerState;

	/** Game sprites (plane hitboxes and smoke images). **/
	public var sprites:Null<Sprites>;

	// as EmpDisableEffect
	static final EMP_BOLTS = 2;
	static final EMP_BLUE = 0x4BC1FF; // (0.294, 0.757, 1)
	static final EMP_BOLT_WIDTH = 1.5;
	static final EMP_DISPLACE = 2.0; // displacement starts at radius / 2
	static final EMP_DETAIL = 3.0;

	// as AcidDisableEffect's SimpleSmokeEffect
	static final ACID_LIFETIME = 12; // ticks: Const.sec(0.4) at 30 updates/s
	static final ACID_START_RADIUS = 5.0;
	static final ACID_END_RADIUS = 13.0;
	static final ACID_START_ALPHA = 0.53; // SimpleSmokeEffect's 0.43, plus its 0.1
	static final ACID_DRAG = 0.9;
	static final ACID_RISE = 0.01; // game units per tick, upward
	static final ACID_SPAWN_RISE = 2.0; // game units per tick added to the plane's velocity
	static final ACID_COLOR = 0x00E600; // AcidCloud.ENEMY_CLOUD_COLOR (0, 0.9, 0)

	static final SMOKE_1 = "effects/smoke_white1.png";
	static final SMOKE_2 = "effects/smoke_white2.png";

	// as AcidCloud
	static final ACID_CLOUD_RADIUS = 68.0;
	static final ACID_CLOUD_LIFETIME = 78; // ticks: Const.sec(2.6) at 30 updates/s
	static final ACID_CLOUD_ALPHA = 0.775;
	static final FRIENDLY_CLOUD_COLOR = 0x99FF99; // AcidCloud (0.6, 1, 0.6)
	static final ENEMY_CLOUD_COLOR = 0x00E600; // AcidCloud (0, 0.9, 0)

	public function new(state:PlayerState) {
		super();
		this.state = state;
	}

	// Where a point of an object's hitbox goes on the map (as ObjectLayer's).
	function placeVertex(object:GameObject, px:Float, py:Float) {
		var angle:Float = 0;
		if (object.angle != null)
			angle = -Math.PI * object.angle / 1800;

		final geom = state.geom;
		final pos = new h3d.Vector(object.positionX / 2, geom.maxY - object.positionY / 2);
		final relative = new h3d.Vector(px, -py);
		relative.transform(h3d.Matrix.R(0, 0, angle));

		if (object.flipX)
			relative.x *= -1;
		if (object.flipY)
			relative.y *= -1;

		return pos + relative;
	}

	// A plane's hitbox, as the game's ConcaveBody.getHull: its points' (x, y)
	// pairs in the plane's local frame.
	function planeHull(plane:GameObject):Null<Array<Float>> {
		final sprites = this.sprites;
		if (sprites == null)
			return null;
		final sprite = sprites.forType(plane.type, null, plane.type <= ObjectType.MIRANDA ? plane.spin : null);
		return sprite == null ? null : sprite.frame.hull;
	}

	// The hitbox's bounding circle radius, as getConvexDelegate's
	// getBoundingCircleRadius (the hull is near-centred on the origin).
	static function boundingRadius(hull:Array<Float>):Float {
		var radius = 0.0;
		var i = 0;
		while (i + 1 < hull.length) {
			final d = hull[i] * hull[i] + hull[i + 1] * hull[i + 1];
			if (d > radius)
				radius = d;
			i += 2;
		}
		return Math.sqrt(radius);
	}

	override function draw(ctx:RenderContext) {
		clear();
		final sprites = this.sprites;
		final replay = state.replay;
		final tick = state.frameIdx;
		final update = replay.updates[replay.updateAt(tick)];

		if (sprites != null)
			drawAcidClouds(sprites, update.objects, tick);

		if (sprites != null)
			drawAcidSmoke(sprites, tick);

		for (object in update.objects)
			if (object.type != null && object.type <= ObjectType.MIRANDA && object.hasEmpFor() && object.empFor > 0)
				drawLightning(object, tick);

		super.draw(ctx);
	}

	// Acid clouds, as AcidCloud.render: four slowly turning smoke sprites
	// around the cloud's centre, growing over its lifetime, in the friendly
	// or enemy cloud colour. The recording has neither the cloud's spawn
	// time nor its random per-puff orientations, so its age comes from the
	// first update its uid appears in, and the orientations from noise.
	function drawAcidClouds(sprites:Sprites, objects:Array<GameObject>, tick:Int) {
		final smoke1 = sprites.tile(SMOKE_1);
		final smoke2 = sprites.tile(SMOKE_2);
		if (smoke1 == null || smoke2 == null)
			return;

		// a spectator's view: clouds of the first allowed team are friendly.
		// The teams playing aren't recorded as such; the lowest plane team is
		// the first one.
		var firstTeam = 0x7FFFFFFF;
		for (o in objects)
			if (o.type != null && o.type <= ObjectType.MIRANDA && o.team != null && o.team < firstTeam)
				firstTeam = o.team;

		for (cloud in objects) {
			if (cloud.type != ObjectType.ACID_CLOUD || cloud.uid == null)
				continue;
			final x = cloud.positionX / 2, y = state.geom.maxY - cloud.positionY / 2;
			final age = cloudAge(cloud.uid, tick);
			final fraction = Math.min(1, age / ACID_CLOUD_LIFETIME);
			var alpha = ACID_CLOUD_ALPHA;
			if (fraction > 0.6)
				alpha *= (1 - fraction) / 0.4;
			final color = cloud.team == firstTeam ? FRIENDLY_CLOUD_COLOR : ENEMY_CLOUD_COLOR;
			final scale = 2 * ACID_CLOUD_RADIUS * (0.6 + 0.6 * fraction) / smoke1.width;

			// four puffs at quarter-turn offsets, as at the cloud's spawn
			final noise = EffectLayer.noise;
			for (i in 0...4) {
				final tile = (i & 1) == 0 ? smoke1 : smoke2;
				final angle = i * Math.PI / 2;
				final px = x + ACID_CLOUD_RADIUS / 2 * Math.cos(angle);
				final py = y - ACID_CLOUD_RADIUS / 2 * Math.sin(angle);
				final orientation = noise(cloud.uid, i * 2) * Math.PI * 2;
				final velocity = 0.8 + 0.7 * noise(cloud.uid, i * 2 + 1);
				final rotation = orientation + (noise(cloud.uid, i * 2 + 13) < 0.5 ? -velocity : velocity) * age / 180 * Math.PI;
				TexturePages.drawImage(this, tile, px, py, scale, rotation, alpha, false, 0.5, null, color);
			}
		}
	}

	// How many ticks ago a uid was first recorded, scanning back at most a
	// cloud's lifetime (older than that, it is invisible anyway).
	function cloudAge(uid:Int, tick:Int):Int {
		final replay = state.replay;
		var i = replay.updateAt(tick);
		final minTick = tick - ACID_CLOUD_LIFETIME;
		var first = tick;
		while (i >= 0 && replay.ticks[i] >= minTick) {
			var seen = false;
			for (o in replay.updates[i].objects) {
				if (o.uid == uid) {
					seen = true;
					break;
				}
			}
			if (!seen)
				break;
			first = replay.ticks[i];
			i--;
		}
		return tick - first;
	}

	// Lightning around an EMPed plane, as EmpDisableEffect.render: two bolts
	// between opposite points of its hull, each a midpoint-displaced line
	// from EMP blue to white.
	function drawLightning(plane:GameObject, tick:Int) {
		final hull = planeHull(plane);
		if (hull == null)
			return;

		final points = Std.int(hull.length / 2);
		if (points < 2)
			return;
		final radius = boundingRadius(hull);
		final noise = EffectLayer.noise;

		for (bolt in 0...EMP_BOLTS) {
			final a = Std.int(noise(tick, (plane.uid ?? 0) * 4 + bolt) * points);
			final b = (a + Std.int(points / 2)) % points;
			final from = placeVertex(plane, hull[a * 2], hull[a * 2 + 1]);
			final to = placeVertex(plane, hull[b * 2], hull[b * 2 + 1]);

			// midpoint displacement, as Miranda.renderLightning: the bolt's
			// chain of points, each level's midpoint jittered uniformly
			final seed = (plane.uid ?? 0) * 97 + bolt * 31;
			final chain = lightningChain(from.x, from.y, to.x, to.y, radius / EMP_DISPLACE, tick, seed);

			// each segment gradients from EMP blue at its start vertex to
			// white at its end, as the game colours each GL_LINES segment:
			// drawn as a thin quad with per-vertex colours
			final br = ((EMP_BLUE >> 16) & 0xFF) / 255, bg = ((EMP_BLUE >> 8) & 0xFF) / 255, bb = (EMP_BLUE & 0xFF) / 255;
			var i = 0;
			while (i + 3 < chain.length) {
				final x1 = chain[i], y1 = chain[i + 1];
				final x2 = chain[i + 2], y2 = chain[i + 3];
				i += 2;
				var dx = x2 - x1, dy = y2 - y1;
				final len = Math.sqrt(dx * dx + dy * dy);
				if (len <= 0)
					continue;
				final nx = -dy / len * EMP_BOLT_WIDTH / 2, ny = dx / len * EMP_BOLT_WIDTH / 2;
				beginFill(0xFFFFFF);
				addVertex(x1 + nx, y1 + ny, br, bg, bb, 1);
				addVertex(x2 + nx, y2 + ny, 1, 1, 1, 1);
				addVertex(x2 - nx, y2 - ny, 1, 1, 1, 1);
				addVertex(x1 - nx, y1 - ny, br, bg, bb, 1);
				endFill();
				i += 2;
			}
		}
	}

	// The chain of points along a bolt (x, y pairs), from (x1, y1) to
	// (x2, y2), its midpoints displaced by up to `displace` until the
	// displacement falls under the detail level. Each endpoint appears
	// exactly once.
	function lightningChain(x1:Float, y1:Float, x2:Float, y2:Float, displace:Float, tick:Int, seed:Int):Array<Float> {
		if (displace < EMP_DETAIL)
			return [x1, y1, x2, y2];

		final noise = EffectLayer.noise;
		final midX = (x1 + x2) / 2 + (noise(tick, seed) * 2 - 1) * displace;
		final midY = (y1 + y2) / 2 + (noise(tick, seed + 1) * 2 - 1) * displace;
		// first runs (x1, y1) -> mid, second runs (x2, y2) -> mid, both
		// including their endpoints: keep first, then second's pairs
		// reversed without its last (the midpoint, already in first), for
		// the chain through the midpoint
		final first = lightningChain(x1, y1, midX, midY, displace / 2, tick, seed + 2);
		final second = lightningChain(x2, y2, midX, midY, displace / 2, tick, seed + 6);
		final reversed = [];
		var k = second.length - 4;
		while (k >= 0) {
			reversed.push(second[k]);
			reversed.push(second[k + 1]);
			k -= 2;
		}
		return first.concat(reversed);
	}

	// Green smoke rising off acid-covered planes, as AcidDisableEffect: every
	// update a puff from a random point of the plane's hull, inheriting its
	// velocity plus an upward drift, decaying, rising, growing and fading (as
	// SimpleSmokeEffect).
	function drawAcidSmoke(sprites:Sprites, tick:Int) {
		final replay = state.replay;
		final maxY = state.geom.maxY;
		final smoke1 = sprites.tile(SMOKE_1);
		final smoke2 = sprites.tile(SMOKE_2);
		if (smoke1 == null || smoke2 == null)
			return;

		// plane states over the emission window, newest first: uid -> ticks
		final states:Map<Int, Array<PlaneState>> = [];
		var i = replay.updateAt(tick);
		final minTick = tick - ACID_LIFETIME;
		while (i >= 0 && replay.ticks[i] >= minTick) {
			final t = replay.ticks[i];
			for (o in replay.updates[i].objects) {
				if (o.type == null || o.type > ObjectType.MIRANDA || !o.hasAcidFor() || o.acidFor <= 0)
					continue;
				final ticks = states[o.uid ?? -1] ?? [];
				ticks.push({x: o.positionX, y: o.positionY, angle: o.angle ?? 0, tick: t, type: o.type});
				states[o.uid ?? -1] = ticks;
			}
			i--;
		}

		final noise = EffectLayer.noise;
		for (uid => ticks in states) {
			// each state is a puff emitted that tick; the oldest has no
			// earlier position to give its velocity, so no puff from it
			for (a in 0...ticks.length - 1) {
				final emitted = ticks[a];
				final before = ticks[a + 1];
				final age = tick - emitted.tick;
				if (age >= ACID_LIFETIME)
					continue;

				// the puff's start: a random hull point, rotated with the plane
				final hull = planeHullByType(emitted.type);
				if (hull == null)
					continue;
				final points = Std.int(hull.length / 2);
				if (points < 1)
					continue;
				final p = Std.int(noise(emitted.tick, uid * 7 + 1) * points);
				final angle = emitted.angle * Math.PI / 1800;
				final cos = Math.cos(angle), sin = Math.sin(angle);
				final offX = hull[p * 2], offY = hull[p * 2 + 1];
				// replay positions are half pixels; the plane's velocity per
				// tick plus the game's upward spawn drift
				var x = emitted.x + 2 * (offX * cos - offY * sin);
				var y = emitted.y + 2 * (offX * sin + offY * cos);
				final dt = Math.max(1, emitted.tick - before.tick);
				var vx = (emitted.x - before.x) / dt;
				var vy = (emitted.y - before.y) / dt + 2 * ACID_SPAWN_RISE;

				// drift for the puff's age: decay, rise
				for (_ in 0...age) {
					x += vx;
					y += vy;
					vx *= ACID_DRAG;
					vy = vy * ACID_DRAG + 2 * ACID_RISE;
				}

				final fraction = age / ACID_LIFETIME;
				final alpha = ACID_START_ALPHA * (1 - fraction);
				final radius = ACID_START_RADIUS + (ACID_END_RADIUS - ACID_START_RADIUS) * fraction;
				final image = (emitted.tick & 1) == 0 ? smoke1 : smoke2;
				TexturePages.drawImage(this, image, x / 2, maxY - y / 2, radius / 10, 0, alpha, false, 0.5, null, ACID_COLOR);
			}
		}
	}

	// A plane type's hitbox (acid puffs are drawn at an old position of the
	// plane, which is no longer at hand, so its type's hull is used).
	function planeHullByType(type:Int):Null<Array<Float>> {
		final sprites = this.sprites;
		if (sprites == null)
			return null;
		final sprite = sprites.forType(type, null, null);
		return sprite == null ? null : sprite.frame.hull;
	}
}

// A plane's recorded state at one tick, in the replay's half pixels.
private typedef PlaneState = {
	x:Float,
	y:Float,
	angle:Float, // tenths of a degree
	tick:Int,
	type:Int,
};

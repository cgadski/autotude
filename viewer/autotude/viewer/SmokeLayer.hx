package autotude.viewer;

import autotude.proto.GameObject;
import autotude.proto.ObjectType;
import h2d.RenderContext;
import h2d.Tile;

// A plane's recorded state at one tick, in the replay's half pixels.
// Plane damage smoke, as the game's TrailingSmokeEffect: a plane below 55%
// health emits a puff every tick, from its smoke offset (rotated with it,
// flattened by its bank), which drifts along the plane's velocity as it
// decays, rises, grows and fades. The puffs are rebuilt from the replay each
// frame, so scrubbing (even backwards) stays right.
typedef PlaneTick = {
	x:Float,
	y:Float,
	health:Float,
	angle:Float, // tenths of a degree
	spin:Float, // degrees
	tick:Int,
	type:Int,
};

// Plane damage smoke, as the game's TrailingSmokeEffect: a plane below 55%
// health emits a puff every tick, from its smoke offset (rotated with it,
// flattened by its bank), which drifts along the plane's velocity as it
// decays, rises, grows and fades. The puffs are rebuilt from the replay each
// frame, so scrubbing (even backwards) stays right.
class SmokeLayer extends h2d.Graphics {
	final state:PlayerState;

	/** Game sprites. **/
	public var sprites:Null<Sprites>;

	/** The level's useBlackSmokeForPlaneDamage: white smoke when false. **/
	public var blackSmoke = true;

	// as TrailingSmokeEffect
	static final DAMAGE_FRACTION_MIN = 0.45;
	static final DAMAGE_FRACTION_MAX = 0.95;
	static final SMOKE_ALPHA_MIN = 0.85;
	static final SMOKE_ALPHA_MAX = 1.0;
	static final FADE_MIN = 0.028; // the default, for a dead or healed plane
	static final FADE_RANGE = 0.032; // added in full by the least damaged plane
	static final START_SIZE = 4.0;
	static final GROWTH_PER_TICK = 0.45;
	static final DRAG_PER_TICK = 0.8;
	static final RISE_PER_TICK = 0.01;
	// the longest a puff lives: its strongest alpha over the slowest fade
	static final MAX_AGE = Math.ceil(SMOKE_ALPHA_MAX / FADE_MIN);

	// each plane type's smoke offset (x, y), as its SMOKE_OFFSET
	static final SMOKE_OFFSETS = [
		[2.0, 5.0], // loopy
		[-1.0, 1.0], // bomber
		[-1.0, 11.0], // explodet
		[-10.0, -4.0], // biplane
		[-15.0, 1.0], // miranda
	];

	public function new(state:PlayerState) {
		super();
		this.state = state;
	}

	// how far into smoking the plane is, from its health (0 to 1)
	static function smokeFraction(health:Float):Float {
		final damageFraction = Math.min(DAMAGE_FRACTION_MAX, 1 - health / 1000);
		return (damageFraction - DAMAGE_FRACTION_MIN) / (DAMAGE_FRACTION_MAX - DAMAGE_FRACTION_MIN);
	}

	override function draw(ctx:RenderContext) {
		clear();
		final sprites = this.sprites;
		if (sprites == null || !state.showMapArt) {
			super.draw(ctx);
			return;
		}
		final replay = state.replay;
		final tick = state.frameIdx;
		final maxY = state.geom.maxY;
		final smoke1 = sprites.tile(blackSmoke ? "effects/smoke1.png" : "effects/smoke_white1.png");
		final smoke2 = sprites.tile(blackSmoke ? "effects/smoke2.png" : "effects/smoke_white2.png");
		if (smoke1 == null || smoke2 == null) {
			super.draw(ctx);
			return;
		}

		// plane states over the emission window, newest first: owner -> ticks
		final states:Map<Int, Array<PlaneTick>> = [];
		var i = replay.updateAt(tick);
		final minTick = tick - MAX_AGE;
		while (i >= 0 && replay.ticks[i] >= minTick) {
			final t = replay.ticks[i];
			for (o in replay.updates[i].objects) {
				if (o.type == null || o.type > ObjectType.MIRANDA)
					continue;
				final ticks = states[o.owner ?? -1] ?? [];
				ticks.push({x: o.positionX, y: o.positionY, health: o.health ?? 1000, angle: o.angle ?? 0, spin: o.spin ?? 0,
					tick: t, type: o.type});
				states[o.owner ?? -1] = ticks;
			}
			i--;
		}

		final tint = blackSmoke ? -1 : 0x8C8C8C; // white smoke is drawn gray, as in game
		final noise = EffectLayer.noise;
		for (owner => ticks in states) {
			// a puff fades with the plane's state every tick: from its damage
			// while it stays damaged, the default slow rate once it dies or
			// heals, so a dying plane's smoke lingers as in game. fades[a] is
			// the fade accumulated by a puff of age a.
			final fadeRates = [for (_ in 0...MAX_AGE + 1) FADE_MIN];
			for (s in ticks) {
				final age = tick - s.tick;
				if (age >= 0 && age <= MAX_AGE && s.health < 550)
					fadeRates[age] = FADE_MIN + (1 - smokeFraction(s.health)) * FADE_RANGE;
			}
			final fades = [for (_ in 0...MAX_AGE + 1) 0.0];
			var acc = 0.0;
			for (a in 1...MAX_AGE + 1)
				fades[a] = acc += fadeRates[a];

			// each state is a puff emitted that tick; the oldest has no
			// earlier position to give its velocity, so no puff from it
			for (a in 0...ticks.length - 1) {
				final emitted = ticks[a];
				final before = ticks[a + 1];
				if (emitted.health >= 550) // damage fraction below 0.45: no smoke
					continue;
				final age = tick - emitted.tick;
				final alpha = SMOKE_ALPHA_MIN + smokeFraction(emitted.health) * (SMOKE_ALPHA_MAX - SMOKE_ALPHA_MIN)
					- fades[age];
				if (alpha <= 0)
					continue;

				// the puff's start: the plane's smoke offset, rotated with it and
				// flattened by its bank, and a velocity inherited from the plane
				// (deterministically jittered, as in game)
				final offset = SMOKE_OFFSETS[emitted.type];
				final angle = emitted.angle * Math.PI / 1800;
				final cos = Math.cos(angle), sin = Math.sin(angle);
				final flatten = Math.cos(emitted.spin * Math.PI / 180);
				final offX = offset[0], offY = offset[1] * flatten;
				var x = emitted.x + 2 * (offX * cos - offY * sin);
				var y = emitted.y + 2 * (offX * sin + offY * cos);
				final eTick = emitted.tick;
				final dt = Math.max(1, eTick - before.tick);
				final velX = (emitted.x - before.x) / dt, velY = (emitted.y - before.y) / dt;
				final speed = Math.sqrt(velX * velX + velY * velY);
				var vx = velX + (noise(eTick, owner) * 2 - 1) * 0.1 * speed;
				var vy = velY + (noise(eTick, owner + 1) * 2 - 1) * 0.1 * speed;

				// drift for the puff's age: decay, rise; then draw it grown and faded
				for (_ in 0...age) {
					x += vx;
					y += vy;
					vx *= DRAG_PER_TICK;
					vy = vy * DRAG_PER_TICK + 2 * RISE_PER_TICK; // half pixels
				}
				final size = START_SIZE + GROWTH_PER_TICK * age;
				final image = (emitted.tick & 1) == 0 ? smoke1 : smoke2;
				TexturePages.drawImage(this, image, x / 2, maxY - y / 2, size / 10, 0, alpha, false, 0.5, null, tint);
			}
		}
		super.draw(ctx);
	}
}

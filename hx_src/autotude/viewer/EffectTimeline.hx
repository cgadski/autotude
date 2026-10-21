package autotude.viewer;

import autotude.proto.GameObject;
import autotude.proto.ObjectType;

enum EffectKind {
	/** A plane appeared (spawned). **/
	Spawn;

	/** A plane disappeared: it died. **/
	PlaneExplosion;

	/** An explosive projectile or powerup ended. `size` scales the blast. **/
	Explosion(size:Float);

	/** A projectile was fired. **/
	Fire;

	/** A plane took damage. **/
	Hit;

	/** A plane picked up a powerup or the ball. **/
	Pickup(powerup:Int);

	/** A plane fired the ball (lost it without scoring). **/
	BallFire;

	Goal;
	BaseDestroyed;
}

typedef TimedEffect = {
	tick:Int,
	kind:EffectKind,

	/** The object involved (projectile, plane, ...). **/
	type:Int,

	team:Null<Int>,

	/** The player whose object it is. **/
	owner:Null<Int>,

	/** Map position in pixels, y down. **/
	x:Float,

	y:Float
};

// Energy drain per tick that means a plane is afterburning (see afterburning).
final AFTERBURNER_DRAIN_MIN = 30;
final AFTERBURNER_DRAIN_MAX = 100;

// Ticks between a kill event and its plane disappearing.
final KILL_WINDOW = 15;

// How big an explosion each explosive object makes (1 = a plane's).
final EXPLOSIVES:Map<Int, Float> = [
	ObjectType.DOMB => 0.6,
	ObjectType.NADE => 0.35,
	ObjectType.FLAK => 0.3,
	ObjectType.DIRECTOR_ROCKET => 0.4,
	ObjectType.THERMOBARIC_ROCKET => 0.5,
	ObjectType.REMOTE_MINE => 0.5,
	ObjectType.DIRECTOR_MINE => 0.5,
	ObjectType.HOMING_MISSLE => 0.5,
	ObjectType.BIG_BOMB => 1.2,
	ObjectType.EMP_CAPSULE => 0.3,
	ObjectType.ACID_BOMB => 0.3,
];

/**
	Effects (and sounds) a replay implies but doesn't record directly,
	worked out once from how objects appear, change and disappear. Effects
	are keyed by tick, so they stay right when scrubbing.
**/
class EffectTimeline {
	public final effects:Array<TimedEffect> = [];

	final replay:Replay;
	final maxY:Float;

	public function new(replay:Replay) {
		this.replay = replay;
		this.maxY = replay.mapGeometry.maxY;

		// planes also disappear on goal resets and when players leave; only
		// those with a kill event explode
		final deaths:Map<Int, Array<Int>> = [];
		for (i in 0...replay.updates.length)
			for (event in replay.updates[i].events)
				if (event.hasKill()) {
					final died = event.kill.whoDied;
					final ticks = deaths.get(died) ?? [];
					ticks.push(replay.ticks[i]);
					deaths.set(died, ticks);
				}
		function killed(player:Int, tick:Int):Bool {
			for (t in deaths.get(player) ?? [])
				if (t >= tick - KILL_WINDOW && t <= tick + KILL_WINDOW)
					return true;
			return false;
		}

		var previous:Map<Int, GameObject> = [];
		for (i in 0...replay.updates.length) {
			final update = replay.updates[i];
			final tick = replay.ticks[i];
			final current:Map<Int, GameObject> = [];
			for (o in update.objects)
				current.set(o.uid, o);

			// the first update holds everything already in the game
			if (i > 0) {
				for (uid => o in current) {
					final before = previous.get(uid);
					if (before == null) {
						if (o.type <= ObjectType.MIRANDA)
							add(tick, Spawn, o);
						else if (o.type >= ObjectType.DOUBLE_FIRE_MISSLE && o.type != ObjectType.GOAL && o.type != ObjectType.BASE)
							add(tick, Fire, o);
					} else if (o.type <= ObjectType.MIRANDA && o.powerup != before.powerup) {
						if (o.powerup != null)
							add(tick, Pickup(o.powerup), o);
						else if (before.powerup == ObjectType.BALL && !scored(update))
							add(tick, BallFire, o);
					}
				}
				for (uid => o in previous) {
					if (current.exists(uid))
						continue;
					if (o.type <= ObjectType.MIRANDA) {
						if (killed(o.owner, tick))
							add(tick, PlaneExplosion, o);
					}
					else if (o.type == ObjectType.BASE)
						add(tick, BaseDestroyed, o);
					else {
						final size = EXPLOSIVES.get(o.type);
						if (size != null)
							add(tick, Explosion(size), o);
					}
				}
			}

			for (event in update.events) {
				if (event.hasGoal())
					effects.push({tick: tick, kind: Goal, type: -1, team: null, owner: null, x: 0, y: 0});
				if (event.hasDamage()) {
					final target = planeOf(current, event.damage.target);
					if (target != null)
						add(tick, Hit, target);
				}
			}

			previous = current;
		}
	}

	function add(tick:Int, kind:EffectKind, o:GameObject) {
		effects.push({
			tick: tick,
			kind: kind,
			type: o.type,
			team: o.hasTeam() ? o.team : null,
			owner: o.hasOwner() ? o.owner : null,
			x: o.positionX / 2,
			y: maxY - o.positionY / 2
		});
	}

	static function scored(update:autotude.proto.Update):Bool {
		for (e in update.events)
			if (e.hasGoal())
				return true;
		return false;
	}

	static function planeOf(objects:Map<Int, GameObject>, player:Int):Null<GameObject> {
		for (o in objects)
			if (o.type <= ObjectType.MIRANDA && o.owner == player)
				return o;
		return null;
	}

	/**
		Whether a plane is afterburning at `tick`. Replays don't record the
		afterburner key, but it drains a steady 60-ish energy (of 1000) per
		tick, net of recharge, where weapons take hundreds at once. Looks at
		the last two updates, so firing a weapon meanwhile doesn't hide it.
	**/
	public static function afterburning(replay:Replay, tick:Int, plane:GameObject):Bool {
		final i = replay.updateAt(tick);
		var after = plane;
		for (back in 1...3) {
			if (i - back < 0)
				break;
			final update = replay.updates[i - back];
			var before:Null<GameObject> = null;
			for (o in update.objects)
				if (o.uid == plane.uid)
					before = o;
			if (before == null)
				break;
			final drain = (before.ammo - after.ammo) / Math.max(1, haxe.Int64.toInt(update.duration));
			if (drain >= AFTERBURNER_DRAIN_MIN && drain <= AFTERBURNER_DRAIN_MAX)
				return true;
			after = before;
		}
		return false;
	}

	/** Index of the first effect at or after `tick`. **/
	public function indexAt(tick:Int):Int {
		var lo = 0, hi = effects.length;
		while (lo < hi) {
			final mid = (lo + hi) >> 1;
			if (effects[mid].tick < tick)
				lo = mid + 1;
			else
				hi = mid;
		}
		return lo;
	}

	/** Effects that started in (from, to]. **/
	public function between(from:Int, to:Int):Array<TimedEffect> {
		return [for (i in indexAt(from + 1)...indexAt(to + 1)) effects[i]];
	}
}

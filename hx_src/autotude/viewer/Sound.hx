package autotude.viewer;

import autotude.proto.GameObject;
import autotude.proto.ObjectType;
import autotude.viewer.EffectTimeline.TimedEffect;
import js.Browser;
import js.html.audio.AudioBuffer;
import js.html.audio.AudioBufferSourceNode;
import js.html.audio.AudioContext;
import js.html.audio.GainNode;
import js.html.audio.StereoPannerNode;
import js.lib.Promise;

final SOUND_ROOT = "viewer_assets/sounds/";

// Sound for a projectile or other object appearing.
final FIRE_SOUNDS:Map<Int, String> = [
	ObjectType.DOUBLE_FIRE_MISSLE => "planes/loopy/tracking_fire",
	ObjectType.TRACKER_MISSLE => "planes/loopy/tracking_fire",
	ObjectType.EMP_CAPSULE => "planes/loopy/emp_fire",
	ObjectType.EMP_EXPLOSION => "planes/loopy/emp_burst",
	ObjectType.ACID_BOMB => "planes/loopy/emp_fire",
	ObjectType.ACID_CLOUD => "planes/loopy/acid",
	ObjectType.NADE => "planes/bomber/grenade_fire",
	ObjectType.FLAK => "planes/bomber/flak_tailgun_fire",
	ObjectType.SUPPRESSOR => "planes/bomber/tailgun_fire",
	ObjectType.DOMB => "planes/bomber/bomb_fire",
	ObjectType.BIPLANE_PRIMARY => "planes/biplane/machine_gun_fire",
	ObjectType.BIPLANE_SECONDARY => "planes/biplane/basic_gun_fire",
	ObjectType.HEAVY_CANNON => "planes/biplane/heavy_cannon_fire",
	ObjectType.DIRECTOR_ROCKET => "planes/explodet/rocket_fire",
	ObjectType.THERMOBARIC_ROCKET => "planes/explodet/rocket_fire",
	ObjectType.REMOTE_MINE => "planes/explodet/mine_fire",
	ObjectType.DIRECTOR_MINE => "planes/explodet/mine_fire",
	ObjectType.LASER => "planes/miranda/laser_fire",
	ObjectType.TRICKSTER_SHOT => "planes/miranda/laser_fire",
	ObjectType.LASER_SHOT => "planes/miranda/laser_fire",
	ObjectType.HOMING_MISSLE => "powerup/homing_missile_fire",
	ObjectType.WALL => "powerup/wall_fire",
	ObjectType.SHIELD => "powerup/shield_fire",
	ObjectType.BIG_BOMB => "powerup/big_bomb_falling",
];

// Sound for an explosive ending.
final EXPLODE_SOUNDS:Map<Int, String> = [
	ObjectType.NADE => "planes/bomber/bomb_explode",
	ObjectType.FLAK => "planes/bomber/bomb_explode",
	ObjectType.DOMB => "planes/bomber/bomb_explode",
	ObjectType.DIRECTOR_ROCKET => "planes/explodet/rocket_explode",
	ObjectType.THERMOBARIC_ROCKET => "planes/explodet/rocket_explode",
	ObjectType.REMOTE_MINE => "planes/explodet/mine_explode",
	ObjectType.DIRECTOR_MINE => "planes/explodet/mine_explode",
	ObjectType.HOMING_MISSLE => "powerup/homing_missile_explosion",
	ObjectType.BIG_BOMB => "powerup/big_bomb_explode",
];

final ENGINE_SOUNDS:Map<Int, String> = [
	ObjectType.LOOPY => "planes/loopy/engine_loop",
	ObjectType.BOMBER => "planes/bomber/engine_loop",
	ObjectType.EXPLODET => "planes/explodet/engine_loop",
	ObjectType.BIPLANE => "planes/biplane/engine_loop",
	ObjectType.MIRANDA => "planes/miranda/engine_loop",
];
final AFTERBURNER_SOUND = "planes/afterburner";

// Volumes (0-1) by kind of sound.
final ENGINE_VOLUME = 0.12;
final AFTERBURNER_VOLUME = 0.35;
final EFFECT_VOLUME = 0.6;
final MASTER_VOLUME = 0.8;

// The same sound isn't restarted more often than this (seconds), so rapid
// fire doesn't pile up.
final MIN_REPEAT = 0.05;

// Jumps bigger than this (ticks), like scrubbing, don't play what was skipped.
final MAX_CATCH_UP = 15;

typedef Loop = {
	source:AudioBufferSourceNode,
	gain:GainNode,
	pan:StereoPannerNode,
	used:Bool
};

/**
	The game's sounds for a replay, played as it plays. Sounds are placed
	relative to the camera: quieter further from the centre of the view and
	when zoomed out, and panned left or right.
**/
class Sound {
	public var enabled = true;

	var ctx:Null<AudioContext>;
	var master:Null<GainNode>;
	final buffers:Map<String, AudioBuffer> = [];
	final loading:Map<String, Bool> = [];
	final lastPlayed:Map<String, Float> = [];
	final loops:Map<String, Loop> = [];
	var lastTick = -1;

	public function new() {
		// browsers only allow audio after the user interacts with the page
		final start = () -> resume();
		Browser.window.addEventListener("pointerdown", start);
		Browser.window.addEventListener("keydown", start);
	}

	function resume() {
		if (ctx == null) {
			final ctx = new AudioContext();
			final master = ctx.createGain();
			master.connect(ctx.destination);
			this.ctx = ctx;
			this.master = master;
			for (name in FIRE_SOUNDS)
				load(name);
			for (name in EXPLODE_SOUNDS)
				load(name);
			for (name in ENGINE_SOUNDS)
				load(name);
			for (name in [
				AFTERBURNER_SOUND, "planes/plane_explode", "planes/respawn_forcefield", "planes/bullet_hit_plane", "powerup/pickup",
				"powerup/ball_pickup", "powerup/ball_fire", "map/mode/goal_scored", "map/base/base_explode"
			])
				load(name);
		}
		final ctx = this.ctx;
		if (ctx != null && ctx.state == SUSPENDED)
			ctx.resume();
	}

	function load(name:String) {
		final ctx = this.ctx;
		if (ctx == null || loading.exists(name))
			return;
		loading.set(name, true);
		Browser.window.fetch(SOUND_ROOT + name + ".ogg")
			.then(res -> res.ok ? res.arrayBuffer() : Promise.reject('missing sound $name'))
			.then(data -> ctx.decodeAudioData(data))
			.then(buffer -> buffers.set(name, buffer), _ -> null);
	}

	/** Play what happened since the last call, and keep loops in step. Call every frame. **/
	public function update(state:PlayerState, timeline:EffectTimeline) {
		final ctx = this.ctx, master = this.master;
		final tick = state.frameIdx;
		final jumped = tick < lastTick || tick - lastTick > MAX_CATCH_UP;
		final from = lastTick;
		lastTick = tick;
		if (ctx == null || master == null)
			return;
		master.gain.value = enabled ? MASTER_VOLUME : 0;
		if (!state.playing || !enabled) {
			stopLoops();
			return;
		}

		final listener = new Listener(state);
		if (!jumped)
			for (e in timeline.between(from, tick))
				playEffect(e, listener);

		final update = state.replay.updates[state.replay.updateAt(tick)];
		for (loop in loops)
			loop.used = false;
		for (o in update.objects) {
			if (o.type > ObjectType.MIRANDA)
				continue;
			final engine = ENGINE_SOUNDS.get(o.type);
			final x = o.positionX / 2, y = state.geom.maxY - o.positionY / 2;
			if (engine != null)
				setLoop('engine ${o.uid}', engine, listener, x, y, ENGINE_VOLUME * (0.4 + 0.6 * o.throttle / 1000));
			if (EffectTimeline.afterburning(state.replay, tick, o))
				setLoop('afterburner ${o.uid}', AFTERBURNER_SOUND, listener, x, y, AFTERBURNER_VOLUME);
		}
		for (key => loop in loops)
			if (!loop.used) {
				loop.source.stop();
				loops.remove(key);
			}
	}

	function playEffect(e:TimedEffect, listener:Listener) {
		final name = switch e.kind {
			case Fire: FIRE_SOUNDS.get(e.type);
			case Explosion(_): EXPLODE_SOUNDS.get(e.type);
			case PlaneExplosion: "planes/plane_explode";
			case Spawn: "planes/respawn_forcefield";
			case Hit: "planes/bullet_hit_plane";
			case Pickup(powerup): powerup == ObjectType.BALL ? "powerup/ball_pickup" : "powerup/pickup";
			case BallFire: "powerup/ball_fire";
			case BaseDestroyed: "map/base/base_explode";
			case Goal: null;
		}
		if (e.kind == Goal)
			play("map/mode/goal_scored", 1, 0); // heard everywhere
		else if (name != null)
			play(name, EFFECT_VOLUME * listener.gain(e.x, e.y), listener.pan(e.x));
	}

	function play(name:String, volume:Float, pan:Float) {
		final ctx = this.ctx, master = this.master, buffer = buffers.get(name);
		if (ctx == null || master == null || buffer == null || volume < 0.01)
			return;
		final last = lastPlayed.get(name);
		if (last != null && ctx.currentTime - last < MIN_REPEAT)
			return;
		lastPlayed.set(name, ctx.currentTime);

		final source = ctx.createBufferSource();
		source.buffer = buffer;
		final gain = ctx.createGain();
		gain.gain.value = volume;
		final panner = ctx.createStereoPanner();
		panner.pan.value = pan;
		source.connect(gain);
		gain.connect(panner);
		panner.connect(master);
		source.start();
	}

	function setLoop(key:String, name:String, listener:Listener, x:Float, y:Float, volume:Float) {
		final ctx = this.ctx, master = this.master, buffer = buffers.get(name);
		if (ctx == null || master == null || buffer == null)
			return;
		var loop = loops.get(key);
		if (loop == null) {
			final source = ctx.createBufferSource();
			source.buffer = buffer;
			source.loop = true;
			final gain = ctx.createGain();
			final pan = ctx.createStereoPanner();
			source.connect(gain);
			gain.connect(pan);
			pan.connect(master);
			// start at a random point so engines don't play in unison
			source.start(0, Math.random() * buffer.duration);
			loop = {source: source, gain: gain, pan: pan, used: true};
			loops.set(key, loop);
		}
		loop.used = true;
		loop.gain.gain.value = volume * listener.gain(x, y);
		loop.pan.pan.value = listener.pan(x);
	}

	function stopLoops() {
		for (loop in loops)
			loop.source.stop();
		loops.clear();
	}
}

/** Where the "ears" are: the centre of the view, scaled by zoom. **/
private class Listener {
	final x:Float;
	final y:Float;
	final halfWidth:Float;
	final zoomGain:Float;

	public function new(state:PlayerState) {
		x = state.pos.x;
		y = state.pos.y;
		halfWidth = Viewer.WIDTH / state.scale / 2;
		// scale 1 is the game's own view; zoomed out, everything is further away
		zoomGain = Math.min(1, Math.max(0.3, Math.sqrt(state.scale)));
	}

	/** 1 near the centre of the view, fading out beyond its edges. **/
	public function gain(sx:Float, sy:Float):Float {
		final d = Math.sqrt((sx - x) * (sx - x) + (sy - y) * (sy - y)) / halfWidth;
		final falloff = d < 0.6 ? 1 : 1 / (1 + 3 * (d - 0.6) * (d - 0.6));
		return zoomGain * falloff;
	}

	/** -1 (left) to 1 (right), gentler than hard panning. **/
	public function pan(sx:Float):Float {
		return Math.max(-0.7, Math.min(0.7, (sx - x) / halfWidth * 0.7));
	}
}

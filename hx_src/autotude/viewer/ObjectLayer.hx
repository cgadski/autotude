package autotude.viewer;

import js.html.TextTrackCue;
import autotude.proto.ObjectType;
import h2d.Text;
import autotude.proto.Poly;
import h3d.Matrix;
import h3d.Vector;
import haxe.Resource;
import haxe.io.BytesInput;
import autotude.proto.GameObject;
import h2d.RenderContext;
import autotude.proto.ConcaveObstacle;
import h2d.Graphics;
import h2d.Object;
import autotude.proto.MapGeometry;
import autotude.viewer.Sprites.Sprite;

final CONTAINER_OVER = "planes/powerup/container_over.png";
final BALL_IMAGE = "render/planes/explodet/mine/0_128_5_0000.png";

// A powerup's icon, as each Powerup class in the game draws it: inside the
// powerup's container on the map, and in the badge over a plane holding it.
// The ball's icon is the ball itself (see ballSprite).
final POWERUP_ICONS:Map<Int, String> = [
	ObjectType.MISSLE_POWERUP => "render/powerups/missile/0_128_5.animatedpoly",
	ObjectType.SHIELD_POWERUP => "planes/powerup/shield/shield.poly",
	ObjectType.WALL_POWERUP => "planes/powerup/wall.poly",
	ObjectType.BIG_BOMB_POWERUP => "render/powerups/big_bomb/0_128_5.animatedpoly",
	ObjectType.HEALTH_POWERUP => "planes/powerup/health/healthpack.animatedpoly",
];

// Explodet rockets, as the game's Rocket class draws them: in the shooter's
// colour, unfolding their fins over the first 180ms, then from 450ms
// spinning through frames 100ms apart, with a flame behind.
final ROCKET_OPEN = "render/planes/explodet/rocket_open/0_128_5.animatedpoly";
final ROCKET_SPIN = "render/planes/explodet/rocket_spin/0_128_5.animatedpoly";
final ROCKET_OPEN_MS = 180;
final ROCKET_SPIN_START_MS = 450;
final ROCKET_SPIN_CYCLE_MS = 900;
final ROCKET_FLAMES:Map<Int, String> = [
	ObjectType.DIRECTOR_ROCKET => "effects/afterburner/afterburner_blue.png",
	ObjectType.THERMOBARIC_ROCKET => "effects/afterburner/afterburner1.png",
];
final ROCKET_FLAME_SCALE = 0.5;

// Sprites that differ from the hitbox poly for a type.
final SPRITE_OVERRIDES:Map<Int, String> = [
	ObjectType.HEALTH_POWERUP => "planes/powerup/container_health.poly",
];

// Pixel sizes of icons inside a container on the map.
final CONTAINER_ICON_SIZE = 26;

// The badge beside a plane holding a powerup, and its icon. It sits right of
// the plane's bars, which PlaneGraphics draws from 40px left to 40px right
// of the plane, 32-56px above it.
final BADGE_IMAGE = "hud/over_plane/powerup_container.png";
final BADGE_SIZE = 30;
final BADGE_ICON_SIZE = 21;
final BADGE_X = 58;
final BADGE_Y = 44;

// The ball at its hitbox poly's size looks too big next to the game's.
final BALL_SCALE = 0.8;

final AFTERBURNER_IMAGE = "effects/afterburner/afterburner1.png";

// Explodet mines are a spiky mine carried by a drone: directly for remote
// mines, on a chain for the regular (director) ones. Replays only record
// the mine, so it hangs straight down. Distances in pixels, measured from
// the game.
final MINE_IMAGE = "render/planes/explodet/mine/0_128_5_0000.png";
final MINE_DRONE = "render/planes/explodet/drone/0_128_5.animatedpoly";
final MINE_LINK = "planes/explodet/link.png";
final REMOTE_MINE_DRONE_HEIGHT = 17;
final DIRECTOR_MINE_DRONE_HEIGHT = 33;

class ObjectLayer extends Graphics {
	final replay:Replay;
	final geom:MapGeometry;
	final state:PlayerState;
	final polyManager:PolyManager;

	final planeGraphics:Map<Int, PlaneGraphics> = new Map();

	/** Game sprites, drawn instead of hitboxes once loaded. **/
	public var sprites:Null<Sprites>;

	/** For how long objects have existed (rockets animate by it). **/
	public var timeline:Null<EffectTimeline>;

	public function new(state:PlayerState) {
		this.replay = state.replay;
		this.geom = state.geom;
		this.state = state;
		this.polyManager = new PolyManager(new BytesInput(Resource.getBytes("polys")));
		super();
	}

	// Where a point of an object's poly goes on the map.
	function placeVertex(object:GameObject, px:Float, py:Float, extraScale:Float = 1):Vector {
		var angle:Float = 0;
		if (object.angle != null) {
			angle = -Math.PI * object.angle / 1800;
		}

		final pos = new Vector(object.positionX / 2, geom.maxY - object.positionY / 2);
		var relative = new Vector(px * extraScale, -py * extraScale);
		relative.transform(Matrix.R(0, 0, angle));

		if (object.flipX) {
			relative.x *= -1;
		}
		if (object.flipY) {
			relative.y *= -1;
		}
		if (object.scale != null) {
			relative.x *= object.scale / 1000;
			relative.y *= object.scale / 1000;
		}

		return pos + relative;
	}

	function drawSprite(sprite:Null<Sprite>, object:GameObject, extraScale:Float = 1) {
		if (sprite == null)
			return;
		polysDrawn += 1;
		beginTileFill(0, 0, 1, 1, sprite.tile);
		final hull = sprite.frame.hull;
		var i = 0;
		while (i + 1 < hull.length) {
			final dest = placeVertex(object, hull[i], hull[i + 1], extraScale);
			TexturePages.addVertex(this, sprite.frame, sprite.tile, hull[i], hull[i + 1], dest.x, dest.y);
			i += 2;
		}
		endFill();
	}

	// Draw an object as the game does. False if there's no sprite for it.
	function drawGameSprite(sprites:Sprites, object:GameObject):Bool {
		if (object.type == ObjectType.REMOTE_MINE || object.type == ObjectType.DIRECTOR_MINE)
			return drawMine(sprites, object);

		// only planes have frames by roll; other animations are by time
		final spin = object.type <= ObjectType.MIRANDA ? object.spin : null;
		final polyOverride = SPRITE_OVERRIDES.get(object.type);
		final rocketFlame = ROCKET_FLAMES.get(object.type);
		final sprite = if (object.type == ObjectType.BALL) ballSprite(sprites, object.team) else if (rocketFlame != null)
			rocketSprite(sprites, object) else if (polyOverride != null) sprites.forPoly(polyOverride, object.team,
				spin) else sprites.forType(object.type, object.team, spin);
		if (sprite == null)
			return false;

		if (object.type == ObjectType.BALL) {
			drawSprite(sprite, object, BALL_SCALE);
			return true;
		}

		if (object.type <= ObjectType.MIRANDA && afterburning(object))
			drawFlame(sprites, sprite, object, AFTERBURNER_IMAGE, 0.9);
		if (rocketFlame != null)
			drawFlame(sprites, sprite, object, rocketFlame, ROCKET_FLAME_SCALE);
		drawSprite(sprite, object);
		// a powerup is its icon in a container (a bubble, or health's frame)
		final icon = POWERUP_ICONS.get(object.type);
		if (icon != null) {
			drawIcon(sprites.forPoly(icon, null), uprightAt(object, 0), CONTAINER_ICON_SIZE);
			if (object.type != ObjectType.HEALTH_POWERUP)
				drawSprite(sprites.withImage(sprite, CONTAINER_OVER), object);
		}
		return true;
	}

	function afterburning(plane:GameObject):Bool
		return EffectTimeline.afterburning(replay, state.frameIdx, plane);

	// The rocket's frame for how long ago it was fired.
	function rocketSprite(sprites:Sprites, rocket:GameObject):Null<Sprite> {
		final timeline = this.timeline;
		final ms = timeline == null ? ROCKET_SPIN_START_MS : timeline.age(rocket.uid, state.frameIdx) * 1000 / 30;
		// frames are keyed by their time in tens of milliseconds
		return if (ms < ROCKET_SPIN_START_MS) sprites.forPoly(ROCKET_OPEN, rocket.team, Std.int(Math.min(ms,
			ROCKET_OPEN_MS) / 10)) else sprites.forPoly(ROCKET_SPIN, rocket.team,
			Std.int((ROCKET_SPIN_START_MS + (ms - ROCKET_SPIN_START_MS) % ROCKET_SPIN_CYCLE_MS) / 10));
	}

	// A flame behind the object's tail (the left of its sprite), its bright
	// end at the object.
	function drawFlame(sprites:Sprites, plane:Sprite, object:GameObject, image:String, scale:Float) {
		final tile = sprites.tile(image);
		if (tile == null)
			return;
		final hull = plane.frame.hull;
		var tail = Math.POSITIVE_INFINITY, minY = Math.POSITIVE_INFINITY, maxY = Math.NEGATIVE_INFINITY;
		var i = 0;
		while (i + 1 < hull.length) {
			tail = Math.min(tail, hull[i]);
			minY = Math.min(minY, hull[i + 1]);
			maxY = Math.max(maxY, hull[i + 1]);
			i += 2;
		}
		final at = placeVertex(object, tail + 4, (minY + maxY) / 2);
		final ahead = placeVertex(object, tail + 5, (minY + maxY) / 2);
		final rotation = Math.atan2(ahead.y - at.y, ahead.x - at.x);
		final flicker = 0.85 + 0.15 * Math.sin(state.frameIdx * 2.7 + object.uid);
		TexturePages.drawImage(this, tile, at.x, at.y, scale * flicker, rotation, 1, true, 1);
	}

	// The badge the game shows by a plane holding a powerup or the ball.
	function drawHeldPowerup(sprites:Sprites, plane:GameObject) {
		final held = plane.powerup;
		final icon = held == ObjectType.BALL ? ballSprite(sprites, plane.team) : {
			final poly = held == null ? null : POWERUP_ICONS.get(held);
			poly == null ? null : sprites.forPoly(poly, null);
		};
		final badge = sprites.forImage(BADGE_IMAGE);
		if (icon == null || badge == null)
			return;
		final at = uprightAt(plane, BADGE_Y, BADGE_X);
		drawSprite(badge, at, BADGE_SIZE / badge.tile.width);
		drawIcon(icon, at, BADGE_ICON_SIZE);
	}

	// Draw an icon centred on `at`, scaled to fit `size` pixels. Long icons
	// (missiles, bombs) stand upright, as in the game's badges.
	function drawIcon(icon:Null<Sprite>, at:GameObject, size:Float) {
		if (icon == null)
			return;
		final hull = icon.frame.hull;
		var minX = Math.POSITIVE_INFINITY, maxX = Math.NEGATIVE_INFINITY;
		var minY = Math.POSITIVE_INFINITY, maxY = Math.NEGATIVE_INFINITY;
		var i = 0;
		while (i + 1 < hull.length) {
			minX = Math.min(minX, hull[i]);
			maxX = Math.max(maxX, hull[i]);
			minY = Math.min(minY, hull[i + 1]);
			maxY = Math.max(maxY, hull[i + 1]);
			i += 2;
		}
		final w = maxX - minX, h = maxY - minY;
		if (w <= 0 || h <= 0)
			return;
		final upright = w > 1.5 * h;
		final o = uprightAt(at, 0);
		if (upright)
			o.angle = 900; // a quarter turn, nose up
		// centre the hull on `at`
		final scale = size / Math.max(w, h);
		final cx = (minX + maxX) / 2 * scale, cy = (minY + maxY) / 2 * scale;
		final offX = upright ? cy : -cx, offY = upright ? -cx : -cy;
		o.positionX += Std.int(offX * 2);
		o.positionY += Std.int(offY * 2);
		drawSprite(icon, o, scale);
	}

	// An upright, unflipped copy of an object's position, moved `up` and `right` pixels.
	function uprightAt(object:GameObject, up:Float, right:Float = 0):GameObject {
		final o = new GameObject();
		o.positionX = object.positionX + Std.int(right * 2);
		o.positionY = object.positionY + Std.int(up * 2); // positions are in half pixels
		return o;
	}

	function drawMine(sprites:Sprites, object:GameObject):Bool {
		final mine = sprites.forImage(MINE_IMAGE, object.team);
		final drone = sprites.forPoly(MINE_DRONE, object.team);
		if (mine == null || drone == null)
			return false;

		final above = uprightAt.bind(object);
		final remote = object.type == ObjectType.REMOTE_MINE;
		final droneHeight = remote ? REMOTE_MINE_DRONE_HEIGHT : DIRECTOR_MINE_DRONE_HEIGHT;
		if (!remote) {
			final link = sprites.forImage(MINE_LINK);
			final top = droneHeight - drone.tile.height / 2, bottom = mine.tile.height / 2 - 2;
			var y = bottom;
			while (link != null && y < top) {
				drawSprite(link, above(y));
				y += link.tile.height / 2;
			}
		}
		drawSprite(mine, above(0));
		drawSprite(drone, above(droneHeight));
		return true;
	}

	// The game draws the ball's hitbox with the spiky mine image, in the
	// colour of the team that last touched it.
	function ballSprite(sprites:Sprites, team:Null<Int>):Null<Sprite> {
		final hitbox = sprites.forType(ObjectType.BALL, null, null);
		return hitbox == null ? null : sprites.withImage(hitbox, BALL_IMAGE, team);
	}

	function showPoly(poly:Poly, object:GameObject) {
		polysDrawn += 1;

		var x:Array<Float> = poly.verticesX;
		var y:Array<Float> = poly.verticesY;

		if (object.hasTeam()) {
			final color = replay.teamColorPoly(object.team);
			if (color != null) {
				beginFill(color);
			} else {
				// unassigned team?
				beginFill(Viewer.BACKGROUND, 0.5);
			}
		} else {
			// no team
			beginFill(Viewer.BACKGROUND, 0.5);
		}

		for (i in 0...x.length) {
			final dest = placeVertex(object, x[i], y[i]);
			lineTo(dest.x, dest.y);
		}
		endFill();
	}

	function getPlaneGraphics(player:Int):PlaneGraphics {
		final lookup = planeGraphics.get(player);
		if (lookup != null) {
			return lookup;
		}
		final graphics = new PlaneGraphics(state);
		planeGraphics.set(player, graphics);
		addChild(graphics);
		return graphics;
	}

	final planesSynced:Map<Int, Bool> = new Map();

	function drawBallAt(object:GameObject) {
		var pos = new Vector(object.positionX / 2, geom.maxY - object.positionY / 2);
		var radius = 16;
		lineStyle(2, 0, 1);
		beginFill(replay.teamColorPoly(object.team));
		drawCircle(pos.x, pos.y, radius);
		endFill();
		lineStyle(0, 0, 0);
	}

	function drawObject(object:GameObject) {
		final sprites = state.showMapArt ? this.sprites : null;
		if (sprites == null || !drawGameSprite(sprites, object))
			drawPlaceholder(object);

		if (object.type <= 4) {
			getPlaneGraphics(object.owner).syncObject(object);
			planesSynced.set(object.owner, true);
			if (sprites != null)
				drawHeldPowerup(sprites, object);
			else if (object.powerup == ObjectType.BALL)
				drawBallAt(object);
		}
	}

	// Hitboxes and simple shapes, for when there are no sprites.
	function drawPlaceholder(object:GameObject) {
		final pos = new Vector(object.positionX / 2, geom.maxY - object.positionY / 2);

		if (object.type == ObjectType.BALL) {
			drawBallAt(object);
			return;
		}

		final poly = polyManager.getPoly(object.type, object.spin);
		if (poly != null) {
			showPoly(poly, object);
		} else {
			// TODO: draw marker
		}

		// TODO: cheat on biplane bullets, bomber flak

		if (object.type == ObjectType.HEALTH_POWERUP) {
			final d = 10;
			flush();
			lineStyle(5, 0xFF0000);
			moveTo(pos.x - d, pos.y);
			lineTo(pos.x + d, pos.y);
			flush();
			moveTo(pos.x, pos.y - d);
			lineTo(pos.x, pos.y + d);
			flush();
			lineStyle(0, 0, 1);
		}

		if (object.type == 60 && poly != null) {
			// final pos = vec2(object.positionX / 2, object.positionY / 2);
			// ctx.fillStyle = "purple";
			// ctx.fillCircle(toScreen(pos), 5);
			// ctx.beginPath();
			// for (i in 0...poly.verticesX.length) {
			// 	final relative = vec2(poly.verticesX[i], poly.verticesY[i]);
			// 	ctx.lineToVec(toScreen(pos + relative));
			// }
			// ctx.stroke();
			// cheat on biplane because the hitbox for bullets is too small to see, except for HC
		}
	}

	var polysDrawn = 0;

	override function draw(ctx:RenderContext) {
		clear();
		final update = replay.updates[replay.updateAt(state.frameIdx)];

		// Draw objects / sync planes.
		planesSynced.clear();
		polysDrawn = 0;
		for (object in update.objects) {
			drawObject(object);
		}

		// Remove planes that are not used.
		for (owner in planeGraphics.keys()) {
			if (!planesSynced.exists(owner)) {
				removeChild(getPlaneGraphics(owner));
				planeGraphics.remove(owner);
			}
		}

		super.draw(ctx);
	}
}

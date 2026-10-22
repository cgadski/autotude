package autotude.viewer;

import js.html.TextTrackCue;
import autotude.proto.ObjectType;
import h2d.Text;
import h3d.Matrix;
import h3d.Vector;
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
// spinning through frames 100ms apart, with a flame behind (blue for thermobaric rockets).
final ROCKET_OPEN = "render/planes/explodet/rocket_open/0_128_5.animatedpoly";
final ROCKET_SPIN = "render/planes/explodet/rocket_spin/0_128_5.animatedpoly";
final ROCKET_OPEN_MS = 180;
final ROCKET_SPIN_START_MS = 450;
final ROCKET_SPIN_CYCLE_MS = 900;
final ROCKET_FLAMES:Map<Int, String> = [
	ObjectType.DIRECTOR_ROCKET => "effects/afterburner/afterburner1.png",
	ObjectType.THERMOBARIC_ROCKET => "effects/afterburner/afterburner_blue.png",
];
final ROCKET_FLAME_SCALE = 0.5;

// Deployed walls (see drawWall).
final WALL_CAPS = "render/powerups/wall";
final WALL_BEAM = "planes/powerup/wall/beam_texture.png";
final WALL_ELECTRIC = "planes/powerup/wall/electric_";

// Sprites that differ from the hitbox poly for a type.
// Length of loopy's missile animation, in tens of milliseconds (9 frames of 133 ms).
final MISSILE_CYCLE = 120;

final BULLET_TRAILS:Map<Int, String> = [
	ObjectType.BIPLANE_PRIMARY => "planes/biplane/trail.png",
	ObjectType.BIPLANE_SECONDARY => "planes/biplane/trail.png",
	ObjectType.HEAVY_CANNON => "planes/biplane/trail_cannon.png",
	ObjectType.FLAK => "planes/biplane/trail_cannon.png",
];

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
// The mine is smaller than its image: about 0.65x (measured against the
// drone in game screenshots), and the game's Mine class makes remote mines
// 1.2x that.
final MINE_SCALE = 0.65;
final REMOTE_MINE_SCALE = 0.65 * 1.2;

class ObjectLayer extends Graphics {
	final replay:Replay;
	final geom:MapGeometry;
	final state:PlayerState;

	final planeGraphics:Map<Int, PlaneGraphics> = new Map();

	/** Game sprites, drawn instead of hitboxes once loaded. **/
	public var sprites:Null<Sprites>;

	/** For how long objects have existed (rockets animate by it). **/
	public var timeline:Null<EffectTimeline>;

	public function new(state:PlayerState) {
		this.replay = state.replay;
		this.geom = state.geom;
		this.state = state;
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
		// the whole image, as the game draws it (the hull is just the hitbox)
		final corners = TexturePages.imageCorners(sprite.frame, sprite.tile);
		var i = 0;
		while (i + 1 < corners.length) {
			final dest = placeVertex(object, corners[i], corners[i + 1], extraScale);
			TexturePages.addVertex(this, sprite.frame, sprite.tile, corners[i], corners[i + 1], dest.x, dest.y);
			i += 2;
		}
		endFill();
	}

	// Draw an object as the game does. False if there's no sprite for it.
	function drawGameSprite(sprites:Sprites, object:GameObject):Bool {
		if (object.type == ObjectType.REMOTE_MINE || object.type == ObjectType.DIRECTOR_MINE)
			return drawMine(sprites, object);
		if (object.type == ObjectType.WALL)
			return drawWall(sprites, object);

		// planes have frames by roll; loopy's missiles animate by time (frames
		// keyed in tens of milliseconds); other animations are not played
		final spin = if (object.type <= ObjectType.MIRANDA) object.spin else if (object.type == ObjectType.DOUBLE_FIRE_MISSLE
			|| object.type == ObjectType.TRACKER_MISSLE) {
			final timeline = this.timeline;
			timeline == null ? 0 : Std.int(timeline.age(object.uid, state.frameIdx) * 100 / 30) % MISSILE_CYCLE;
		} else null;
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
		final trail = BULLET_TRAILS.get(object.type);
		if (trail != null)
			drawBulletTrail(sprites, object, trail);
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

	// as in the TrailedBullet altitude class
	function drawBulletTrail(sprites:Sprites, bullet:GameObject, image:String) {
		final tile = sprites.tile(image);
		if (tile == null)
			return;
		final scale = bullet.scale == null ? 1 : bullet.scale / 1000;
		final at = placeVertex(bullet, 0, 0);
		final ahead = placeVertex(bullet, 1, 0);
		final rotation = Math.atan2(ahead.y - at.y, ahead.x - at.x);
		final anchor = 1 - 4 / tile.width;
		TexturePages.drawImage(this, tile, at.x, at.y, 2 * scale, rotation, 0.3, false, anchor, scale);
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
		final hull = TexturePages.imageCorners(icon.frame, icon.tile);
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

	// A deployed wall, as the game's Wall and WallBeamEffect draw it: its
	// shape filled faintly in the team's colour, a beam and crackling
	// electricity along it, and a team-coloured cap at each end.
	function drawWall(sprites:Sprites, wall:GameObject):Bool {
		final timeline = this.timeline;
		final team = timeline == null ? null : timeline.teamOf(wall);
		final hitbox = sprites.forType(ObjectType.WALL, null, null);
		final cap = sprites.tile('$WALL_CAPS/${Sprites.TEAM_COLORS[(team ?? -1) - Sprites.FIRST_TEAM] ?? "0_128_5"}_0000.png');
		final beam = sprites.tile(WALL_BEAM);
		final electric = sprites.tile('$WALL_ELECTRIC${Std.int(state.frameIdx / 2) % 3}.png');
		if (hitbox == null || cap == null || beam == null || electric == null)
			return false;

		// the wall runs along its hitbox's y axis
		final hull = hitbox.frame.hull;
		var half = 0.0;
		var i = 1;
		while (i < hull.length) {
			half = Math.max(half, Math.abs(hull[i]));
			i += 2;
		}
		final top = placeVertex(wall, 0, half), bottom = placeVertex(wall, 0, -half);
		final along = Math.atan2(top.y - bottom.y, top.x - bottom.x);
		final across = along - Math.PI / 2;
		final length = Math.sqrt((top.x - bottom.x) * (top.x - bottom.x) + (top.y - bottom.y) * (top.y - bottom.y));
		final cx = (top.x + bottom.x) / 2, cy = (top.y + bottom.y) / 2;

		final color = Sprites.teamColor(team);
		if (color != null) {
			beginFill(color, 0.25);
			var i = 0;
			while (i + 1 < hull.length) {
				final p = placeVertex(wall, hull[i], hull[i + 1]);
				lineTo(p.x, p.y);
				i += 2;
			}
			endFill();
		}
		TexturePages.drawImage(this, beam, cx, cy, length / beam.width, along, 0.9, false, 0.5, 1);
		TexturePages.drawImage(this, electric, cx, cy, length / electric.width, along, 1, state.frameIdx % 4 < 2, 0.5, 1);
		TexturePages.drawImage(this, cap, top.x, top.y, 1, across);
		TexturePages.drawImage(this, cap, bottom.x, bottom.y, 1, across + Math.PI);
		return true;
	}

	function drawMine(sprites:Sprites, object:GameObject):Bool {
		final mine = sprites.forImage(MINE_IMAGE, object.team);
		final drone = sprites.forPoly(MINE_DRONE, object.team);
		if (mine == null || drone == null)
			return false;

		final above = uprightAt.bind(object);
		final remote = object.type == ObjectType.REMOTE_MINE;
		final mineScale = remote ? REMOTE_MINE_SCALE : MINE_SCALE;
		final droneHeight = remote ? REMOTE_MINE_DRONE_HEIGHT : DIRECTOR_MINE_DRONE_HEIGHT;
		if (!remote) {
			final link = sprites.forImage(MINE_LINK);
			final top = droneHeight - drone.tile.height / 2, bottom = mine.tile.height * mineScale / 2 - 2;
			var y = bottom;
			while (link != null && y < top) {
				drawSprite(link, above(y));
				y += link.tile.height / 2;
			}
		}
		drawSprite(mine, above(0), mineScale);
		drawSprite(drone, above(droneHeight));
		return true;
	}

	// The game draws the ball's hitbox with the spiky mine image, in the
	// colour of the team that last touched it.
	function ballSprite(sprites:Sprites, team:Null<Int>):Null<Sprite> {
		final hitbox = sprites.forType(ObjectType.BALL, null, null);
		return hitbox == null ? null : sprites.withImage(hitbox, BALL_IMAGE, team);
	}

	// Fill a hitbox (x, y pairs, from sprites.json) in the object's team colour.
	function showHull(hull:Array<Float>, object:GameObject) {
		polysDrawn += 1;

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

		var i = 0;
		while (i + 1 < hull.length) {
			final dest = placeVertex(object, hull[i], hull[i + 1]);
			lineTo(dest.x, dest.y);
			i += 2;
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

	// Hitboxes and simple shapes: the plain view (M), or without game resources
	// (then there are no hitboxes either, as they come from sprites.json).
	function drawPlaceholder(object:GameObject) {
		final pos = new Vector(object.positionX / 2, geom.maxY - object.positionY / 2);

		if (object.type == ObjectType.BALL) {
			drawBallAt(object);
			return;
		}

		final sprites = this.sprites;
		final hitbox = sprites == null ? null : sprites.forType(object.type, null, object.type <= ObjectType.MIRANDA ? object.spin : null);
		if (hitbox != null) {
			showHull(hitbox.frame.hull, object);
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

		if (object.type == 60 && hitbox != null) {
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

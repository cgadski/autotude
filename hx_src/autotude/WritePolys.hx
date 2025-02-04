package autotude;

import haxe.io.Output;
import autotude.proto.Poly;
import autotude.proto.ObjectType;
import sys.io.File;

final SRC_DIR = "poly_src/";
final DEST = "data/polys";

class PolyFile {
	public final path:String;
	public final objectType:Int;

	final ignoreSpin:Bool;

	public function new(path:String, objectType:Int, ignoreSpin:Bool = false) {
		this.path = path;
		this.objectType = objectType;
		this.ignoreSpin = ignoreSpin;
	}

	function readHull(hullString:String, poly:Poly) {
		if (hullString.length == 0)
			return;

		final tokens = hullString.split(",");
		var i = 0;
		while (i < tokens.length) {
			final current = tokens[i];
			if (current.length > 0 && current.charAt(0) != '!') {
				final x = Std.parseFloat(tokens[i]);
				final y = Std.parseFloat(tokens[++i]);

				poly.addVerticesX(x);
				poly.addVerticesY(y);
			}
			i++;
		}
	}

	public function process(output:Output) {
		if (this.path == "")
			return;

		var tree = Xml.parse(File.getContent(SRC_DIR + this.path));
		var elem = tree.firstElement();

		if (elem.nodeName == "AnimatedPoly") {
			processAnimated(tree, output);
		} else {
			processStatic(tree, output);
		}
	}

	function processStatic(tree:Xml, output:Output) {
		final hullString = tree.firstElement().get("hull");
		final poly = new Poly();

		poly.type = objectType;
		readHull(hullString, poly);

		poly.writeDelimitedTo(output);
	}

	function processAnimated(tree:Xml, output:Output) {
		for (frame in tree.firstElement().firstElement().elements()) {
			final poly = new Poly();
			poly.type = objectType;
			final hullString = frame.firstElement().get("hull");
			readHull(hullString, poly);

			if (ignoreSpin) {
				poly.writeDelimitedTo(output);
				return;
			}

			final delayMs = Std.parseInt(frame.get("delayMs"));
			if (delayMs == null) {
				throw "Can't read delayMs.";
			}
			poly.spin = Std.int(delayMs / 10);
			poly.writeDelimitedTo(output);
		}
	}
}

final files:Array<PolyFile> = [
	// # Planes
	new PolyFile("render/planes/loopy/0_128_5.animatedpoly", ObjectType.LOOPY),
	new PolyFile("render/planes/bomber/0_128_5.animatedpoly", ObjectType.BOMBER),
	new PolyFile("render/planes/explodet/0_128_5.animatedpoly", ObjectType.EXPLODET),
	new PolyFile("render/planes/biplane/0_128_5.animatedpoly", ObjectType.BIPLANE),
	new PolyFile("render/planes/miranda/0_128_5.animatedpoly", ObjectType.MIRANDA),
	// # Powerups
	new PolyFile("planes/powerup/container.poly", ObjectType.MISSLE_POWERUP),
	new PolyFile("planes/powerup/container.poly", ObjectType.SHIELD_POWERUP),
	new PolyFile("planes/powerup/container.poly", ObjectType.WALL_POWERUP),
	new PolyFile("planes/powerup/container.poly", ObjectType.BIG_BOMB_POWERUP),
	new PolyFile("planes/powerup/ball.poly", ObjectType.BALL),
	new PolyFile("planes/powerup/container.poly", ObjectType.HEALTH_POWERUP),
	new PolyFile("planes/powerup/container.poly", ObjectType.POWERUP_SPAWNER),
	// # Projectiles
	// ## Loopy
	new PolyFile("planes/loopy/trackingbullet.poly", ObjectType.DOUBLE_FIRE_MISSLE),
	new PolyFile("planes/loopy/trackingbullet.poly", ObjectType.TRACKER_MISSLE),
	new PolyFile("planes/loopy/emp_grenade.poly", ObjectType.EMP_CAPSULE),
	new PolyFile("", ObjectType.EMP_EXPLOSION),
	new PolyFile("planes/loopy/acid_grenade.poly", ObjectType.ACID_BOMB),
	new PolyFile("", ObjectType.ACID_CLOUD),
	// ## Bomber
	new PolyFile("planes/bomber/grenade.poly", ObjectType.NADE),
	new PolyFile("planes/bomber/big_shell.poly", ObjectType.FLAK),
	new PolyFile("planes/bomber/gun.poly", ObjectType.SUPPRESSOR),
	new PolyFile("render/planes/bomber/bomb/0_128_5.animatedpoly", ObjectType.DOMB, true),
	// ## Biplane
	new PolyFile("planes/biplane/bullet.poly", ObjectType.BIPLANE_PRIMARY), // CAUTION: this poly is very small
	new PolyFile("planes/biplane/bullet.poly", ObjectType.BIPLANE_SECONDARY),
	new PolyFile("planes/biplane/bullet_cannon.poly", ObjectType.HEAVY_CANNON),
	// ## Explodet
	new PolyFile("planes/explodet/rocket.poly", ObjectType.DIRECTOR_ROCKET),
	new PolyFile("planes/explodet/rocket.poly", ObjectType.THERMOBARIC_ROCKET),
	new PolyFile("planes/explodet/mine.poly", ObjectType.REMOTE_MINE),
	new PolyFile("planes/explodet/mine.poly", ObjectType.DIRECTOR_MINE),
	// ## Miranda
	new PolyFile("planes/miranda/laser.poly", ObjectType.LASER), // TODO: need laser hitbox
	new PolyFile("planes/miranda/charge_shot.poly", ObjectType.TRICKSTER_SHOT),
	new PolyFile("planes/miranda/charge_shot.poly", ObjectType.LASER_SHOT),
	// ## Special
	new PolyFile("render/powerups/missile/0_128_5.animatedpoly", ObjectType.HOMING_MISSLE, true),
	new PolyFile("planes/powerup/wall.poly", ObjectType.WALL),
	new PolyFile("planes/powerup/shield/shield.poly", ObjectType.SHIELD),
	new PolyFile("render/powerups/big_bomb/0_128_5.animatedpoly", ObjectType.BIG_BOMB, true),
	new PolyFile("map/goal/goal.poly", ObjectType.GOAL),
	new PolyFile("map/base/base.poly", ObjectType.BASE),
];

class WritePolys {
	static function main() {
		final output = File.write(DEST, true);
		final map:Map<Int, Bool> = new Map();

		for (file in files) {
			file.process(output);
			if (file.path != "")
				map.set(file.objectType, true);
		}
		output.close();

		var totalWritten = 0;
		for (type in map.keys()) {
			totalWritten += 1;
		}
		Sys.println('$totalWritten / ${files.length} game objects are mapped to poly data.');
	}
}

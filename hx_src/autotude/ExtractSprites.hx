package autotude;

import autotude.ExtractMapArt.ImageDef;
import autotude.ExtractMapArt.PageDef;
import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

// Extracts the game's sprites for objects in replays (planes, projectiles,
// powerups, goals, bases) from an Altitude install, for the replay viewer.
//
// Usage: haxe hx_src/build_sprites.hxml <path to Altitude install>
//
// The polys the viewer uses as hitboxes (WritePolys.files) are textured
// polys in the game, so we take each one's frames from dist/.poly and every
// texture page in the directories of the images they use from dist/.image
// (same page format as maps, see ExtractMapArt). Team-coloured images are
// named by colour (e.g. 0_128_5_0070.png) and the pages hold every colour,
// so the viewer can swap in a team's colour by name.
//
// Animated poly frames are keyed by roll ("delayMs", in tenths of a degree).

final SPRITE_OUT_DIR = "hx_src/out/viewer_assets/sprites/";

// Polys the viewer draws besides the hitbox polys.
final EXTRA_POLYS = [
	"planes/powerup/health/healthpack.animatedpoly",
	"planes/powerup/shield/shield.poly",
	"render/powerups/missile/0_128_5.animatedpoly",
	"render/powerups/big_bomb/0_128_5.animatedpoly",
	"planes/powerup/wall/end_cap.poly",
	"render/planes/explodet/mine/0_128_5.animatedpoly",
];

class ExtractSprites {
	static function main() {
		final args = Sys.args();
		if (args.length != 1) {
			Sys.println("usage: haxe hx_src/build_sprites.hxml <path to Altitude install>");
			Sys.exit(1);
		}
		final dist = findDist(args[0]);

		if (FileSystem.exists(SPRITE_OUT_DIR))
			removeDir(SPRITE_OUT_DIR);
		FileSystem.createDirectory(SPRITE_OUT_DIR);

		// object type -> poly, from the hitbox table
		final types:Map<Int, String> = [];
		final polyPaths = EXTRA_POLYS.copy();
		for (file in WritePolys.files) {
			if (file.path == "")
				continue;
			types.set(file.objectType, file.path);
			if (!polyPaths.contains(file.path))
				polyPaths.push(file.path);
		}

		final polys:haxe.DynamicAccess<Array<Dynamic>> = {};
		final imageDirs:Array<String> = [];
		for (path in polyPaths) {
			final frames = readPoly(dist + ".poly/" + path);
			polys.set(path, frames);
			for (frame in frames) {
				final image:Null<String> = frame.image;
				if (image != null && !imageDirs.contains(Path.directory(image)))
					imageDirs.push(Path.directory(image));
			}
		}

		final pages:Array<PageDef> = [];
		final images:Map<String, ImageDef> = [];
		imageDirs.sort(Reflect.compare);
		for (dir in imageDirs) {
			final full = dist + ".image/" + dir + "/";
			final names = FileSystem.readDirectory(full).filter(f -> ~/^p[0-9]+$/.match(f));
			names.sort(Reflect.compare);
			for (name in names) {
				final prefix = dir.split("/").join("_") + "_" + name;
				pages.push(ExtractMapArt.readPage(File.getBytes(full + name), prefix, SPRITE_OUT_DIR, images, pages.length));
			}
		}

		final typeKeys:haxe.DynamicAccess<String> = {};
		for (type => path in types)
			typeKeys.set(Std.string(type), path);
		File.saveContent(SPRITE_OUT_DIR + "sprites.json", Json.stringify({
			pages: pages,
			images: images,
			polys: polys,
			types: typeKeys
		}));
		Sys.println('${polyPaths.length} polys, ${imageDirs.length} image dirs, ${pages.length} pages, ${Lambda.count(images)} images');
	}

	static function findDist(install:String):String {
		for (sub in ["app/resources/dist/", "resources/dist/", ""]) {
			final dir = Path.addTrailingSlash(install) + sub;
			if (FileSystem.exists(dir + ".image") && FileSystem.exists(dir + ".poly"))
				return dir;
		}
		throw 'no resources/dist/.image in $install';
	}

	// Frames of a .poly (one frame, roll 0) or .animatedpoly.
	static function readPoly(path:String):Array<Dynamic> {
		final root = Xml.parse(File.getContent(path)).firstElement();
		if (root.nodeName != "AnimatedPoly") {
			final frame = ExtractMapArt.readTexturedPoly(root);
			frame.spin = 0;
			return [frame];
		}
		return [
			for (frame in root.elementsNamed("frames").next().elementsNamed("Frame")) {
				final item = ExtractMapArt.readTexturedPoly(frame.elementsNamed("poly").next());
				item.spin = Std.int((Std.parseInt(frame.get("delayMs")) ?? 0) / 10);
				item;
			}
		];
	}

	static function removeDir(dir:String) {
		for (f in FileSystem.readDirectory(dir)) {
			final p = Path.join([dir, f]);
			if (FileSystem.isDirectory(p))
				removeDir(p);
			else
				FileSystem.deleteFile(p);
		}
		FileSystem.deleteDirectory(dir);
	}
}

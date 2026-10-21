package autotude;

import autotude.ExtractMapArt.ImageDef;
import autotude.ExtractMapArt.PageDef;
import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

// Extracts team-coloured sprites (planes, some projectiles) from an Altitude
// install for the replay viewer.
//
// Usage: haxe hx_src/build_sprites.hxml <path to Altitude install>
//
// For each sprite group (e.g. render/planes/loopy) the game has texture pages
// in dist/.image/<group>/pN (same format as map pages, see ExtractMapArt) and
// one animated poly per team colour in dist/.poly/<group>/<r_g_b>.animatedpoly.
// Animated poly frames are textured polys keyed by roll ("delayMs", in tenths
// of a degree), with the same hulls the viewer uses for hitboxes.

final SPRITE_OUT_DIR = "hx_src/out/viewer_assets/sprites/";

final GROUPS = [
	"render/planes/loopy",
	"render/planes/bomber",
	"render/planes/explodet",
	"render/planes/biplane",
	"render/planes/miranda",
	"render/planes/bomber/bomb",
	"render/powerups/missile",
	"render/powerups/big_bomb",
];

class ExtractSprites {
	static function main() {
		final args = Sys.args();
		if (args.length != 1) {
			Sys.println("usage: haxe hx_src/build_sprites.hxml <path to Altitude install>");
			Sys.exit(1);
		}
		final dist = findDist(args[0]);
		for (group in GROUPS)
			extract(dist, group);
		Sys.println('extracted ${GROUPS.length} sprite groups into $SPRITE_OUT_DIR');
	}

	static function findDist(install:String):String {
		for (sub in ["app/resources/dist/", "resources/dist/", ""]) {
			final dir = Path.addTrailingSlash(install) + sub;
			if (FileSystem.exists(dir + ".image") && FileSystem.exists(dir + ".poly"))
				return dir;
		}
		throw 'no resources/dist/.image in $install';
	}

	static function extract(dist:String, group:String) {
		final out = SPRITE_OUT_DIR + group.split("/").join("_") + "/";
		if (FileSystem.exists(out))
			for (f in FileSystem.readDirectory(out))
				FileSystem.deleteFile(out + f);
		FileSystem.createDirectory(out);

		final imageDir = dist + ".image/" + group + "/";
		final pageNames = FileSystem.readDirectory(imageDir).filter(f -> ~/^p[0-9]+$/.match(f));
		pageNames.sort((a, b) -> (Std.parseInt(a.substr(1)) ?? 0) - (Std.parseInt(b.substr(1)) ?? 0));
		final pages:Array<PageDef> = [];
		final images:Map<String, ImageDef> = [];
		for (name in pageNames)
			pages.push(ExtractMapArt.readPage(File.getBytes(imageDir + name), name, out, images, pages.length));

		final polyDir = dist + ".poly/" + group + "/";
		final colors:haxe.DynamicAccess<Array<Dynamic>> = {};
		for (f in FileSystem.readDirectory(polyDir)) {
			if (Path.extension(f) != "animatedpoly")
				continue;
			final frames = [];
			final root = Xml.parse(File.getContent(polyDir + f)).firstElement();
			for (frame in root.elementsNamed("frames").next().elementsNamed("Frame")) {
				final item = ExtractMapArt.readTexturedPoly(frame.elementsNamed("poly").next());
				item.spin = Std.int((Std.parseInt(frame.get("delayMs")) ?? 0) / 10);
				frames.push(item);
			}
			colors.set(Path.withoutExtension(f), frames);
		}

		File.saveContent(out + "sprite.json", Json.stringify({pages: pages, images: images, colors: colors}));
		Sys.println('$group: ${pages.length} pages, ${Lambda.count(images)} images, ${colors.keys().length} colours');
	}
}

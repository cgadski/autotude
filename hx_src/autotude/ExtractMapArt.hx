package autotude;

import haxe.Json;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

// Extracts map artwork from Altitude's .altx map archives into a form the
// browser can load: JPEG tiles (as stored by the game), alpha masks as
// greyscale PNGs, and a map.json describing how to place the images.
//
// Usage: haxe hx_src/build_map_art.hxml [map names...]  (all maps by default)
//
// Reads alti_home/maps, the maps an Altitude client downloaded from servers
// (on Windows, %LOCALAPPDATA%\NimblyGames\Altitude\maps\download) and any
// directories listed in $ALTI_MAP_DIRS (separated like PATH).
//
// .altx layout (all little-endian), after LZMA decompression:
//   u32 count, count x (u16 len, utf8 path), count x u32 size, file data...
//
// Texture pages (_derived/dist/.image/**/pN) pack one or more images:
//   u32 count, count x (u16 len, path, i32 x, i32 y, i32 w, i32 h)
//   then big-endian: i32 10002, i32 format, i32, i32, i32 tileCount,
//   tileCount x (i32 w, i32 h, i32 size, size bytes: i32, LZMA alpha, JPEG)
// The game's own pages (resources/dist/.image) are uncompressed:
//   ... i32 format, i32, i32, i32 tileCount, tileCount x (i32 w, i32 h, RGBA)
// Pages are y-up like GL textures: tiles fill rows starting at the bottom,
// and image rectangles are measured from the bottom-left.

final MAP_DIR = "alti_home/maps/";
final OUT_DIR = "hx_src/out/viewer_assets/maps/";
final IMAGE_ROOT = "_derived/dist/.image/";
final COMPRESSED_PAGE = 10002;

typedef Archive = Map<String, Bytes>;

typedef TileDef = {
	x:Int,
	y:Int,
	w:Int,
	h:Int,
	file:String,
	alpha:Null<String>
};

typedef PageDef = {
	w:Int,
	h:Int,
	tiles:Array<TileDef>
};

typedef ImageDef = {
	page:Int,
	x:Int,
	y:Int,
	w:Int,
	h:Int
};

class ExtractMapArt {
	static function main() {
		final only = Sys.args();

		// map name -> .altx; later directories win
		final maps:Map<String, String> = [];
		for (dir in mapDirs()) {
			Sys.println('reading maps in $dir');
			for (file in FileSystem.readDirectory(dir)) {
				if (Path.extension(file) != "altx")
					continue;
				final name = Path.withoutExtension(file);
				final previous = maps.get(name);
				if (previous != null)
					Sys.println('$name: using ${dir + file} instead of $previous');
				maps.set(name, dir + file);
			}
		}
		final names = [for (name in maps.keys()) name];
		names.sort(Reflect.compare);

		var done = 0;
		for (name in names) {
			final path = maps.get(name);
			if (path == null || (only.length > 0 && !only.contains(name)))
				continue;
			try {
				extract(name, readArchive(path));
				done++;
			} catch (e) {
				Sys.println('$name: FAILED: $e');
			}
		}
		Sys.println('extracted $done map(s) into $OUT_DIR');
	}

	// alti_home/maps, then maps the game client downloaded from servers (custom
	// and ladder maps), then any directories in $ALTI_MAP_DIRS.
	static function mapDirs():Array<String> {
		final dirs = [MAP_DIR];
		final localAppData = Sys.getEnv("LOCALAPPDATA");
		if (localAppData != null)
			dirs.push(Path.join([localAppData, "NimblyGames/Altitude/maps/download"]));
		final extra = Sys.getEnv("ALTI_MAP_DIRS");
		if (extra != null)
			for (dir in extra.split(Sys.systemName() == "Windows" ? ";" : ":"))
				if (dir.length > 0)
					dirs.push(dir);
		return [
			for (dir in dirs)
				if (FileSystem.exists(dir) && FileSystem.isDirectory(dir)) Path.addTrailingSlash(dir)
		];
	}

	static function readArchive(path:String):Archive {
		final input = new BytesInput(Lzma.decode(File.getBytes(path)).data);
		final count = input.readInt32();
		final names = [for (_ in 0...count) input.readString(input.readUInt16())];
		final sizes = [for (_ in 0...count) input.readInt32()];
		final archive:Archive = [];
		for (i in 0...count)
			archive.set(names[i], input.read(sizes[i]));
		return archive;
	}

	static function extract(name:String, archive:Archive) {
		final out = OUT_DIR + name + "/";
		if (FileSystem.exists(out))
			for (f in FileSystem.readDirectory(out))
				FileSystem.deleteFile(out + f);
		FileSystem.createDirectory(out);

		final pages:Array<PageDef> = [];
		final images:Map<String, ImageDef> = [];
		final entries = [for (path => data in archive) {path: path, data: data}];
		entries.sort((a, b) -> Reflect.compare(a.path, b.path));
		for (e in entries)
			if (isPage(e.path)) {
				final prefix = e.path.substr(IMAGE_ROOT.length).split("/").join("_");
				pages.push(readPage(e.data, prefix, out, images, pages.length));
			}

		final levelEntry = entries.filter(e -> Path.extension(e.path) == "alte")[0];
		final levelPath = levelEntry.path;
		final level = Xml.parse(levelEntry.data.toString()).firstElement();

		final json = {
			// changes with every extraction, so the viewer won't use stale cached images
			version: DateTools.format(Date.now(), "%Y%m%d%H%M%S"),
			level: Path.withoutExtension(levelPath),
			background: Std.parseInt(level.get("backgroundColor")),
			pages: pages,
			images: images,
			views: [for (view in level.elementsNamed("views").next().elementsNamed("View")) readView(view)],
		};
		File.saveContent(out + "map.json", Json.stringify(json));

		var tiles = 0;
		for (p in pages)
			tiles += p.tiles.length;
		Sys.println('$name: ${pages.length} pages, $tiles tiles, ${Lambda.count(images)} images');
	}

	static function isPage(path:String):Bool {
		return StringTools.startsWith(path, IMAGE_ROOT) && Path.extension(path) == ""
			&& ~/^p[0-9]+$/.match(Path.withoutDirectory(path));
	}

	public static function readPage(data:Bytes, prefix:String, out:String, images:Map<String, ImageDef>, pageIdx:Int):PageDef {
		final input = new BytesInput(data);
		final count = input.readInt32();
		var w = 0, h = 0;
		final entries = [];
		for (_ in 0...count) {
			final path = input.readString(input.readUInt16());
			final img = {
				page: pageIdx,
				x: input.readInt32(),
				y: input.readInt32(),
				w: input.readInt32(),
				h: input.readInt32()
			};
			entries.push({path: path, img: img});
			w = Std.int(Math.max(w, img.x + img.w));
			h = Std.int(Math.max(h, img.y + img.h));
		}

		input.bigEndian = true;
		// Map pages start with a version marker and store each tile as an LZMA
		// alpha mask followed by a JPEG. The game's own pages store raw RGBA.
		final compressed = input.readInt32() == COMPRESSED_PAGE;
		if (compressed)
			input.readInt32(); // texture format (RGBA8, DXT5, ...)
		input.readInt32();
		input.readInt32();
		final tileCount = input.readInt32();

		final tiles:Array<TileDef> = [];
		var tx = 0, ty = 0, rowH = 0;
		for (i in 0...tileCount) {
			final tw = input.readInt32();
			final th = input.readInt32();
			final tile = compressed ? readCompressedTile(data, input, tw, th, '${prefix}_$i', out) : readRawTile(input, tw, th,
				'${prefix}_$i', out);

			// tiles fill the page row by row, starting from the bottom
			if (tx >= w && tx > 0) {
				tx = 0;
				ty += rowH;
				rowH = 0;
			}
			tiles.push({x: tx, y: ty, w: tw, h: th, file: tile.file, alpha: tile.alpha});
			tx += tw;
			rowH = Std.int(Math.max(rowH, th));
		}
		final gridH = ty + rowH;
		if (gridH < h)
			throw 'tiles of $prefix cover ${gridH}px, page needs ${h}px';

		// pages are y-up (like GL textures); flip to the top-down coordinates
		// a canvas uses
		for (t in tiles)
			t.y = gridH - t.y - t.h;
		for (e in entries) {
			e.img.y = gridH - e.img.y - e.img.h;
			images.set(e.path, e.img);
		}

		return {w: w, h: gridH, tiles: tiles};
	}

	// i32 size, then size bytes: i32, LZMA alpha mask, JPEG
	static function readCompressedTile(data:Bytes, input:BytesInput, w:Int, h:Int, name:String, out:String) {
		final size = input.readInt32();
		final start = input.position;
		input.readInt32();

		final alpha = Lzma.decode(data, input.position);
		final jpgStart = input.position + alpha.consumed;
		if (data.get(jpgStart) != 0xFF || data.get(jpgStart + 1) != 0xD8)
			throw '$name: no JPEG after alpha mask';
		File.saveBytes(out + name + ".jpg", data.sub(jpgStart, start + size - jpgStart));
		input.position = start + size;

		if (alpha.data.length != w * h)
			throw '$name: alpha mask is ${alpha.data.length} bytes, expected ${w * h}';
		if (isOpaque(alpha.data))
			return {file: name + ".jpg", alpha: null};
		writePng(out + name + "_a.png", format.png.Tools.buildGrey(w, h, alpha.data, 6));
		return {file: name + ".jpg", alpha: name + "_a.png"};
	}

	// w * h RGBA pixels
	static function readRawTile(input:BytesInput, w:Int, h:Int, name:String, out:String) {
		final argb = haxe.io.Bytes.alloc(w * h * 4);
		for (p in 0...w * h) {
			final r = input.readByte(), g = input.readByte(), b = input.readByte(), a = input.readByte();
			argb.set(p * 4, a);
			argb.set(p * 4 + 1, r);
			argb.set(p * 4 + 2, g);
			argb.set(p * 4 + 3, b);
		}
		writePng(out + name + ".png", format.png.Tools.build32ARGB(w, h, argb, 6));
		return {file: name + ".png", alpha: null};
	}

	static function writePng(path:String, png:format.png.Data) {
		final o = File.write(path);
		new format.png.Writer(o).write(png);
		o.close();
	}

	static function isOpaque(alpha:Bytes):Bool {
		for (i in 0...alpha.length)
			if (alpha.get(i) != 0xFF)
				return false;
		return true;
	}

	static function readView(view:Xml):Dynamic {
		final size = view.get("size").split(",").map(Std.parseInt);
		final items:Array<Dynamic> = [];
		for (geometries in view.elementsNamed("geometry"))
			for (g in geometries.elementsNamed("geometry")) {
				if (g.get("visible") != "true")
					continue;
				final poly = g.elementsNamed("texturedPoly").next();
				if (poly == null)
					continue;
				final item = readTexturedPoly(poly);
				item.layer = Std.parseInt(g.get("layer"));
				item.x = Std.parseFloat(g.get("x"));
				item.y = Std.parseFloat(g.get("y"));
				item.rotation = Std.parseFloat(g.get("orientation"));
				items.push(item);
			}
		// stable sort, lower layers first
		haxe.ds.ArraySort.sort(items, (a, b) -> a.layer - b.layer);
		return {
			name: view.get("name"),
			w: size[0],
			h: size[1],
			items: items
		};
	}

	// A polygon with a texture, as used by maps and by the game's sprites:
	//   <... hull="..."><texture><image path="..."/><xform ...><translate .../>
	// The image is placed at translate + flip(rotate(scale * imagePos)).
	public static function readTexturedPoly(poly:Xml):Dynamic {
		final hull = readHull(poly.get("hull"));
		final texture = poly.elementsNamed("texture").next();
		final image = texture.elementsNamed("image").next();
		final xform = texture.elementsNamed("xform").next();
		final translate = xform.elementsNamed("translate").next();
		return {
			hull: hull.points,
			color: hull.color,
			image: image == null ? null : image.get("path"),
			scale: Std.parseFloat(xform.get("scale")),
			textureRotation: Std.parseFloat(xform.get("rotate")),
			flipX: xform.get("flipX") == "true",
			flipY: xform.get("flipY") == "true",
			tx: Std.parseFloat(translate.get("x")),
			ty: Std.parseFloat(translate.get("y")),
		};
	}

	// "!color,x,y,x,y,!color,x,y,..." where !color sets the colour of the
	// following vertices. We keep the first colour, used to fill untextured
	// polygons.
	public static function readHull(hull:String):{points:Array<Float>, color:Int} {
		final points:Array<Float> = [];
		var color:Null<Int> = null;
		for (token in hull.split(",")) {
			if (token.length == 0)
				continue;
			if (token.charAt(0) == "!") {
				if (color == null)
					color = Std.parseInt(token.substr(1));
			} else {
				points.push(Std.parseFloat(token));
			}
		}
		return {points: points, color: color == null ? -1 : color};
	}
}

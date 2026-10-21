package autotude.viewer;

import h2d.Graphics;
import h2d.Tile;
import hxd.BitmapData;
import js.Browser;
import js.html.CanvasElement;
import js.html.ImageElement;
import js.lib.Promise;

// Texture pages and textured polygons, as written by autotude.ExtractMapArt
// and autotude.ExtractSprites.

typedef PageTile = {
	x:Int,
	y:Int,
	w:Int,
	h:Int,
	file:String,
	alpha:Null<String>
};

typedef Page = {
	w:Int,
	h:Int,
	tiles:Array<PageTile>
};

typedef PageImage = {
	page:Int,
	x:Int,
	y:Int,
	w:Int,
	h:Int
};

/** A polygon (y-up) with an image placed at translate + flip(rotate(scale * imagePos)). **/
typedef TexturedPoly = {
	hull:Array<Float>,
	color:Int,
	image:Null<String>,
	scale:Float,
	textureRotation:Float,
	flipX:Bool,
	flipY:Bool,
	tx:Float,
	ty:Float
};

class TexturePages {
	/**
		Fetch an extractor's JSON, checking with the server rather than
		trusting the browser's cache, so a rebuild is picked up on reload.
	**/
	public static function fetchJson(url:String, what:String):Promise<Dynamic> {
		return Browser.window.fetch(url, {cache: NO_CACHE}).then(res -> {
			if (!res.ok)
				throw 'no $what (${res.status})';
			return res.json();
		});
	}

	/**
		Load every page under `root` and cut out each image as its own texture.
		`version` (from the extractor) is added to image URLs so cached images
		from an older extraction aren't reused.
	**/
	public static function load(root:String, pages:Array<Page>, images:haxe.DynamicAccess<PageImage>,
			?version:String):Promise<Map<String, Tile>> {
		final query = version == null ? "" : "?v=" + StringTools.urlEncode(version);
		return Promise.all([for (page in pages) loadPage(root, page, query)]).then(canvases -> {
			final textures:Map<String, Tile> = [];
			for (path in images.keys()) {
				final img = images.get(path);
				if (img == null)
					continue;
				final bmp = BitmapData.fromNative(canvases[img.page].getContext2d()).sub(img.x, img.y, img.w, img.h);
				textures.set(path, Tile.fromBitmap(bmp));
			}
			return textures;
		});
	}

	/**
		Add a vertex of `poly` to a tile fill on `g` (see `Graphics.beginTileFill`).
		`px, py` is the hull point in the poly's own space, `x, y` where it goes.
	**/
	public static function addVertex(g:Graphics, poly:TexturedPoly, tile:Tile, px:Float, py:Float, x:Float, y:Float) {
		// invert translate + flip(rotate(scale * imagePos)); flips mirror
		// about the translate point
		var qx = px - poly.tx, qy = py - poly.ty;
		if (poly.flipX)
			qx = -qx;
		if (poly.flipY)
			qy = -qy;
		final rot = -poly.textureRotation * Math.PI / 180;
		final cos = Math.cos(rot), sin = Math.sin(rot);
		final ix = (qx * cos - qy * sin) / poly.scale;
		final iy = (qx * sin + qy * cos) / poly.scale;
		// images are y-up too
		final tex = tile.getTexture();
		g.addVertex(x, y, 1, 1, 1, 1, ix / tex.width, (tile.height - iy) / tex.height);
	}

	/**
		The corners of a poly's whole image in the poly's own space (x, y
		pairs). The game draws sprites as their whole image; the hull is only
		their hitbox, often much smaller (shots, shields, rotor blades).
	**/
	public static function imageCorners(poly:TexturedPoly, tile:Tile):Array<Float> {
		final rot = poly.textureRotation * Math.PI / 180;
		final cos = Math.cos(rot), sin = Math.sin(rot);
		final out = [];
		for (corner in [[0, 0], [1, 0], [1, 1], [0, 1]]) {
			// image space is y-up from the bottom-left corner
			final ix = corner[0] * tile.width * poly.scale, iy = corner[1] * tile.height * poly.scale;
			var x = ix * cos - iy * sin, y = ix * sin + iy * cos;
			if (poly.flipX)
				x = -x;
			if (poly.flipY)
				y = -y;
			out.push(poly.tx + x);
			out.push(poly.ty + y);
		}
		return out;
	}

	/**
		Draw a whole image centred on (x, y), scaled, rotated (radians,
		clockwise on screen), faded and optionally mirrored. `anchorX` is
		where along the image's width (0 left, 1 right) sits on (x, y).
		`scaleY` stretches the height separately.
	**/
	public static function drawImage(g:Graphics, tile:Tile, x:Float, y:Float, scale:Float = 1, rotation:Float = 0, alpha:Float = 1,
			flipX = false, anchorX = 0.5, ?scaleY:Float) {
		if (alpha <= 0 || scale <= 0)
			return;
		final w = tile.width * scale, h = tile.height * (scaleY ?? scale);
		final cos = Math.cos(rotation), sin = Math.sin(rotation);
		final tex = tile.getTexture();
		final u0 = tile.x / tex.width, u1 = (tile.x + tile.width) / tex.width;
		final v0 = tile.y / tex.height, v1 = (tile.y + tile.height) / tex.height;
		g.beginTileFill(0, 0, 1, 1, tile);
		final left = -anchorX * w;
		for (corner in [[0, 0], [1, 0], [1, 1], [0, 1]]) {
			final lx = left + corner[0] * w, ly = (corner[1] - 0.5) * h;
			final u = (flipX ? 1 - corner[0] : corner[0]) == 0 ? u0 : u1;
			g.addVertex(x + lx * cos - ly * sin, y + lx * sin + ly * cos, 1, 1, 1, alpha, u, corner[1] == 0 ? v0 : v1);
		}
		g.endFill();
	}

	static function loadPage(root:String, page:Page, query:String):Promise<CanvasElement> {
		final canvas = Browser.document.createCanvasElement();
		canvas.width = page.w;
		canvas.height = page.h;
		final ctx = canvas.getContext2d({willReadFrequently: true});
		return Promise.all([
			for (tile in page.tiles)
				loadImage(root + tile.file + query).then(img -> {
					ctx.drawImage(img, tile.x, tile.y);
					final alpha = tile.alpha;
					return alpha == null ? Promise.resolve(true) : loadImage(root + alpha + query).then(mask -> {
						applyAlpha(ctx, mask, tile);
						return true;
					});
				})
		]).then(_ -> canvas);
	}

	// Copy a greyscale mask into the alpha channel of one tile of the page.
	static function applyAlpha(ctx:js.html.CanvasRenderingContext2D, mask:ImageElement, tile:PageTile) {
		final maskCanvas = Browser.document.createCanvasElement();
		maskCanvas.width = tile.w;
		maskCanvas.height = tile.h;
		final maskCtx = maskCanvas.getContext2d({willReadFrequently: true});
		maskCtx.drawImage(mask, 0, 0);
		final alpha = maskCtx.getImageData(0, 0, tile.w, tile.h).data;
		final pixels = ctx.getImageData(tile.x, tile.y, tile.w, tile.h);
		final data = pixels.data;
		var i = 3;
		while (i < data.length) {
			data[i] = alpha[i - 3];
			i += 4;
		}
		ctx.putImageData(pixels, tile.x, tile.y);
	}

	static function loadImage(src:String):Promise<ImageElement> {
		return new Promise((resolve, reject) -> {
			final img = Browser.document.createImageElement();
			img.onload = () -> resolve(img);
			img.onerror = () -> reject('failed to load $src');
			img.src = src;
		});
	}
}

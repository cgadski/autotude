package autotude.viewer;

import autotude.viewer.TexturePages.Page;
import autotude.viewer.TexturePages.PageImage;
import autotude.viewer.TexturePages.TexturedPoly;
import h2d.Graphics;
import h2d.Object;
import h2d.RenderContext;
import h2d.Tile;
import h3d.mat.Data.Wrap;
import js.lib.Promise;

// Format of map.json, written by game_resources/bin/maps.rs.

typedef MapArtItem = TexturedPoly & {
	layer:Int,
	x:Float,
	y:Float,
	rotation:Float
};

typedef MapArtView = {
	name:String,
	w:Int,
	h:Int,
	items:Array<MapArtItem>
};

typedef MapArtData = {
	?version:String,
	level:String,
	background:Int,
	// the level's useBlackSmokeForPlaneDamage: white smoke when false
	?blackSmoke:Bool,
	pages:Array<Page>,
	images:haxe.DynamicAccess<PageImage>,
	views:Array<MapArtView>
};

final MAP_ART_ROOT = "game_resources/maps/";
final GAME_VIEW = "Game";

/**
	A level "view" (parallax plane) drawn in map coordinates (y down).
	Views smaller than the map scroll slower than the camera, like in game.
**/
class ParallaxView extends Graphics {
	final state:PlayerState;
	final w:Float;
	final h:Float;

	public function new(state:PlayerState, view:MapArtView, textures:Map<String, Tile>) {
		super();
		this.state = state;
		this.w = view.w;
		this.h = view.h;
		for (item in view.items)
			drawItem(item, textures);
	}

	function drawItem(item:MapArtItem, textures:Map<String, Tile>) {
		final tile = item.image == null ? null : textures.get(item.image);
		if (item.image != null && tile == null)
			return; // image not in this map's pages
		final wrapping = tile != null && tile.getTexture().wrap == Repeat;

		if (tile != null) {
			beginTileFill(0, 0, 1, 1, tile);
		} else {
			beginFill(item.color & 0xFFFFFF, ((item.color >>> 24) & 0xFF) / 255);
		}

		final rot = item.rotation * Math.PI / 180;
		final cos = Math.cos(rot), sin = Math.sin(rot);

		if (tile != null && !wrapping) {
			// the image at translate + flip(rotate(scale * imagePos))
			final trot = item.textureRotation * Math.PI / 180;
			final tcos = Math.cos(trot), tsin = Math.sin(trot);
			for (c in [[0.0, 0.0], [tile.width, 0.0], [tile.width, tile.height], [0.0, tile.height]]) {
				final sx = c[0] * item.scale, sy = c[1] * item.scale;
				var rx = sx * tcos - sy * tsin, ry = sx * tsin + sy * tcos;
				if (item.flipX)
					rx = -rx;
				if (item.flipY)
					ry = -ry;
				final px = item.tx + rx, py = item.ty + ry;
				// level coordinates are y-up
				final x = item.x + px * cos - py * sin;
				final y = h - (item.y + px * sin + py * cos);
				TexturePages.addVertex(this, item, tile, px, py, x, y, item.color);
			}
			endFill();
			return;
		}

		var i = 0;
		while (i + 1 < item.hull.length) {
			final px = item.hull[i], py = item.hull[i + 1];
			i += 2;

			// level coordinates are y-up
			final x = item.x + px * cos - py * sin;
			final y = h - (item.y + px * sin + py * cos);

			if (tile == null)
				lineTo(x, y);
			else
				TexturePages.addVertex(this, item, tile, px, py, x, y, item.color);
		}
		endFill();
	}

	override function sync(ctx:RenderContext) {
		final mapW = state.geom.maxX, mapH = state.geom.maxY;
		final visW = Viewer.WIDTH / state.scale, visH = Viewer.HEIGHT / state.scale;

		// In game the camera shows at most a screen of the map, which views
		// are big enough to cover. When zoomed out further, stretch a view so
		// it still covers everything visible.
		final s = Math.max(1, Math.max(Math.min(visW, mapW) / w, Math.min(visH, mapH) / h));
		setScale(s);
		setPosition(parallax(state.pos.x, visW, mapW, w * s), parallax(state.pos.y, visH, mapH, h * s));
		super.sync(ctx);
	}

	// Offset for a view of size `viewSize` so its edges meet the map's edges
	// when the camera does.
	static function parallax(center:Float, visible:Float, mapSize:Float, viewSize:Float):Float {
		if (viewSize == mapSize)
			return 0;
		final camStart = center - visible / 2;
		final f = mapSize > visible ? hxd.Math.clamp(camStart / (mapSize - visible), 0, 1) : 0.5;
		return camStart - f * (viewSize - visible);
	}
}

class MapArt {
	public final background:Int;

	/** The level's useBlackSmokeForPlaneDamage: white smoke when false. **/
	public final blackSmoke:Bool;

	public final back:Array<Object> = [];
	public final game:Array<Object> = []; // covers planes and goals
	public final front:Array<Object> = [];

	function new(state:PlayerState, data:MapArtData, textures:Map<String, Tile>) {
		background = data.background & 0xFFFFFF;
		blackSmoke = data.blackSmoke ?? true;
		var inFront = false;
		for (view in data.views) {
			final parallaxView = new ParallaxView(state, view, textures);
			if (inFront) {
				front.push(parallaxView);
			} else if (view.name == GAME_VIEW) {
				game.push(parallaxView);
				inFront = true;
			} else {
				back.push(parallaxView);
			}
		}
	}

	/** Fetch and decode a map's artwork. Rejects if it hasn't been extracted. **/
	public static function load(state:PlayerState, mapName:String):Promise<MapArt> {
		final root = MAP_ART_ROOT + mapName + "/";
		return TexturePages.fetchJson(root + "map.json", 'map art for $mapName').then((data:MapArtData) -> {
			return TexturePages.load(root, data.pages, data.images, data.version)
				.then(textures -> new MapArt(state, data, textures));
		});
	}
}

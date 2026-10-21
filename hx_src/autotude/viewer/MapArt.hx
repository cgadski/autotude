package autotude.viewer;

import autotude.viewer.TexturePages.Page;
import autotude.viewer.TexturePages.PageImage;
import autotude.viewer.TexturePages.TexturedPoly;
import h2d.Graphics;
import h2d.Object;
import h2d.RenderContext;
import h2d.Tile;
import js.Browser;
import js.lib.Promise;

// Format of map.json, written by autotude.ExtractMapArt.

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
	level:String,
	background:Int,
	pages:Array<Page>,
	images:haxe.DynamicAccess<PageImage>,
	views:Array<MapArtView>
};

final MAP_ART_ROOT = "viewer_assets/maps/";
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

		if (tile != null) {
			beginTileFill(0, 0, 1, 1, tile);
		} else {
			beginFill(item.color & 0xFFFFFF, ((item.color >>> 24) & 0xFF) / 255);
		}

		final rot = item.rotation * Math.PI / 180;
		final cos = Math.cos(rot), sin = Math.sin(rot);

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
				TexturePages.addVertex(this, item, tile, px, py, x, y);
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

	/** Views drawn under the game objects, back to front. **/
	public final back:Array<Object> = [];

	/** Views drawn over the game objects, back to front. **/
	public final front:Array<Object> = [];

	function new(state:PlayerState, data:MapArtData, textures:Map<String, Tile>) {
		background = data.background & 0xFFFFFF;
		var inFront = false;
		for (view in data.views) {
			(inFront ? front : back).push(new ParallaxView(state, view, textures));
			if (view.name == GAME_VIEW)
				inFront = true;
		}
	}

	/** Fetch and decode a map's artwork. Rejects if it hasn't been extracted. **/
	public static function load(state:PlayerState, mapName:String):Promise<MapArt> {
		final root = MAP_ART_ROOT + mapName + "/";
		return Browser.window.fetch(root + "map.json").then(res -> {
			if (!res.ok)
				throw 'no map art for $mapName (${res.status})';
			return res.json();
		}).then((data:MapArtData) -> {
			return TexturePages.load(root, data.pages, data.images).then(textures -> new MapArt(state, data, textures));
		});
	}
}

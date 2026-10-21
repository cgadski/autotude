package autotude.viewer;

import autotude.viewer.TexturePages.Page;
import autotude.viewer.TexturePages.PageImage;
import autotude.viewer.TexturePages.TexturedPoly;
import h2d.Tile;
import js.lib.Promise;

// Format of sprites.json, written by autotude.ExtractSprites.

typedef SpriteFrame = TexturedPoly & {
	spin:Int
};

typedef SpriteData = {
	?version:String,
	pages:Array<Page>,
	images:haxe.DynamicAccess<PageImage>,
	polys:haxe.DynamicAccess<Array<SpriteFrame>>,
	// object type -> poly
	types:haxe.DynamicAccess<String>
};

typedef Sprite = {
	frame:SpriteFrame,
	tile:Tile
};

final SPRITES_JSON = "viewer_assets/sprites/sprites.json";

// Colours (r_g_b, as in image names) of teams 3 (red) through 11 (brown),
// from the game's em.altitude.game.model.Team. Teams 0-2 are reserved and
// spectators.
final TEAM_COLORS = [
	"171_5_13", "30_58_206", "0_128_5", "240_166_20", "239_95_0", "115_0_214", "93_138_168", "230_118_118", "98_38_0"
];
final FIRST_TEAM = 3;

final COLOR_IN_NAME = ~/[0-9]+_[0-9]+_[0-9]+/;

class Sprites {
	final data:SpriteData;
	final textures:Map<String, Tile>;

	function new(data:SpriteData, textures:Map<String, Tile>) {
		this.data = data;
		this.textures = textures;
	}

	/** Fetch and decode the sprites. Rejects if they haven't been extracted. **/
	public static function load():Promise<Sprites> {
		final root = haxe.io.Path.directory(SPRITES_JSON) + "/";
		return TexturePages.fetchJson(SPRITES_JSON, "sprites").then((data:SpriteData) -> {
			return TexturePages.load(root, data.pages, data.images, data.version).then(textures -> new Sprites(data, textures));
		});
	}

	/** An image on its own, if it was extracted. **/
	public function tile(image:String):Null<Tile>
		return textures.get(image);

	/** The sprite the game draws for an object type, if any. **/
	public function forType(type:Int, team:Null<Int>, spin:Null<Int>):Null<Sprite> {
		final poly = data.types.get(Std.string(type));
		return poly == null ? null : forPoly(poly, team, spin);
	}

	/**
		A frame of a poly (a path under the game's dist/.poly), in a team's
		colour if it has one, at the closest roll to `spin`.
	**/
	public function forPoly(poly:String, team:Null<Int>, spin:Null<Int> = null):Null<Sprite> {
		final frames = data.polys.get(poly);
		if (frames == null || frames.length == 0)
			return null;

		// closest roll, like PolyManager.getPoly
		var best = frames[0];
		if (spin != null) {
			var bestDiff = 360;
			for (frame in frames) {
				final diff = Std.int(Math.abs(((spin - frame.spin + 180) % 360 + 360) % 360 - 180));
				if (diff < bestDiff) {
					best = frame;
					bestDiff = diff;
				}
			}
		}

		final image = best.image;
		if (image == null)
			return null;
		final tile = textures.get(teamImage(image, team)) ?? textures.get(image);
		return tile == null ? null : {frame: best, tile: tile};
	}

	/** An image on its own, centred on the origin, in a team's colour if it has one. **/
	public function forImage(image:String, ?team:Int):Null<Sprite> {
		final tile = textures.get(teamImage(image, team)) ?? textures.get(image);
		if (tile == null)
			return null;
		final w = tile.width / 2, h = tile.height / 2;
		return {
			frame: {
				hull: [-w, -h, w, -h, w, h, -w, h],
				color: -1,
				image: image,
				scale: 1,
				textureRotation: 0,
				flipX: false,
				flipY: false,
				tx: -w,
				ty: -h,
				spin: 0
			},
			tile: tile
		};
	}

	/**
		The same frame with a different image (in a team's colour if it has
		one), scaled to the width of the original image.
	**/
	public function withImage(sprite:Sprite, image:String, ?team:Int):Null<Sprite> {
		final tile = textures.get(teamImage(image, team)) ?? textures.get(image);
		if (tile == null)
			return null;
		final frame = Reflect.copy(sprite.frame);
		if (frame == null)
			return null;
		frame.image = image;
		frame.scale = sprite.frame.scale * sprite.tile.width / tile.width;
		return {frame: frame, tile: tile};
	}

	/** A team's colour as 0xRRGGBB, if it's a player team. **/
	public static function teamColor(team:Null<Int>):Null<Int> {
		final color = TEAM_COLORS[(team ?? -1) - FIRST_TEAM];
		if (color == null)
			return null;
		final rgb = color.split("_").map(Std.parseInt);
		return ((rgb[0] ?? 0) << 16) | ((rgb[1] ?? 0) << 8) | (rgb[2] ?? 0);
	}

	// Team-coloured images are named by colour, e.g. render/planes/loopy/0_128_5_0070.png.
	static function teamImage(image:String, team:Null<Int>):String {
		final color = TEAM_COLORS[(team ?? -1) - FIRST_TEAM];
		if (color == null)
			return image;
		return COLOR_IN_NAME.replace(image, color);
	}
}

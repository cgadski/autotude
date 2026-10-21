package autotude.viewer;

import autotude.proto.ObjectType;
import autotude.viewer.TexturePages.Page;
import autotude.viewer.TexturePages.PageImage;
import autotude.viewer.TexturePages.TexturedPoly;
import h2d.Tile;
import js.Browser;
import js.lib.Promise;

// Format of sprite.json, written by autotude.ExtractSprites.

typedef SpriteFrame = TexturedPoly & {
	spin:Int
};

typedef SpriteData = {
	pages:Array<Page>,
	images:haxe.DynamicAccess<PageImage>,
	colors:haxe.DynamicAccess<Array<SpriteFrame>>
};

final SPRITE_ROOT = "viewer_assets/sprites/";

// sprite group for each object type that has one
final SPRITE_GROUPS:Map<Int, String> = [
	ObjectType.LOOPY => "render_planes_loopy",
	ObjectType.BOMBER => "render_planes_bomber",
	ObjectType.EXPLODET => "render_planes_explodet",
	ObjectType.BIPLANE => "render_planes_biplane",
	ObjectType.MIRANDA => "render_planes_miranda",
	ObjectType.DOMB => "render_planes_bomber_bomb",
	ObjectType.HOMING_MISSLE => "render_powerups_missile",
	ObjectType.BIG_BOMB => "render_powerups_big_bomb",
];

// Sprite colours (r_g_b) of teams 3 (red) through 11 (brown), from the
// game's em.altitude.game.model.Team. Teams 0-2 are reserved and spectators.
final TEAM_COLORS = [
	"171_5_13", "30_58_206", "0_128_5", "240_166_20", "239_95_0", "115_0_214", "93_138_168", "230_118_118", "98_38_0"
];
final FIRST_TEAM = 3;

class Sprites {
	final frames:Map<String, Array<SpriteFrame>> = [];
	final textures:Map<String, Tile> = [];

	function new() {}

	/** Fetch and decode every sprite group. Rejects if they haven't been extracted. **/
	public static function load():Promise<Sprites> {
		final sprites = new Sprites();
		final groups = [for (g in SPRITE_GROUPS) g];
		return Promise.all([for (group in groups) loadGroup(sprites, group)]).then(_ -> sprites);
	}

	static function loadGroup(sprites:Sprites, group:String):Promise<Bool> {
		final root = SPRITE_ROOT + group + "/";
		return Browser.window.fetch(root + "sprite.json").then(res -> {
			if (!res.ok)
				throw 'no sprites for $group (${res.status})';
			return res.json();
		}).then((data:SpriteData) -> {
			return TexturePages.load(root, data.pages, data.images).then(textures -> {
				for (path => tile in textures)
					sprites.textures.set(path, tile);
				for (color in data.colors.keys()) {
					final frames = data.colors.get(color);
					if (frames != null)
						sprites.frames.set('$group/$color', frames);
				}
				return true;
			});
		});
	}

	/** The frame to draw for an object, with its texture, if there's a sprite for it. **/
	public function get(type:Int, team:Null<Int>, spin:Null<Int>):Null<{frame:SpriteFrame, tile:Tile}> {
		final group = SPRITE_GROUPS.get(type);
		final color = TEAM_COLORS[(team ?? -1) - FIRST_TEAM];
		if (group == null || color == null)
			return null;
		final frames = this.frames.get('$group/$color');
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
		final tile = image == null ? null : textures.get(image);
		return tile == null ? null : {frame: best, tile: tile};
	}
}

package autotude.viewer;

import js.html.TextTrackCue;
import autotude.proto.ObjectType;
import h2d.Text;
import autotude.proto.Poly;
import h3d.Matrix;
import h3d.Vector;
import haxe.Resource;
import haxe.io.BytesInput;
import autotude.proto.GameObject;
import h2d.RenderContext;
import autotude.proto.ConcaveObstacle;
import h2d.Graphics;
import h2d.Object;
import autotude.proto.MapGeometry;

class ObjectLayer extends Graphics {
	final replay:Replay;
	final geom:MapGeometry;
	final state:PlayerState;
	final polyManager:PolyManager;

	final planeGraphics:Map<Int, PlaneGraphics> = new Map();

	public function new(state:PlayerState) {
		this.replay = state.replay;
		this.geom = state.geom;
		this.state = state;
		this.polyManager = new PolyManager(new BytesInput(Resource.getBytes("polys")));
		super();
	}

	function showPoly(poly:Poly, object:GameObject) {
		polysDrawn += 1;

		var angle:Float = 0;
		if (object.angle != null) {
			angle = -Math.PI * object.angle / 1800;
		}

		var pos = new Vector(object.positionX / 2, geom.maxY - object.positionY / 2);

		final x = poly.verticesX;
		final y = poly.verticesY;

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

		for (i in 0...x.length) {
			var relative = new Vector(x[i], -y[i]);
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

			final dest = pos + relative;
			lineTo(dest.x, dest.y);
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
		final pos = new Vector(object.positionX / 2, geom.maxY - object.positionY / 2);

		if (object.type == ObjectType.BALL) {
			drawBallAt(object);
			return;
		}

		final poly = polyManager.getPoly(object.type, object.spin);
		if (poly != null) {
			showPoly(poly, object);
		} else {
			// TODO: draw marker
		}

		if (object.type <= 4) {
			getPlaneGraphics(object.owner).syncObject(object);
			planesSynced.set(object.owner, true);
			if (object.powerup == ObjectType.BALL) {
				drawBallAt(object);
			};
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

		if (object.type == 60 && poly != null) {
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
		final update = replay.updates[state.frameIdx];

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

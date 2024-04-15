package autotude.viewer;

import autotude.proto.ObjectType;
import h2d.Text;
import h3d.Vector4;
import h2d.HtmlText;
import js.html.Console;
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
			final code = replay.teams.indexOf(object.team);
			if (object.team == replay.teams[0]) {
				beginFill(0xEC8686);
			} else if (object.team == replay.teams[1]) {
				beginFill(0xAEEBAE);
			} else {
				beginFill(Viewer.BACKGROUND, 0.5);
			}
		} else {
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

	function drawObject(object:GameObject) {
		final pos = new Vector(object.positionX / 2, geom.maxY - object.positionY / 2);

		// fillStyle = C.fill;

		// Tr.tr(object.spin);
		final poly = polyManager.getPoly(object.type, object.spin);
		if (poly != null) {
			showPoly(poly, object);
		} else {
			// TODO: draw marker
		}

		// TODO: cheat on biplane bullets

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

		if (object.type == ObjectType.BALL) {}

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

		polysDrawn = 0;
		for (object in update.objects) {
			drawObject(object);
		}

		super.draw(ctx);
	}
}

package autotude.viewer;

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

class BoundLayer extends Graphics {
	final state:PlayerState;

	public function new(state:PlayerState) {
		this.state = state;
		super();
	}

	override function draw(ctx:RenderContext) {
		clear();
		if (!state.showBounds) {
			super.draw(ctx);
			return;
		}

		// map bounds
		lineStyle(1, 0x0000FF, 0.5);
		final tx = Viewer.WIDTH / 2 - state.scale * state.pos.x;
		final ty = Viewer.HEIGHT / 2 - state.scale * state.pos.y;
		drawRect(tx, ty, state.scale * state.geom.maxX, state.scale * state.geom.maxY);

		// view bounds
		lineStyle(1, 0x00FF00, 0.5);
		final rx = Viewer.WIDTH * state.scale;
		final ry = Viewer.HEIGHT * state.scale;
		drawRect((Viewer.WIDTH - rx) / 2, (Viewer.HEIGHT - ry) / 2, rx, ry);

		// center of view
		final d = 2.5;
		moveTo(Viewer.WIDTH / 2 - d, Viewer.HEIGHT / 2);
		lineTo(Viewer.WIDTH / 2 + d, Viewer.HEIGHT / 2);
		flush();
		moveTo(Viewer.WIDTH / 2, Viewer.HEIGHT / 2 - d);
		lineTo(Viewer.WIDTH / 2, Viewer.HEIGHT / 2 + d);
		flush();
		// moveTo(Viewer.WIDTH / 2 - 5, Viewer.HEIGHT / 2);
		// lineTo(Viewer.WIDTH / 2 + 10, Viewer.HEIGHT / 2);

		super.draw(ctx);
	}
}

package autotude.viewer;

import h2d.Mask;
import h2d.RenderContext;
import autotude.proto.ConcaveObstacle;
import h2d.Graphics;
import h2d.Object;
import autotude.proto.MapGeometry;

private class ObstaclePoly extends Graphics {
	public function new(ob:ConcaveObstacle, maxY:Float) {
		super();
		beginFill(Viewer.BACKGROUND);
		for (i in 0...ob.verticesX.length) {
			lineTo(ob.verticesX[i], maxY - ob.verticesY[i]);
		}
		lineTo(ob.verticesX[0], maxY - ob.verticesY[0]);
		endFill();
	}
}

class MapLayer extends Object {
	final geom:MapGeometry;

	public function new(state:PlayerState) {
		this.geom = state.geom;
		super();

		for (ob in geom.obstacles) {
			addChild(new ObstaclePoly(ob, geom.maxY));
		}
	}
}

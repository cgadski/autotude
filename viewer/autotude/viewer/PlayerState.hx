package autotude.viewer;

import js.html.Console;
import js.html.CanvasElement;
import autotude.proto.MapGeometry;
import autotude.proto.GameObject;
import autotude.proto.ObjectType;
import h2d.Scene;
import h3d.Vector;
import js.html.DivElement;

// enum {
// }
class PlayerState {
	// references
	public final s2d:Scene;
	public final replay:Replay;
	public final geom:MapGeometry;
	public final sidebar:DivElement;
	public final canvas:CanvasElement;

	public var stem:String;

	// camera
	public var pos:Vector = new Vector(0, 0);
	public var scale:Float = 1;
	public var followBall:Bool = false;
	public var showBounds:Bool = false;
	public var showMapArt:Bool = true;
	public var showPlaneBars:Bool = true;

	// scrubber
	// game tick (frame, 1/30 s) being shown, as in the "t" URL parameter
	public var frameIdx(default, set):Int = 0;
	public var framesRemaining(get, null):Int = 0;
	public var playing:Bool = false;

	public function new(s2d:Scene, sidebar:DivElement, canvas:CanvasElement, stem: String, replay:Replay, geom:MapGeometry) {
		this.s2d = s2d;
		this.stem = stem;
		this.replay = replay;
		this.geom = geom;
		this.sidebar = sidebar;
		this.canvas = canvas;

		fitView();
	}

	public function fitView() {
		pos.x = geom.maxX / 2;
		pos.y = geom.maxY / 2;
		scale = Viewer.WIDTH / geom.maxX;
		if ((canvas.clientWidth / canvas.clientHeight) >= (Viewer.WIDTH / Viewer.HEIGHT)) {
			final letterboxScaling = canvas.clientHeight / Viewer.HEIGHT;
			final desiredScaling = Math.min(canvas.clientHeight / geom.maxY, canvas.clientWidth / geom.maxX);
			scale = desiredScaling / letterboxScaling;
		}
	}

	public function followBallStep() {
		final update = replay.updates[replay.updateAt(frameIdx)];
		var holder:Null<GameObject> = null, ball:Null<GameObject> = null;
		for (o in update.objects) {
			if (o.type == ObjectType.BALL)
				ball = o;
			else if (o.type <= ObjectType.MIRANDA && o.powerup == ObjectType.BALL)
				holder = o;
		}
		final target = holder ?? ball;
		if (target == null)
			return;

		scale = 1;
		pos.x = clampCenter(target.positionX / 2, Viewer.WIDTH / 2 / scale, geom.maxX);
		pos.y = clampCenter(geom.maxY - target.positionY / 2, Viewer.HEIGHT / 2 / scale, geom.maxY);
	}

	static function clampCenter(v:Float, half:Float, max:Float):Float {
		return half * 2 >= max ? max / 2 : Math.min(max - half, Math.max(half, v));
	}

	public function togglePlay() {
		this.playing = !this.playing;
	}

	function set_frameIdx(f:Int) {
		frameIdx = f;
		boundFrame();
		return frameIdx;
	}

	function get_framesRemaining():Int {
		return replay.totalTicks - frameIdx - 1;
	}

	function boundFrame() {
		if (frameIdx >= replay.totalTicks) {
			frameIdx = replay.totalTicks - 1;
			this.playing = false;
		}
		if (frameIdx < 0) {
			frameIdx = 0;
		}
	}

	public function addTimestamp() {
		var url = new js.html.URL(js.Browser.window.location.href);
		url.searchParams.set('t', Std.string(frameIdx));
		js.Browser.window.history.pushState({}, "", url.href);
	}
}

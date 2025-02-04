package autotude.viewer;

import js.html.Console;
import js.html.CanvasElement;
import autotude.proto.MapGeometry;
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

	// camera
	public var pos:Vector = new Vector(0, 0);
	public var scale:Float = 1;
	public var showBounds:Bool = false;

	// scrubber
	public var frameIdx(default, set):Int = 0;
	public var framesRemaining(get, null):Int = 0;
	public var playing:Bool = false;

	public function new(s2d:Scene, sidebar:DivElement, canvas:CanvasElement, replay:Replay, geom:MapGeometry) {
		this.s2d = s2d;
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

	public function togglePlay() {
		this.playing = !this.playing;
	}

	function set_frameIdx(f:Int) {
		frameIdx = f;
		boundFrame();
		return frameIdx;
	}

	function get_framesRemaining():Int {
		return replay.updates.length - frameIdx - 1;
	}

	function boundFrame() {
		if (frameIdx >= replay.updates.length) {
			frameIdx = replay.updates.length - 1;
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

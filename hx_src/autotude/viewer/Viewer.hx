package autotude.viewer;

import js.html.URLSearchParams;
import js.html.CanvasElement;
import js.html.SpanElement;
import js.html.InputElement;
import js.html.Console;
import hxd.Key;
import js.html.DivElement;
import h2d.Scene;
import hxd.Event;
import h2d.Interactive;
import h3d.Vector;
import h3d.Engine;
import haxe.io.BytesInput;
import haxe.io.Bytes;
import js.Browser;

final WIDTH = 1280;
final HEIGHT = 720;
final BACKGROUND = 0xA9A7A7;
final SCALE_MIN = 0.2;
final SCALE_MAX = 1.5;

inline function getElem(id:String) {
	return Browser.document.getElementById(id);
}

class Viewer extends hxd.App {
	var playerState:Null<PlayerState>;
	var game:Null<Game>;

	var draggable:Null<Interactive>;
	final bindings = new Bindings();

	final sidebar:DivElement = cast getElem("sidebar");
	final help:DivElement = cast getElem("help");
	final scoreboard:DivElement = cast getElem("scoreboard");

	final scrubber:InputElement = cast getElem("scrubber");
	final timeBefore:SpanElement = cast getElem("time_before");
	final timeAfter:SpanElement = cast getElem("time_after");
	final canvas:CanvasElement = cast getElem("webgl");

	public function new() {
		super();
		scrubber.oninput = onScrubberInput;

		registerBindings();
		bindings.renderCard(help);

		// help.classList.toggle("show");
		scoreboard.classList.toggle("show");

		sidebar.addEventListener("wheel", (e:js.html.WheelEvent) -> {
			e.stopPropagation();
		}, {passive: true});
	}

	override function init() {
		engine.backgroundColor = BACKGROUND;
		s2d.scaleMode = LetterBox(WIDTH, HEIGHT, false, Center, Center);

		draggable = new Interactive(s2d.width, s2d.height, s2d);
		draggable.onPush = onPush;
		draggable.onRelease = onRelease;
		draggable.onWheel = onWheel;

		// load map
		var urlParams = new URLSearchParams(Browser.window.location.search);
		var recordingFile = urlParams.get("f");
		final request = Browser.window.fetch("/recordings/" + recordingFile);
		final timestamp = urlParams.get("t");

		request.then((res) -> {
			res.arrayBuffer().then((buf) -> {
				final replay = new Replay(new BytesInput(Bytes.ofData(buf)));
				if (replay != null && replay.mapGeometry != null) {
					this.playerState = new PlayerState(s2d, sidebar, canvas, replay, replay.mapGeometry);
					if (timestamp != null) {
						playerState.frameIdx = Std.parseInt(timestamp) ?? 0;
					}
					s2d.addChild(game = new Game(playerState));

					scrubber.min = "0";
					scrubber.max = Std.string(replay.updates.length - 1);
					scrubber.removeAttribute("disabled");
				}
			});
		});
	}

	// dragging scrubber
	function onScrubberInput(e:js.html.Event) {
		if (playerState == null)
			return;

		final val:Int = Std.int(untyped e.target.value);
		playerState.frameIdx = val;
	}

	// dragging / zooming the map
	var dragStart:Null<Vector>;
	var dragPosStart:Null<Vector>;

	function onWheel(e:Event) {
		if (playerState == null)
			return;

		playerState.scale *= Math.exp(e.wheelDelta);
		playerState.scale = Math.max(SCALE_MIN, playerState.scale);
		playerState.scale = Math.min(SCALE_MAX, playerState.scale);
	}

	function onPush(e:Event) {
		if (draggable == null || playerState == null)
			return;

		draggable.startCapture(onDrag);
		dragStart = new Vector(e.relX, e.relY);
		dragPosStart = playerState.pos.clone();
	}

	function onRelease(e:Event) {
		if (draggable == null)
			return;
		draggable.stopCapture();
	}

	function onDrag(e:Event) {
		if (dragStart == null || dragPosStart == null || playerState == null)
			return;
		if (e.kind != EMove)
			return;

		final newPos = new Vector(e.relX, e.relY);
		playerState.pos = (1 / playerState.scale) * (dragStart - newPos) + dragPosStart;
	}

	var netTime:Float = 0;
	final frameTime:Float = 1 / 30;

	override function update(dt:Float) {
		bindings.update();
		if (playerState != null) {
			if (playerState.playing) {
				netTime += dt;
				final steps = Std.int(netTime / frameTime);
				playerState.frameIdx += steps;
				netTime -= frameTime * steps;
			} else {
				netTime = 0;
			}

			timeBefore.innerHTML = Replay.showTimestampHtml(playerState.frameIdx);
			timeAfter.innerHTML = Replay.showTimestampHtml(playerState.framesRemaining);
			scrubber.value = Std.string(playerState.frameIdx);
		}
	}

	function registerBindings() {
		final r = bindings.register;
		final n = (cb:(PlayerState) -> Void) -> {
			if (playerState != null)
				cb(playerState);
		}

		r("Toggle help", [Key.H], () -> {
			help.classList.toggle("show");
		});

		r("Toggle sidebar", [Key.S], () -> {
			sidebar.classList.toggle("show");
		});

		r("Play / pause", [Key.K], () -> {
			n((s) -> s.togglePlay());
		});

		r("Play / pause", [Key.SPACE], () -> {
			n((s) -> s.togglePlay());
		});

		r("→ 2 seconds", [Key.SHIFT, Key.L], () -> {
			n((s) -> s.frameIdx += 60);
		});

		r("← 2 seconds", [Key.SHIFT, Key.J], () -> {
			n((s) -> s.frameIdx -= 60);
		});

		r("→ one frame ", [Key.CTRL, Key.L], () -> {
			n((s) -> s.frameIdx += 1);
		});

		r("← one frame", [Key.CTRL, Key.J], () -> {
			n((s) -> s.frameIdx -= 1);
		});

		r("→ 1/3 seconds", [Key.L], () -> {
			n((s) -> s.frameIdx += 10);
		});

		r("← 1/3 seconds", [Key.J], () -> {
			n((s) -> s.frameIdx -= 10);
		});

		r("Fit map to screen", [Key.F], () -> {
			n((s) -> s.fitView());
		});

		r("Zoom to in-game vision", [Key.Z], () -> {
			n((s) -> s.scale = 1);
		});

		r("Toggle bounds", [Key.B], () -> {
			n((s) -> s.showBounds = !s.showBounds);
		});

		r("Add timestamp to URL", [Key.T], () -> {
			n((s) -> s.addTimestamp());
		});
	}

	override function onResize() {
		if (draggable == null)
			return;
		draggable.width = s2d.width;
		draggable.height = s2d.height;
	}

	static function main() {
		Engine.ANTIALIASING = 1;
		Key.ALLOW_KEY_REPEAT = true;

		new Viewer();
	}
}

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
// outside the map, matching the page
final PAGE_BACKGROUND = 0x15171C;
final SCALE_MIN = 0.2;
final SCALE_MAX = 1.5;
// zoom factor per mouse wheel notch
final ZOOM_PER_NOTCH = 1.15;

// where the volume slider's level is remembered (localStorage)
final VOLUME_KEY = "autotude-viewer-volume";

// a phone (or any touch screen): tap plays/pauses, dragging seeks and the
// camera follows the ball
final PHONE_UA = ~/Android|iPhone|iPad|iPod|IEMobile|Opera Mini|Mobile/;
// a full screen width of dragging seeks this many ticks (30s)
final PHONE_SEEK_TICKS_PER_WIDTH = 900;
// dragging this far (s2d units) seeks; less counts as a tap
final PHONE_TAP_SLOP = 20;

// the playback icons that flash over the game when it's toggled
final PLAY_ICON = '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>';
final PAUSE_ICON = '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M6 5h4v14H6zM14 5h4v14h-4z"/></svg>';

function phoneMode():Bool {
	if (Browser.window.location.search.indexOf("phone") >= 0)
		return true;
	return PHONE_UA.match(Browser.navigator.userAgent)
		|| js.Syntax.code("window.matchMedia('(pointer: coarse)').matches");
}

inline function getElem(id:String) {
	return Browser.document.getElementById(id);
}

class Viewer extends hxd.App {
	var playerState:Null<PlayerState>;
	var game:Null<Game>;

	var draggable:Null<Interactive>;
	final bindings = new Bindings();
	final sound = new Sound();
	var score:Null<Scoreboard>;

	final sidebar:DivElement = cast getElem("sidebar");
	final help:DivElement = cast getElem("help");
	final scoreboard:DivElement = cast getElem("scoreboard");

	final scrubber:InputElement = cast getElem("scrubber");
	final timeBefore:SpanElement = cast getElem("time_before");
	final timeAfter:SpanElement = cast getElem("time_after");
	final playButton:js.html.ButtonElement = cast getElem("play");
	final speedSelect:js.html.SelectElement = cast getElem("speed");
	final muteButton:js.html.ButtonElement = cast getElem("mute");
	final volumeSlider:InputElement = cast getElem("volume");
	final fullscreenButton:js.html.ButtonElement = cast getElem("fullscreen");
	final canvas:CanvasElement = cast getElem("webgl");

	// playback speed, from the speed selector
	var speed:Float = 1;
	var showingPlaying:Null<Bool>;

	// dragging / seeking on the game (phone mode)
	final tapAt = new Vector(0, 0);
	var seekFrom = 0;
	var seeking = false;
	var scrubbing = false;
	var seekWasPlaying = false;
	var seekShownUntil = 0.0;

	final seekBar:DivElement = cast getElem("seek");
	final seekFill:DivElement = cast getElem("seek-fill");
	final seekTime:SpanElement = cast getElem("seek-time");
	final flash:DivElement = cast getElem("flash");

	public function new() {
		super();
		scrubber.oninput = onScrubberInput;
		playButton.onclick = () -> {
			if (playerState != null)
				playerState.togglePlay();
			playButton.blur(); // keep Space for the viewer's own binding
		};
		fullscreenButton.onclick = () -> {
			toggleFullscreen();
			fullscreenButton.blur();
		};
		// Esc also leaves full screen, so follow the browser's state
		Browser.document.addEventListener("fullscreenchange", () -> {
			fullscreenButton.title = Browser.document.fullscreenElement == null ? "Full screen (Shift + F)" : "Exit full screen (Shift + F)";
		});
		muteButton.onclick = () -> {
			toggleSound();
			muteButton.blur();
		};
		// the volume is remembered in this browser, if it allows storage
		try {
			final saved = Browser.window.localStorage.getItem(VOLUME_KEY);
			if (saved != null)
				volumeSlider.value = saved;
		} catch (_) {}
		setVolume();
		volumeSlider.oninput = () -> {
			setVolume();
			try {
				Browser.window.localStorage.setItem(VOLUME_KEY, volumeSlider.value);
			} catch (_) {}
		};
		volumeSlider.onchange = () -> volumeSlider.blur();
		speedSelect.onchange = () -> {
			speed = Std.parseFloat(speedSelect.value);
			if (Math.isNaN(speed))
				speed = 1;
			speedSelect.blur();
		};

		registerBindings();
		bindings.renderCard(help);

		// help.classList.toggle("show");
		scoreboard.classList.toggle("show");

		sidebar.addEventListener("wheel", (e:js.html.WheelEvent) -> {
			e.stopPropagation();
		}, {passive: true});
	}

	override function init() {
		engine.backgroundColor = PAGE_BACKGROUND;
		s2d.scaleMode = LetterBox(WIDTH, HEIGHT, false, Center, Center);

		draggable = new Interactive(s2d.width, s2d.height, s2d);
		if (phoneMode()) {
			Browser.document.body.classList.add("phone");
			// no page scrolling: a drag on the game doesn't scroll Safari and
			// bring its URL bar back
			Browser.document.addEventListener("touchmove", (e:js.html.Event) -> e.preventDefault(), {passive: false});
			// touches on the seek bar are the bar's alone; the game's gestures
			// listen on the window, so don't let the bar's events reach them
			for (kind in ["mousedown", "mousemove", "mouseup", "touchstart", "touchmove", "touchend"])
				seekBar.addEventListener(kind, (e:js.html.Event) -> e.stopPropagation());
			// the seek bar stays open while paused; drag it to set the time
			seekBar.addEventListener("pointerdown", (e:js.html.PointerEvent) -> {
				if (playerState == null)
					return;
				scrubbing = true;
				seekBar.setPointerCapture(e.pointerId);
				scrubTo(e.clientX);
			});
			seekBar.addEventListener("pointermove", (e:js.html.PointerEvent) -> {
				if (scrubbing)
					scrubTo(e.clientX);
			});
			seekBar.addEventListener("pointerup", (e:js.html.PointerEvent) -> {
				scrubbing = false;
				seekBar.releasePointerCapture(e.pointerId);
			});
			seekBar.addEventListener("pointercancel", (_) -> scrubbing = false);
			draggable.onPush = onPhonePush;
			draggable.onRelease = onPhoneRelease;
		} else {
			draggable.onPush = onPush;
			draggable.onRelease = onRelease;
			draggable.onWheel = onWheel;
		}

		// load map
		var urlParams = new URLSearchParams(Browser.window.location.search);
		var recordingFile = urlParams.get("f");
		final request = Browser.window.fetch("/recordings/" + recordingFile);
		final timestamp = urlParams.get("t");

		request.then((res) -> {
			res.arrayBuffer().then((buf) -> {
				final replay = new Replay(new BytesInput(Bytes.ofData(buf)));
				if (replay != null && replay.mapGeometry != null) {
					final stem = ~/\.pb$/.replace(recordingFile ?? "", "");
					this.playerState = new PlayerState(s2d, sidebar, canvas, stem, replay, replay.mapGeometry);
					score = new Scoreboard(replay, scoreboard);
					if (timestamp != null) {
						playerState.frameIdx = Std.parseInt(timestamp) ?? 0;
					}
					if (phoneMode())
						playerState.followBall = true;
					// optional camera: map pixels from the top-left, and zoom (1 = in game)
					final x = Std.parseFloat(urlParams.get("x") ?? ""), y = Std.parseFloat(urlParams.get("y") ?? "");
					final zoom = Std.parseFloat(urlParams.get("zoom") ?? "");
					if (!Math.isNaN(x) && !Math.isNaN(y)) {
						playerState.pos.x = x;
						playerState.pos.y = y;
					}
					if (!Math.isNaN(zoom))
						playerState.scale = Math.min(SCALE_MAX, Math.max(SCALE_MIN, zoom));
					s2d.addChild(game = new Game(playerState));

					scrubber.min = "0";
					scrubber.max = Std.string(replay.totalTicks - 1);
					scrubber.removeAttribute("disabled");
					playButton.disabled = false;
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
		playerState.followBall = false;

		// wheel up (negative delta) zooms in. heaps gives deltaY / 120, and a
		// wheel notch is usually 100px of deltaY.
		final notches = e.wheelDelta * 120 / 100;
		final before = playerState.scale;
		var after = before * Math.pow(ZOOM_PER_NOTCH, -notches);
		after = Math.min(SCALE_MAX, Math.max(SCALE_MIN, after));

		// zoom toward the cursor: keep the map point under it where it is.
		// The view centre (WIDTH / 2, HEIGHT / 2) shows playerState.pos.
		final offX = e.relX - WIDTH / 2, offY = e.relY - HEIGHT / 2;
		playerState.pos.x += offX / before - offX / after;
		playerState.pos.y += offY / before - offY / after;
		playerState.scale = after;
	}

	function onPush(e:Event) {
		if (draggable == null || playerState == null)
			return;

		playerState.followBall = false;
		draggable.startCapture(onDrag);
		dragStart = new Vector(e.relX, e.relY);
		dragPosStart = playerState.pos.clone();
	}

	function onRelease(e:Event) {
		if (draggable == null)
			return;
		draggable.stopCapture();
	}

	// Phone mode: a tap plays/pauses, a horizontal drag seeks.
	function onPhonePush(e:Event) {
		final draggable = this.draggable;
		if (draggable == null)
			return;
		tapAt.set(e.relX, e.relY);
		seekFrom = playerState == null ? 0 : playerState.frameIdx;
		seekWasPlaying = playerState != null && playerState.playing;
		seeking = false;
		draggable.startCapture(onPhoneDrag);
	}

	function onPhoneDrag(e:Event) {
		if (e.kind != EMove || playerState == null)
			return;
		final dx = e.relX - tapAt.x;
		if (!seeking) {
			if (Math.abs(dx) < PHONE_TAP_SLOP)
				return;
			seeking = true;
			playerState.playing = false;
			seekShownUntil = 0;
			updateSeekVisibility();
		}
		playerState.frameIdx = seekFrom + Math.round(dx / s2d.width * PHONE_SEEK_TICKS_PER_WIDTH);
		updateSeekIndicator();
	}

	function onPhoneRelease(e:Event) {
		if (draggable == null)
			return;
		draggable.stopCapture();
		final state = playerState;
		if (state == null)
			return;
		if (seeking) {
			state.playing = seekWasPlaying;
			seeking = false;
			if (state.playing) {
				seekShownUntil = haxe.Timer.stamp() + 0.8;
			} else {
				// paused: keep the bar open
				seekShownUntil = 0;
				updateSeekVisibility();
			}
		} else if (Math.pow(e.relX - tapAt.x, 2) + Math.pow(e.relY - tapAt.y, 2) < PHONE_TAP_SLOP * PHONE_TAP_SLOP) {
			state.togglePlay();
			showFlash(state.playing);
		}
	}

	// flash a play or pause icon over the game
	function showFlash(playing:Bool) {
		flash.innerHTML = playing ? PAUSE_ICON : PLAY_ICON;
		flash.classList.remove("show");
		js.Syntax.code("void {0}.offsetWidth", flash); // restart the animation
		flash.classList.add("show");
	}

	function updateSeekIndicator() {
		final state = playerState;
		if (state == null)
			return;
		seekTime.textContent = Replay.showTimestamp(state.frameIdx) + " / " + Replay.showTimestamp(state.replay.totalTicks);
		final total = state.replay.totalTicks - 1;
		seekFill.style.width = (total > 0 ? 100 * state.frameIdx / total : 0) + "%";
	}

	// set the time from a touch on the seek bar
	function scrubTo(clientX:Float) {
		final state = playerState;
		if (state == null)
			return;
		final rect = seekBar.getBoundingClientRect();
		final total = state.replay.totalTicks - 1;
		final fraction = Math.min(1, Math.max(0, (clientX - rect.left) / Math.max(1, rect.width)));
		state.frameIdx = Math.round(fraction * total);
		updateSeekIndicator();
	}

	// the seek bar shows while seeking, scrubbing, or paused
	function updateSeekVisibility() {
		final state = playerState;
		final show = phoneMode() && (seeking || scrubbing || (state != null && !state.playing));
		if (show)
			updateSeekIndicator();
		seekBar.classList.toggle("show", show);
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
		// hide the seek bar a moment after seeking ends, unless paused
		if (seekShownUntil > 0 && haxe.Timer.stamp() > seekShownUntil) {
			seekShownUntil = 0;
			updateSeekVisibility();
		}
		if (playerState != null) {

			if (playerState.playing) {
				netTime += dt * speed;
				final steps = Std.int(netTime / frameTime);
				playerState.frameIdx += steps;
				netTime -= frameTime * steps;
			} else {
				netTime = 0;
			}

			if (showingPlaying != playerState.playing) {
				showingPlaying = playerState.playing;
				playButton.innerHTML = playerState.playing ? "&#10074;&#10074;" : "&#9654;";
				updateSeekVisibility();
			}
			timeBefore.innerHTML = Replay.showTimestampHtml(playerState.frameIdx);
			timeAfter.innerHTML = Replay.showTimestampHtml(playerState.framesRemaining);
			scrubber.value = Std.string(playerState.frameIdx);
			final game = this.game;
			if (game != null)
				sound.update(playerState, game.timeline);
			final score = this.score;
			if (score != null)
				score.update(playerState.frameIdx);
		}
	}

	// The whole page (map, timeline and panels) goes full screen.
	function toggleFullscreen() {
		final doc = Browser.document;
		if (doc.fullscreenElement == null)
			doc.documentElement.requestFullscreen();
		else
			doc.exitFullscreen();
	}

	function toggleSound() {
		sound.enabled = !sound.enabled;
		showSoundState();
	}

	// Volume slider (0-100) to the sound system; moving it also unmutes.
	function setVolume() {
		final v = Std.parseFloat(volumeSlider.value);
		sound.volume = Math.isNaN(v) ? 1 : v / 100;
		if (sound.volume > 0)
			sound.enabled = true;
		showSoundState();
	}

	function showSoundState() {
		muteButton.innerHTML = !sound.enabled || sound.volume == 0 ? "&#128263;" : "&#128266;";
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

		// before plain F, so Shift + F isn't taken as F
		r("Full screen", [Key.SHIFT, Key.F], () -> {
			toggleFullscreen();
		});
		r("Fit map to screen", [Key.F], () -> {
			n((s) -> s.fitView());
		});

		r("Zoom to in-game vision", [Key.Z], () -> {
			n((s) -> s.scale = 1);
		});

		r("Follow the spectated camera", [Key.C], () -> {
			n((s) -> s.followBall = !s.followBall);
		});

		r("Toggle bounds", [Key.B], () -> {
			n((s) -> s.showBounds = !s.showBounds);
		});
		r("Toggle game artwork", [Key.M], () -> {
			n((s) -> s.showMapArt = !s.showMapArt);
		});
		r("Toggle health and energy bars", [Key.E], () -> {
			n((s) -> s.showPlaneBars = !s.showPlaneBars);
		});

		r("Toggle plane controls", [Key.O], () -> {
			n((s) -> s.showControls = !s.showControls);
		});
		r("Toggle sound", [Key.N], () -> {
			toggleSound();
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

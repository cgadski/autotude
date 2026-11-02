package autotude.viewer;

import h2d.RenderContext;
import h3d.Vector4;
import h2d.Text;
import autotude.proto.GameObject;
import h2d.Graphics;

class PlaneGraphics extends Graphics {
	final replay:Replay;
	final state:PlayerState;
	final nickname:Text;

	var object:Null<GameObject> = null;

	public function new(state:PlayerState) {
		super();
		this.replay = state.replay;
		this.state = state;

		var font:h2d.Font = hxd.res.DefaultFont.get();
		nickname = new h2d.Text(font);
		nickname.textAlign = Center;
		// readable on both dark map artwork and the plain white background
		nickname.textColor = 0xFFFFFF;
		nickname.dropShadow = {
			dx: 1,
			dy: 1,
			color: 0x000000,
			alpha: 0.9
		};
		nickname.scaleX = 1.5;
		nickname.scaleY = 1.5;
		nickname.y = 15;

		addChild(nickname);
	}

	public function syncObject(object:GameObject) {
		this.object = object;

		x = object.positionX / 2;
		y = replay.mapGeometry.maxY - object.positionY / 2;

		nickname.text = replay.gameStates[replay.updateAt(state.frameIdx)].getName(object.owner);
	}

	// A plane's pressed controls, drawn below it as little orange marks: an
	// arrow per direction (left, right, up, down, as in the controls bitmask),
	// then a dot for primary, a ring for secondary and a diamond for powerup.
	// Slots are fixed, so a press shows up as its mark appearing in place.
	static final CONTROL_COLOR = 0xFF8000;
	static final CONTROL_ALPHA = 0.9;
	static final CONTROL_SPACING = 12.0;
	static final CONTROL_OFFSET_Y = 42.0;

	// The controls bitmask's bits, in order (as ProtobufWriter.recordControls):
	// left, right, up, down, primary, secondary, powerup.
	static final CONTROL_ARROWS = [Math.PI, 0.0, -Math.PI / 2, Math.PI / 2];

	override function draw(ctx:RenderContext) {
		clear();

		final barHeight = 8;
		var yOffset = -40;

		if (object != null && state.showPlaneBars) {
			// energy
			beginFill(0x324AD0);
			final ammo = object.ammo / 1000;
			drawRect(-40, yOffset, ammo * 80, 8);

			// health
			yOffset -= barHeight;
			beginFill(0x13AB43);
			final health = object.health / 1000;
			drawRect(-40, yOffset, health * 80, 8);
			beginFill(0xBCFFD1);
			final healthRestore = object.healthRestore / 1000;
			drawRect(-40 + health * 80, yOffset, healthRestore * 80, 8);

			// throttle
			yOffset -= barHeight;
			beginFill(0xEB7115);
			final throttle = object.throttle / 1000;
			drawRect(-40, yOffset, throttle * 80, 8);
		}

		if (object != null && state.showControls && object.controls != null)
			drawControls(object.controls);

		super.draw(ctx);
	}

	function drawControls(controls:Int) {
		for (i in 0...7) {
			if ((controls & (1 << i)) == 0)
				continue;
			final x = (i - 3) * CONTROL_SPACING, y = CONTROL_OFFSET_Y;
			if (i < 4)
				drawArrow(x, y, CONTROL_ARROWS[i]);
			else if (i == 4)
				drawDot(x, y);
			else if (i == 5)
				drawRing(x, y);
			else
				drawDiamond(x, y);
		}
	}

	// An arrow at (x, y) pointing along `angle` from its tip.
	function drawArrow(x:Float, y:Float, angle:Float) {
		final pts = [5.0, 0.0, -1.0, -3.5, -1.0, -1.5, -4.5, -1.5, -4.5, 1.5, -1.0, 1.5, -1.0, 3.5];
		final cos = Math.cos(angle), sin = Math.sin(angle);
		beginFill(CONTROL_COLOR, CONTROL_ALPHA);
		var i = 0;
		while (i < pts.length) {
			final px = pts[i], py = pts[i + 1];
			final sx = x + px * cos - py * sin;
			final sy = y + px * sin + py * cos;
			if (i == 0)
				moveTo(sx, sy)
			else
				lineTo(sx, sy);
			i += 2;
		}
		endFill();
	}

	function drawDot(x:Float, y:Float) {
		beginFill(CONTROL_COLOR, CONTROL_ALPHA);
		drawCircle(x, y, 2.5);
		endFill();
	}

	function drawRing(x:Float, y:Float) {
		lineStyle(1.5, CONTROL_COLOR, CONTROL_ALPHA);
		drawCircle(x, y, 2.5);
		lineStyle(0, 0, 0);
	}

	function drawDiamond(x:Float, y:Float) {
		beginFill(CONTROL_COLOR, CONTROL_ALPHA);
		moveTo(x, y - 3.5);
		lineTo(x + 3.5, y);
		lineTo(x, y + 3.5);
		lineTo(x - 3.5, y);
		endFill();
	}
}

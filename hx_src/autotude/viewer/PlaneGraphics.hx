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
		nickname.textColor = 0x000000;
		nickname.scaleX = 1.5;
		nickname.scaleY = 1.5;
		nickname.y = 15;

		addChild(nickname);
	}

	public function syncObject(object:GameObject) {
		this.object = object;

		x = object.positionX / 2;
		y = replay.mapGeometry.maxY - object.positionY / 2;

		nickname.text = replay.gameStates[state.frameIdx].getName(object.owner);
	}

	override function draw(ctx:RenderContext) {
		clear();

		final barHeight = 8;
		var yOffset = -40;

		if (object != null) {
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

		super.draw(ctx);
	}
}

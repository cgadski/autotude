package autotude.viewer;

import h2d.Text;
import autotude.proto.GameObject;
import h2d.Graphics;

class PlaneGraphics extends Graphics {
	final replay:Replay;
	final state:PlayerState;
	final nickname:Text;

	public function new(state:PlayerState) {
		super();
		this.replay = state.replay;
		this.state = state;

		var font:h2d.Font = hxd.res.DefaultFont.get();
		nickname = new h2d.Text(font);
		nickname.textAlign = Center;
		addChild(nickname);
	}

	public function syncObject(object:GameObject) {
		nickname.text = replay.gameStates[state.frameIdx].getName(object.owner);
		nickname.x = object.positionX / 2;
		nickname.y = replay.mapGeometry.maxY - object.positionY / 2;
	}
}

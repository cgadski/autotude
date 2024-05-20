package autotude.viewer;

import js.html.SpanElement;
import autotude.Replay.showTimestampHtml;
import autotude.proto.GameEvent;
import protohx.Protohx.PT_Int64;
import js.html.AnchorElement;
import js.Browser;
import js.html.Document;
import js.html.ParagraphElement;
import haxe.Int64;
import js.html.DivElement;
import h2d.Mask;
import h2d.RenderContext;
import autotude.proto.ConcaveObstacle;
import h2d.Graphics;
import h2d.Object;
import autotude.proto.MapGeometry;

class Game extends Object {
	final replay:Replay;
	final geom:MapGeometry;

	final state:PlayerState;

	final mapMask:Object;
	final boundLayer:Graphics;

	final mapLayer:MapLayer;
	final objectLayer:ObjectLayer;

	final sidebarEntries:Map<Int, ParagraphElement> = new Map();

	public function new(state:PlayerState) {
		this.replay = state.replay;
		this.geom = state.geom;
		this.state = state;
		super();

		final mapGeometry:MapGeometry = cast replay.mapGeometry;

		final background = new Graphics();
		background.beginFill(0xFFFFFF);
		background.drawRect(0, 0, mapGeometry.maxX, mapGeometry.maxY);
		background.endFill();

		boundLayer = new BoundLayer(state);
		mapLayer = new MapLayer(state);
		objectLayer = new ObjectLayer(state);

		mapMask = new Mask(mapGeometry.maxX, mapGeometry.maxY);

		mapMask.addChild(background);
		mapMask.addChild(mapLayer);
		mapMask.addChild(objectLayer);

		addChild(mapMask);
		addChild(boundLayer);

		loadSidebar();
	}

	static function sidebarEntry(time: Int, cb: (SpanElement) -> Void): ParagraphElement {
		final elem = Browser.document.createParagraphElement();
		final anchor = Browser.document.createAnchorElement();
		final span = Browser.document.createSpanElement();
		elem.appendChild(anchor);
		elem.appendChild(span);
		anchor.innerHTML = showTimestampHtml(time);
		anchor.href = "#";
		cb(span);
		return elem;
	}

	function loadSidebar() {
		final sidebar = state.sidebar;

		sidebar.appendChild(sidebarEntry(0, (span) -> span.innerText = 'map: ${replay.mapName}'));

		for (update in replay.updates) {
			for (event in update.events) {
				// final entry = sidebarEntry(update.time, event);
				// if (entry != null) {
				// 	sidebar.appendChild(entry);
				// 	entries.set(update.time, entry);
				// }
				// if (event.hasChat()) {
				// 	final message = event.chat.message;
				// 	final sender = event.chat.sender;
				// 	sidebar.appendChild(sidebarEntry('$sender: $message'));
				// }
			}
		}
	}

	override function sync(ctx:RenderContext) {
		// objective is to make trans + scale * pos = view / 2
		// so trans = view / 2 - scale * pos
		final tx = Viewer.WIDTH / 2 - state.scale * state.pos.x;
		final ty = Viewer.HEIGHT / 2 - state.scale * state.pos.y;

		mapMask.setPosition(tx, ty);
		mapMask.setScale(state.scale);

		super.sync(ctx);
	}

	override function draw(ctx:RenderContext) {
		super.draw(ctx);
	}
}

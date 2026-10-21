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

	final sidebarManager:SidebarManager;

	final boundLayer:Graphics;
	final mapLayer:MapLayer;
	final objectLayer:ObjectLayer;

	final mapMask:Object;

	// map artwork, filled in once loaded
	final background:Graphics;
	final artBack = new Object();
	final artFront = new Object();
	var art:Null<MapArt>;
	var showingArt = false;

	public function new(state:PlayerState) {
		this.replay = state.replay;
		this.geom = state.geom;
		this.state = state;
		super();

		final mapGeometry:MapGeometry = cast replay.mapGeometry;

		sidebarManager = new SidebarManager(state);

		background = new Graphics();

		boundLayer = new BoundLayer(state);
		mapLayer = new MapLayer(state);
		objectLayer = new ObjectLayer(state);

		mapMask = new Mask(mapGeometry.maxX, mapGeometry.maxY);
		drawBackground(0xFFFFFF);
		mapMask.addChild(background);
		mapMask.addChild(artBack);
		mapMask.addChild(mapLayer);
		mapMask.addChild(objectLayer);
		mapMask.addChild(artFront);

		addChild(mapMask);
		addChild(boundLayer);

		if (replay.mapName != null)
			MapArt.load(state, replay.mapName).then(onArtLoaded, e -> js.html.Console.warn(e));
		Sprites.load().then(onSpritesLoaded, e -> js.html.Console.warn(e));
	}

	function onArtLoaded(art:MapArt) {
		this.art = art;
		for (view in art.back)
			artBack.addChild(view);
		for (view in art.front)
			artFront.addChild(view);
	}

	function onSpritesLoaded(sprites:Sprites) {
		objectLayer.sprites = sprites;
	}

	function drawBackground(color:Int) {
		background.clear();
		background.beginFill(color);
		background.drawRect(0, 0, geom.maxX, geom.maxY);
		background.endFill();
	}

	// Show either the map's artwork or the plain obstacle outlines.
	function updateArtVisibility() {
		final art = this.art;
		final show = art != null && state.showMapArt;
		artBack.visible = artFront.visible = show;
		mapLayer.visible = !show;
		if (show != showingArt)
			drawBackground(art != null && show ? art.background : 0xFFFFFF);
		showingArt = show;
	}

	override function sync(ctx:RenderContext) {
		// objective is to make trans + scale * pos = view / 2
		// so trans = view / 2 - scale * pos
		final tx = Viewer.WIDTH / 2 - state.scale * state.pos.x;
		final ty = Viewer.HEIGHT / 2 - state.scale * state.pos.y;

		mapMask.setPosition(tx, ty);
		mapMask.setScale(state.scale);
		updateArtVisibility();

		super.sync(ctx);
	}

	override function draw(ctx:RenderContext) {
		super.draw(ctx);
	}
}

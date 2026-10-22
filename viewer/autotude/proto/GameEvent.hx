package autotude.proto;
import protohx.Protohx;
class GameEvent extends protohx.Message {

	/** LABEL_OPTIONAL chat : TYPE_MESSAGE = 1 */
	@:isVar public var chat(get, set):ChatEvent;
	public inline function setChat(value:ChatEvent):GameEvent{
		this.chat = value;
		return this;
	}

	public function clearChat():Void {
		this.chat = null;
	}

	inline public function hasChat():Bool {
		return this.chat != null;
	}

	public function set_chat(value:ChatEvent):ChatEvent{
		return this.chat = value;
	}

	public function get_chat():ChatEvent {
		return this.chat;
	}


	/** LABEL_OPTIONAL map_load : TYPE_MESSAGE = 2 */
	@:isVar public var mapLoad(get, set):MapLoadEvent;
	public inline function setMapLoad(value:MapLoadEvent):GameEvent{
		this.mapLoad = value;
		return this;
	}

	public function clearMapLoad():Void {
		this.mapLoad = null;
	}

	inline public function hasMapLoad():Bool {
		return this.mapLoad != null;
	}

	public function set_mapLoad(value:MapLoadEvent):MapLoadEvent{
		return this.mapLoad = value;
	}

	public function get_mapLoad():MapLoadEvent {
		return this.mapLoad;
	}


	/** LABEL_OPTIONAL set_player : TYPE_MESSAGE = 3 */
	@:isVar public var setPlayer(get, set):SetPlayerEvent;
	public inline function setSetPlayer(value:SetPlayerEvent):GameEvent{
		this.setPlayer = value;
		return this;
	}

	public function clearSetPlayer():Void {
		this.setPlayer = null;
	}

	inline public function hasSetPlayer():Bool {
		return this.setPlayer != null;
	}

	public function set_setPlayer(value:SetPlayerEvent):SetPlayerEvent{
		return this.setPlayer = value;
	}

	public function get_setPlayer():SetPlayerEvent {
		return this.setPlayer;
	}


	/** LABEL_OPTIONAL remove_player : TYPE_MESSAGE = 4 */
	@:isVar public var removePlayer(get, set):RemovePlayerEvent;
	public inline function setRemovePlayer(value:RemovePlayerEvent):GameEvent{
		this.removePlayer = value;
		return this;
	}

	public function clearRemovePlayer():Void {
		this.removePlayer = null;
	}

	inline public function hasRemovePlayer():Bool {
		return this.removePlayer != null;
	}

	public function set_removePlayer(value:RemovePlayerEvent):RemovePlayerEvent{
		return this.removePlayer = value;
	}

	public function get_removePlayer():RemovePlayerEvent {
		return this.removePlayer;
	}


	/** LABEL_OPTIONAL goal : TYPE_MESSAGE = 6 */
	@:isVar public var goal(get, set):GoalEvent;
	public inline function setGoal(value:GoalEvent):GameEvent{
		this.goal = value;
		return this;
	}

	public function clearGoal():Void {
		this.goal = null;
	}

	inline public function hasGoal():Bool {
		return this.goal != null;
	}

	public function set_goal(value:GoalEvent):GoalEvent{
		return this.goal = value;
	}

	public function get_goal():GoalEvent {
		return this.goal;
	}


	/** LABEL_OPTIONAL kill : TYPE_MESSAGE = 7 */
	@:isVar public var kill(get, set):KillEvent;
	public inline function setKill(value:KillEvent):GameEvent{
		this.kill = value;
		return this;
	}

	public function clearKill():Void {
		this.kill = null;
	}

	inline public function hasKill():Bool {
		return this.kill != null;
	}

	public function set_kill(value:KillEvent):KillEvent{
		return this.kill = value;
	}

	public function get_kill():KillEvent {
		return this.kill;
	}


	/** LABEL_OPTIONAL damage : TYPE_MESSAGE = 8 */
	@:isVar public var damage(get, set):DamageEvent;
	public inline function setDamage(value:DamageEvent):GameEvent{
		this.damage = value;
		return this;
	}

	public function clearDamage():Void {
		this.damage = null;
	}

	inline public function hasDamage():Bool {
		return this.damage != null;
	}

	public function set_damage(value:DamageEvent):DamageEvent{
		return this.damage = value;
	}

	public function get_damage():DamageEvent {
		return this.damage;
	}


	/** LABEL_OPTIONAL meta : TYPE_MESSAGE = 9 */
	@:isVar public var meta(get, set):MetaEvent;
	public inline function setMeta(value:MetaEvent):GameEvent{
		this.meta = value;
		return this;
	}

	public function clearMeta():Void {
		this.meta = null;
	}

	inline public function hasMeta():Bool {
		return this.meta != null;
	}

	public function set_meta(value:MetaEvent):MetaEvent{
		return this.meta = value;
	}

	public function get_meta():MetaEvent {
		return this.meta;
	}


	/** LABEL_OPTIONAL score_update : TYPE_MESSAGE = 10 */
	@:isVar public var scoreUpdate(get, set):ScoreUpdateEvent;
	public inline function setScoreUpdate(value:ScoreUpdateEvent):GameEvent{
		this.scoreUpdate = value;
		return this;
	}

	public function clearScoreUpdate():Void {
		this.scoreUpdate = null;
	}

	inline public function hasScoreUpdate():Bool {
		return this.scoreUpdate != null;
	}

	public function set_scoreUpdate(value:ScoreUpdateEvent):ScoreUpdateEvent{
		return this.scoreUpdate = value;
	}

	public function get_scoreUpdate():ScoreUpdateEvent {
		return this.scoreUpdate;
	}

	public function new(){
		super();
	}

	/** @private */
	override public function writeToBuffer(output:PT_OutputStream):Void {
		if (hasChat()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 1);
			protohx.WriteUtils.write__TYPE_MESSAGE(output, this.chat);
		}
		if (hasMapLoad()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 2);
			protohx.WriteUtils.write__TYPE_MESSAGE(output, this.mapLoad);
		}
		if (hasSetPlayer()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 3);
			protohx.WriteUtils.write__TYPE_MESSAGE(output, this.setPlayer);
		}
		if (hasRemovePlayer()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 4);
			protohx.WriteUtils.write__TYPE_MESSAGE(output, this.removePlayer);
		}
		if (hasGoal()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 6);
			protohx.WriteUtils.write__TYPE_MESSAGE(output, this.goal);
		}
		if (hasKill()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 7);
			protohx.WriteUtils.write__TYPE_MESSAGE(output, this.kill);
		}
		if (hasDamage()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 8);
			protohx.WriteUtils.write__TYPE_MESSAGE(output, this.damage);
		}
		if (hasMeta()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 9);
			protohx.WriteUtils.write__TYPE_MESSAGE(output, this.meta);
		}
		if (hasScoreUpdate()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 10);
			protohx.WriteUtils.write__TYPE_MESSAGE(output, this.scoreUpdate);
		}
		super.writeExtensionOrUnknownFields(output);
	}

	override public function forEachFields(fn:String->Dynamic->Void):Void {
		if (hasChat()) {
			fn("chat", this.chat);
		}
		if (hasMapLoad()) {
			fn("mapLoad", this.mapLoad);
		}
		if (hasSetPlayer()) {
			fn("setPlayer", this.setPlayer);
		}
		if (hasRemovePlayer()) {
			fn("removePlayer", this.removePlayer);
		}
		if (hasGoal()) {
			fn("goal", this.goal);
		}
		if (hasKill()) {
			fn("kill", this.kill);
		}
		if (hasDamage()) {
			fn("damage", this.damage);
		}
		if (hasMeta()) {
			fn("meta", this.meta);
		}
		if (hasScoreUpdate()) {
			fn("scoreUpdate", this.scoreUpdate);
		}
	}

	/** @private */
	override public function readFromSlice(input:PT_InputStream, bytesAfterSlice:PT_UInt):Void {
		var chat__count:PT_UInt = 0;
		var map_load__count:PT_UInt = 0;
		var set_player__count:PT_UInt = 0;
		var remove_player__count:PT_UInt = 0;
		var goal__count:PT_UInt = 0;
		var kill__count:PT_UInt = 0;
		var damage__count:PT_UInt = 0;
		var meta__count:PT_UInt = 0;
		var score_update__count:PT_UInt = 0;
		while (hasBytes(input, bytesAfterSlice)) {
			var tag:PT_UInt = protohx.ReadUtils.read__TYPE_UINT32(input);
			switch (tag >> 3) {
			case 1:
				if (chat__count != 0) {
					throw new PT_IOError('Bad data format: GameEvent.chat cannot be set twice.');
				}
				++chat__count;
				this.chat = new ChatEvent();
				protohx.ReadUtils.read__TYPE_MESSAGE(input, this.chat);
			case 2:
				if (map_load__count != 0) {
					throw new PT_IOError('Bad data format: GameEvent.mapLoad cannot be set twice.');
				}
				++map_load__count;
				this.mapLoad = new MapLoadEvent();
				protohx.ReadUtils.read__TYPE_MESSAGE(input, this.mapLoad);
			case 3:
				if (set_player__count != 0) {
					throw new PT_IOError('Bad data format: GameEvent.setPlayer cannot be set twice.');
				}
				++set_player__count;
				this.setPlayer = new SetPlayerEvent();
				protohx.ReadUtils.read__TYPE_MESSAGE(input, this.setPlayer);
			case 4:
				if (remove_player__count != 0) {
					throw new PT_IOError('Bad data format: GameEvent.removePlayer cannot be set twice.');
				}
				++remove_player__count;
				this.removePlayer = new RemovePlayerEvent();
				protohx.ReadUtils.read__TYPE_MESSAGE(input, this.removePlayer);
			case 6:
				if (goal__count != 0) {
					throw new PT_IOError('Bad data format: GameEvent.goal cannot be set twice.');
				}
				++goal__count;
				this.goal = new GoalEvent();
				protohx.ReadUtils.read__TYPE_MESSAGE(input, this.goal);
			case 7:
				if (kill__count != 0) {
					throw new PT_IOError('Bad data format: GameEvent.kill cannot be set twice.');
				}
				++kill__count;
				this.kill = new KillEvent();
				protohx.ReadUtils.read__TYPE_MESSAGE(input, this.kill);
			case 8:
				if (damage__count != 0) {
					throw new PT_IOError('Bad data format: GameEvent.damage cannot be set twice.');
				}
				++damage__count;
				this.damage = new DamageEvent();
				protohx.ReadUtils.read__TYPE_MESSAGE(input, this.damage);
			case 9:
				if (meta__count != 0) {
					throw new PT_IOError('Bad data format: GameEvent.meta cannot be set twice.');
				}
				++meta__count;
				this.meta = new MetaEvent();
				protohx.ReadUtils.read__TYPE_MESSAGE(input, this.meta);
			case 10:
				if (score_update__count != 0) {
					throw new PT_IOError('Bad data format: GameEvent.scoreUpdate cannot be set twice.');
				}
				++score_update__count;
				this.scoreUpdate = new ScoreUpdateEvent();
				protohx.ReadUtils.read__TYPE_MESSAGE(input, this.scoreUpdate);
			default:
				super.readUnknown(input, tag);
			}
		}
	}

}


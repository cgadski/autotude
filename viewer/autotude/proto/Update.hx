package autotude.proto;
import protohx.Protohx;
class Update extends protohx.Message {

	/** LABEL_OPTIONAL time : TYPE_INT64 = 1 */
	@:isVar public var time(get, set):PT_Int64;
	public inline function setTime(value:PT_Int64):Update{
		this.time = value;
		return this;
	}

	private var hasField__0:PT_UInt = 0;

	public function clearTime():Void {
		hasField__0 &= 0xfffffffe;
		this.time = defaultInt64();
	}

	inline public function hasTime():PT_Bool {
		return (hasField__0 & 0x1) != 0;
	}

	public function set_time(value:PT_Int64):PT_Int64{
		hasField__0 |= 0x1;
		return this.time = value;
	}

	public function get_time():PT_Int64 {
		return this.time;
	}


	/** LABEL_OPTIONAL duration : TYPE_UINT64 = 4 */
	@:isVar public var duration(get, set):PT_UInt64;
	public inline function setDuration(value:PT_UInt64):Update{
		this.duration = value;
		return this;
	}

	public function clearDuration():Void {
		hasField__0 &= 0xfffffffd;
		this.duration = defaultUInt64();
	}

	inline public function hasDuration():PT_Bool {
		return (hasField__0 & 0x2) != 0;
	}

	public function set_duration(value:PT_UInt64):PT_UInt64{
		hasField__0 |= 0x2;
		return this.duration = value;
	}

	public function get_duration():PT_UInt64 {
		if(!hasDuration()) {
			return Protohx.newUInt64(0, 1);
		}
		return this.duration;
	}


	/** LABEL_REPEATED objects : TYPE_MESSAGE = 2 */
	@:isVar public var objects(get, set):Array<GameObject>;
	public inline function setObjects(value:Array<GameObject>):Update{
		this.objects = value;
		return this;
	}

	public function set_objects(value:Array<GameObject>):Array<GameObject> {
		return this.objects = value;
	}

	public function get_objects():Array<GameObject> {
		return this.objects;
	}

	public function addObjects(value:GameObject):Void {
		if(this.objects == null) this.objects = [value];
		else this.objects.push(value);
	}


	/** LABEL_REPEATED events : TYPE_MESSAGE = 3 */
	@:isVar public var events(get, set):Array<GameEvent>;
	public inline function setEvents(value:Array<GameEvent>):Update{
		this.events = value;
		return this;
	}

	public function set_events(value:Array<GameEvent>):Array<GameEvent> {
		return this.events = value;
	}

	public function get_events():Array<GameEvent> {
		return this.events;
	}

	public function addEvents(value:GameEvent):Void {
		if(this.events == null) this.events = [value];
		else this.events.push(value);
	}

	public function new(){
		super();
		this.objects = [];
		this.events = [];
	}

	/** @private */
	override public function writeToBuffer(output:PT_OutputStream):Void {
		if (hasTime()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 1);
			protohx.WriteUtils.write__TYPE_INT64(output, this.time);
		}
		if (hasDuration()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 4);
			protohx.WriteUtils.write__TYPE_UINT64(output, this.duration);
		}
		if (this.objects != null) {
			for (value in this.objects) {
				protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 2);
				protohx.WriteUtils.write__TYPE_MESSAGE(output, value);
			}
		}
		if (this.events != null) {
			for (value in this.events) {
				protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 3);
				protohx.WriteUtils.write__TYPE_MESSAGE(output, value);
			}
		}
		super.writeExtensionOrUnknownFields(output);
	}

	override public function forEachFields(fn:String->Dynamic->Void):Void {
		if (hasTime()) {
			fn("time", this.time);
		}
		if (hasDuration()) {
			fn("duration", this.duration);
		}
		if (this.objects != null && this.objects.length > 0) {
			fn("objects", this.objects);
		}
		if (this.events != null && this.events.length > 0) {
			fn("events", this.events);
		}
	}

	/** @private */
	override public function readFromSlice(input:PT_InputStream, bytesAfterSlice:PT_UInt):Void {
		var time__count:PT_UInt = 0;
		var duration__count:PT_UInt = 0;
		while (hasBytes(input, bytesAfterSlice)) {
			var tag:PT_UInt = protohx.ReadUtils.read__TYPE_UINT32(input);
			switch (tag >> 3) {
			case 1:
				if (time__count != 0) {
					throw new PT_IOError('Bad data format: Update.time cannot be set twice.');
				}
				++time__count;
				this.time = protohx.ReadUtils.read__TYPE_INT64(input);
			case 4:
				if (duration__count != 0) {
					throw new PT_IOError('Bad data format: Update.duration cannot be set twice.');
				}
				++duration__count;
				this.duration = protohx.ReadUtils.read__TYPE_UINT64(input);
			case 2:
				if(this.objects == null) {
					this.objects = [];
				}
				{
					this.objects.push(protohx.ReadUtils.read__TYPE_MESSAGE(input, new GameObject()));
				}
			case 3:
				if(this.events == null) {
					this.events = [];
				}
				{
					this.events.push(protohx.ReadUtils.read__TYPE_MESSAGE(input, new GameEvent()));
				}
			default:
				super.readUnknown(input, tag);
			}
		}
	}

}


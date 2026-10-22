package autotude.proto;
import protohx.Protohx;
class MapGeometry extends protohx.Message {

	/** LABEL_OPTIONAL max_x : TYPE_UINT32 = 1 */
	@:isVar public var maxX(get, set):PT_UInt;
	public inline function setMaxX(value:PT_UInt):MapGeometry{
		this.maxX = value;
		return this;
	}

	private var hasField__0:PT_UInt = 0;

	public function clearMaxX():Void {
		hasField__0 &= 0xfffffffe;
		this.maxX = 0;
	}

	inline public function hasMaxX():PT_Bool {
		return (hasField__0 & 0x1) != 0;
	}

	public function set_maxX(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x1;
		return this.maxX = value;
	}

	public function get_maxX():PT_UInt {
		return this.maxX;
	}


	/** LABEL_OPTIONAL max_y : TYPE_UINT32 = 2 */
	@:isVar public var maxY(get, set):PT_UInt;
	public inline function setMaxY(value:PT_UInt):MapGeometry{
		this.maxY = value;
		return this;
	}

	public function clearMaxY():Void {
		hasField__0 &= 0xfffffffd;
		this.maxY = 0;
	}

	inline public function hasMaxY():PT_Bool {
		return (hasField__0 & 0x2) != 0;
	}

	public function set_maxY(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x2;
		return this.maxY = value;
	}

	public function get_maxY():PT_UInt {
		return this.maxY;
	}


	/** LABEL_REPEATED obstacles : TYPE_MESSAGE = 5 */
	@:isVar public var obstacles(get, set):Array<ConcaveObstacle>;
	public inline function setObstacles(value:Array<ConcaveObstacle>):MapGeometry{
		this.obstacles = value;
		return this;
	}

	public function set_obstacles(value:Array<ConcaveObstacle>):Array<ConcaveObstacle> {
		return this.obstacles = value;
	}

	public function get_obstacles():Array<ConcaveObstacle> {
		return this.obstacles;
	}

	public function addObstacles(value:ConcaveObstacle):Void {
		if(this.obstacles == null) this.obstacles = [value];
		else this.obstacles.push(value);
	}

	public function new(){
		super();
		this.obstacles = [];
	}

	/** @private */
	override public function writeToBuffer(output:PT_OutputStream):Void {
		if (hasMaxX()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 1);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.maxX);
		}
		if (hasMaxY()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 2);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.maxY);
		}
		if (this.obstacles != null) {
			for (value in this.obstacles) {
				protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 5);
				protohx.WriteUtils.write__TYPE_MESSAGE(output, value);
			}
		}
		super.writeExtensionOrUnknownFields(output);
	}

	override public function forEachFields(fn:String->Dynamic->Void):Void {
		if (hasMaxX()) {
			fn("maxX", this.maxX);
		}
		if (hasMaxY()) {
			fn("maxY", this.maxY);
		}
		if (this.obstacles != null && this.obstacles.length > 0) {
			fn("obstacles", this.obstacles);
		}
	}

	/** @private */
	override public function readFromSlice(input:PT_InputStream, bytesAfterSlice:PT_UInt):Void {
		var max_x__count:PT_UInt = 0;
		var max_y__count:PT_UInt = 0;
		while (hasBytes(input, bytesAfterSlice)) {
			var tag:PT_UInt = protohx.ReadUtils.read__TYPE_UINT32(input);
			switch (tag >> 3) {
			case 1:
				if (max_x__count != 0) {
					throw new PT_IOError('Bad data format: MapGeometry.maxX cannot be set twice.');
				}
				++max_x__count;
				this.maxX = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 2:
				if (max_y__count != 0) {
					throw new PT_IOError('Bad data format: MapGeometry.maxY cannot be set twice.');
				}
				++max_y__count;
				this.maxY = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 5:
				if(this.obstacles == null) {
					this.obstacles = [];
				}
				{
					this.obstacles.push(protohx.ReadUtils.read__TYPE_MESSAGE(input, new ConcaveObstacle()));
				}
			default:
				super.readUnknown(input, tag);
			}
		}
	}

}


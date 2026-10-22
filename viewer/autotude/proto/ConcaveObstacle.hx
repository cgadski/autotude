package autotude.proto;
import protohx.Protohx;
class ConcaveObstacle extends protohx.Message {

	/** LABEL_REPEATED vertices_x : TYPE_INT32 = 1 */
	@:isVar public var verticesX(get, set):Array<PT_Int>;
	public inline function setVerticesX(value:Array<PT_Int>):ConcaveObstacle{
		this.verticesX = value;
		return this;
	}

	public function set_verticesX(value:Array<PT_Int>):Array<PT_Int> {
		return this.verticesX = value;
	}

	public function get_verticesX():Array<PT_Int> {
		return this.verticesX;
	}

	public function addVerticesX(value:PT_Int):Void {
		if(this.verticesX == null) this.verticesX = [value];
		else this.verticesX.push(value);
	}


	/** LABEL_REPEATED vertices_y : TYPE_INT32 = 2 */
	@:isVar public var verticesY(get, set):Array<PT_Int>;
	public inline function setVerticesY(value:Array<PT_Int>):ConcaveObstacle{
		this.verticesY = value;
		return this;
	}

	public function set_verticesY(value:Array<PT_Int>):Array<PT_Int> {
		return this.verticesY = value;
	}

	public function get_verticesY():Array<PT_Int> {
		return this.verticesY;
	}

	public function addVerticesY(value:PT_Int):Void {
		if(this.verticesY == null) this.verticesY = [value];
		else this.verticesY.push(value);
	}


	/** LABEL_REPEATED decomposition : TYPE_MESSAGE = 3 */
	@:isVar public var decomposition(get, set):Array<ConvexHull>;
	public inline function setDecomposition(value:Array<ConvexHull>):ConcaveObstacle{
		this.decomposition = value;
		return this;
	}

	public function set_decomposition(value:Array<ConvexHull>):Array<ConvexHull> {
		return this.decomposition = value;
	}

	public function get_decomposition():Array<ConvexHull> {
		return this.decomposition;
	}

	public function addDecomposition(value:ConvexHull):Void {
		if(this.decomposition == null) this.decomposition = [value];
		else this.decomposition.push(value);
	}

	public function new(){
		super();
		this.verticesX = [];
		this.verticesY = [];
		this.decomposition = [];
	}

	/** @private */
	override public function writeToBuffer(output:PT_OutputStream):Void {
		if (this.verticesX != null && this.verticesX.length > 0) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 1);
			protohx.WriteUtils.writePackedRepeated(output, protohx.WriteUtils.write__TYPE_INT32, this.verticesX);
		}
		if (this.verticesY != null && this.verticesY.length > 0) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 2);
			protohx.WriteUtils.writePackedRepeated(output, protohx.WriteUtils.write__TYPE_INT32, this.verticesY);
		}
		if (this.decomposition != null) {
			for (value in this.decomposition) {
				protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 3);
				protohx.WriteUtils.write__TYPE_MESSAGE(output, value);
			}
		}
		super.writeExtensionOrUnknownFields(output);
	}

	override public function forEachFields(fn:String->Dynamic->Void):Void {
		if (this.verticesX != null && this.verticesX.length > 0) {
			fn("verticesX", this.verticesX);
		}
		if (this.verticesY != null && this.verticesY.length > 0) {
			fn("verticesY", this.verticesY);
		}
		if (this.decomposition != null && this.decomposition.length > 0) {
			fn("decomposition", this.decomposition);
		}
	}

	/** @private */
	override public function readFromSlice(input:PT_InputStream, bytesAfterSlice:PT_UInt):Void {
		while (hasBytes(input, bytesAfterSlice)) {
			var tag:PT_UInt = protohx.ReadUtils.read__TYPE_UINT32(input);
			switch (tag >> 3) {
			case 1:
				if(this.verticesX == null) {
					this.verticesX = [];
				}
				if (cast((tag & 7), PT_UInt) == protohx.WireType.LENGTH_DELIMITED) {
					protohx.ReadUtils.readPackedRepeated(input, protohx.ReadUtils.read__TYPE_INT32, this.verticesX);
				} else 				{
					this.verticesX.push(cast protohx.ReadUtils.read__TYPE_INT32(input));
				}
			case 2:
				if(this.verticesY == null) {
					this.verticesY = [];
				}
				if (cast((tag & 7), PT_UInt) == protohx.WireType.LENGTH_DELIMITED) {
					protohx.ReadUtils.readPackedRepeated(input, protohx.ReadUtils.read__TYPE_INT32, this.verticesY);
				} else 				{
					this.verticesY.push(cast protohx.ReadUtils.read__TYPE_INT32(input));
				}
			case 3:
				if(this.decomposition == null) {
					this.decomposition = [];
				}
				{
					this.decomposition.push(protohx.ReadUtils.read__TYPE_MESSAGE(input, new ConvexHull()));
				}
			default:
				super.readUnknown(input, tag);
			}
		}
	}

}


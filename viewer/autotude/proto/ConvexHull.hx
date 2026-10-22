package autotude.proto;
import protohx.Protohx;
class ConvexHull extends protohx.Message {

	/** LABEL_REPEATED vertices_x : TYPE_INT32 = 1 */
	@:isVar public var verticesX(get, set):Array<PT_Int>;
	public inline function setVerticesX(value:Array<PT_Int>):ConvexHull{
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
	public inline function setVerticesY(value:Array<PT_Int>):ConvexHull{
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

	public function new(){
		super();
		this.verticesX = [];
		this.verticesY = [];
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
		super.writeExtensionOrUnknownFields(output);
	}

	override public function forEachFields(fn:String->Dynamic->Void):Void {
		if (this.verticesX != null && this.verticesX.length > 0) {
			fn("verticesX", this.verticesX);
		}
		if (this.verticesY != null && this.verticesY.length > 0) {
			fn("verticesY", this.verticesY);
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
			default:
				super.readUnknown(input, tag);
			}
		}
	}

}


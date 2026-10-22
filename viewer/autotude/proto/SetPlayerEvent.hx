package autotude.proto;
import protohx.Protohx;
class SetPlayerEvent extends protohx.Message {

	/** LABEL_OPTIONAL id : TYPE_UINT32 = 1 */
	@:isVar public var id(get, set):PT_UInt;
	public inline function setId(value:PT_UInt):SetPlayerEvent{
		this.id = value;
		return this;
	}

	private var hasField__0:PT_UInt = 0;

	public function clearId():Void {
		hasField__0 &= 0xfffffffe;
		this.id = 0;
	}

	inline public function hasId():PT_Bool {
		return (hasField__0 & 0x1) != 0;
	}

	public function set_id(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x1;
		return this.id = value;
	}

	public function get_id():PT_UInt {
		return this.id;
	}


	/** LABEL_OPTIONAL name : TYPE_STRING = 2 */
	@:isVar public var name(get, set):PT_String;
	public inline function setName(value:PT_String):SetPlayerEvent{
		this.name = value;
		return this;
	}

	public function clearName():Void {
		this.name = null;
	}

	inline public function hasName():Bool {
		return this.name != null;
	}

	public function set_name(value:PT_String):PT_String{
		return this.name = value;
	}

	public function get_name():PT_String {
		return this.name;
	}


	/** LABEL_OPTIONAL team : TYPE_UINT32 = 3 */
	@:isVar public var team(get, set):PT_UInt;
	public inline function setTeam(value:PT_UInt):SetPlayerEvent{
		this.team = value;
		return this;
	}

	public function clearTeam():Void {
		hasField__0 &= 0xfffffffd;
		this.team = 0;
	}

	inline public function hasTeam():PT_Bool {
		return (hasField__0 & 0x2) != 0;
	}

	public function set_team(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x2;
		return this.team = value;
	}

	public function get_team():PT_UInt {
		return this.team;
	}


	/** LABEL_OPTIONAL level : TYPE_UINT32 = 4 */
	@:isVar public var level(get, set):PT_UInt;
	public inline function setLevel(value:PT_UInt):SetPlayerEvent{
		this.level = value;
		return this;
	}

	public function clearLevel():Void {
		hasField__0 &= 0xfffffffb;
		this.level = 0;
	}

	inline public function hasLevel():PT_Bool {
		return (hasField__0 & 0x4) != 0;
	}

	public function set_level(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x4;
		return this.level = value;
	}

	public function get_level():PT_UInt {
		return this.level;
	}


	/** LABEL_OPTIONAL ace_rank : TYPE_UINT32 = 5 */
	@:isVar public var aceRank(get, set):PT_UInt;
	public inline function setAceRank(value:PT_UInt):SetPlayerEvent{
		this.aceRank = value;
		return this;
	}

	public function clearAceRank():Void {
		hasField__0 &= 0xfffffff7;
		this.aceRank = 0;
	}

	inline public function hasAceRank():PT_Bool {
		return (hasField__0 & 0x8) != 0;
	}

	public function set_aceRank(value:PT_UInt):PT_UInt{
		hasField__0 |= 0x8;
		return this.aceRank = value;
	}

	public function get_aceRank():PT_UInt {
		return this.aceRank;
	}


	/** LABEL_OPTIONAL vapor : TYPE_STRING = 6 */
	@:isVar public var vapor(get, set):PT_String;
	public inline function setVapor(value:PT_String):SetPlayerEvent{
		this.vapor = value;
		return this;
	}

	public function clearVapor():Void {
		this.vapor = null;
	}

	inline public function hasVapor():Bool {
		return this.vapor != null;
	}

	public function set_vapor(value:PT_String):PT_String{
		return this.vapor = value;
	}

	public function get_vapor():PT_String {
		return this.vapor;
	}

	public function new(){
		super();
	}

	/** @private */
	override public function writeToBuffer(output:PT_OutputStream):Void {
		if (hasId()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 1);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.id);
		}
		if (hasName()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 2);
			protohx.WriteUtils.write__TYPE_STRING(output, this.name);
		}
		if (hasTeam()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 3);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.team);
		}
		if (hasLevel()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 4);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.level);
		}
		if (hasAceRank()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.VARINT, 5);
			protohx.WriteUtils.write__TYPE_UINT32(output, this.aceRank);
		}
		if (hasVapor()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 6);
			protohx.WriteUtils.write__TYPE_STRING(output, this.vapor);
		}
		super.writeExtensionOrUnknownFields(output);
	}

	override public function forEachFields(fn:String->Dynamic->Void):Void {
		if (hasId()) {
			fn("id", this.id);
		}
		if (hasName()) {
			fn("name", this.name);
		}
		if (hasTeam()) {
			fn("team", this.team);
		}
		if (hasLevel()) {
			fn("level", this.level);
		}
		if (hasAceRank()) {
			fn("aceRank", this.aceRank);
		}
		if (hasVapor()) {
			fn("vapor", this.vapor);
		}
	}

	/** @private */
	override public function readFromSlice(input:PT_InputStream, bytesAfterSlice:PT_UInt):Void {
		var id__count:PT_UInt = 0;
		var name__count:PT_UInt = 0;
		var team__count:PT_UInt = 0;
		var level__count:PT_UInt = 0;
		var ace_rank__count:PT_UInt = 0;
		var vapor__count:PT_UInt = 0;
		while (hasBytes(input, bytesAfterSlice)) {
			var tag:PT_UInt = protohx.ReadUtils.read__TYPE_UINT32(input);
			switch (tag >> 3) {
			case 1:
				if (id__count != 0) {
					throw new PT_IOError('Bad data format: SetPlayerEvent.id cannot be set twice.');
				}
				++id__count;
				this.id = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 2:
				if (name__count != 0) {
					throw new PT_IOError('Bad data format: SetPlayerEvent.name cannot be set twice.');
				}
				++name__count;
				this.name = protohx.ReadUtils.read__TYPE_STRING(input);
			case 3:
				if (team__count != 0) {
					throw new PT_IOError('Bad data format: SetPlayerEvent.team cannot be set twice.');
				}
				++team__count;
				this.team = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 4:
				if (level__count != 0) {
					throw new PT_IOError('Bad data format: SetPlayerEvent.level cannot be set twice.');
				}
				++level__count;
				this.level = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 5:
				if (ace_rank__count != 0) {
					throw new PT_IOError('Bad data format: SetPlayerEvent.aceRank cannot be set twice.');
				}
				++ace_rank__count;
				this.aceRank = protohx.ReadUtils.read__TYPE_UINT32(input);
			case 6:
				if (vapor__count != 0) {
					throw new PT_IOError('Bad data format: SetPlayerEvent.vapor cannot be set twice.');
				}
				++vapor__count;
				this.vapor = protohx.ReadUtils.read__TYPE_STRING(input);
			default:
				super.readUnknown(input, tag);
			}
		}
	}

}


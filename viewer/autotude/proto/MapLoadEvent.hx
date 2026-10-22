package autotude.proto;
import protohx.Protohx;
class MapLoadEvent extends protohx.Message {

	/** LABEL_OPTIONAL map : TYPE_MESSAGE = 1 */
	@:isVar public var map(get, set):MapGeometry;
	public inline function setMap(value:MapGeometry):MapLoadEvent{
		this.map = value;
		return this;
	}

	public function clearMap():Void {
		this.map = null;
	}

	inline public function hasMap():Bool {
		return this.map != null;
	}

	public function set_map(value:MapGeometry):MapGeometry{
		return this.map = value;
	}

	public function get_map():MapGeometry {
		return this.map;
	}


	/** LABEL_OPTIONAL name : TYPE_STRING = 2 */
	@:isVar public var name(get, set):PT_String;
	public inline function setName(value:PT_String):MapLoadEvent{
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


	/** LABEL_OPTIONAL server : TYPE_STRING = 3 */
	@:isVar public var server(get, set):PT_String;
	public inline function setServer(value:PT_String):MapLoadEvent{
		this.server = value;
		return this;
	}

	public function clearServer():Void {
		this.server = null;
	}

	inline public function hasServer():Bool {
		return this.server != null;
	}

	public function set_server(value:PT_String):PT_String{
		return this.server = value;
	}

	public function get_server():PT_String {
		return this.server;
	}


	/** LABEL_OPTIONAL datetime : TYPE_STRING = 4 */
	@:isVar public var datetime(get, set):PT_String;
	public inline function setDatetime(value:PT_String):MapLoadEvent{
		this.datetime = value;
		return this;
	}

	public function clearDatetime():Void {
		this.datetime = null;
	}

	inline public function hasDatetime():Bool {
		return this.datetime != null;
	}

	public function set_datetime(value:PT_String):PT_String{
		return this.datetime = value;
	}

	public function get_datetime():PT_String {
		return this.datetime;
	}


	/** LABEL_OPTIONAL server_ip : TYPE_STRING = 5 */
	@:isVar public var serverIp(get, set):PT_String;
	public inline function setServerIp(value:PT_String):MapLoadEvent{
		this.serverIp = value;
		return this;
	}

	public function clearServerIp():Void {
		this.serverIp = null;
	}

	inline public function hasServerIp():Bool {
		return this.serverIp != null;
	}

	public function set_serverIp(value:PT_String):PT_String{
		return this.serverIp = value;
	}

	public function get_serverIp():PT_String {
		return this.serverIp;
	}


	/** LABEL_OPTIONAL protocol_version : TYPE_STRING = 6 */
	@:isVar public var protocolVersion(get, set):PT_String;
	public inline function setProtocolVersion(value:PT_String):MapLoadEvent{
		this.protocolVersion = value;
		return this;
	}

	public function clearProtocolVersion():Void {
		this.protocolVersion = null;
	}

	inline public function hasProtocolVersion():Bool {
		return this.protocolVersion != null;
	}

	public function set_protocolVersion(value:PT_String):PT_String{
		return this.protocolVersion = value;
	}

	public function get_protocolVersion():PT_String {
		return this.protocolVersion;
	}

	public function new(){
		super();
	}

	/** @private */
	override public function writeToBuffer(output:PT_OutputStream):Void {
		if (hasMap()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 1);
			protohx.WriteUtils.write__TYPE_MESSAGE(output, this.map);
		}
		if (hasName()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 2);
			protohx.WriteUtils.write__TYPE_STRING(output, this.name);
		}
		if (hasServer()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 3);
			protohx.WriteUtils.write__TYPE_STRING(output, this.server);
		}
		if (hasDatetime()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 4);
			protohx.WriteUtils.write__TYPE_STRING(output, this.datetime);
		}
		if (hasServerIp()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 5);
			protohx.WriteUtils.write__TYPE_STRING(output, this.serverIp);
		}
		if (hasProtocolVersion()) {
			protohx.WriteUtils.writeTag(output, protohx.WireType.LENGTH_DELIMITED, 6);
			protohx.WriteUtils.write__TYPE_STRING(output, this.protocolVersion);
		}
		super.writeExtensionOrUnknownFields(output);
	}

	override public function forEachFields(fn:String->Dynamic->Void):Void {
		if (hasMap()) {
			fn("map", this.map);
		}
		if (hasName()) {
			fn("name", this.name);
		}
		if (hasServer()) {
			fn("server", this.server);
		}
		if (hasDatetime()) {
			fn("datetime", this.datetime);
		}
		if (hasServerIp()) {
			fn("serverIp", this.serverIp);
		}
		if (hasProtocolVersion()) {
			fn("protocolVersion", this.protocolVersion);
		}
	}

	/** @private */
	override public function readFromSlice(input:PT_InputStream, bytesAfterSlice:PT_UInt):Void {
		var map__count:PT_UInt = 0;
		var name__count:PT_UInt = 0;
		var server__count:PT_UInt = 0;
		var datetime__count:PT_UInt = 0;
		var server_ip__count:PT_UInt = 0;
		var protocol_version__count:PT_UInt = 0;
		while (hasBytes(input, bytesAfterSlice)) {
			var tag:PT_UInt = protohx.ReadUtils.read__TYPE_UINT32(input);
			switch (tag >> 3) {
			case 1:
				if (map__count != 0) {
					throw new PT_IOError('Bad data format: MapLoadEvent.map cannot be set twice.');
				}
				++map__count;
				this.map = new MapGeometry();
				protohx.ReadUtils.read__TYPE_MESSAGE(input, this.map);
			case 2:
				if (name__count != 0) {
					throw new PT_IOError('Bad data format: MapLoadEvent.name cannot be set twice.');
				}
				++name__count;
				this.name = protohx.ReadUtils.read__TYPE_STRING(input);
			case 3:
				if (server__count != 0) {
					throw new PT_IOError('Bad data format: MapLoadEvent.server cannot be set twice.');
				}
				++server__count;
				this.server = protohx.ReadUtils.read__TYPE_STRING(input);
			case 4:
				if (datetime__count != 0) {
					throw new PT_IOError('Bad data format: MapLoadEvent.datetime cannot be set twice.');
				}
				++datetime__count;
				this.datetime = protohx.ReadUtils.read__TYPE_STRING(input);
			case 5:
				if (server_ip__count != 0) {
					throw new PT_IOError('Bad data format: MapLoadEvent.serverIp cannot be set twice.');
				}
				++server_ip__count;
				this.serverIp = protohx.ReadUtils.read__TYPE_STRING(input);
			case 6:
				if (protocol_version__count != 0) {
					throw new PT_IOError('Bad data format: MapLoadEvent.protocolVersion cannot be set twice.');
				}
				++protocol_version__count;
				this.protocolVersion = protohx.ReadUtils.read__TYPE_STRING(input);
			default:
				super.readUnknown(input, tag);
			}
		}
	}

}


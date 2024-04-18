package autotude.viewer;

import js.html.URLSearchParams;

@:structInit class ViewerParams {
    public final map:String;
    public final time:Null<Int>;

    function write():String {
        final params = new URLSearchParams();
        params.append("map", map);
        params.append("time", Std.string(time));
        return untyped params.toString();
    }
}

// public function new(search:String) {
//     final params = new URLSearchParams(search);
//     final map = params.get("map");
// }

function parse(search:String):Null<ViewerParams> {
    final params = new URLSearchParams(search);
    final map = params.get("map");

    final time = params.get("time");
    final timeParsed = (time == null) ? null : Std.parseInt(time);

    if (map == null)
        return null;

    return {
        map: map,
        time: timeParsed,
    }
}

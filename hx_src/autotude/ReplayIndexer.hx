package autotude;

import sys.FileSystem;
import haxe.io.Bytes;
import autotude.proto.GameObject;
import autotude.proto.GameEvent;
import haxe.io.BytesInput;
import sys.io.File;
import haxe.Json;

private class ReplaySummary {
    final bytes:Bytes;
    final replay:Replay;

    public function new(bytes:Bytes, replay:Replay) {
        this.bytes = bytes;
        this.replay = replay;

        for (update in replay.updates)   {
            for (event in update.events) {
                onEvent(event);
            }
            for (object in update.objects) {
                onObject(object);
            }
        }
    }

    public var numMapLoads:Int = 0;

    public function onEvent(event: GameEvent) {
        if (event.mapLoad != null) {
            numMapLoads += 1;
        }
    }

    public var maxUid:Int = 0;
    public var minPosX:Int = 0;
    public var minPosY:Int = 0;
    public var maxPosX:Int = 0;
    public var maxPosY:Int = 0;
    
    public function onObject(object: GameObject) {
        if (object.hasUid()) {
            if (object.uid > maxUid)
                maxUid = object.uid;
        }
        if (object.hasPositionX()) {
            maxPosX = Std.int(Math.max(maxPosX, object.positionX));
            minPosX = Std.int(Math.min(minPosX, object.positionX));

            maxPosY = Std.int(Math.max(maxPosY, object.positionY));
            minPosY = Std.int(Math.min(minPosY, object.positionY));
        }
    }

    public function show() {
        final seconds = replay.updates.length / 30;
        Sys.println('map loads: $numMapLoads');
        Sys.println('teams: ${replay.teams}');
        Sys.println('duration: ${Std.int(seconds)} seconds');
        Sys.println('distinct objects: ${maxUid + 1}');
        Sys.println('x range: $minPosX to $maxPosX');
        Sys.println('y range: $minPosY to $maxPosY');
        Sys.println('kilobytes: ${bytes.length / 1000}');
        Sys.println('kb per minute: ${Std.int((60 / 1000) * (bytes.length / seconds))}');
   }
}

class ReplayIndexer {
    public static function main() {
        final files = FileSystem.readDirectory(Sys.args()[0]);
        var totalUpdates = 0;
        for (file in files) {
            final bytes = File.getBytes(Sys.args()[0] + file);
            final replay = new Replay(new BytesInput(bytes));
            totalUpdates += replay.updates.length;

            // final summary = new ReplaySummary(bytes, replay);
            // summary.show();
            // final ticks = replay.updates.length;
            // Sys.println('$file: $ticks updates');
        }
        final minutes = Std.int(totalUpdates / (30 * 60));
        Sys.println('Total time recorded: $minutes minutes');
    }
}

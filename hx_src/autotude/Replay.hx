package autotude;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import autotude.proto.MapGeometry;
import protohx.ReadingBuffer;
import haxe.io.BytesInput;
import autotude.proto.Update;
import format.gz.Reader;

@:structInit class Player {
    public final name:String;
    public final team:Int;
    // public final aceRank:Int;
    // public final level:Int;
}

@:structInit class GameState {
    public final players:Map<Int, Player>;

    public function getName(id:Int):String {
        final player = players.get(id);
        if (player != null) {
            return player.name;
        }
        return "??";
    }
}

private inline function showDigits(d:Int):String {
    if (d >= 10) {
        return Std.string(d);
    } else {
        return "0" + Std.string(d);
    }
}

function showTimestamp(frames:Int):String {
    final minutes = Std.int(frames / (60 * 30));
    frames -= minutes * 60 * 30;
    final seconds = Std.int(frames / 30);
    frames -= seconds * 30;
    final d = showDigits;
    // return '${d(minutes)}:${d(seconds)}<i>:${d(frames)}</i>';
    return '${d(minutes)}:${d(seconds)}:${d(frames)}';
}

class Replay {
    public final updates:Array<Update> = [];
    public final gameStates:Array<GameState> = [];

    public var mapGeometry:MapGeometry = cast null;
    public var mapName:String = cast null;

    public final teams:Array<Int>;

    public function new(bytes: BytesInput) {
        final reader = new Reader(bytes);
        final decompressed = new BytesOutput();
        reader.readHeader();
        reader.readData(decompressed);
        final buf = new ReadingBuffer(new BytesInput(decompressed.getBytes()));

        final teamMap:Map<Int, Bool> = new Map();
        var players:Map<Int, Player> = new Map();

        while (buf.bytesAvailable > 0) {
            final update = new Update();
            update.mergeDelimitedFrom(buf);
            updates.push(update);

            var playersModified = false;

            for (event in update.events) {
                if (event.hasMapLoad()) {
                    mapGeometry = event.mapLoad.map;
                    mapName = event.mapLoad.name;
                    continue;
                }
                if (event.hasSetPlayer()) {
                    final setPlayer = event.setPlayer;
                    players.set(setPlayer.id, { 
                        name: setPlayer.name,
                        team: setPlayer.team
                    });
                    playersModified = true;
                    continue;
                }
                if (event.hasRemovePlayer()) {
                    players.remove(event.removePlayer.id);
                    playersModified = true;
                    continue;
                }
            }

            for (ob in update.objects) {
                if (ob.hasTeam() && ob.team > 2) {
                    teamMap.set(ob.team, true);
                }
            }

            if (playersModified) {
                players = players.copy();
            }
            gameStates.push({
                players: players
            });
        }

        teams = [for (team in teamMap.keys()) team];
        if (mapGeometry == null || mapName == null) {
            throw "No map load event found in replay";
        }
    }
}
package autotude;

import haxe.io.Eof;

using StringTools;

import sys.io.FileInput;
import sys.io.File;
import mustache.Parser;
import mustache.Partials;

function forLines(input:FileInput, handle:(String) -> Void) {
	while (true) {
		try {
			handle(input.readLine());
		} catch (e:Eof) {
			return;
		}
	}
}

@:structInit class ReplayEntry {
	final file:String;
	final url:String = "url";
	final title:String = "title";
	final date:String = "date";
	final duration:String = "duration";
	final description:Array<String>;

	public static function parse(input:FileInput):Array<ReplayEntry> {
		final entries:Array<ReplayEntry> = [];
		forLines(input, (line) -> {
			if (line.startsWith('#')) {
				// start new entry with filename equal to the markdown heading
				final file = line.substr(1).trim();
				entries.push({
					file: file,
					description: []
				});
			} else if (line.trim().length > 0) {
				// read lines as description, except empty lines
				entries[entries.length - 1].description.push(line.trim());
			}
		});
		return entries;
	}
}

class MakeIndex {
	// public static function main() {
	// 	final template = File.getContent("site_src/index.html");
	// 	final replays = File.read(Sys.args()[0], false);
	// 	final context:Dynamic = {
	// 		replays: ReplayEntry.parse(replays)
	// 	};
	// 	final output:String = Mustache.render(template, context, (x) -> x);
	// 	Sys.println(output);
	// }

	public static function main() {
		var view:Dynamic = {
			title: "Joe"
		};

		view.calc = function() {
			return 2 + 4;
		};

		var output:String = Mustache.render("{{title}} spends {{calc}}", view, (x) -> x);
        Sys.println(output);
	}
}

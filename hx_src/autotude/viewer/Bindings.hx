package autotude.viewer;

import js.html.Console;
import js.Browser;
import js.html.Window;
import js.html.Document;
import js.html.DivElement;
import hxd.Key;

typedef KeyBinding = {
	desc:String,
	keys:Array<Int>,
	cb:() -> Void,
};

class Bindings {
	final bindings:Array<KeyBinding> = [];

	public function new() {}

	public function update() {
		final usedKeys:Map<Int, Bool> = new Map();

		for (b in bindings) {
			final primaryKey = b.keys[b.keys.length - 1];
			if (Key.isPressed(primaryKey) && !(usedKeys.get(primaryKey) ?? false)) {
				var modifiersPressed = true;
				for (i in 0...b.keys.length - 1) {
					if (!Key.isDown(b.keys[i])) {
						modifiersPressed = false;
						break;
					}
				}
				if (modifiersPressed) {
					usedKeys.set(primaryKey, true);
					b.cb();
				}
			}
		}
	}

	public function register(desc:String, keys:Array<Int>, cb:() -> Void) {
		bindings.push({
			desc: desc,
			keys: keys,
			cb: cb
		});
	}

	public function renderCard(card:DivElement) {
		for (b in bindings) {
			final p = Browser.document.createParagraphElement();
			final keys = [for (k in b.keys) '<kbd>${StringTools.htmlEscape(Key.getKeyName(k) ?? "?")}</kbd>'].join(" + ");
			p.innerHTML = '<span class="desc">${StringTools.htmlEscape(b.desc)}</span><span>$keys</span>';
			card.appendChild(p);
		}
	}
}

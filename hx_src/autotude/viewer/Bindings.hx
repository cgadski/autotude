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

	// One row per action, with alternative keys for it joined by "or".
	public function renderCard(card:DivElement) {
		final descs:Array<String> = [];
		final keysByDesc:Map<String, Array<String>> = [];
		for (b in bindings) {
			final keys = [for (k in b.keys) '<kbd>${StringTools.htmlEscape(Key.getKeyName(k) ?? "?")}</kbd>'].join(" + ");
			final existing = keysByDesc.get(b.desc);
			if (existing != null) {
				existing.push(keys);
			} else {
				descs.push(b.desc);
				keysByDesc.set(b.desc, [keys]);
			}
		}
		for (desc in descs) {
			final p = Browser.document.createParagraphElement();
			p.innerHTML = '<span class="desc">${StringTools.htmlEscape(desc)}</span><span>${(keysByDesc.get(desc) ?? []).join(" or ")}</span>';
			card.appendChild(p);
		}
	}
}

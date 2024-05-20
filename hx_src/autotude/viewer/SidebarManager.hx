package autotude.viewer;

import autotude.Replay.showTimestamp;
import js.Browser;
import js.html.ParagraphElement;
import js.html.SpanElement;

class SidebarManager {
	final state:PlayerState;

	public function new(state:PlayerState) {
		this.state = state;
		loadSidebar();
	}

	static function sidebarEntry(time:Int, cb:(SpanElement) -> Void):ParagraphElement {
		final elem = Browser.document.createParagraphElement();
		final anchor = Browser.document.createAnchorElement();
		final separator = Browser.document.createSpanElement();
		final span = Browser.document.createSpanElement();
		elem.appendChild(anchor);
		elem.append(separator);
		elem.appendChild(span);
		anchor.innerHTML = showTimestamp(time);
		anchor.href = "#";
		separator.innerText = ": ";
		cb(span);
		return elem;
	}

	function loadSidebar() {
		final sidebar = state.sidebar;

		sidebar.appendChild(sidebarEntry(0, (span) -> span.innerText = 'map: ${state.replay.mapName}'));

		for (update in state.replay.updates) {
			for (event in update.events) {
				// final entry = sidebarEntry(update.time, event);
				// if (entry != null) {
				// 	sidebar.appendChild(entry);
				// 	entries.set(update.time, entry);
				// }
				// if (event.hasChat()) {
				// 	final message = event.chat.message;
				// 	final sender = event.chat.sender;
				// 	sidebar.appendChild(sidebarEntry('$sender: $message'));
				// }
			}
		}
	}
}

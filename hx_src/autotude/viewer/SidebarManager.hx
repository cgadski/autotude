package autotude.viewer;

using StringTools;

import js.html.Console;
import haxe.Int64;
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

	function sidebarEntry(time:Int, cb:(SpanElement) -> Void):ParagraphElement {
		final elem = Browser.document.createParagraphElement();
		final anchor = Browser.document.createAnchorElement();
		final separator = Browser.document.createSpanElement();
		final span = Browser.document.createSpanElement();
		elem.appendChild(anchor);
		elem.append(separator);
		elem.appendChild(span);
		anchor.innerHTML = showTimestamp(time);
		anchor.href = "#";
		anchor.onclick = function(e) {
			state.frameIdx = time - 15;
			e.preventDefault();
		}
		separator.innerText = ": ";
		cb(span);
		return elem;
	}

	function loadSidebar() {
		final sidebar = state.sidebar;

		sidebar.appendChild(sidebarEntry(0, (span) -> span.innerText = 'map: ${state.replay.mapName}'));

		var idx = 0;
		for (update in state.replay.updates) {
			final gameState = state.replay.gameStates[idx];
			for (event in update.events) {
				// final entry = sidebarEntry(update.time, event);
				// if (entry != null) {
				// 	sidebar.appendChild(entry);
				// 	entries.set(update.time, entry);
				// }
				if (event.hasGoal()) {
					final whoScored = gameState.getName(event.goal.whoScored[0]);
					final color = state.replay.teamColorText(gameState.getTeam(event.goal.whoScored[0]));
					sidebar.appendChild(sidebarEntry(idx, (span) -> {
						span.innerHTML = '<span style="color:$color">${whoScored.htmlEscape()}</span> scored goal';
					}));
				}
				if (event.hasChat()) {
					final message = event.chat.message;
					final sender = gameState.getName(event.chat.sender);
					final color = state.replay.teamColorText(gameState.getTeam(event.chat.sender));
					sidebar.appendChild(sidebarEntry(idx, (span) -> {
						span.innerHTML = '<span style="color:$color">${sender.htmlEscape()}</span>: ${message.htmlEscape()}';
						span.style.opacity = "0.5";
					}));
				}
				// if (event.hasKill()) {
				// 	final whoKilled = event.kill.whoKilled
				// }
			}
			idx++;
		}
	}
}

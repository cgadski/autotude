<script lang="ts">
    import { formatDuration } from "$lib";
    import GameCardSmall from "$lib/GameCardSmall.svelte";
    import type { Game } from "$lib";

    export let games: Game[];
    export let selectedGame: string | null = null;
    export let handle: string | null = null;

    function selectGame(stem: string) {
        selectedGame = selectedGame === stem ? null : stem;
    }

    function groupGamesByDay(games: Game[]) {
        const grouped = games.reduce((acc, game) => {
            if (!acc.has(game.day_bin)) {
                acc.set(game.day_bin, []);
            }
            acc.get(game.day_bin)!.push(game);
            return acc;
        }, new Map<string, Game[]>());

        return Array.from(grouped.entries())
            .sort(([a], [b]) => b.localeCompare(a))
            .map(([day_bin, games]) => ({
                day_bin,
                games,
                gameCount: games.length,
            }));
    }

    $: selectedGameData = selectedGame
        ? games.find((g) => g.stem === selectedGame) || null
        : null;
    $: groupedGames = groupGamesByDay(games);

    function isSelectedGameInDay(dayGames: Game[]) {
        return selectedGame
            ? dayGames.some((game) => game.stem === selectedGame)
            : false;
    }
</script>

<table class="table table-sm">
    <thead>
        <tr>
            <th scope="col" style="width: 6em"></th>
            <th scope="col" style="width: 6em"></th>
            <th scope="col"></th>
        </tr>
    </thead>
    <tbody>
        {#each groupedGames as { day_bin, games: dayGames, gameCount }}
            <tr class:transparent-border={isSelectedGameInDay(dayGames)}>
                <td class="text-end align-middle">
                    {new Date(day_bin + "T12:00:00Z").toLocaleDateString(
                        "en-GB",
                        {
                            weekday: "short",
                            day: "numeric",
                            month: "numeric",
                        },
                    )}
                </td>
                <td class="text-center align-middle">
                    {#if dayGames.length > 0}
                        <div class="small text-muted">
                            {gameCount} game{gameCount !== 1 ? "s" : ""}
                        </div>
                    {/if}
                </td>
                <td class="game-cell align-middle">
                    <div class="game-container">
                        {#each dayGames as game}
                            <button
                                class="game-square"
                                class:selected={selectedGame === game.stem}
                                on:click={() => selectGame(game.stem)}
                                title="Game {game.stem}"
                            >
                                <slot
                                    {game}
                                    selected={selectedGame === game.stem}
                                >
                                    <!-- Default game square if no slot content provided -->
                                    <div
                                        class="default-square"
                                        class:win={game.winner ==
                                            (game.teams["3"]?.includes(
                                                handle || "",
                                            )
                                                ? 3
                                                : 4)}
                                        class:loss={game.winner !=
                                            (game.teams["3"]?.includes(
                                                handle || "",
                                            )
                                                ? 3
                                                : 4)}
                                    ></div>
                                </slot>
                            </button>
                        {/each}
                    </div>
                </td>
            </tr>
            {#if isSelectedGameInDay(dayGames) && selectedGameData}
                <tr>
                    <td colspan="3" class="pb-3 px-3">
                        <GameCardSmall game={selectedGameData} {handle} />
                    </td>
                </tr>
            {/if}
        {/each}
    </tbody>
</table>

<style>
    .game-cell {
        vertical-align: middle;
        padding: 0.5rem;
    }

    .game-container {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 4px;
    }

    .game-square {
        width: 18px;
        height: 18px;
        border: 1px solid transparent;
        border-radius: 2px;
        cursor: pointer;
        transition: all 0.15s ease;
        padding: 0;
        margin: 0;
        background: none;
    }

    .game-square:hover {
        transform: scale(1.15);
        border-color: #ffffff;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
    }

    .game-square.selected {
        border-color: #0d6efd;
        border-width: 2px;
        box-shadow: 0 0 0 1px #0d6efd;
    }

    .default-square {
        width: 100%;
        height: 100%;
        border-radius: 2px;
    }

    .default-square.win {
        background-color: #a3d5a3;
    }

    .default-square.loss {
        background-color: #f5a3a3;
    }

    .transparent-border {
        border-bottom-color: transparent !important;
    }
</style>

<script lang="ts">
    import { formatDuration } from "$lib";
    import GameCardSmall from "$lib/GameCardSmall.svelte";
    import type { Game } from "$lib";

    export let games: Game[];
    export let selectedGame: string | null = null;

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
                                    <div class="default-square"></div>
                                </slot>
                            </button>
                        {/each}
                    </div>
                </td>
            </tr>
            {#if isSelectedGameInDay(dayGames) && selectedGameData}
                <tr>
                    <td colspan="3" class="pb-3 px-3">
                        <GameCardSmall game={selectedGameData} />
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

    .transparent-border {
        border-bottom-color: transparent !important;
    }
</style>

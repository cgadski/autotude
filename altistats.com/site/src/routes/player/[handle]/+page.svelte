<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import { formatDuration, planes } from "$lib";
    import HorizontalList from "$lib/HorizontalList.svelte";
    import GameCardSmall from "$lib/GameCardSmall.svelte";

    // @type {import('./$types').PageData}
    export let data;

    let selectedGame: string | null = null;
    let selectedGameData: any = null;

    async function selectGame(stem: string) {
        if (selectedGame === stem) {
            selectedGame = null;
            selectedGameData = null;
            return;
        }

        selectedGame = stem;

        const response = await fetch(`/api/game/${encodeURIComponent(stem)}`);
        if (response.ok) {
            selectedGameData = await response.json();
            console.log(selectedGameData);
        }
    }

    function isSelectedGameInDay(day: any) {
        if (!selectedGame) return false;
        return day.games.some((game: any) => game.stem === selectedGame);
    }
</script>

<SiteHeader />

<section>
    <h2>Player: {data.handle}</h2>

    <dl>
        <dt>Nicknames</dt>
        <dd>
            <HorizontalList items={data.nicks} let:item>{item}</HorizontalList>
        </dd>
        <dt>Time played</dt>
        <dd>
            <HorizontalList items={data.timeAlive} let:item>
                {planes[item.plane]}: {formatDuration(item.time_alive)}
            </HorizontalList>
        </dd>
    </dl>
</section>

<section>
    <h2>Recent games</h2>

    <table class="table table-sm">
        <thead>
            <tr>
                <th scope="col" style="width: 6em"></th>
                <th scope="col" style="width: 6em"></th>
                <th scope="col"></th>
            </tr>
        </thead>
        <tbody>
            {#each data.gamesByDay as day}
                <tr class:transparent-border={isSelectedGameInDay(day)}>
                    <td class="text-end align-middle">
                        {new Date(
                            day.day_bin + "T12:00:00Z",
                        ).toLocaleDateString("en-GB", {
                            weekday: "short",
                            day: "numeric",
                            month: "numeric",
                        })}
                    </td>
                    <td class="text-center align-middle">
                        {#if day.games.length > 0}
                            <div class="fw-medium">
                                {formatDuration(day.time)}
                            </div>
                            <div class="small text-muted">
                                {day.games.length} game{day.games.length !== 1
                                    ? "s"
                                    : ""}
                            </div>
                        {/if}
                    </td>
                    <td class="game-cell align-middle">
                        <div class="game-container">
                            {#each day.games as game}
                                <button
                                    class="game-square"
                                    class:win={game.winner == game.playerTeam}
                                    class:loss={game.winner != game.playerTeam}
                                    class:selected={selectedGame === game.stem}
                                    on:click={() => selectGame(game.stem)}
                                    title="Game {game.stem}"
                                ></button>
                            {/each}
                        </div>
                    </td>
                </tr>
                {#if isSelectedGameInDay(day) && selectedGameData}
                    <tr>
                        <td colspan="3" class="pb-3 px-3">
                            <GameCardSmall
                                game={selectedGameData}
                                handle={data.handle}
                            />
                        </td>
                    </tr>
                {/if}
            {/each}
        </tbody>
    </table>
</section>

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

    .game-square.win {
        background-color: #a3d5a3;
    }

    .game-square.loss {
        background-color: #f5a3a3;
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

    .transparent-border {
        border-bottom-color: transparent !important;
    }

    thead {
        height: 0;
        visibility: hidden;
    }

    thead th {
        border: none;
        padding: 0;
        height: 0;
        line-height: 0;
    }
</style>

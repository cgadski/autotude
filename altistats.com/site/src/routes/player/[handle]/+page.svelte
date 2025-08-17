<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import { formatDuration, formatDurationCoarse, planes } from "$lib";
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

    // Group data by month and scale by maximum single value
    $: monthlyData = (() => {
        const months = new Map();

        // First pass: collect data
        data.timeAliveByMonth.forEach((row) => {
            if (!months.has(row.time_bin_desc)) {
                months.set(row.time_bin_desc, {
                    month: row.time_bin_desc,
                    total_time: row.total_time,
                    planes: new Map(),
                });
            }
            months.get(row.time_bin_desc).planes.set(row.plane, {
                time_alive: row.time_alive,
                proportion: row.proportion,
            });
        });

        // Find maximum single time_alive value across all month/plane combinations
        const maxSingleValue = Math.max(
            ...data.timeAliveByMonth.map((row) => row.time_alive),
        );

        // Second pass: calculate scaled proportions for each month
        const result = Array.from(months.values()).map((month) => ({
            ...month,
            planes: new Map(
                Array.from(month.planes.entries()).map(([plane, data]) => {
                    const scaledProportion =
                        maxSingleValue > 0
                            ? data.time_alive / maxSingleValue
                            : 0;
                    return [
                        plane,
                        {
                            ...data,
                            scaledProportion,
                        },
                    ];
                }),
            ),
        }));

        return result.sort((a, b) => b.month.localeCompare(a.month));
    })();

    $: allPlanes = planes.map((_, index) => index);
</script>

<SiteHeader />

<section>
    <h2>Player: {data.handle}</h2>

    <dl>
        <dt>Nicknames</dt>
        <dd>
            <HorizontalList items={data.nicks} let:item>{item}</HorizontalList>
        </dd>
    </dl>
</section>

<section>
    <h2>Activity</h2>

    {#if monthlyData.length > 0}
        <div class="table-responsive">
            <table class="table table-sm monthly-table">
                <thead>
                    <tr>
                        <th scope="col" style="width: 6em"></th>
                        <th scope="col" style="width: 6em"></th>
                        {#each allPlanes as plane}
                            <th scope="col" class="text-center"
                                >{planes[plane]}</th
                            >
                        {/each}
                    </tr>
                </thead>
                <tbody>
                    {#each monthlyData as monthData}
                        <tr>
                            <td class="text-end align-middle">
                                {new Date(
                                    monthData.month + "-01",
                                ).toLocaleDateString("en-US", {
                                    month: "short",
                                    year: "numeric",
                                })}
                            </td>
                            <td class="text-center align-middle">
                                <div class="fw-medium">
                                    {formatDurationCoarse(monthData.total_time)}
                                </div>
                            </td>
                            {#each allPlanes as plane}
                                {@const planeData = monthData.planes.get(plane)}
                                <td
                                    class="position-relative align-middle"
                                    style="min-width: 120px;"
                                >
                                    {#if planeData}
                                        <div
                                            class="progress"
                                            style="height: 1.5rem;"
                                        >
                                            <div
                                                class="progress-bar"
                                                style="width: {planeData.scaledProportion *
                                                    100}%; background-color: hsl(210, 70%, 60%);"
                                            ></div>
                                        </div>
                                        <small
                                            class="position-absolute top-50 start-50 translate-middle text-dark fw-medium"
                                        >
                                            {formatDuration(
                                                planeData.time_alive,
                                            )}
                                        </small>
                                    {/if}
                                </td>
                            {/each}
                        </tr>
                    {/each}
                </tbody>
            </table>
        </div>
    {:else}
        <p class="text-muted">No time played data available.</p>
    {/if}
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
</style>

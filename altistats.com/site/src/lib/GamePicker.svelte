<script lang="ts">
    import { formatDuration } from "$lib";
    import GameCardSmall from "$lib/GameCardSmall.svelte";
    import type { Game } from "$lib";

    export let month: string; // yyyy-mm format
    export let games: Game[];
    export let selectedDay: string | null = null;
    export let selectedGame: string | null = null;
    export let selectedHandles: string[] = [];
    export let playerHandle: string | null = null;

    function selectDay(day: string) {
        selectedDay = selectedDay === day ? null : day;
        selectedGame = null; // Clear game selection when day changes
    }

    function selectGame(stem: string) {
        selectedGame = selectedGame === stem ? null : stem;
    }

    function getDaysInMonth(month: string) {
        const [year, monthNum] = month.split("-").map(Number);
        const firstDay = new Date(year, monthNum - 1, 1);
        const lastDay = new Date(year, monthNum, 0);
        const daysInMonth = lastDay.getDate();

        // Get day of week for first day (0 = Sunday, 1 = Monday, etc.)
        const firstDayOfWeek = firstDay.getDay();

        const days = [];

        // Add empty cells for days before the first day of the month
        for (let i = 0; i < firstDayOfWeek; i++) {
            days.push(null);
        }

        // Add all days of the month
        for (let day = 1; day <= daysInMonth; day++) {
            const dayString = `${year}-${monthNum.toString().padStart(2, "0")}-${day.toString().padStart(2, "0")}`;
            days.push(dayString);
        }

        return days;
    }

    function getGamesForDay(day: string) {
        return games.filter((game) => game.day_bin === day);
    }

    function hasGames(day: string) {
        return games.some((game) => game.day_bin === day);
    }

    function hasSelectedPlayers(day: string) {
        if (selectedHandles.length === 0) return false;

        return games
            .filter((game) => game.day_bin === day)
            .some((game) => {
                const team3Players = game.teams["3"] || [];
                const team4Players = game.teams["4"] || [];
                const allPlayers = [...team3Players, ...team4Players];
                return selectedHandles.every((handle) =>
                    allPlayers.includes(handle),
                );
            });
    }

    function isPlayerWin(game: any): boolean {
        if (!playerHandle) return false;
        const team3Players = game.teams["3"] || [];
        const team4Players = game.teams["4"] || [];

        const playerTeam = team3Players.includes(playerHandle)
            ? 3
            : team4Players.includes(playerHandle)
              ? 4
              : null;

        return playerTeam !== null && game.winner === playerTeam;
    }

    function formatDayNumber(day: string) {
        return new Date(day + "T12:00:00Z").getDate();
    }

    $: selectedGameData = selectedGame
        ? games.find((g) => g.stem === selectedGame) || null
        : null;
    $: selectedDayGames = selectedDay ? getGamesForDay(selectedDay) : [];
    $: monthDays = getDaysInMonth(month);

    const weekDays = ["S", "M", "T", "W", "T", "F", "S"];
</script>

<div class="game-picker">
    <div class="row">
        <div class="col-12 col-md-auto mb-4">
            <!-- Calendar View -->
            <div class="d-flex justify-content-center justify-content-md-start">
                <div class="calendar-grid">
                    <!-- Week day headers -->
                    {#each weekDays as weekDay}
                        <div class="calendar-day-header">{weekDay}</div>
                    {/each}

                    <!-- Calendar days -->
                    {#each monthDays as day}
                        {#if day === null}
                            <div class="calendar-day empty"></div>
                        {:else}
                            <button
                                class="calendar-day"
                                class:has-games={hasGames(day)}
                                class:selected={selectedDay === day}
                                on:click={() => selectDay(day)}
                                title={hasGames(day)
                                    ? `${getGamesForDay(day).length} games`
                                    : "No games"}
                            >
                                {#if hasSelectedPlayers(day)}
                                    <div class="search-indicator"></div>
                                {/if}
                            </button>
                        {/if}
                    {/each}
                </div>
            </div>
        </div>

        <div class="col-12 col-md">
            <!-- Selected Day Games View -->
            {#if selectedDay && selectedDayGames.length > 0}
                <div class="mb-3">
                    <strong>
                        {new Date(
                            selectedDay + "T12:00:00Z",
                        ).toLocaleDateString("en-GB", {
                            weekday: "short",
                            day: "numeric",
                            month: "numeric",
                        })}
                    </strong>
                    <div class="small text-muted">
                        {selectedDayGames.length} game{selectedDayGames.length !==
                        1
                            ? "s"
                            : ""}
                    </div>
                </div>
                <div class="game-container mb-3">
                    {#each selectedDayGames as game}
                        <button
                            class="game-square"
                            class:selected={selectedGame === game.stem}
                            on:click={() => selectGame(game.stem)}
                            title="Game {game.stem}"
                        >
                            <div
                                class="game-square-content"
                                class:win={playerHandle && isPlayerWin(game)}
                                class:loss={playerHandle &&
                                    !isPlayerWin(game) &&
                                    (game.teams["3"]?.includes(playerHandle) ||
                                        game.teams["4"]?.includes(
                                            playerHandle,
                                        ))}
                                class:team-3={!playerHandle &&
                                    game.winner === 3}
                                class:team-4={!playerHandle &&
                                    game.winner === 4}
                            >
                                {#if selectedHandles.length > 0 && selectedHandles.every( (handle) => [...(game.teams["3"] || []), ...(game.teams["4"] || [])].includes(handle), )}
                                    <div class="player-indicator"></div>
                                {/if}
                            </div>
                        </button>
                    {/each}
                </div>
                {#if selectedGame && selectedGameData}
                    <div>
                        <GameCardSmall game={selectedGameData} />
                    </div>
                {/if}
            {:else if selectedDay}
                <div class="mb-3">
                    <strong>
                        {new Date(
                            selectedDay + "T12:00:00Z",
                        ).toLocaleDateString("en-GB", {
                            weekday: "short",
                            day: "numeric",
                            month: "numeric",
                        })}
                    </strong>
                    <div class="small text-muted">0 games</div>
                </div>
            {/if}
        </div>
    </div>
</div>

<style>
    .calendar-grid {
        display: grid;
        grid-template-columns: repeat(7, 36px);
        gap: 4px;
        background-color: white;
        width: fit-content;
    }

    .calendar-day-header {
        background-color: #f8f9fa;
        padding: 0.25rem;
        text-align: center;
        font-weight: 600;
        font-size: 0.75rem;
        color: #6c757d;
    }

    .calendar-day {
        background-color: #e9ecef;
        border: 1px solid transparent;
        padding: 0;
        text-align: center;
        cursor: pointer;
        transition: all 0.2s ease;
        position: relative;
        width: 36px;
        height: 36px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 0.75rem;
        border-radius: 2px;
    }

    .calendar-day.empty {
        background-color: transparent;
        cursor: default;
    }

    .calendar-day:not(.empty):hover {
        background-color: #dee2e6;
    }

    .calendar-day:not(.has-games):not(.empty)::before,
    .calendar-day:not(.has-games):not(.empty)::after {
        content: "";
        position: absolute;
        top: 50%;
        left: 50%;
        width: 24px;
        height: 1px;
        background-color: #6c757d;
        transform-origin: center;
    }

    .calendar-day:not(.has-games):not(.empty)::before {
        transform: translate(-50%, -50%) rotate(45deg);
    }

    .calendar-day:not(.has-games):not(.empty)::after {
        transform: translate(-50%, -50%) rotate(-45deg);
    }

    .calendar-day.has-games {
        background-color: #e9ecef;
        border: 1px solid transparent;
    }

    .calendar-day.has-games:hover {
        background-color: #dee2e6;
    }

    .calendar-day.selected {
        background-color: #e9ecef;
        border: 3px solid #0d6efd;
    }

    .calendar-day.selected:hover {
        background-color: #dee2e6;
    }

    .search-indicator {
        position: absolute;
        width: 8px;
        height: 8px;
        background-color: black;
        border-radius: 50%;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
    }

    .game-square-content {
        width: 100%;
        height: 100%;
        position: relative;
        border-radius: 2px;
    }

    .game-square-content.win {
        background-color: #a3d5a3;
    }

    .game-square-content.loss {
        background-color: #f5a3a3;
    }

    .game-square-content.team-3 {
        background-color: rgba(220, 53, 69, 0.25);
    }

    .game-square-content.team-4 {
        background-color: rgba(13, 110, 253, 0.25);
    }

    .player-indicator {
        position: absolute;
        width: 8px;
        height: 8px;
        background-color: black;
        border-radius: 50%;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
    }
</style>

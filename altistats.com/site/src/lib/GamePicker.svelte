<script lang="ts">
    import { generateCalendarDays, formatTime } from "$lib";
    import GameCard from "$lib/GameCard.svelte";
    import HorizontalList from "$lib/HorizontalList.svelte";
    import type { Game } from "$lib";
    import { onMount } from "svelte";

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

    function getPlayerGamesForDay(day: string) {
        if (selectedHandles.length === 0) return [];

        return games.filter((game) => {
            if (game.day_bin !== day) return false;

            const team3Players = game.teams["3"] || [];
            const team4Players = game.teams["4"] || [];
            const allPlayers = [...team3Players, ...team4Players];
            return selectedHandles.every((handle) =>
                allPlayers.includes(handle),
            );
        });
    }

    function shouldMarkDay(day: string) {
        return selectedHandles.length > 0 && hasSelectedPlayers(day);
    }

    function shouldMarkGame(game: Game) {
        return (
            selectedHandles.length > 0 &&
            selectedHandles.every((handle) =>
                [
                    ...(game.teams["3"] || []),
                    ...(game.teams["4"] || []),
                ].includes(handle),
            )
        );
    }

    function gameColor(game: Game) {
        if (playerHandle) {
            const team3Players = game.teams["3"] || [];
            const team4Players = game.teams["4"] || [];

            const playerTeam = team3Players.includes(playerHandle)
                ? 3
                : team4Players.includes(playerHandle)
                  ? 4
                  : null;

            let won = game.winner === playerTeam;
            return won ? "bg-success-subtle" : "bg-danger-subtle";
        } else {
            return game.winner == 3 ? "team-red" : "team-blue";
        }
    }

    $: selectedGameData = selectedGame
        ? games.find((g) => g.stem === selectedGame) || null
        : null;
    $: selectedDayGames = selectedDay ? getGamesForDay(selectedDay) : [];
    $: monthDays = generateCalendarDays(month);

    const weekDays = ["S", "M", "T", "W", "T", "F", "S"];

    // Auto-select the last day with games when component mounts or month changes
    $: if (month && games.length > 0 && selectedDay === null) {
        const daysWithGames = games
            .filter((game) => game.day_bin.startsWith(month))
            .map((game) => game.day_bin)
            .sort();

        if (daysWithGames.length > 0) {
            const lastDay = daysWithGames[daysWithGames.length - 1];
            selectedDay = lastDay;
        }
    }

    function dayGameCount(day: string) {
        if (selectedHandles.length > 0) {
            let games = getPlayerGamesForDay(day).length;
            if (games > 0) {
                return games;
            } else {
                return "";
            }
        } else {
            return getGamesForDay(day).length;
        }
    }
</script>

{#snippet marker()}
    <i
        class="bi bi-person-fill position-absolute bottom-0 end-0 pe-1 text-dark"
        style="font-size: 12px; padding: 2px;"
    ></i>
{/snippet}

{#snippet daySquare(day: string)}
    <button
        class="p-0 square bg-transparent border-0"
        on:click={() => selectDay(day)}
    >
        <div
            class="
            h-100 w-100 border rounded-1
        {selectedDay === day ? 'border-primary border-3' : 'border-secondary'}
        {hasGames(day) ? 'bg-secondary-subtle' : 'bg-white'}"
        ></div>
        {#if hasGames(day)}
            <span class="position-absolute top-0 start-0 ps-1 text-dark small">
                {dayGameCount(day)}
            </span>
        {/if}
        {#if shouldMarkDay(day)}
            {@render marker()}
        {/if}
    </button>
{/snippet}

{#snippet gameSquare(game: Game)}
    <button
        class="p-0 square bg-transparent border-0"
        on:click={() => selectGame(game.stem)}
    >
        <div
            class="
            h-100 w-100 border rounded-1
        {selectedGame === game.stem
                ? 'border-primary border-3'
                : 'border-secondary'}
        {gameColor(game)}"
        ></div>
        {#if shouldMarkGame(game)}
            {@render marker()}
        {/if}
    </button>
{/snippet}

<div class="row">
    <div
        class="d-flex col-md-auto justify-content-center justify-content-md-start"
    >
        <div class="calendar-grid mb-3 mb-md-0">
            {#each weekDays as weekDay}
                <div
                    class="text-center align-content-center fw-bold text-muted small"
                >
                    {weekDay}
                </div>
            {/each}

            {#each monthDays as day}
                {#if day === null}
                    <div class="square bg-transparent border-0"></div>
                {:else}
                    {@render daySquare(day)}
                {/if}
            {/each}
        </div>
    </div>

    <div class="col-12 col-md">
        {#if selectedDay}
            <div class="mb-3">
                <strong>
                    {new Date(selectedDay + "T12:00:00Z").toLocaleDateString(
                        "en-GB",
                        {
                            weekday: "short",
                            day: "numeric",
                            month: "numeric",
                        },
                    )}
                </strong>
                <div class="small text-muted">
                    <HorizontalList
                        items={[
                            `${selectedDayGames.length} game${selectedDayGames.length !== 1 ? "s" : ""}`,
                            ...(selectedDayGames.length > 0
                                ? [
                                      selectedDayGames.length > 1
                                          ? `${formatTime(selectedDayGames[0].started_at)} - ${formatTime(selectedDayGames[selectedDayGames.length - 1].started_at)}`
                                          : formatTime(
                                                selectedDayGames[0].started_at,
                                            ),
                                  ]
                                : []),
                        ]}
                        let:item
                    >
                        {item}
                    </HorizontalList>
                </div>
            </div>
            <div class="d-flex flex-wrap gap-1 mb-3">
                {#each selectedDayGames as game}
                    {@render gameSquare(game)}
                {/each}
            </div>
            {#if selectedGame && selectedGameData}
                <GameCard
                    game={selectedGameData}
                    handles={selectedHandles}
                    handle={playerHandle}
                />
            {/if}
        {/if}
    </div>
</div>

<style>
    .calendar-grid {
        display: grid;
        grid-template-columns: repeat(7, 36px);
        grid-template-rows: 2rem repeat(auto-fill, 36px);
        gap: 4px;
        width: fit-content;
    }

    .square {
        width: 36px;
        height: 36px;
        position: relative;
        box-sizing: border-box;
    }
</style>

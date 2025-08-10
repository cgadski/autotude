<script lang="ts">
    import { formatFullDate, formatStat } from "$lib";

    import type { Game } from "$lib";

    export let game: Game;
    export let linkForm;
</script>

{#if linkForm}
    <a class="card-container clickable-card" href="/game/{game.stem}">
        <div
            class="card-head d-flex justify-content-between align-items-center"
        >
            <div class="time-cell">
                {formatFullDate(game.started_at)}
            </div>
            <div class="map-cell">
                {game.map}
            </div>
            <div
                class="duration-cell d-flex align-items-center justify-content-end"
            >
                <span>{formatStat(game.duration, ["duration"])}</span>
                <i class="bi bi-chevron-right ms-2"></i>
            </div>
        </div>

        <div class="teams">
            <div class="team team-3">
                <div class="team-header">
                    {#if game.winner === 3}
                        <i class="bi bi-trophy-fill text-warning trophy"></i>
                    {/if}
                </div>
                <div class="players-grid">
                    {#each game.teams["3"] || [] as player, index}
                        <span
                            class="badge bg-danger bg-opacity-75 player-badge"
                        >
                            {player.nick}
                        </span>
                    {/each}
                </div>
            </div>
            <div class="team team-4">
                <div class="team-header">
                    {#if game.winner === 4}
                        <i class="bi bi-trophy-fill text-warning trophy"></i>
                    {/if}
                </div>
                <div class="players-grid">
                    {#each game.teams["4"] || [] as player, index}
                        <span
                            class="badge bg-primary bg-opacity-75 player-badge"
                        >
                            {player.nick}
                        </span>
                    {/each}
                </div>
            </div>
        </div>
    </a>
{:else}
    <div class="card-container">
        <div
            class="card-head d-flex justify-content-between align-items-center"
        >
            <div class="time-cell">
                {formatFullDate(game.started_at)}
            </div>
            <div class="map-cell">
                {game.map}
            </div>
            <div
                class="duration-cell d-flex align-items-center justify-content-end"
            >
                <span>{formatStat(game.duration, ["duration"])}</span>
            </div>
        </div>

        <div class="teams">
            <div class="team team-3">
                <div class="team-header">
                    {#if game.winner === 3}
                        <i class="bi bi-trophy-fill text-warning trophy"></i>
                    {/if}
                </div>
                <div class="players-grid">
                    {#each game.teams["3"] || [] as player, index}
                        <a
                            href="/player/{player.vapor}"
                            class="text-decoration-none"
                        >
                            <span
                                class="badge bg-danger bg-opacity-75 player-badge"
                            >
                                {player.nick}
                            </span>
                        </a>
                    {/each}
                </div>
            </div>
            <div class="team team-4">
                <div class="team-header">
                    {#if game.winner === 4}
                        <i class="bi bi-trophy-fill text-warning trophy"></i>
                    {/if}
                </div>
                <div class="players-grid">
                    {#each game.teams["4"] || [] as player, index}
                        <a
                            href="/player/{player.vapor}"
                            class="text-decoration-none"
                        >
                            <span
                                class="badge bg-primary bg-opacity-75 player-badge"
                            >
                                {player.nick}
                            </span>
                        </a>
                    {/each}
                </div>
            </div>
        </div>
    </div>
{/if}

<style>
    .teams {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 0.25rem;
        padding: 0.25rem;
    }

    .team {
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
    }

    .team-header {
        display: flex;
        justify-content: center;
        align-items: center;
        min-height: 1.5rem;
    }

    .trophy {
        font-size: 1rem;
    }

    .players-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 0.25rem;
    }

    .player-badge {
        display: inline-block;
        margin: 0.1rem;
        transition: opacity 0.2s;
        font-size: 0.75rem;
    }

    .player-badge:hover {
        opacity: 0.8;
    }

    .card-container {
        margin-top: 0.5em;
        border-radius: 6px;
        box-shadow: 0 1px 6px rgba(0, 0, 0, 0.05);
        background-color: white;
        border: 1px solid #eaeaea;
        overflow: hidden;
    }

    .card-head {
        text-decoration: none;
        color: inherit;
        padding: 0.5rem;
        background-color: white;
        box-sizing: border-box;
    }

    .clickable-card {
        transition: all 0.15s ease-in-out;
        cursor: pointer;
        text-decoration: none;
        color: inherit;
        display: block;
    }

    .clickable-card:hover {
        background-color: #f8f9fa;
        border-color: var(--bs-primary);
        color: inherit;
    }

    .clickable-card:hover .card-head {
        background-color: transparent;
    }

    .time-cell,
    .map-cell,
    .duration-cell {
        padding: 0 0.25rem;
        overflow: hidden;
    }

    .time-cell {
        width: 25%;
        color: #666;
    }

    .map-cell {
        width: 50%;
        font-weight: 500;
    }

    .duration-cell {
        width: 25%;
    }

    @media (max-width: 576px) {
        .time-cell {
            width: 25%;
        }
        .map-cell {
            width: 40%;
        }

        .duration-cell {
            width: 35%;
        }
    }
</style>

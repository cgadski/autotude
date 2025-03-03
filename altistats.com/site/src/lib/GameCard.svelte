<script lang="ts">
    import { formatDuration } from "$lib";

    import type { Game } from "$lib/db";

    export let game: Game;
    export let linkForm;

    // Format the full date for display
    const formatFullDate = (dateStr: string) => {
        const date = new Date(dateStr);
        const month = new Intl.DateTimeFormat("en", { month: "short" }).format(
            date,
        );
        const day = date.getDate();
        const hours = String(date.getHours()).padStart(2, "0");
        const minutes = String(date.getMinutes()).padStart(2, "0");
        return `${month} ${day} ${hours}h${minutes}`;
    };
</script>

{#if linkForm}
    <a
        class="card-head d-flex justify-content-between align-items-center clickable-head"
        href="/game/{game.stem}"
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
            <span>{formatDuration(game.duration)}</span>
            <i class="bi bi-chevron-right ms-2"></i>
        </div>
    </a>
{:else}
    <div class="card-head d-flex justify-content-between align-items-center">
        <div class="time-cell">
            {formatFullDate(game.started_at)}
        </div>
        <div class="map-cell">
            {game.map}
        </div>
        <div
            class="duration-cell d-flex align-items-center justify-content-end"
        >
            <span>{formatDuration(game.duration)}</span>
        </div>
    </div>
{/if}

<div class="teams">
    <div class="team">
        {#each game.teams["3"] || [] as player}
            <a href="/player/{player.vapor}" class="text-decoration-none">
                <span class="badge bg-danger bg-opacity-75 player-badge">
                    {player.nick}
                    <i class="bi bi-person-circle ms-1 opacity-75"></i>
                </span>
            </a>
        {/each}
    </div>
    <div class="team">
        {#each game.teams["4"] || [] as player}
            <a href="/player/{player.vapor}" class="text-decoration-none">
                <span class="badge bg-primary bg-opacity-75 player-badge">
                    {player.nick}
                    <i class="bi bi-person-circle ms-1 opacity-75"></i>
                </span>
            </a>
        {/each}
    </div>
</div>

<style>
    .teams {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 1rem;
    }

    .player-badge {
        display: inline-block;
        margin: 0.2rem;
        transition: opacity 0.2s;
    }

    .player-badge:hover {
        opacity: 0.8;
    }

    .card-head {
        text-decoration: none;
        color: inherit;
        padding: 0.75rem;
        background-color: white;
        margin-top: 1em;
        box-sizing: border-box;

        border-radius: 8px;
        box-shadow: 0 1px 8px rgba(0, 0, 0, 0.05);
        background-color: white;
        border: 1px solid #eaeaea;
    }

    .clickable-head {
        transition: all 0.15s ease-in-out;
        cursor: pointer;
    }

    .clickable-head:hover {
        background-color: #f8f9fa;
        border-color: var(--bs-primary);
    }

    .time-cell,
    .map-cell,
    .duration-cell {
        padding: 0 0.5rem;
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

    .teams {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 0.5rem;
    }

    .team {
        padding: 0.5rem;
        border-radius: 4px;
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

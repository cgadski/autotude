<script lang="ts">
    import { formatDuration } from "$lib";

    export let game: {
        stem: string;
        map: string;
        started_at: string;
        duration: number;
        teams?: {
            "3": Array<{ nick: string; vapor: string }>;
            "4": Array<{ nick: string; vapor: string }>;
        };
    };
    export let linkForm;

    // Format the full date for display
    const formatFullDate = (dateStr: string) => {
        const date = new Date(dateStr);
        return date.toLocaleTimeString([], {
            month: "short",
            day: "numeric",
            hour: "2-digit",
            minute: "2-digit",
        });
    };
</script>

{#if linkForm}
    <a
        class="card-head d-flex justify-content-between align-items-center"
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

<!-- Expanded details view -->
{#if !linkForm}
    <div class="teams p-2">
        <div class="team red">
            {#each game.teams["3"] || [] as player}
                <div>
                    <a href="/player/{player.vapor}">{player.nick}</a>
                </div>
            {/each}
        </div>
        <div class="team blue">
            {#each game.teams["4"] || [] as player}
                <div>
                    <a href="/player/{player.vapor}">{player.nick}</a>
                </div>
            {/each}
        </div>
    </div>

    <p>
        <a href="/viewer/?f={game.stem}.pb">View replay</a> (desktop only)
    </p>
{/if}

<style>
    .card-head {
        text-decoration: none;
        color: inherit;
        /* margin: 0.5em; */
    }

    .game-card-container {
        margin-bottom: 0.5rem;
        border: 1px solid #dee2e6;
        border-radius: 0.25rem;
        overflow: hidden;
    }

    .time-cell,
    .map-cell,
    .duration-cell {
        padding: 0 0.5rem;
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

    .blue {
        background: #96ccff;
    }

    .red {
        background: #fbabab;
    }

    @media (max-width: 576px) {
        .map-cell {
            width: 43%;
        }

        .time-cell {
            width: 27%;
        }
        .duration-cell {
            width: 30%;
        }
    }
</style>

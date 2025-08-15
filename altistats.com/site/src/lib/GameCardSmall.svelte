<script lang="ts">
    import { formatDatetime, formatStat } from "$lib";

    import type { Game } from "$lib";
    import HorizontalList from "./HorizontalList.svelte";

    export let game: Game;
</script>

<div class="game-card">
    <div class="game-header">
        <div class="time">
            {formatDatetime(game.started_at)}
        </div>
        <div class="map">
            {game.map}
        </div>
        <div class="duration">
            {formatStat(game.duration, ["duration"])}
        </div>
    </div>

    <div class="teams">
        <div class="team team-red">
            <div class="players">
                <HorizontalList items={game.teams["3"]} let:item>
                    <a href="/player/{item}" class="player-link">
                        {item}
                    </a>
                </HorizontalList>
            </div>
            <div class="trophy-space">
                {#if game.winner === 3}
                    <i class="bi bi-trophy-fill trophy"></i>
                {/if}
            </div>
        </div>

        <div class="team team-blue">
            <div class="players">
                <HorizontalList items={game.teams["4"]} let:item>
                    <a href="/player/{item}" class="player-link">
                        {item}
                    </a>
                </HorizontalList>
            </div>
            <div class="trophy-space">
                {#if game.winner === 4}
                    <i class="bi bi-trophy-fill trophy"></i>
                {/if}
            </div>
        </div>
    </div>
</div>

<style>
    .game-card {
        margin: 0.5rem 0;
        border-radius: 8px;
        box-shadow: 0 1px 6px rgba(0, 0, 0, 0.1);
        background-color: white;
        border: 1px solid #e0e0e0;
        overflow: hidden;
    }

    .game-header {
        display: flex;
        align-items: center;
        padding: 0.5rem 0.75rem;
        background-color: #f8f9fa;
        border-bottom: 1px solid #e0e0e0;
        font-size: 0.9rem;
    }

    .time {
        color: #666;
        flex: 0 0 auto;
        margin-right: 0.75rem;
    }

    .map {
        font-weight: 500;
        flex: 1;
    }

    .duration {
        color: #666;
        font-size: 0.85rem;
        display: flex;
        align-items: center;
        flex: 0 0 auto;
    }

    .teams {
        display: flex;
    }

    .team {
        flex: 1;
        display: flex;
        align-items: center;
        padding: 0.5rem;
        min-height: 2.5rem;
    }

    .team-red {
        background-color: rgba(220, 53, 69, 0.08);
        border-right: 1px solid rgba(220, 53, 69, 0.2);
    }

    .team-blue {
        background-color: rgba(13, 110, 253, 0.08);
    }

    .players {
        flex: 1;
        display: flex;
        flex-wrap: wrap;
        gap: 0.25rem 0.5rem;
        align-items: center;
    }

    .separator {
        color: #999;
        font-size: 0.75rem;
        margin: 0 0.1rem;
    }

    .player {
        font-size: 0.85rem;
        color: #333;
    }

    .player-link {
        font-size: 0.85rem;
        color: #333;
        text-decoration: none;
        transition: color 0.15s ease;
    }

    .player-link:hover {
        color: #0066cc;
        text-decoration: underline;
    }

    .trophy-space {
        flex: 0 0 1.5rem;
        display: flex;
        align-items: center;
        justify-content: center;
        margin-left: 0.5rem;
    }

    .trophy {
        color: #ffc107;
        font-size: 1rem;
    }

    /* Mobile layout */
    @media (max-width: 576px) {
        .teams {
            flex-direction: column;
        }

        .team-red {
            border-right: none;
            border-bottom: 1px solid rgba(220, 53, 69, 0.2);
        }

        .game-header {
            font-size: 0.85rem;
        }

        .time {
            margin-right: 0.5rem;
        }
    }
</style>

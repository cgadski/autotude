<script lang="ts">
    export let game: {
        stem: string;
        map: string;
        started_at: string;
        teams: {
            "3": Array<{ nick: string; vapor: string }>;
            "4": Array<{ nick: string; vapor: string }>;
        };
    };
    export let disableLink: boolean = false;
</script>

{#if disableLink}
    <div class="game-card no-link">
        <div class="header">
            <strong class="map-name">{game.map}</strong>
            <span class="time"
                >{new Date(game.started_at).toLocaleString()}</span
            >
        </div>
        <div class="teams">
            <div class="team blue">
                {#each game.teams["3"] || [] as player}
                    <div class="player">{player.nick}</div>
                {/each}
            </div>
            <div class="team red">
                {#each game.teams["4"] || [] as player}
                    <div class="player">{player.nick}</div>
                {/each}
            </div>
        </div>
    </div>
{:else}
    <a href="/game/{game.stem}" class="game-card">
        <div class="header">
            <strong class="map-name">{game.map}</strong>
            <span class="time"
                >{new Date(game.started_at).toLocaleString()}</span
            >
        </div>
        <div class="teams">
            <div class="team blue">
                {#each game.teams["3"] || [] as player}
                    <div class="player">{player.nick}</div>
                {/each}
            </div>
            <div class="team red">
                {#each game.teams["4"] || [] as player}
                    <div class="player">{player.nick}</div>
                {/each}
            </div>
        </div>
    </a>
{/if}

<style>
    .game-card {
        padding: 1rem;
        margin: 0.5rem 0;
        background: rgba(0, 0, 0, 0.03);
        border-radius: 4px;
        text-decoration: none;
        color: inherit;
        display: block;
    }

    .game-card:not(.no-link) {
        transition: all 0.2s ease;
    }

    .game-card:not(.no-link):hover {
        background: rgba(0, 0, 0, 0.07);
    }

    .header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 0.5rem;
    }

    .map-name {
        font-size: 1.17em;
        margin: 0;
    }

    .teams {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 1rem;
    }

    .team {
        padding: 0.5rem;
        border-radius: 4px;
    }

    .blue {
        background: #96ccff;
        transition: background 0.2s ease;
    }

    .red {
        background: #fbabab;
        transition: background 0.2s ease;
    }

    .game-card:not(.no-link):hover .blue {
        background: #7abbff;
    }

    .game-card:not(.no-link):hover .red {
        background: #f99a9a;
    }

    .player {
        padding: 0.2rem 0;
    }
</style>

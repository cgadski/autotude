<script lang="ts">
    import GamePicker from "$lib/GamePicker.svelte";

    export let data;

    let selectedGame: string | null = null;
</script>

<div class="narrow no-bg">
    <GamePicker games={data.games} bind:selectedGame let:game>
        <div
            class="game-square-content"
            class:win={game.winner ===
                (game.teams["3"]?.includes(data.handle) ? 3 : 4)}
            class:loss={game.winner !==
                (game.teams["3"]?.includes(data.handle) ? 3 : 4)}
        ></div>
    </GamePicker>
</div>

<style>
    .game-square-content {
        width: 100%;
        height: 100%;
        position: relative;
    }

    .game-square-content.win {
        background-color: #d4edda;
        border-color: #c3e6cb;
    }

    .game-square-content.loss {
        background-color: #f8d7da;
        border-color: #f5c6cb;
    }
</style>

<script lang="ts">
    import GameCard from "$lib/GameCard.svelte";
    import type { Game } from "$lib/db";

    /* @type {import('./$types').PageData} */
    export let data: {
        game: Game;
    };
</script>

<svelte:head>
    <link rel="stylesheet" href="/css/water.css" />
</svelte:head>

<div class="container">
    <h1>Game Details</h1>
    {#if data.game}
        <GameCard game={data.game} disableLink="true" />
    {:else}
        <p>Game not found</p>
    {/if}
</div>

<style>
    .container {
        max-width: 800px;
        margin: 0 auto;
        padding: 1rem;
    }
</style>

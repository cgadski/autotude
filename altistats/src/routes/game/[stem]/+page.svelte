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

<h1>Game Details</h1>
{#if data.game}
    <GameCard game={data.game} disableLink="true" />
{:else}
    <p>Game not found</p>
{/if}

<h2>Stats</h2>

<p>Coming soon...</p>

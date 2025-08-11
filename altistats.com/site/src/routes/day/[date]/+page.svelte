<script lang="ts">
    import { formatDate } from "$lib";
    import GameCard from "$lib/GameCard.svelte";
    import SiteHeader from "$lib/SiteHeader.svelte";

    // @type {import('./$types').PageData}
    export let data;
</script>

<SiteHeader />

<section class="no-bg">
    <h2>
        {data.games.length} games from {formatDate(data.date)}
    </h2>

    <div class="mt-3">
        {#each data.games as game, i}
            <GameCard {game} linkForm="true" />
        {/each}
    </div>
</section>

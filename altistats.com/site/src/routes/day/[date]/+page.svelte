<script lang="ts">
    import { formatDuration } from "$lib";
    import GameCard from "$lib/GameCard.svelte";
    import SiteHeader from "$lib/SiteHeader.svelte";

    // @type {import('./$types').PageData}
    export let data;

    // Format the date for display
    const formatDate = (dateStr: string) => {
        const date = new Date(dateStr);
        return date.toLocaleDateString("en-US", {
            weekday: "long",
            year: "numeric",
            month: "long",
            day: "numeric",
        });
    };
</script>

<div>
    <SiteHeader />

    <div class="content-section">
        <h2 class="section-title">
            {data.games.length} games from {formatDate(data.date)}
        </h2>

        <div class="mt-2">
            {#each data.games as game, i}
                <GameCard {game} linkForm="true" />
            {/each}
        </div>
    </div>
</div>

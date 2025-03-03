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

<SiteHeader />

<section>
    <h2>Player: {data.player.nick}</h2>

    <div class="player-stats">
        <div class="row cols-2 g-2">
            <div class="col">
                <div class="card h-100">
                    <div class="card-body text-center">
                        <p class="h4 mb-0">{data.player.games}</p>
                        <p class="mb-0 small">Games Played</p>
                    </div>
                </div>
            </div>
            <div class="col">
                <div class="card h-100">
                    <div class="card-body text-center">
                        <p class="h4 mb-0">{data.player.days_played}</p>
                        <p class="mb-0 small">Days Active</p>
                    </div>
                </div>
            </div>
            <div class="col">
                <div class="card h-100">
                    <div class="card-body text-center">
                        <p class="h4 mb-0">
                            {new Date(
                                data.player.last_seen,
                            ).toLocaleDateString()}
                        </p>
                        <p class="mb-0 small">Last Played</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
    {#if data.player.nicks.length > 1}
        <h2>Nicknames</h2>
        <div class="d-flex flex-wrap gap-2">
            {#each data.player.nicks as nick}
                <span class="badge bg-secondary">{nick}</span>
            {/each}
        </div>
    {/if}
</section>

<section class="no-bg">
    <h2>Games</h2>

    {#if data.gamesByDate && data.gamesByDate.length > 0}
        {#each data.gamesByDate as dateGroup}
            <h6 class="date-header">
                {formatDate(dateGroup.binned_date)}
            </h6>
            {#each dateGroup.games as game}
                <GameCard {game} linkForm={true} />
            {/each}
            <div class="games-list"></div>
        {/each}
    {:else}
        <p class="text-muted">No games found for this player.</p>
    {/if}
</section>

<style>
    .date-header {
        background-color: #f8f9fa;
        padding: 0.5rem;
        border-radius: 4px;
        margin-bottom: 0.5rem;
    }

    .games-list {
        margin-left: 1rem;
    }
</style>

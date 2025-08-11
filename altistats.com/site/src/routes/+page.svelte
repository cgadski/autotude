<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import GameCard from "$lib/GameCard.svelte";
    import { formatStat, formatDatetime } from "$lib";
    import * as d3 from "d3";
    import { onMount } from "svelte";
    import { invalidateAll } from "$app/navigation";

    // @type {import('./$types').PageData}
    export let data;
    // let secondsAgo = 0;
    // let chartElement: HTMLElement;
    // let refreshInterval: number;

    // function updateTimer() {
    //     if (data.lastUpdate) {
    //         const lastUpdate = new Date(data.lastUpdate);
    //         secondsAgo = Math.floor((new Date() - lastUpdate) / 1000);

    //         if (secondsAgo > 60) {
    //             invalidateAll();
    //         }
    //     }
    // }

    // onMount(() => {
    //     refreshInterval = setInterval(updateTimer, 1000) as unknown as number;
    //     updateTimer();

    //     return () => {
    //         clearInterval(refreshInterval);
    //     };
    // });

    // onMount(() => {
    //     renderChart();

    //     const resizeObserver = new ResizeObserver(() => {
    //         renderChart();
    //     });

    //     if (chartElement) {
    //         resizeObserver.observe(chartElement);
    //     }

    //     return () => {
    //         if (chartElement) {
    //             resizeObserver.unobserve(chartElement);
    //         }
    //     };
    // });

    const mainStatKeys = ["_total_games", "_total_time", "_total_players"];

    const mainStats = data.globalStats.filter((stat) =>
        mainStatKeys.includes(stat.query_name),
    );

    const miniStats = data.globalStats.filter(
        (stat) => !mainStatKeys.includes(stat.query_name),
    );
</script>

<SiteHeader navPage="home" />

<section>
    <h2>Active servers</h2>
    <div class="d-flex flex-wrap gap-2">
        {#each data.listings as listing}
            <div class="card">
                <div class="card-body py-2 px-3 d-flex align-items-center">
                    <div class="me-2 server-info">
                        <span class="fw-medium server-name">{listing.name}</span
                        >
                        <small class="text-muted ms-2 map-name"
                            >{listing.map}</small
                        >
                    </div>
                    <span class="badge bg-primary rounded-pill ms-1"
                        >{listing.players}</span
                    >
                </div>
            </div>
        {/each}
    </div>
    <!-- <p class="text-muted small text-end mt-2 mb-0">
        (Update from {secondsAgo} seconds ago)
    </p> -->
</section>

<section>
    <h2>Past activity (3 days)</h2>
    <div class="chart-container" bind:this={chartElement}></div>
</section>

<section>
    <h2>Recording database</h2>

    <div class="row cols-2 g-2 mb-2">
        {#each mainStats as stat}
            <div class="col">
                <div class="card stats-card">
                    <div class="card-body text-center">
                        <p class="h4 mb-0">
                            {formatStat(stat.stat, stat.attributes)}
                        </p>
                        <p class="mb-0 small">{stat.description}</p>
                    </div>
                </div>
            </div>
        {/each}
    </div>

    {#if miniStats.length > 0}
        <div class="d-flex flex-wrap gap-2">
            {#each miniStats as stat}
                <div class="card p-2">
                    {stat.description}:
                    {formatStat(stat.stat, stat.attributes)}
                </div>
            {/each}
        </div>
    {/if}
</section>

<section class="no-bg narrow">
    <h2>Recent Games</h2>
    {#each data.recentGames as game}
        <GameCard {game} linkForm={true} />
    {/each}
</section>

<style>
    .chart-container {
        width: 100%;
        height: 200px;
        margin: 20px 0;
        box-sizing: border-box;
    }

    @media (max-width: 576px) {
        .chart-container {
            height: 150px;
        }
    }
</style>

<script lang="ts">
    export let data;

    import SiteHeader from "$lib/SiteHeader.svelte";
    import GameCardSmall from "$lib/GameCardSmall.svelte";

    import { onMount } from "svelte";
    import { invalidateAll } from "$app/navigation";
    import { renderChart } from "./listing_chart";

    let secondsAgo = 0;
    let chartElement: HTMLElement;
    let refreshInterval: number;

    function updateTimer() {
        if (data.lastUpdate) {
            const lastUpdate = new Date(data.lastUpdate);
            secondsAgo = Math.floor(
                (new Date().getTime() - lastUpdate.getTime()) / 1000,
            );

            if (secondsAgo > 60) {
                invalidateAll();
            }
        }
    }

    onMount(() => {
        refreshInterval = setInterval(updateTimer, 1000) as unknown as number;
        updateTimer();

        return () => {
            clearInterval(refreshInterval);
        };
    });

    onMount(() => {
        renderChart(data, chartElement);

        const resizeObserver = new ResizeObserver(() => {
            renderChart(data, chartElement);
        });

        if (chartElement) {
            resizeObserver.observe(chartElement);
        }

        return () => {
            if (chartElement) {
                resizeObserver.unobserve(chartElement);
            }
        };
    });
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
    <p class="text-muted small text-end mt-2 mb-0">
        (Update from {secondsAgo} seconds ago)
    </p>
</section>

<section>
    <h2>Past activity (3 days)</h2>
    <div
        class="w-100 my-3"
        style="height: 200px; box-sizing: border-box;"
        bind:this={chartElement}
    ></div>
</section>

<section class="no-bg narrow">
    <h2>Recent Games</h2>
    <!-- {JSON.stringify(data.recentGames)} -->
    {#each data.recentGames as game}
        <GameCardSmall {game} linkForm={true} />
    {/each}
</section>

<style>
    @media (max-width: 576px) {
        :global(div[style*="height: 200px"]) {
            height: 150px !important;
        }
    }
</style>

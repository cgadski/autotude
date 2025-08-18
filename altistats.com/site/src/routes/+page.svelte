<script lang="ts">
    export let data;

    import SiteHeader from "$lib/SiteHeader.svelte";
    import GameCardSmall from "$lib/GameCardSmall.svelte";

    import { onMount } from "svelte";
    import { renderChart } from "./listing_chart";

    let secondsAgo = 0;
    let chartElement: HTMLElement;
    let refreshInterval: number;
    let listingsData: any = null;
    let loading = true;

    async function fetchListingsData() {
        try {
            const response = await fetch("/api/listings");
            const data = await response.json();
            listingsData = data;
            loading = false;
        } catch (error) {
            console.error("Failed to fetch listings data:", error);
        }
    }

    function updateTimer() {
        if (listingsData?.lastUpdate) {
            const lastUpdate = new Date(listingsData.lastUpdate);
            secondsAgo = Math.floor(
                (new Date().getTime() - lastUpdate.getTime()) / 1000,
            );

            if (secondsAgo > 60) {
                fetchListingsData();
            }
        }
    }

    onMount(() => {
        fetchListingsData().then(() => {
            updateTimer();
        });
        refreshInterval = setInterval(updateTimer, 1000) as unknown as number;

        return () => {
            clearInterval(refreshInterval);
        };
    });

    onMount(() => {
        const renderChartWithData = () => {
            if (listingsData && chartElement) {
                renderChart(listingsData, chartElement);
            }
        };

        renderChartWithData();

        const resizeObserver = new ResizeObserver(() => {
            renderChartWithData();
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
    {#if loading}
        <div class="d-flex justify-content-center py-3">
            <div class="spinner-border text-primary" role="status">
                <span class="visually-hidden">Loading...</span>
            </div>
        </div>
    {:else if listingsData}
        <div class="d-flex flex-wrap gap-2">
            {#each listingsData.listings as listing}
                <div class="card">
                    <div class="card-body py-2 px-3 d-flex align-items-center">
                        <div class="me-2 server-info">
                            <span class="fw-medium server-name"
                                >{listing.name}</span
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
    {:else}
        <div class="d-flex justify-content-center py-3">
            <p class="text-muted">No server data available</p>
        </div>
    {/if}
</section>

<section>
    <h2>Past activity (3 days)</h2>
    {#if loading}
        <div
            class="d-flex justify-content-center align-items-center my-3"
            style="height: 200px;"
        >
            <div class="spinner-border text-primary" role="status">
                <span class="visually-hidden">Loading...</span>
            </div>
        </div>
    {:else}
        <div
            class="w-100 my-3"
            style="height: 200px; box-sizing: border-box;"
            bind:this={chartElement}
        ></div>
    {/if}
</section>

<section class="no-bg narrow">
    <h2>Recent Games</h2>

    {#each data.recentGames as game}
        <div class="mb-3">
            <GameCardSmall {game} />
        </div>
    {/each}
</section>

<style>
    @media (max-width: 576px) {
        :global(div[style*="height: 200px"]) {
            height: 150px !important;
        }
    }
</style>

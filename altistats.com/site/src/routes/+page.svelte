<script lang="ts">
    export let data;

    import SiteHeader from "$lib/SiteHeader.svelte";
    import { onMount } from "svelte";
    import { getGameRuns, renderScheduleChart } from "./schedule_chart";
    import { renderChart } from "./listing_chart";
    import { renderStat } from "$lib";

    let secondsAgo = 0;
    let scheduleElement: HTMLElement;
    let listingChartElement: HTMLElement;
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
        const render = () => {
            if (data.gameTimestamps && scheduleElement) {
                renderScheduleChart(
                    { gameTimestamps: data.gameTimestamps },
                    scheduleElement,
                );
            }
        };

        render();

        const resizeObserver = new ResizeObserver(() => {
            render();
        });

        if (scheduleElement) {
            resizeObserver.observe(scheduleElement);
        }

        return () => {
            if (scheduleElement) {
                resizeObserver.unobserve(scheduleElement);
            }
        };
    });

    onMount(() => {
        const renderListingChart = () => {
            if (listingsData?.listingsSeries && listingChartElement) {
                renderChart(listingsData, listingChartElement);
            }
        };

        const interval = setInterval(() => {
            renderListingChart();
        }, 100);

        setTimeout(() => clearInterval(interval), 5000);

        const resizeObserver = new ResizeObserver(() => {
            renderListingChart();
        });

        if (listingChartElement) {
            resizeObserver.observe(listingChartElement);
        }

        return () => {
            if (listingChartElement) {
                resizeObserver.unobserve(listingChartElement);
            }
        };
    });
</script>

<SiteHeader navPage="home" />

<section>
    <h2>
        Server listings <span class="small text-muted">(live)</span>
    </h2>
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
    <h2>Recent activity <span class="small text-muted">(last 3 days)</span></h2>

    {#if loading}
        <div class="d-flex justify-content-center py-3">
            <div class="spinner-border text-primary" role="status">
                <span class="visually-hidden">Loading...</span>
            </div>
        </div>
    {:else if listingsData?.listingsSeries}
        <div
            class="w-100"
            style="height: 200px"
            bind:this={listingChartElement}
        ></div>
    {:else}
        <div class="d-flex justify-content-center py-3">
            <p class="text-muted">No activity data available</p>
        </div>
    {/if}
</section>

<section>
    <h2>Ladder times <span class="small text-muted">(last 3 months)</span></h2>

    <div class="d-flex justify-content-center">
        <div
            class="w-100"
            style="max-width: 600px"
            bind:this={scheduleElement}
        ></div>
    </div>
</section>

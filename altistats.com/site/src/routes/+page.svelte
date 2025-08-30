<script lang="ts">
    export let data;

    import SiteHeader from "$lib/SiteHeader.svelte";
    import { onMount } from "svelte";
    import { getGameRuns, renderScheduleChart } from "./schedule_chart";
    import { renderStat } from "$lib";

    let secondsAgo = 0;
    let scheduleElement: HTMLElement;
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
</script>

<SiteHeader navPage="home" />

<section>
    <h2>Server listing <span class="text-muted">(live)</span></h2>
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
    <h2>Ranked activity <span class="text-muted">(last 3 months)</span></h2>

    <div class="w-100" bind:this={scheduleElement}></div>
</section>

<section class="">
    <h2>Game database</h2>
    <div class="row g-3">
        {#each data.globalStats as item}
            <div class="col-auto">
                <div class="card">
                    <div class="card-body py-2 px-3">
                        <div class="text-muted small">{item.description}</div>
                        <div class="fw-bold">{renderStat(item.stat)}</div>
                    </div>
                </div>
            </div>
        {/each}
    </div>
</section>

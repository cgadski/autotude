<script lang="ts">
    export let data;
    import GamePicker from "$lib/GamePicker.svelte";
    import HandlePicker from "$lib/HandlePicker.svelte";

    import { renderStat } from "$lib";
    import SiteHeader from "$lib/SiteHeader.svelte";
    import LinkList from "$lib/LinkList.svelte";
    import SeriesBlurb from "./SeriesBlurb.svelte";

    let selectedGame: string | null = null;
    let selectedDay: string | null = null;
    let selectedHandles: string[] = [];

    // Clear selections when the series or period changes — including when
    // the new period is null (a series with no games yet)
    let lastSeries: number | null = null;
    let lastPeriod: string | null = null;
    $: if (
        data.params.series !== lastSeries ||
        data.params.period !== lastPeriod
    ) {
        lastSeries = data.params.series;
        lastPeriod = data.params.period;
        selectedDay = null;
        selectedGame = null;
    }

    $: gameCountsMap = new Map(
        data.gameCountsByMonth.map((item) => [item.time_bin, item.game_count]),
    );

    $: seriesRow = data.series[data.params.series];

    $: series = seriesRow.series_key;

    $: seriesImg = ["planeball.png", "top_dog_1.png", "top_dog_2.png"][series];

    $: isTourny = series > 0;
</script>

<SiteHeader navPage="games" />

<section>
    <div class="row g-3 mb-3">
        <div class="col-12 col-md-8">
            <dl>
                <dt>Series</dt>
                <dd>
                    <LinkList
                        items={data.series.map((row: any) => ({
                            label: row.series_name,
                            href: `?series=${row.series_key}`,
                            active: data.params.series === row.series_key,
                            info: "",
                        }))}
                    />
                </dd>
                <SeriesBlurb {series} />
            </dl>
            <p>{seriesRow.series_desc}</p>
        </div>
        <div class="col-12 col-md-4 text-center">
            {#if seriesImg}
                <img
                    src="/images/{seriesImg}"
                    alt={seriesRow.series_name}
                    class="img-fluid"
                />
            {/if}
        </div>
    </div>

    {#if !isTourny}
        <dl>
            <dt>Month</dt>
            <dd>
                <LinkList
                    items={data.timeBins
                        .filter((row) => gameCountsMap.get(row.time_bin) > 0)
                        .map((row) => ({
                            label: row.time_bin,
                            href: `?series=${data.params.series}&period=${row.time_bin}`,
                            active: data.params.period === row.time_bin,
                            info:
                                gameCountsMap.get(row.time_bin)?.toString() ||
                                "0",
                        }))}
                />
            </dd>
        </dl>
    {/if}

    <GamePicker
        dayPicker={!isTourny}
        month={data.params.period || data.timeBins[0]?.time_bin || ""}
        games={data.games}
        bind:selectedDay
        bind:selectedGame
        {selectedHandles}
        playerHandle={null}
    />

    <div class="mt-3">
        <HandlePicker handles={data.handles} bind:selectedHandles />
    </div>
</section>

<section class="no-bg">
    <h2>Database stats</h2>
    <div class="d-flex justify-content-center flex-wrap gap-1">
        {#each data.globalStats as item}
            <div class="card">
                <div class="card-body py-2 px-3">
                    <div class="text-muted small">{item.description}</div>
                    <div class="fw-bold">{renderStat(item.stat)}</div>
                </div>
            </div>
        {/each}
    </div>
</section>

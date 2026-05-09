<script lang="ts">
    export let data;
    import HorizontalList from "$lib/HorizontalList.svelte";
    import GameCard from "$lib/GameCard.svelte";
    import GamePicker from "$lib/GamePicker.svelte";
    import HandlePicker from "$lib/HandlePicker.svelte";

    import { renderStat } from "$lib";
    import SiteHeader from "$lib/SiteHeader.svelte";
    import LinkList from "$lib/LinkList.svelte";

    let selectedGame: string | null = null;
    let selectedDay: string | null = null;
    let selectedHandles: string[] = [];

    // Clear selected day when month changes
    $: if (data.params.period) {
        selectedDay = null;
        selectedGame = null;
    }

    $: gameCountsMap = new Map(
        data.gameCountsByMonth.map((item) => [item.time_bin, item.game_count]),
    );

    $: seriesRow = data.series[data.params.series];
</script>

<SiteHeader navPage="games" />

<section class="no-bg pt-0">
    <div class="d-flex flex-wrap gap-1">
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

<section>
    <HandlePicker handles={data.handles} bind:selectedHandles />

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
    </dl>

    <p>{seriesRow.series_desc}</p>

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
                            gameCountsMap.get(row.time_bin)?.toString() || "0",
                    }))}
            />
        </dd>
    </dl>

    <GamePicker
        month={data.params.period || data.timeBins[0]?.time_bin || ""}
        games={data.games}
        bind:selectedDay
        bind:selectedGame
        {selectedHandles}
        playerHandle={null}
    />
</section>

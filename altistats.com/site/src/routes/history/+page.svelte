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

    // Create a lookup map for game counts per month
    $: gameCountsMap = new Map(
        data.gameCountsByMonth.map((item) => [
            item.time_bin_desc,
            item.game_count,
        ]),
    );
</script>

<SiteHeader navPage="history" />

<section>
    <HandlePicker handles={data.handles} bind:selectedHandles />

    <dl>
        <dt>Month</dt>
        <dd>
            <LinkList
                items={data.timeBins.map((row) => ({
                    label: row.time_bin_desc,
                    href: `?period=${row.time_bin_desc}`,
                    active: data.params.period === row.time_bin_desc,
                    info:
                        gameCountsMap.get(row.time_bin_desc)?.toString() || "0",
                }))}
            />
        </dd>
    </dl>

    <GamePicker
        month={data.params.period || data.timeBins[0]?.time_bin_desc || ""}
        games={data.games}
        bind:selectedDay
        bind:selectedGame
        {selectedHandles}
        playerHandle={null}
    />
</section>

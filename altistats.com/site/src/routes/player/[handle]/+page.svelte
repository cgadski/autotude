<script lang="ts">
    import GamePicker from "$lib/GamePicker.svelte";
    import LinkList from "$lib/LinkList.svelte";

    export let data;

    let selectedDay: string | null = null;
    let selectedGame: string | null = null;

    // Clear selected day when month changes
    $: if (data.params.period) {
        selectedDay = null;
        selectedGame = null;
    }

    // Filter games to only those that include this player
    $: playerGames = data.games.filter((game) => {
        const team3Players = game.teams["3"] || [];
        const team4Players = game.teams["4"] || [];
        const allPlayers = [...team3Players, ...team4Players];
        return allPlayers.includes(data.handle);
    });

    // Create a lookup map for game counts per month
    $: gameCountsMap = new Map(
        data.gameCountsByMonth.map((item) => [
            item.time_bin_desc,
            item.game_count,
        ]),
    );
</script>

<dl class="mb-4">
    <dt>Month</dt>
    <dd>
        <LinkList
            items={data.timeBins.map((row) => ({
                label: row.time_bin_desc,
                href: `?period=${row.time_bin_desc}`,
                active: data.params.period === row.time_bin_desc,
                info: gameCountsMap.get(row.time_bin_desc)?.toString() || "0",
            }))}
        />
    </dd>
</dl>

<GamePicker
    month={data.params.period || data.timeBins[0]?.time_bin_desc || ""}
    games={playerGames}
    bind:selectedDay
    bind:selectedGame
    selectedHandles={[]}
    playerHandle={data.handle}
/>

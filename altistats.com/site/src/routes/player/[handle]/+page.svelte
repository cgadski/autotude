<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import { formatStat } from "$lib";
    import HorizontalList from "$lib/HorizontalList.svelte";
    import GameCardSmall from "$lib/GameCardSmall.svelte";

    // @type {import('./$types').PageData}
    export let data;
</script>

<SiteHeader />

<section>
    <h2>Player: {data.handle}</h2>

    <dl>
        <dt>Nicknames</dt>
        <dd>
            <HorizontalList items={data.nicks} let:item>{item}</HorizontalList>
        </dd>
        <dt>Career stats</dt>
        <dd>
            <HorizontalList items={data.stats} let:item>
                {item.description}: {formatStat(item.stat, item.attributes)}
            </HorizontalList>
        </dd>
    </dl>
</section>

<section class="no-bg narrow">
    <h2>Recent games</h2>

    {#each data.games as game}
        <GameCardSmall {game} handle={data.handle} />
    {/each}
</section>

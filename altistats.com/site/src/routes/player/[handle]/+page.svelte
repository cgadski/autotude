<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import StatLinks from "$lib/StatLinks.svelte";
    import { formatStat } from "$lib";
    import GameCard from "$lib/GameCard.svelte";
    import HorizontalList from "$lib/HorizontalList.svelte";
    import GameCardSmall from "$lib/GameCardSmall.svelte";

    // @type {import('./$types').PageData}
    export let data;

    // const mainQueries = [
    //     "p_total_games",
    //     "p_time_played",
    //     "p_total_kills",
    //     "p_total_goals",
    // ];

    // const mainStats = data.stats.filter((stat) =>
    //     mainQueries.includes(stat.query_name),
    // );

    // const miniStats = (data.stats || []).filter(
    //     (stat) => !mainQueries.includes(stat.query_name),
    // );

    // $: miniStatItems = miniStats.map((stat) => ({
    //     label: stat.description,
    //     value: formatStat(stat.stat, stat.attributes),
    //     href: `/players?stat=${stat.query_name}`,
    // }));
</script>

<SiteHeader />

<section>
    <h2>Player: {data.handle}</h2>

    <div class="d-flex align-items-center">
        <div class="fw-medium me-2">Nicknames:</div>
        <HorizontalList items={data.nicks} let:item>{item}</HorizontalList>
    </div>

    <!-- <div class="row cols-2 g-2 mb-2">
        {#each mainStats as stat}
            <div class="col">
                <a
                    href="/players?stat={stat.query_name}"
                    class="text-decoration-none"
                >
                    <div class="card h-100">
                        <div class="card-body text-center">
                            <p class="h4 mb-0">
                                {formatStat(stat.stat, stat.attributes)}
                            </p>
                            <p class="mb-0 small">{stat.description}</p>
                        </div>
                    </div>
                </a>
            </div>
        {/each}
    </div> -->
</section>

<section>
    <HorizontalList items={data.stats} let:item>
        {item.description}: {formatStat(item.stat, item.attributes)}
    </HorizontalList>
</section>

<section class="no-bg narrow">
    <h2>Recent Games</h2>

    {#each data.games as game}
        <GameCardSmall {game} handle={data.handle} />
    {/each}
</section>

<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import StatLinks from "$lib/StatLinks.svelte";
    import { formatStat } from "$lib";
    import GameCard from "$lib/GameCard.svelte";

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
        <StatLinks
            items={data.nicks.map((n) => ({
                label: "asdf",
                value: "asdf",
            }))}
        />
        <!-- {data.nicks.join(", ")} -->
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
    <StatLinks
        items={[
            { label: "stat 1", href: "#" },
            { label: "stat 1", href: "#" },
            { label: "stat 1", href: "#" },
        ]}
    />

    <StatLinks
        items={data.stats.map((s: any) => ({
            label: s.description,
            value: formatStat(s.stat, s.attributes),
        }))}
    />
</section>

<!-- <section class="no-bg narrow">
    <h2>Recent Games</h2>

    {#each data.games as game}
        <GameCard {game} linkForm={true} />
    {/each}
</section> -->

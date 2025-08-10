<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import { formatStat } from "$lib";
    import GameCard from "$lib/GameCard.svelte";

    // @type {import('./$types').PageData}
    export let data;

    const mainQueries = ["p_total_games", "p_time_played", "p_total_kills"];

    const mainStats = data.stats.filter((stat) =>
        mainQueries.includes(stat.query_name),
    );

    const miniStats = (data.stats || []).filter(
        (stat) => !mainQueries.includes(stat.query_name),
    );

    const formatDate = (dateStr: string) => {
        const date = new Date(dateStr);
        return date.toLocaleDateString("en-US", {
            weekday: "long",
            year: "numeric",
            month: "long",
            day: "numeric",
        });
    };
</script>

<SiteHeader />

<section>
    <h2>Player: {data.name}</h2>

    <div class="row cols-2 g-2 mb-2">
        {#each mainStats as stat}
            <div class="col">
                <a
                    href="/index/player?stat={stat.query_name}"
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
    </div>

    {#if miniStats.length > 0}
        <div class="d-flex flex-wrap gap-2">
            {#each miniStats as stat}
                <a
                    href="/index/player?stat={stat.query_name}"
                    class="text-decoration-none"
                >
                    <div class="card p-2">
                        {stat.description}: {formatStat(
                            stat.stat,
                            stat.attributes,
                        )}
                    </div>
                </a>
            {/each}
        </div>
    {/if}

    <h2>Nicknames</h2>
    <div class="d-flex flex-wrap gap-2">
        {#each data.nicks as nick}
            <span class="badge bg-secondary">{nick}</span>
        {/each}
    </div>
</section>

<section class="no-bg narrow">
    <h2>Recent Games</h2>

    {#each data.games as game}
        <GameCard {game} linkForm={true} />
    {/each}
</section>

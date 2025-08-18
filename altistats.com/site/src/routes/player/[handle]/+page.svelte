<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import { formatDate } from "$lib";
    import HorizontalList from "$lib/HorizontalList.svelte";
    import GamePicker from "$lib/GamePicker.svelte";
    import LinkList from "$lib/LinkList.svelte";

    // @type {import('./$types').PageData}
    export let data;

    let selectedGame: string | null = null;

    // Debug the games data
    $: console.log("Games data:", {
        gamesCount: data.games?.length || 0,
        firstGame: data.games?.[0],
        sampleStems: data.games?.slice(0, 3).map((g) => g.stem),
    });
</script>

<SiteHeader />

<section>
    <h2>Player: {data.handle}</h2>

    <dl>
        <dt>Nicknames</dt>
        <dd>
            <HorizontalList items={data.nicks} let:item>{item}</HorizontalList>
        </dd>
        <dt>Last played</dt>
        <dd>
            {formatDate(data.lastPlayed)}
        </dd>
        <dt>Stats</dt>
        <dd>
            <a
                href="/player/{encodeURIComponent(data.handle)}/stats"
                class="btn btn-outline-primary btn-sm"
            >
                View Activity & Stats →
            </a>
        </dd>
    </dl>
</section>

<section class="narrow no-bg">
    <dl>
        <dt>Show games from</dt>
        <dd>
            <div class="pb-2">
                <LinkList
                    items={[
                        { label: "last week", href: "#" },
                        { label: "all-time", href: "#" },
                    ]}
                />
            </div>
        </dd>
    </dl>

    <GamePicker games={data.games} bind:selectedGame let:game>
        <div
            class="game-square-content"
            class:win={game.winner ===
                (game.teams["3"]?.includes(data.handle) ? 3 : 4)}
            class:loss={game.winner !==
                (game.teams["3"]?.includes(data.handle) ? 3 : 4)}
        ></div>
    </GamePicker>
</section>

<style>
    /* Styles moved to components.css */
</style>

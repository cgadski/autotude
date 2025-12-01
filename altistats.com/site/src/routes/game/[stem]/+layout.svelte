<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import LinkList from "$lib/LinkList.svelte";
    import { page } from "$app/stores";
    import { formatDatetime, formatTimestamp, renderStat } from "$lib";
    import HorizontalList from "$lib/HorizontalList.svelte";

    export let data;

    const views = [
        {
            name: "Timeline",
            path: `/game/${data.stem}`,
            routeId: "/game/[stem]",
        },
        {
            name: "Loadouts",
            path: `/game/${data.stem}/loadouts`,
            routeId: "/game/[stem]/loadouts",
        },
        {
            name: "Kill Matrix",
            path: `/game/${data.stem}/kill-matrix`,
            routeId: "/game/[stem]/kill-matrix",
        },
    ];

    $: viewItems = views.map((view) => ({
        label: view.name,
        href: view.path,
        active: view.routeId === $page.route.id,
    }));

    let game = data.game;
    let gameProps = [
        { desc: "Map", value: game.map },
        { desc: "Duration", value: game.duration + "d" },
        { desc: "Replay version", value: game.version },
        { desc: "Marked broken", value: game.broken ? "yes" : "no" },
    ];
</script>

<SiteHeader />

<section class="no-bg">
    <h2>
        Ranked game on {formatDatetime(data.game.started_at)}
        <a
            href="/viewer/?f={data.game.stem}.pb"
            style="float:right"
            class="btn px-1 py-0 btn-primary">View replay</a
        >
    </h2>
    <HorizontalList items={gameProps} let:item>
        <span class="fw-medium">{item.desc}</span>: {renderStat(item.value)}
    </HorizontalList>
</section>

<section>
    <dl>
        <dt>View</dt>
        <dd>
            <LinkList items={viewItems} />
        </dd>
    </dl>

    <slot />
</section>

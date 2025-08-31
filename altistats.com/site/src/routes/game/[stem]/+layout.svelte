<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import LinkList from "$lib/LinkList.svelte";
    import { page } from "$app/stores";
    import { formatTimestamp } from "$lib";

    export let data;

    const views = [
        {
            name: "Player Stats",
            path: `/game/${data.stem}`,
            routeId: "/game/[stem]",
        },
        {
            name: "Timeline",
            path: `/game/${data.stem}/timeline`,
            routeId: "/game/[stem]/timeline",
        },
        {
            name: "Kill Matrix",
            path: `/game/${data.stem}/kill-matrix`,
            routeId: "/game/[stem]/kill-matrix",
        },
        {
            name: "Messages",
            path: `/game/${data.stem}/messages`,
            routeId: "/game/[stem]/messages",
        },
    ];

    $: viewItems = views.map((view) => ({
        label: view.name,
        href: view.path,
        active: view.routeId === $page.route.id,
    }));
</script>

<SiteHeader />

<section class="no-bg">
    <div class="d-flex gap-3 mb-3 align-items-center">
        <h3 class="mb-0">{data.game.map}</h3>
        <div class="text-muted">
            {new Date(data.game.started_at * 1000).toLocaleDateString("en-GB", {
                weekday: "short",
                day: "numeric",
                month: "short",
                year: "numeric",
            })}
        </div>
        <div class="text-muted ms-auto">
            {formatTimestamp(data.game.duration)}
        </div>
    </div>

    <a
        href="/viewer/?f={data.game.stem}.pb"
        class="btn btn-sm btn-outline-primary mb-3">View replay</a
    > (desktop only)
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

<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import { formatDate, formatTimeAgo, renderStat } from "$lib";
    import HorizontalList from "$lib/HorizontalList.svelte";
    import LinkList from "$lib/LinkList.svelte";
    import { page } from "$app/stores";

    export let data;

    const uriHandle = encodeURIComponent(data.handle);

    const views = [
        {
            name: "Games",
            path: `/player/${uriHandle}`,
            routeId: "/player/[handle]",
        },
        {
            name: "Plane usage",
            path: `/player/${uriHandle}/plane-usage`,
            routeId: "/player/[handle]/plane-usage",
        },
        {
            name: "Stats",
            path: `/player/${uriHandle}/stats`,
            routeId: "/player/[handle]/stats",
        },
    ];

    $: viewItems = views.map((view) => ({
        label: view.name,
        href: view.path,
        active: view.routeId === $page.route.id,
    }));
</script>

<SiteHeader />

<section>
    <div class="d-flex gap-3 mb-3">
        <h3>{data.handle}</h3>
        <HorizontalList items={data.nicks} let:item>{item}</HorizontalList>
    </div>

    <div class="row g-2">
        <div class="col-auto">
            <div class="card">
                <div class="card-body py-2 px-3">
                    <div class="text-muted small">Last played</div>
                    <div class="fw-bold">
                        {formatTimeAgo(data.lastPlayed)}
                    </div>
                </div>
            </div>
        </div>
        <div class="col-auto">
            <div class="card">
                <div class="card-body py-2 px-3">
                    <div class="text-muted small">Career games</div>
                    <div class="fw-bold">{@html renderStat(data.nPlayed)}</div>
                </div>
            </div>
        </div>
        <div class="col-auto">
            <div class="card">
                <div class="card-body py-2 px-3">
                    <div class="text-muted small">Career KD</div>
                    <div class="fw-bold">{@html renderStat(data.nKills)}</div>
                </div>
            </div>
        </div>
    </div>
</section>

<section>
    <dl class="mb-0">
        <dt>View</dt>
        <dd>
            <LinkList items={viewItems} />
        </dd>
    </dl>

    <slot />
</section>

<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import { formatDate } from "$lib";
    import HorizontalList from "$lib/HorizontalList.svelte";
    import { page } from "$app/stores";
    import { goto } from "$app/navigation";

    export let data;

    const views = [
        {
            name: "Activity",
            path: `/player/${data.handle}`,
            routeId: "/player/[handle]",
        },
        {
            name: "Games",
            path: `/player/${data.handle}/games`,
            routeId: "/player/[handle]/games",
        },
        {
            name: "Stats",
            path: `/player/${data.handle}/stats`,
            routeId: "/player/[handle]/stats",
        },
    ];

    $: currentView = views.find((view) => view.routeId === $page.route.id);

    function navigateTo(path: string) {
        goto(path, { noScroll: true });
    }
</script>

<SiteHeader />

<section class="no-bg">
    <div class="d-flex gap-3 mb-3">
        <h3>{data.handle}</h3>
        <HorizontalList items={data.nicks} let:item>{item}</HorizontalList>
    </div>

    <div class="row g-3">
        <div class="col-auto">
            <div class="card">
                <div class="card-body py-2 px-3">
                    <div class="text-muted small">Last played</div>
                    <div class="fw-bold">
                        {new Date(data.lastPlayed * 1000).toLocaleDateString(
                            "en-GB",
                            {
                                weekday: "short",
                                day: "numeric",
                                month: "numeric",
                            },
                        )}
                    </div>
                </div>
            </div>
        </div>
        <div class="col-auto">
            <div class="card">
                <div class="card-body py-2 px-3">
                    <div class="text-muted small">Total games</div>
                    <div class="fw-bold">1,234</div>
                </div>
            </div>
        </div>
        <div class="col-auto">
            <div class="card">
                <div class="card-body py-2 px-3">
                    <div class="text-muted small">Total kills</div>
                    <div class="fw-bold">5,678</div>
                </div>
            </div>
        </div>
    </div>
</section>

<section>
    <div class="btn-group mb-3" role="group">
        {#each views as view}
            <button
                type="button"
                class="btn btn-outline-primary"
                class:active={currentView?.routeId === view.routeId}
                on:click={() => navigateTo(view.path)}
            >
                {view.name}
            </button>
        {/each}
    </div>

    <slot />
</section>

<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import { formatDate } from "$lib";
    import HorizontalList from "$lib/HorizontalList.svelte";
    import { page } from "$app/stores";

    export let data;

    $: isActivityRoute = $page.route.id === "/player/[handle]";
    $: isGamesRoute = $page.route.id === "/player/[handle]/games";
</script>

<SiteHeader />

<section>
    <div class="d-flex gap-3 mb-3">
        <h3>{data.handle}</h3>
        <HorizontalList items={data.nicks} let:item>{item}</HorizontalList>
    </div>

    <div class="row g-3">
        <div class="col-auto">
            <div class="card">
                <div class="card-body py-2 px-3">
                    <div class="text-muted small">Last played</div>
                    <div class="fw-bold">{formatDate(data.lastPlayed)}</div>
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
        <a
            href="/player/{data.handle}"
            class="btn btn-outline-primary"
            class:active={isActivityRoute}
        >
            Activity
        </a>
        <a
            href="/player/{data.handle}/games"
            class="btn btn-outline-primary"
            class:active={isGamesRoute}
        >
            Games
        </a>
    </div>

    <slot />
</section>

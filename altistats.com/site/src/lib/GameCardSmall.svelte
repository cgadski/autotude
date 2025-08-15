<script lang="ts">
    import { formatTimeAgo } from "$lib";

    import type { Game } from "$lib";
    import HorizontalList from "./HorizontalList.svelte";

    export let game: Game;
    export let handle: string | null = null;
</script>

<div class="card mb-3">
    <a
        href="/game/{game.stem}"
        class="card-header d-flex align-items-center py-2 text-decoration-none"
    >
        <div class="fw-medium me-3">
            {game.map}
        </div>
        <div class="small flex-fill">
            {formatTimeAgo(game.started_at)}
        </div>
        <i class="bi bi-arrow-right"></i>
    </a>

    <div class="row g-0">
        <div class="col-12 col-sm-6">
            <div
                class="p-2 bg-danger bg-opacity-10 border-end border-danger border-opacity-25 d-flex align-items-center"
                style="min-height: 2.5rem;"
            >
                <div class="flex-fill">
                    <HorizontalList items={game.teams["3"]} let:item>
                        <a
                            href="/player/{encodeURIComponent(item)}"
                            class="text-decoration-none text-dark small"
                            class:fw-bold={item === handle}
                        >
                            {item}
                        </a>
                    </HorizontalList>
                </div>
                <div class="ms-2">
                    {#if game.winner === 3}
                        <i class="bi bi-trophy-fill text-warning"></i>
                    {/if}
                </div>
            </div>
        </div>

        <div class="col-12 col-sm-6">
            <div
                class="p-2 bg-primary bg-opacity-10 d-flex align-items-center"
                style="min-height: 2.5rem;"
            >
                <div class="flex-fill">
                    <HorizontalList items={game.teams["4"]} let:item>
                        <a
                            href="/player/{encodeURIComponent(item)}"
                            class="text-decoration-none text-dark small"
                            class:fw-bold={item === handle}
                        >
                            {item}
                        </a>
                    </HorizontalList>
                </div>
                <div class="ms-2">
                    {#if game.winner === 4}
                        <i class="bi bi-trophy-fill text-warning"></i>
                    {/if}
                </div>
            </div>
        </div>
    </div>
</div>

<style>
    .card {
        box-shadow: 0 1px 8px rgba(0, 0, 0, 0.05);
    }

    a:hover {
        color: #0066cc !important;
        text-decoration: underline !important;
    }

    @media (max-width: 575.98px) {
        .border-end {
            border-right: none !important;
            border-bottom: 1px solid rgba(220, 53, 69, 0.25) !important;
        }
    }
</style>

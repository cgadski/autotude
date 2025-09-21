<script lang="ts">
    import { formatDatetime, formatTimeAgo, formatTimestamp } from "$lib";

    import type { Game } from "$lib";
    import HorizontalList from "./HorizontalList.svelte";

    export let game: Game;
    export let handle: string | null = null;
    export let handles: string[] = [];

    // If handle is provided, add it to handles array for backward compatibility
    $: highlightHandles = handle ? [handle, ...handles] : handles;
</script>

<div class="card">
    <div class="card-header d-flex align-items-center position-relative">
        <div class="fw-medium me-3">
            {game.map}
        </div>
        <div class="small flex-fill">
            {formatDatetime(game.started_at)}
        </div>
        <a
            class="btn px-1 py-0 btn-primary stretched-link"
            href="/game/{game.stem}">See game</a
        >
    </div>

    <div class="row g-0">
        <div class="col-12 col-sm-6">
            <div
                class="p-2 team-red border-end border-danger border-opacity-25 d-flex align-items-center"
                style="min-height: 2.5rem;"
            >
                <div class="flex-fill">
                    <HorizontalList items={game.teams["3"]} let:item>
                        <a
                            href="/player/{encodeURIComponent(item)}"
                            class="small"
                            class:fw-bold={highlightHandles.includes(item)}
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
                class="p-2 team-blue d-flex align-items-center"
                style="min-height: 2.5rem;"
            >
                <div class="flex-fill">
                    <HorizontalList items={game.teams["4"]} let:item>
                        <a
                            href="/player/{encodeURIComponent(item)}"
                            class="small"
                            class:fw-bold={highlightHandles.includes(item)}
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
    /*a:hover {
        color: #0066cc !important;
        text-decoration: underline !important;
    }*/

    @media (max-width: 575.98px) {
        .border-end {
            border-right: none !important;
            border-bottom: 1px solid rgba(220, 53, 69, 0.25) !important;
        }
    }
</style>

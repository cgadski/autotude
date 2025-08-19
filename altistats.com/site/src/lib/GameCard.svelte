<script lang="ts">
    import { formatDatetime, formatDuration } from "$lib";

    import type { Game } from "$lib";

    export let game: Game;
</script>

<div class="card">
    <div class="card-header d-flex align-items-center py-2">
        <div class="fw-medium me-3">
            {game.map}
        </div>
        <div class="small me-3">
            {formatDatetime(game.started_at)}
        </div>
        <div class="small text-muted ms-auto">
            {formatDuration(game.duration)}
        </div>
    </div>

    <div class="row g-0">
        <div class="col-12 col-sm-6">
            <div
                class="p-2 bg-danger bg-opacity-10 border-end border-danger border-opacity-25 position-relative"
            >
                {#if game.winner === 3}
                    <i class="bi bi-trophy-fill text-warning trophy-position"
                    ></i>
                {/if}
                {#each game.teams["3"] || [] as handle}
                    <div class="d-flex justify-content-between py-1">
                        <a href="/player/{encodeURIComponent(handle)}"
                            >{handle}</a
                        >
                        <span class="small text-muted">
                            <!-- Plane info will go here -->
                        </span>
                    </div>
                {/each}
            </div>
        </div>

        <div class="col-12 col-sm-6">
            <div class="p-2 bg-primary bg-opacity-10 position-relative">
                {#if game.winner === 4}
                    <i class="bi bi-trophy-fill text-warning trophy-position"
                    ></i>
                {/if}
                {#each game.teams["4"] || [] as handle}
                    <div class="d-flex justify-content-between py-1">
                        <a href="/player/{encodeURIComponent(handle)}"
                            >{handle}</a
                        >
                        <span class="small text-muted">
                            <!-- Plane info will go here -->
                        </span>
                    </div>
                {/each}
            </div>
        </div>
    </div>
</div>

<style>
    .card {
        box-shadow: 0 1px 8px rgba(0, 0, 0, 0.05);
    }

    .trophy-position {
        position: absolute;
        top: 0.5rem;
        right: 0.5rem;
    }

    @media (max-width: 575.98px) {
        .border-end {
            border-right: none !important;
            border-bottom: 1px solid rgba(220, 53, 69, 0.25) !important;
        }
    }
</style>

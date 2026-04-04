<script lang="ts">
    import { renderStat } from "$lib";

    export let data;

    function percentileColor(rank: number, total: number): string {
        if (!total) return "var(--bs-tertiary-bg)";
        let t = 1 - (rank - 1) / (total - 1 || 1);
        return `hsl(${t * 120} 40% 90%)`;
    }
</script>

{#snippet card(title, repr, rank, total, href, bg)}
    <svelte:element
        this={href ? "a" : "div"}
        href={href || undefined}
        class="stat-card rounded px-2 py-1"
        class:text-decoration-none={href}
        style="background-color:{bg}"
    >
        <div class="text-muted small text-start">
            {title}{#if href}<span class="ms-1">›</span>{/if}
        </div>
        {#if repr}
            {#if repr.includes("|")}
                {@const [mainStat, details] = repr.split("|", 2)}
                <div class="text-center fw-bold">
                    {@html renderStat(mainStat)}
                </div>
                <div class="text-center text-muted small">
                    {@html renderStat(details)}
                </div>
            {:else}
                <div class="text-center fw-bold">{@html renderStat(repr)}</div>
            {/if}
            <div class="text-center small">
                <span class="fw-semibold text-primary">#{rank}</span><span
                    class="text-muted">/{total}</span
                >
            </div>
        {:else}
            <div class="text-center text-muted">&mdash;</div>
        {/if}
    </svelte:element>
{/snippet}

{#each data.stats as stat}
    {@const overall = stat.overall}
    <div class="border-bottom py-3">
        <div class="fw-semibold mb-2">{stat.description}</div>
        <div class="d-flex flex-wrap justify-content-center gap-2">
            {#if overall}
                {@render card(
                    "Overall",
                    overall.repr,
                    overall.rank,
                    overall.total,
                    `/players?stat=${stat.query_name}`,
                    percentileColor(overall.rank, overall.total),
                )}
            {/if}
            {#each stat.planes as p}
                {#if p.hidden}
                    {@render card(
                        p.planeName,
                        null,
                        null,
                        null,
                        null,
                        "var(--bs-tertiary-bg)",
                    )}
                {:else}
                    {@render card(
                        p.planeName,
                        p.repr,
                        p.rank,
                        p.total,
                        `/players?stat=${stat.query_name}&plane=${p.planeName}`,
                        percentileColor(p.rank, p.total),
                    )}
                {/if}
            {/each}
        </div>
    </div>
{/each}

{#if data.stats.length === 0}
    <p class="text-muted">No stats available.</p>
{/if}

<style>
    .stat-card {
        min-width: 10em;
        color: inherit;
    }
</style>

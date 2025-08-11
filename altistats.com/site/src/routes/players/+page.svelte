<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import { formatStat, formatShortDate, type StatMeta } from "$lib";
    import { onMount } from "svelte";

    // @type {import('./$types').PageData}
    export let data;

    let histogramElement: HTMLElement;
    import { renderHistogram } from "./histogram.js";
    import type { QueryParams } from "./+page.server.js";

    function makeLink(override: {
        stat?: string | null;
        period?: string | null;
        plane?: string | null;
    }) {
        const current = Object.assign({}, data.params);
        const modified = Object.assign({}, current, override);

        const urlParams = new URLSearchParams();
        let defined = (x) => x !== null && x !== undefined;
        if (defined(modified.stat)) {
            urlParams.set("stat", modified.stat);
        }
        if (defined(modified.period)) {
            urlParams.set("period", modified.period);
        }
        if (defined(modified.plane)) {
            urlParams.set("plane", modified.plane);
        }
        const queryString = urlParams.toString();
        const href = queryString ? `/players?${queryString}` : "/players";

        const isActive = JSON.stringify(current) === JSON.stringify(modified);

        return {
            href,
            class: `filter-link${isActive ? " active" : ""}`,
        };
    }

    // onMount(() => {
    //     if (histogramElement && !data.params.stat != null) {
    //         renderHistogram(histogramElement, data);
    //     }
    // });

    // $: if (data.players && histogramElement && !data.params.stat != null) {
    //     renderHistogram(histogramElement, data);
    // }
</script>

<SiteHeader navPage="players" />

<!-- <section>
    {JSON.stringify(data)}
</section> -->

<section>
    <div>
        <div class="filter-label">Stat:</div>
        <div class="filter-options">
            <a {...makeLink({ stat: null })}> None </a>
            {#each data.statMetas as meta, index}
                <span class="separator">•</span>
                <a {...makeLink({ stat: meta.query_name })}>
                    {meta.description}
                </a>
            {/each}
        </div>
    </div>

    {#if data.params.stat != null}
        <div class="mt-2">
            <div class="filter-label">Period:</div>
            <div class="filter-options">
                <a {...makeLink({ period: null })}> All time </a>
                {#each data.timeBins as bin, i}
                    <span class="separator">•</span>
                    <a {...makeLink({ period: bin.time_bin_desc })}>
                        {bin.time_bin_desc}
                    </a>
                {/each}
            </div>
        </div>

        <div class="mt-2">
            <div class="filter-label">Plane:</div>
            <div class="filter-options">
                <a {...makeLink({ plane: null })}> All planes </a>
                {#each ["Loopy", "Bomber", "Whale", "Biplane", "Miranda"] as plane, i}
                    <span class="separator">•</span>
                    <a {...makeLink({ plane: plane.toLowerCase() })}>
                        {plane}
                    </a>
                {/each}
            </div>
        </div>
    {/if}
</section>

<!-- {#if data.stat != null}
    <section class="no-bg">
        <div bind:this={histogramElement}></div>
    </section>
{/if} -->

<section class="narrow">
    <table class="table table-sm">
        <colgroup>
            <col style="width: 2em;" />
            <col />
            <col />
        </colgroup>
        <tbody>
            {#each data.players as player, index}
                <tr>
                    <td class="text-muted">{index + 1}</td>
                    <td>
                        <a href="/player/{player.handle}">
                            {player.handle}
                        </a>
                        {#if data.params.stat == null}
                            <small class="text-muted ms-2">
                                ({player.nicks.join(", ")})
                            </small>
                        {/if}
                    </td>
                    <td class="text-end">
                        {#if data.params.stat == null}
                            {formatShortDate(player.stat)}
                        {:else}
                            {formatStat(player.stat, data.stat.attributes)}
                        {/if}
                    </td>
                </tr>
            {/each}
        </tbody>
    </table>
</section>

<style>
    .filter-label {
        display: inline-block;
        font-weight: 500;
    }
    .filter-options {
        display: inline-flex;
        flex-wrap: wrap;
        gap: 0em;
        margin-left: 0.5em;
    }
    .filter-link {
        color: #6c757d;
        text-decoration: none;
        border-radius: 3px;
        padding: 0.1rem 0.15rem;
    }

    .filter-link:hover {
        background-color: #f8f9fa;
        color: #495057;
    }

    .filter-link.active {
        color: #0d6efd;
        background-color: #f8f9fa;
        /*font-weight: 500;*/
    }

    .separator {
        color: #999;
        margin: 0 0.5em;
        display: inline-flex;
        align-items: center;
    }
</style>

<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import { formatStat, formatShortDate, type StatMeta } from "$lib";
    import { onMount } from "svelte";

    // @type {import('./$types').PageData}
    export let data;

    let histogramElement: HTMLElement;
    import { renderHistogram } from "./histogram.js";

    onMount(() => {
        if (histogramElement && !data.isNoneStat) {
            renderHistogram(histogramElement, data);
        }
    });

    $: if (data.players && histogramElement && !data.isNoneStat) {
        renderHistogram(histogramElement, data);
    }

    function statActive(meta: StatMeta) {
        if (data.stat != null) {
            return meta.query_name == data.stat.query_name;
        }
        return false;
    }

    function makeLinkUrl(opts: any): string {
        return "/players";
    }

    function makeLinkClass(opts: any): string[] {
        return ["filter-link"];
    }
</script>

<SiteHeader navPage="player" />

<section>
    {JSON.stringify(data)}
</section>

<section>
    <div>
        <div class="filter-label">Stat:</div>
        <div class="filter-options">
            {#each data.statMetas as meta, index}
                {#if index > 0}<span class="separator">•</span>{/if}
                <a
                    href={makeLinkUrl({ stat: meta })}
                    class={makeLinkClass({ stat: meta })}
                >
                    {meta.description}
                </a>
            {/each}
        </div>
    </div>

    {#if data.stat != null}
        <div class="mt-2">
            <div class="filter-label">Period:</div>
            <div class="filter-options">
                {#each ["All Time", "This Month", "Last Month", "2023", "2022", "2021"] as period, i}
                    {#if i > 0}<span class="separator">•</span>{/if}
                    <a href="/players" class="filter-link">
                        {period}
                    </a>
                {/each}
            </div>
        </div>

        <div class="mt-2">
            <div class="filter-label">Plane:</div>
            <div class="filter-options">
                {#each ["All Planes", "Loopy", "Bomber", "Whale", "Biplane", "Miranda"] as plane, i}
                    {#if i > 0}<span class="separator">•</span>{/if}
                    <a href="/players" class="filter-link">
                        {plane}
                    </a>
                {/each}
            </div>
        </div>
    {/if}
</section>

{#if data.stat != null}
    <section class="no-bg">
        <div bind:this={histogramElement}></div>
    </section>
{/if}

<section class="narrow">
    <table class="table table-sm">
        <colgroup>
            <col />
            <col />
            <col />
        </colgroup>
        <tbody>
            {#each data.players as player, index}
                <tr>
                    <td class="text-muted">{index + 1}</td>
                    <td>
                        <a href="/player/{player.vapor}">
                            {player.name}
                        </a>
                        {#if data.isNoneStat && player.nicks}
                            <small class="text-muted ms-2">
                                ({player.nicks.join(", ")})
                            </small>
                        {/if}
                    </td>
                    <td class="text-end">
                        {#if data.stat != null}
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
        font-weight: 500;
    }

    .separator {
        color: #999;
        margin: 0 0.5em;
        display: inline-flex;
        align-items: center;
    }
</style>

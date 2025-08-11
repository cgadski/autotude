<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import StatLinks from "$lib/StatLinks.svelte";
    import { formatStat, formatShortDate, type StatMeta } from "$lib";
    import { onMount } from "svelte";

    // @type {import('./$types').PageData}
    export let data;

    let histogramElement: HTMLElement;
    import { renderHistogram } from "./histogram.js";
    import type { QueryParams } from "./+page.server.js";

    function makeLinkItem(
        override: {
            stat?: string | null;
            period?: string | null;
            plane?: string | null;
        },
        label: string,
    ) {
        const current = Object.assign({}, data.params);
        const modified = Object.assign({}, current, override);

        const urlParams = new URLSearchParams();
        let defined = (x: any) => x !== null && x !== undefined;
        if (defined(modified.stat)) {
            urlParams.set("stat", modified.stat || "");
        }
        if (defined(modified.period)) {
            urlParams.set("period", modified.period || "");
        }
        if (defined(modified.plane)) {
            urlParams.set("plane", modified.plane || "");
        }
        const queryString = urlParams.toString();
        const href = queryString ? `/players?${queryString}` : "/players";

        const isActive = JSON.stringify(current) === JSON.stringify(modified);

        return {
            label,
            href,
            active: isActive,
        };
    }

    $: statItems = [
        makeLinkItem({ stat: null }, "None"),
        ...data.statMetas.map((meta) =>
            makeLinkItem({ stat: meta.query_name }, meta.description),
        ),
    ];

    $: periodItems =
        data.params.stat != null
            ? [
                  makeLinkItem({ period: null }, "All time"),
                  ...data.timeBins.map((bin: any) =>
                      makeLinkItem(
                          { period: bin.time_bin_desc },
                          bin.time_bin_desc,
                      ),
                  ),
              ]
            : [];

    $: planeItems =
        data.params.stat != null
            ? [
                  makeLinkItem({ plane: null }, "All planes"),
                  ...["Loopy", "Bomber", "Whale", "Biplane", "Miranda"].map(
                      (plane) =>
                          makeLinkItem({ plane: plane.toLowerCase() }, plane),
                  ),
              ]
            : [];

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
    <div class="d-flex align-items-center">
        <div class="fw-medium me-2">Stat:</div>
        <StatLinks items={statItems} />
    </div>

    {#if data.params.stat != null}
        <div class="mt-2 d-flex align-items-center">
            <div class="fw-medium me-2">Period:</div>
            <StatLinks items={periodItems} />
        </div>

        <div class="mt-2 d-flex align-items-center">
            <div class="fw-medium me-2">Plane:</div>
            <StatLinks items={planeItems} />
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
                            {formatStat(
                                player.stat,
                                data.stat?.attributes || [],
                            )}
                        {/if}
                    </td>
                </tr>
            {/each}
        </tbody>
    </table>
</section>

<style>
    /* No custom styles needed - using Bootstrap utility classes and StatLinks component */
</style>

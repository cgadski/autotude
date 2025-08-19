<script lang="ts">
    export let data;

    import SiteHeader from "$lib/SiteHeader.svelte";
    import StatLinks from "$lib/StatLinks.svelte";
    import {
        formatShortDate,
        type StatMeta,
        formatTimeAgo,
        renderStat,
    } from "$lib";
    import { onMount } from "svelte";
    import PlayersTable from "./PlayersTable.svelte";
    import HandlePicker from "$lib/HandlePicker.svelte";

    let histogramElement: HTMLElement;
    import { renderHistogram } from "./histogram.ts";
    import type { QueryParams } from "./+page.server.js";
    import LinkList from "$lib/LinkList.svelte";

    let selectedHandles: string[] = [];

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
                      (plane) => makeLinkItem({ plane: plane }, plane),
                  ),
              ]
            : [];

    // Extract all handles for the HandlePicker
    $: allHandles = data.playerStats
        ? data.playerStats.map((p) => p.handle)
        : data.players
          ? data.players.map((p) => p.handle)
          : [];

    onMount(() => {
        if (histogramElement && data.params.stat != null) {
            renderHistogram(histogramElement, data, selectedHandles);
        }
    });

    // Consolidated reactive rendering - triggers when any dependency changes
    $: if (histogramElement && data.params.stat != null && data.playerStats) {
        renderHistogram(histogramElement, data, selectedHandles);
    }
</script>

<SiteHeader navPage="players" />

<section>
    <dl>
        <dt>Stat</dt>
        <dd>
            <LinkList items={statItems} />
        </dd>
        {#if data.params.stat != null}
            <dt>Period</dt>
            <dd>
                <LinkList items={periodItems} />
            </dd>
            <dt>Plane</dt>
            <dd>
                <LinkList items={planeItems} />
            </dd>
        {/if}
    </dl>
</section>

{#if data.params.stat != null}
    <section class="no-bg">
        <div
            bind:this={histogramElement}
            style="width: 100%; height: auto;"
        ></div>
    </section>
{/if}

{#if data.stat == null}
    {@const recent = data.players.filter((p) => !p.is_older).length}
    <section class="narrow">
        <h2>
            {data.players.length} players
            <span class="text-muted">
                ({recent} played in last 48 hours)
            </span>
        </h2>
        <PlayersTable players={data.players} />
    </section>
{/if}

{#if data.stat != null}
    <section class="narrow">
        <HandlePicker
            handles={allHandles}
            handleDescription="Showing players:"
            bind:selectedHandles
        />

        <table class="table table-sm">
            <colgroup>
                <col style="width: 2em;" />
                <col />
                <col style="width: 1%; white-space: nowrap;" />
                <col style="width: 1%; white-space: nowrap;" />
            </colgroup>
            <tbody>
                {#each data.playerStats as player, index}
                    <tr
                        class={selectedHandles.includes(player.handle)
                            ? "table-warning"
                            : ""}
                    >
                        <td class="text-muted">{index + 1}</td>
                        <td>
                            <a
                                href="/player/{player.handle}"
                                class={selectedHandles.includes(player.handle)
                                    ? "fw-bold"
                                    : ""}
                            >
                                {player.handle}
                            </a>
                        </td>
                        {#if player.repr.includes("|")}
                            {@const [mainStat, details] = player.repr.split(
                                "|",
                                2,
                            )}
                            <td class="text-end text-nowrap align-baseline">
                                {renderStat(mainStat)}
                            </td>
                            <td
                                class="text-muted text-nowrap align-baseline small"
                            >
                                {renderStat(details)}
                            </td>
                        {:else}
                            <td
                                class="text-end text-nowrap align-baseline"
                                colspan="2"
                            >
                                {renderStat(player.repr)}
                            </td>
                        {/if}
                    </tr>
                {/each}
            </tbody>
        </table>
    </section>
{/if}

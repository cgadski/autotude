<script lang="ts">
    export let data;

    import SiteHeader from "$lib/SiteHeader.svelte";
    import StatLinks from "$lib/StatLinks.svelte";
    import {
        formatStat,
        formatShortDate,
        type StatMeta,
        formatTimeAgo,
    } from "$lib";
    import { onMount } from "svelte";
    import PlayersTable from "./PlayersTable.svelte";

    let histogramElement: HTMLElement;
    import { renderHistogram } from "./histogram.js";
    import type { QueryParams } from "./+page.server.js";
    import LinkList from "$lib/LinkList.svelte";

    $: recentPlayers =
        data.stat == null
            ? data.players.filter((player) => {
                  const now = Date.now();
                  const playerTime = player.last_played * 1000;
                  const diffHours = (now - playerTime) / (1000 * 60 * 60);
                  return diffHours < 48;
              })
            : [];

    $: olderPlayers =
        data.stat == null
            ? data.players.filter((player) => {
                  const now = Date.now();
                  const playerTime = player.last_played * 1000;
                  const diffHours = (now - playerTime) / (1000 * 60 * 60);
                  return diffHours >= 48;
              })
            : [];

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

<!-- {#if data.stat != null}
    <section class="no-bg">
        <div bind:this={histogramElement}></div>
    </section>
{/if} -->

{#if data.stat == null}
    {#if recentPlayers.length > 0}
        <section class="narrow">
            <h2>
                {recentPlayers.length} recent players
                <span class="text-muted">(played in last 48 hours)</span>
            </h2>
            <PlayersTable players={recentPlayers} />
        </section>
    {/if}

    {#if olderPlayers.length > 0}
        <section class="narrow">
            <h2>{olderPlayers.length} players</h2>
            <PlayersTable players={olderPlayers} absoluteTime={true} />
        </section>
    {/if}
{/if}

{#if data.stat != null}
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
                        </td>
                        <td class="text-end">
                            {formatStat(
                                player.stat,
                                data.stat?.attributes || [],
                            )}
                            <span class="text-muted">
                                ({player.detail})
                            </span>
                        </td>
                    </tr>
                {/each}
            </tbody>
        </table>
    </section>
{/if}

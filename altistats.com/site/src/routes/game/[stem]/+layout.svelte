<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import LinkList from "$lib/LinkList.svelte";
    import { page } from "$app/stores";
    import {
        formatDatetime,
        formatDatetimeUTC,
        formatDuration,
        perkNames,
    } from "$lib";
    import HorizontalList from "$lib/HorizontalList.svelte";

    export let data;

    const views = [
        {
            name: "Timeline",
            path: `/game/${data.stem}`,
            routeId: "/game/[stem]",
        },
        {
            name: "Kill Matrix",
            path: `/game/${data.stem}/kill-matrix`,
            routeId: "/game/[stem]/kill-matrix",
        },
    ];

    $: redTeamPlayers = data.players.filter((p: any) => p.team === 3);
    $: blueTeamPlayers = data.players.filter((p: any) => p.team === 4);

    $: viewItems = views.map((view) => ({
        label: view.name,
        href: view.path,
        active: view.routeId === $page.route.id,
    }));

    let game = data.game;
    let gameProps = [
        { desc: "Started", value: formatDatetimeUTC(game.started_at) },
        { desc: "Map", value: game.map },
        {
            desc: "Series",
            value: game.series_name,
            href: `/games?series=${game.series_key}`,
        },
        { desc: "Duration", value: formatDuration(game.duration) },
        { desc: "Version", value: game.version },
        ...(game.broken ? [{ desc: "Marked broken", value: "yes" }] : []),
    ];
</script>

<SiteHeader />

<section class="no-bg">
    <div class="d-flex align-items-center flex-wrap gap-2">
        <HorizontalList items={gameProps} let:item>
            <span class="d-flex gap-1">
                <span class="fw-medium">{item.desc}:</span>
                {#if item.href}
                    <a href={item.href}>{item.value}</a>
                {:else}
                    <span>{item.value}</span>
                {/if}
            </span>
        </HorizontalList>
        <a
            href="/viewer/?f={data.game.stem}.pb"
            class="btn px-2 py-0 btn-primary ms-auto"
        >
            View replay
        </a>
    </div>

    <div class="row g-3 pt-3 align-items-stretch">
        {#each [{ players: redTeamPlayers, score: data.game.points_left, team: 3, cls: "team-red" }, { players: blueTeamPlayers, score: data.game.points_right, team: 4, cls: "team-blue" }] as side}
            <div class="col-12 col-md-6 d-flex">
                <div class="{side.cls} p-3 rounded flex-fill">
                    <div class="d-flex align-items-center mb-2 gap-2">
                        <span class="score fw-bold"
                            >{side.score || 0} <small>points</small></span
                        >
                        {#if data.game.winner === side.team}
                            <i class="bi bi-trophy-fill text-warning"></i>
                        {/if}
                    </div>
                    <table class="table table-sm no-bg mb-0 align-middle">
                        <thead>
                            <tr class="text-muted">
                                <th></th>
                                <th class="text-end stat-col">k</th>
                                <th class="text-end stat-col">d</th>
                                <th class="text-end stat-col">g</th>
                                <th class="text-end stat-col">p</th>
                                <th class="text-end stat-col">ps</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            {#each side.players as player}
                                <tr>
                                    <td>
                                        <a
                                            href="/player/{encodeURIComponent(
                                                player.handle,
                                            )}"
                                        >
                                            {player.handle}
                                        </a>
                                    </td>
                                    <td class="text-end stat-col"
                                        >{player.kills}</td
                                    >
                                    <td class="text-end stat-col"
                                        >{player.deaths}</td
                                    >
                                    <td class="text-end stat-col fw-bold">
                                        {player.goals || ""}
                                    </td>
                                    <td class="text-end stat-col fw-bold">
                                        {player.points || ""}
                                    </td>
                                    <td class="text-end stat-col"
                                        >{player.pos}%</td
                                    >
                                    <td class="perk-icons">
                                        {#each [player.red_perk, player.green_perk, player.blue_perk] as perk}
                                            {#if perk != null}
                                                <img
                                                    src="/images/perk_{perk}.png"
                                                    alt={perkNames[perk]}
                                                    title={perkNames[perk]}
                                                    class="perk-icon"
                                                />
                                            {/if}
                                        {/each}
                                    </td>
                                </tr>
                            {/each}
                        </tbody>
                    </table>
                </div>
            </div>
        {/each}
    </div>
</section>

<section>
    <dl>
        <dt>View</dt>
        <dd>
            <LinkList items={viewItems} />
        </dd>
    </dl>

    <slot />
</section>

<style>
    .score {
        font-size: 1.5rem;
        line-height: 1;
    }
    .stat-col {
        width: 2.5rem;
    }
    .perk-icon {
        width: 32px;
        height: 32px;
    }
    .perk-icons {
        display: flex;
        align-items: center;
        gap: 2px;
        padding-left: 0.5rem;
    }
</style>

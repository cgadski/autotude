<script lang="ts">
    import { formatShortDate, formatTimeAgo } from "$lib";
    import Fuse from "fuse.js";

    export let players: Array<{
        handle: string;
        nicks: string[];
        last_played: number;
        is_older?: boolean;
    }>;
    export let absoluteTime: boolean = false;

    let searchQuery = "";
    let fuse: Fuse<(typeof players)[0]>;

    $: {
        fuse = new Fuse(players, {
            keys: [
                { name: "handle", weight: 0.7 },
                { name: "nicks", weight: 0.3 },
            ],
            threshold: 0.3,
            includeScore: true,
        });
    }

    $: filteredPlayers =
        searchQuery.trim() === ""
            ? players
            : fuse.search(searchQuery).map((result) => result.item);
</script>

<div class="mb-3">
    <div class="input-group">
        <span class="input-group-text">
            <i class="bi bi-search"></i>
        </span>
        <input
            type="text"
            class="form-control"
            placeholder="Search by handle or nicknames..."
            bind:value={searchQuery}
        />
        {#if searchQuery.trim() !== ""}
            <button
                class="btn btn-outline-secondary"
                type="button"
                on:click={() => (searchQuery = "")}
            >
                <i class="bi bi-x"></i>
            </button>
        {/if}
    </div>
    {#if searchQuery.trim() !== ""}
        <small class="text-muted">
            Showing {filteredPlayers.length} of {players.length} players
        </small>
    {/if}
</div>

<table class="table table-sm">
    <colgroup>
        <col />
        <col />
    </colgroup>
    <tbody>
        {#each filteredPlayers as player}
            <tr>
                <td>
                    <a href="/player/{encodeURIComponent(player.handle)}">
                        {player.handle}
                    </a>
                    <small class="text-muted ms-2">
                        ({player.nicks.join(", ")})
                    </small>
                </td>
                <td class="text-end text-nowrap">
                    {#if absoluteTime || player.is_older}
                        {formatShortDate(player.last_played)}
                    {:else}
                        {formatTimeAgo(player.last_played)}
                    {/if}
                </td>
            </tr>
        {/each}
    </tbody>
</table>

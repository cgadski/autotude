<script lang="ts">
    import { formatShortDate, formatTimeAgo } from "$lib";

    export let players: Array<{
        handle: string;
        nicks: string[];
        last_played: number;
    }>;
    export let absoluteTime: boolean = false;
</script>

<table class="table table-sm">
    <colgroup>
        <col />
        <col />
    </colgroup>
    <tbody>
        {#each players as player}
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
                    {#if absoluteTime}
                        {formatShortDate(player.last_played)}
                    {:else}
                        {formatTimeAgo(player.last_played)}
                    {/if}
                </td>
            </tr>
        {/each}
    </tbody>
</table>

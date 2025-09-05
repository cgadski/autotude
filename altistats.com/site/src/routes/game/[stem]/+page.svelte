<script lang="ts">
    import { planes } from "$lib";

    export let data;

    $: redTeamPlayers = data.players.filter((p: any) => p.team === 3);
    $: blueTeamPlayers = data.players.filter((p: any) => p.team === 4);

    function getPlaneName(planeIndex: number) {
        return planes[planeIndex] || "Unknown";
    }
</script>

<div class="row g-3">
    <div class="col-12 col-md-6">
        <div class="team-red p-3 rounded">
            <table class="table table-sm mb-0">
                <thead>
                    <tr>
                        <th>Player</th>
                        <th>Plane</th>
                    </tr>
                </thead>
                <tbody>
                    {#each redTeamPlayers as player}
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
                            <td>{getPlaneName(player.plane)}</td>
                        </tr>
                    {/each}
                </tbody>
            </table>
        </div>
    </div>

    <div class="col-12 col-md-6">
        <div class="team-blue p-3 rounded">
            <table class="table table-sm mb-0">
                <thead>
                    <tr>
                        <th>Player</th>
                        <th>Plane</th>
                    </tr>
                </thead>
                <tbody>
                    {#each blueTeamPlayers as player}
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
                            <td>{getPlaneName(player.plane)}</td>
                        </tr>
                    {/each}
                </tbody>
            </table>
        </div>
    </div>
</div>

<style>
    .table {
        background-color: transparent;
    }

    .table th {
        font-weight: 500;
        border-bottom: 2px solid rgba(0, 0, 0, 0.1);
    }

    .table td {
        border-top: 1px solid rgba(0, 0, 0, 0.05);
    }
</style>

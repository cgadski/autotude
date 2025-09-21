<script lang="ts">
    export let data;

    $: redTeam = data.players.filter((p: any) => p.team === 3);
    $: blueTeam = data.players.filter((p: any) => p.team === 4);

    function getKillCount(killerHandle: string, victimHandle: string): number {
        const kill = data.killMatrix.find(
            (k: any) =>
                k.killer_handle === killerHandle &&
                k.victim_handle === victimHandle,
        );
        return kill ? kill.kill_count : 0;
    }

    function getTotalDeaths(
        victimHandle: string,
        killerTeam: { handle: string }[],
    ): number {
        return killerTeam.reduce(
            (sum, killer) => sum + getKillCount(killer.handle, victimHandle),
            0,
        );
    }

    function getTotalKills(
        killerHandle: string,
        victimTeam: { handle: string }[],
    ): number {
        return victimTeam.reduce(
            (sum, victim) => sum + getKillCount(killerHandle, victim.handle),
            0,
        );
    }

    function getTeamKills(
        killerTeam: { handle: string }[],
        victimTeam: { handle: string }[],
    ): number {
        return killerTeam.reduce(
            (killerSum, killer) =>
                killerSum +
                victimTeam.reduce(
                    (victimSum, victim) =>
                        victimSum + getKillCount(killer.handle, victim.handle),
                    0,
                ),
            0,
        );
    }
</script>

{#snippet killMatrix(killerTeam, victimTeam, killerTeamClass, victimTeamClass)}
    <table class="table table-bordered table-sm">
        <thead>
            <tr>
                <th></th>
                {#each killerTeam as player}
                    <th class="text-center fw-normal {killerTeamClass}">
                        <small>{player.handle}</small>
                    </th>
                {/each}
                <th class="text-center fw-medium">all</th>
            </tr>
        </thead>
        <tbody>
            {#each victimTeam as victim}
                <tr>
                    <td
                        class="text-end {victimTeamClass}"
                        style="min-width: 80px;"
                    >
                        <small>{victim.handle}</small>
                    </td>
                    {#each killerTeam as killer}
                        {@const kills = getKillCount(
                            killer.handle,
                            victim.handle,
                        )}
                        <td class="text-center">
                            {kills || ""}
                        </td>
                    {/each}
                    <td class="text-center">
                        {getTotalDeaths(victim.handle, killerTeam) || ""}
                    </td>
                </tr>
            {/each}
            <tr>
                <td class="text-end">all</td>
                {#each killerTeam as killer}
                    <td class="text-center">
                        {getTotalKills(killer.handle, victimTeam) || ""}
                    </td>
                {/each}
                <td class="text-center">
                    {getTeamKills(killerTeam, victimTeam)}
                </td>
            </tr>
        </tbody>
    </table>
{/snippet}

<div class="row g-3">
    <div class="col-12 col-md-6">
        <dl>
            <dt>Red Kills</dt>
            <dd>
                {@render killMatrix(redTeam, blueTeam, "team-red", "team-blue")}
            </dd>
        </dl>
    </div>

    <div class="col-12 col-md-6">
        <dl>
            <dt>Blue Kills</dt>
            <dd>
                {@render killMatrix(blueTeam, redTeam, "team-blue", "team-red")}
            </dd>
        </dl>
    </div>
</div>

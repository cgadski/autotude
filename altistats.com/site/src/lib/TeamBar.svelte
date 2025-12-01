<script lang="ts">
    export let team3Value: number;
    export let team4Value: number;

    function calculatePercentages(team3: number, team4: number) {
        const total = team3 + team4;
        if (total === 0) return { team3: 0, team4: 0 };
        return {
            team3: Math.round((team3 / total) * 100),
            team4: Math.round((team4 / total) * 100),
        };
    }

    $: percentages = calculatePercentages(team3Value, team4Value);
</script>

<div class="team-bar">
    {#if team3Value > 0}
        <div
            class="team-segment team-red-dark"
            style="width: {percentages.team3}%"
        ></div>
    {/if}
    {#if team4Value > 0}
        <div
            class="team-segment team-blue-dark"
            style="width: {percentages.team4}%"
        ></div>
    {/if}
</div>

<style>
    .team-bar {
        display: flex;
        width: 60px;
        height: 12px;
        border-radius: 6px;
        overflow: hidden;
        border: 1px solid #dee2e6;
    }

    .team-segment {
        transition: width 0.3s ease;
    }
</style>

<script lang="ts">
    export let series: number;
</script>

{#if series == 0}
    <p>
        Ladder games, played on the <a href="https://planeball.com"
            >planeball.com</a
        > servers managed by Van1shing.
    </p>
{/if}

{#if series == 1}
    <p>
        First top dog tournament. 3 round Swiss format group stage followed by
        semi-finals and finals, all games bo3, maps fixed in advance. Teams were
        organized by players, subject to rating limit.
    </p>
{/if}

{#if series == 2}
    <p>
        Second top dog tournament, round robin format, bo5 series, losers could
        choose order of maps. At start of each bo5, teams could ban a single red
        perk from the enemy. After each game, losing team could ban 2 more, with
        the restriction of not banning all 3 red perks for a given plane.
    </p>
{/if}

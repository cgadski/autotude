<script lang="ts">
    import NavLinks from "$lib/NavLinks.svelte";
    import SiteHeader from "$lib/SiteHeader.svelte";

    // @type {import('./$types').PageData}
    export let data;
</script>

<SiteHeader navPage="player" />

<section>
    <div class="table-responsive">
        <table class="table table-hover">
            <thead>
                <tr>
                    <th>Player</th>
                    <th>Games</th>
                </tr>
            </thead>
            <tbody>
                {#each data.players as player}
                    <tr class="clickable-row">
                        <td>
                            <a href="/player/{player.vapor}">
                                {player.nicks[0]}
                            </a>
                        </td>
                        <td>{player.games}</td>
                    </tr>
                {/each}
            </tbody>
        </table>
    </div>
</section>

<style>
    .clickable-row a {
        text-decoration: none;
        color: inherit;
        display: block;
    }
</style>

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
                        <td colspan="2">
                            <a href="/player/{player.vapor}" class="row-link">
                                <div class="d-flex justify-content-between">
                                    <span>{player.nicks[0]}</span>
                                    <span>{player.games}</span>
                                </div>
                            </a>
                        </td>
                    </tr>
                {/each}
            </tbody>
        </table>
    </div>
</section>

<style>
    .clickable-row {
        cursor: pointer;
    }

    .row-link {
        text-decoration: none;
        color: inherit;
        display: block;
        padding: 0.5rem 0.75rem;
        margin: -0.5rem -0.75rem; /* Negative margin to make entire cell clickable */
    }

    .row-link:hover {
        color: inherit;
    }
</style>

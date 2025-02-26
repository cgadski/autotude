<script lang="ts">
    import GameCard from "$lib/GameCard.svelte";
    import SiteHeader from "$lib/SiteHeader.svelte";
    import type { Game } from "$lib/db";

    /* @type {import('./$types').PageData} */
    export let data: {
        game: Game;
    };

    let game = data.game;
</script>

<SiteHeader />

<section>
    <GameCard {game} />
</section>

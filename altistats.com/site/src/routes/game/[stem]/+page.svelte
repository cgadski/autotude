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

<section class="no-bg">
    <GameCard {game} />
</section>

<section>
    <a href="/viewer/?f={game.stem}.pb">View replay</a> (desktop only)
</section>

<script lang="ts">
    import type { NavPage } from "$lib";
    import NavLinks from "./NavLinks.svelte";
    export let navPage: NavPage = null;
</script>

<svelte:head>
    <script
        data-goatcounter="https://altistats.goatcounter.com/count"
        async
        src="//gc.zgo.at/count.js"
    ></script>
</svelte:head>

<header class="site-header mb-3">
    <a href="/"><h1 class="site-title">altistats.com</h1></a>
    <NavLinks {navPage} />
</header>

<style>
    .site-header {
        width: 100%;
    }

    header {
        display: flex;
        flex-direction: row;
        justify-content: space-between;
        align-items: center;
        gap: 1rem;
    }

    @media (max-width: 767px) {
        header {
            flex-direction: column;
        }
    }

    h1 {
        font-size: 2rem;
        font-weight: 700;
        color: #0d6efd;
        margin-bottom: 0;
        text-align: center;
    }
</style>

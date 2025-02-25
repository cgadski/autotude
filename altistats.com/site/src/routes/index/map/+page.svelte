<script lang="ts">
    import NavLinks from "$lib/NavLinks.svelte";

    // @type {import('./$types').PageData}
    export let data;
</script>

<div>
    <NavLinks currentPage="map" />

    <div class="content-section">
        <h2 class="section-title">Map Index</h2>
        <p>This page will list all maps and their statistics.</p>
        <p class="text-muted">Coming soon...</p>
    </div>
</div>

<style>
    /* Component-specific styles would go here */
</style>

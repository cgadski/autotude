<script>
    import "$lib/styles/components.css";
    import "bootstrap/dist/css/bootstrap.min.css";
    import "bootstrap-icons/font/bootstrap-icons.css";
    import "$lib/styles/global.css";
</script>

<svelte:head>
    <script
        data-goatcounter="https://altistats.goatcounter.com/count"
        async
        src="//gc.zgo.at/count.js"
    ></script>
</svelte:head>

<div class="container py-4 px-3">
    <slot />
</div>

<style>
    :global(body) {
        background-color: #f8f9fa;
    }

    :global(header) {
        display: flex;
        flex-direction: column;
        align-items: center;
    }
</style>

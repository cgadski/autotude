<script>
    import "$lib/styles/global.css";
    import "$lib/styles/components.css";
    import "bootstrap/dist/css/bootstrap.min.css";
    import "bootstrap-icons/font/bootstrap-icons.css";
</script>

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

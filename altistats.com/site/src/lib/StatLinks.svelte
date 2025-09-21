<script lang="ts">
    export let items: Array<{
        label: string;
        value?: string;
        href?: string;
        active?: boolean;
    }> = [];
</script>

<div class="lh-lg d-flex flex-wrap align-items-center">
    {#each items as item, index}
        {#if index > 0}
            <span class="border-end border-2 mx-2" style="height: 1rem;"></span>
        {/if}
        {#if item.href}
            <a
                href={item.href}
                class="px-1 text-primary rounded {item.active
                    ? 'bg-primary text-white'
                    : 'text-decoration-underline'}"
            >
                <span
                    class="fw-medium {item.active
                        ? 'text-white'
                        : 'text-primary'}">{item.label}</span
                >
                {#if item.value}
                    <span
                        class={item.active ? "text-white" : "text-primary"}
                        style="opacity: {item.active ? '1' : '0.8'};"
                    >
                        ({item.value})</span
                    >
                {/if}
            </a>
        {:else}
            <span class="fw-medium">{item.label}:</span>
            <span class="ms-1 font-muted">
                {#if item.value}
                    {item.value}
                {/if}
            </span>
        {/if}
    {/each}
</div>

<style>
    a:hover:not(.bg-primary) {
        background-color: var(--bs-light) !important;
        color: var(--bs-gray-800) !important;
    }

    a.bg-primary:hover {
        background-color: var(--bs-primary-dark, #0056b3) !important;
    }
</style>

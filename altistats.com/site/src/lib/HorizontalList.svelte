<script lang="ts">
    export let items: any[] = [];
</script>

<div class="d-flex flex-wrap align-items-center">
    {#each items as item, index}
        {#if index > 0}
            <span
                class="border-grey border-end border-1 mx-2"
                style="height: 1rem;"
            ></span>
        {/if}
        <slot {item} {index} />
    {/each}
</div>

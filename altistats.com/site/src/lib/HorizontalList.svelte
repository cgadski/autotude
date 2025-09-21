<script lang="ts">
    export let items: any[] = [];
</script>

<div class="d-flex flex-wrap">
    {#each items as item, index}
        <div class="d-flex align-items-center" style="white-space: nowrap;">
            {#if index > 0}
                <span
                    class="border-end border-1 mx-2"
                    style="height: 1rem; border-color: rgb(0, 0, 0, 0.175) !important;"
                ></span>
            {/if}
            <slot {item} {index} />
        </div>
    {/each}
</div>

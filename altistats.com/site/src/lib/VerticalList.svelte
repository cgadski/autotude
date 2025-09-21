<script lang="ts">
    export let items: any[];
</script>

<table class="table table-sm">
    <tbody>
        {#each items as item, index}
            <tr>
                <slot {item} {index} />
            </tr>
        {/each}
    </tbody>
</table>

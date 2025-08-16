<script lang="ts">
    export let data;
    import HorizontalList from "$lib/HorizontalList.svelte";
    import { renderStat } from "$lib";
    import SiteHeader from "$lib/SiteHeader.svelte";
</script>

<SiteHeader navPage="history" />

<section>
    <HorizontalList items={data.globalStats} let:item>
        <span class="fw-medium">{item.description}</span>: {renderStat(
            item.stat,
        )}
    </HorizontalList>
</section>

<script lang="ts">
    import MiniCalendar from "$lib/MiniCalendar.svelte";
    import NavLinks from "$lib/NavLinks.svelte";
    import SiteHeader from "$lib/SiteHeader.svelte";

    // @type {import('./$types').PageData}
    export let data;
</script>

<div>
    <SiteHeader navPage="date" />

    <div class="content-section">
        <MiniCalendar calendarData={data.calendarData} />
    </div>
</div>

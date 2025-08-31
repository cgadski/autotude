<script lang="ts">
    import { goto } from "$app/navigation";
    import HorizontalList from "./HorizontalList.svelte";

    export let items: Array<{
        label: string;
        href: string;
        active?: boolean;
        info?: string;
    }> = [];

    function handleClick(event: Event, href: string) {
        event.preventDefault();
        goto(href, { noScroll: true });
    }
</script>

<HorizontalList {items} let:item>
    <span class="d-flex align-items-center gap-1">
        <a
            href={item.href}
            on:click={(e) => handleClick(e, item.href)}
            class="px-1 text-primary rounded fw-medium {item.active
                ? 'bg-primary text-white text-decoration-none'
                : 'text-primary'}"
        >
            {item.label}
        </a>
        {#if item.info}
            <span class="text-muted small">({item.info})</span>
        {/if}
    </span>
</HorizontalList>

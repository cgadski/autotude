<script lang="ts">
    import { goto } from "$app/navigation";
    import HorizontalList from "./HorizontalList.svelte";

    export let items: Array<{
        label: string;
        href: string;
        active?: boolean;
    }> = [];

    function handleClick(event: Event, href: string) {
        event.preventDefault();
        goto(href, { noScroll: true });
    }
</script>

<HorizontalList {items} let:item>
    <a
        href={item.href}
        on:click={(e) => handleClick(e, item.href)}
        class="px-1 text-primary rounded {item.active
            ? 'bg-primary text-white text-decoration-none'
            : ''}"
    >
        <span class="fw-medium {item.active ? 'text-white' : 'text-primary'}"
            >{item.label}</span
        >
    </a>
</HorizontalList>

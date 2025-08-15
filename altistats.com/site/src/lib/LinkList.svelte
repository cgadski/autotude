<script lang="ts">
    import HorizontalList from "./HorizontalList.svelte";

    export let items: Array<{
        label: string;
        href: string;
        active?: boolean;
    }> = [];
</script>

<HorizontalList {items} let:item>
    <a
        href={item.href}
        class="px-1 text-primary rounded {item.active
            ? 'bg-primary text-white text-decoration-none'
            : ''}"
    >
        <span class="fw-medium {item.active ? 'text-white' : 'text-primary'}"
            >{item.label}</span
        >
    </a>
</HorizontalList>

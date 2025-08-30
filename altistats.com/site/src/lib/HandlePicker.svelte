<script lang="ts">
    import Fuse from "fuse.js";
    import HorizontalList from "./HorizontalList.svelte";

    export let handles: string[] = [];
    export let selectedHandles: string[] = [];
    export let handleDescription: string = "Showing games with:";

    let searchTerm = "";
    let results: string[] = [];
    let fuse: Fuse<string>;

    $: if (handles && handles.length) {
        const options = {
            includeScore: true,
            threshold: 0.3,
        };
        fuse = new Fuse(handles, options);
    }

    $: {
        if (searchTerm && fuse) {
            const searchResults = fuse.search(searchTerm);
            results = searchResults
                .map((result) => result.item)
                .filter((handle) => !selectedHandles.includes(handle))
                .slice(0, 10);
        } else {
            results = [];
        }
    }

    function selectHandle(handle: string) {
        if (handle && !selectedHandles.includes(handle)) {
            selectedHandles = [...selectedHandles, handle];
        }
        searchTerm = "";
    }

    function removeHandle(handle: string) {
        selectedHandles = selectedHandles.filter((h) => h !== handle);
    }

    function clearAllSelections() {
        selectedHandles = [];
    }

    function handleKeydown(event: KeyboardEvent) {
        if (event.key === "Enter" && searchTerm.trim()) {
            event.preventDefault();
            if (results.length > 0) {
                selectHandle(results[0]);
            }
        }
    }
</script>

<div class="input-group mb-3">
    <input
        type="text"
        class="form-control"
        placeholder="Search for player..."
        bind:value={searchTerm}
        on:keydown={handleKeydown}
    />
</div>

<!-- search results -->
{#if searchTerm && results.length > 0}
    <div class="d-flex flex-wrap gap-2 mb-3">
        {#each results as handle}
            <button
                class="btn btn-sm btn-outline-secondary"
                on:click={() => selectHandle(handle)}
            >
                {handle}
            </button>
        {/each}
    </div>
{:else if searchTerm && results.length === 0}
    <div class="text-muted small mb-3">
        {selectedHandles.length > 0 && handles.length === selectedHandles.length
            ? "All players have been selected"
            : "No matches found"}
    </div>
{/if}

{#if selectedHandles.length > 0}
    <div class="mb-3 d-flex align-items-center">
        <span class="fw-medium me-2">{handleDescription}</span>
        <div class="flex-grow-1">
            <HorizontalList items={selectedHandles}>
                <svelte:fragment let:item let:index>
                    <div class="d-flex align-items-center">
                        <span>{item}</span>
                        <button
                            class="btn text-danger p-0 ms-2"
                            on:click={() => removeHandle(item)}
                        >
                            &times;
                        </button>
                    </div>
                </svelte:fragment>
            </HorizontalList>
        </div>
        <button
            class="btn btn-sm btn-outline-secondary"
            on:click={clearAllSelections}
        >
            Clear all
        </button>
    </div>
{/if}

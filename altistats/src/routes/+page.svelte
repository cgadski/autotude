<script>
    /** @type {import('./$types').PageData} */
    export let data;
    import "./styles.css";
</script>

<svelte:head>
    <link
        rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/water.css@2/out/dark.css"
    />
</svelte:head>

<div class="container mt-5">
    <h1>altistats.com</h1>

    <h2>Active servers</h2>
    <table>
        <thead>
            <tr>
                <td>Server</td>
                <td>Map</td>
                <td>Current players</td>
            </tr>
        </thead>
        <tbody>
            {#each data.listings as listing}
                <tr>
                    <td>
                        {listing.name}
                    </td>
                    <td>{listing.map}</td>
                    <td>{listing.players}</td>
                </tr>
            {/each}
        </tbody>
    </table>

    <h2>Replays</h2>
    <p>Coming this afternoon…</p>
</div>

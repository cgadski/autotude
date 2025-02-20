<script lang="ts">
    import GameCard from "$lib/GameCard.svelte";
    /** @type {import('./$types').PageData} */
    export let data;
    import "./styles.css";

    let secondsAgo = 0;

    function updateTimer() {
        if (data.lastUpdate) {
            const lastUpdate = new Date(data.lastUpdate);
            secondsAgo = Math.floor((new Date() - lastUpdate) / 1000);
        }
    }

    // Update timer every second
    setInterval(updateTimer, 1000);
    updateTimer(); // Initial update
</script>

<svelte:head>
    <link rel="stylesheet" href="/css/water.css" />
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
    <p class="update-time">(Update from {secondsAgo} seconds ago)</p>

    <h2>Recordings</h2>
    {#each data.games as game}
        <GameCard {game} />
    {/each}
</div>

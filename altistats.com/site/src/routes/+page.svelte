<script lang="ts">
    import GameCard from "$lib/GameCard.svelte";
    import { formatDuration } from "$lib";
    // @type {import('./$types').PageData}
    export let data;
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
    <p>
        <strong>{data.totals.n_vapors}</strong> players,
        <strong>{data.totals.n_replays}</strong> games,
        <strong>{data.totals.hours}</strong> hours of gameplay.
    </p>

    <table>
        <tbody>
            {#each data.games as game}
                <tr class="clickable-row">
                    <td>
                        <a href="/game/{game.stem}">
                            {new Date(game.started_at).toLocaleString()}
                        </a>
                    </td>
                    <td>
                        <a href="/game/{game.stem}">{game.map}</a>
                    </td>
                    <td>
                        <a href="/game/{game.stem}"
                            >{formatDuration(game.duration)}</a
                        >
                    </td>
                </tr>
            {/each}
        </tbody>
    </table>

    <style>
        .clickable-row a {
            text-decoration: none;
            color: inherit;
            display: block;
        }
        .clickable-row:hover {
            background-color: rgba(0, 0, 0, 0.1);
        }
    </style>
</div>

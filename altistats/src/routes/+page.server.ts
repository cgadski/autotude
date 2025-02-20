import { getRecentListings, getLastUpdate, getRecentGames, getTotals } from '$lib/db';

export async function load() {
    const [listings, lastUpdate, games, totals] = await Promise.all([
        getRecentListings(),
        getLastUpdate(),
        getRecentGames(),
        getTotals()
    ]);
    return {
        listings,
        lastUpdate,
        games,
        totals
    };
}

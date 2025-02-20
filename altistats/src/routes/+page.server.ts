import { getRecentListings, getLastUpdate, getRecentGames } from '$lib/db';

export async function load() {
    const [listings, lastUpdate, games] = await Promise.all([
        getRecentListings(),
        getLastUpdate(),
        getRecentGames()
    ]);
    return {
        listings,
        lastUpdate,
        games
    };
}

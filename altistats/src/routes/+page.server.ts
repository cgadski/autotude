import { getRecentListings } from '$lib/db';

export async function load() {
    const listings = await getRecentListings();
    return {
        listings
    };
}

import { error } from '@sveltejs/kit';
import { getPlayerInfo, getPlayerGamesByDate } from '$lib/db';

export async function load({ params }) {
    const vapor = params.vapor;
    
    // Get player info
    const playerInfo = await getPlayerInfo(vapor);
    
    if (!playerInfo) {
        throw error(404, 'Player not found');
    }
    
    // Get player games grouped by date
    const gamesByDate = await getPlayerGamesByDate(vapor);
    
    return {
        player: playerInfo,
        gamesByDate
    };
}

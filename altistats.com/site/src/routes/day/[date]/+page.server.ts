import { error } from '@sveltejs/kit';
import { gamesForDate } from '$lib/db';

export async function load({ params }) {
    const date = params.date;
    
    // Validate date format (YYYY-MM-DD)
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
        throw error(400, 'Invalid date format');
    }
    
    // Get games for the specific date
    const games = await gamesForDate(date);
    
    if (games.length === 0) {
        throw error(404, 'No games found for this date');
    }
    
    return {
        date,
        games
    };
}

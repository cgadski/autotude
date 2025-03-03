<script lang="ts">
    import calendarize from "calendarize";
    
    export let calendarData: Array<{ date: string; count: number }> = [];
    
    // Create a map for easy lookup of game counts by date
    const gameCountMap = new Map();
    calendarData.forEach(entry => {
        gameCountMap.set(entry.date, entry.count);
    });
    
    // Debug output
    console.log("Calendar data:", calendarData);
    
    // Get current date for initialization
    const currentDate = new Date();
    let year = currentDate.getFullYear();
    let month = currentDate.getMonth();
    const offset = 0; // Sunday as first day
    
    // Day and month labels
    const labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    const months = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ];
    
    // Generate calendar data
    $: prev = calendarize(new Date(year, month - 1), offset);
    $: current = calendarize(new Date(year, month), offset);
    $: next = calendarize(new Date(year, month + 1), offset);
    
    // Navigation functions
    function toPrev() {
        if (--month < 0) {
            month = 11;
            year--;
        }
    }
    
    function toNext() {
        if (++month > 11) {
            month = 0;
            year++;
        }
    }
    
    // Check if a date is today
    function isToday(day: number): boolean {
        const today = new Date();
        return (
            today.getFullYear() === year &&
            today.getMonth() === month &&
            today.getDate() === day
        );
    }
    
    // Format date as YYYY-MM-DD for URLs and lookup
    function formatDate(year: number, month: number, day: number): string {
        return `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    }
    
    // Get game count for a specific date
    function getGameCount(day: number): number {
        const dateStr = formatDate(year, month, day);
        return gameCountMap.get(dateStr) || 0;
    }
    
    // Calculate color intensity based on count
    function getColorIntensity(count: number): number {
        if (count === 0) return 0;
        return Math.min(Math.max(Math.log(count) / Math.log(10) * 0.7, 0.2), 0.9);
    }
</script>

<div class="calendar-container">
    <div class="calendar-header d-flex justify-content-between align-items-center mb-3">
        <button class="btn btn-sm btn-outline-secondary" on:click={toPrev}>
            &laquo; Prev
        </button>
        <h5 class="mb-0">{months[month]} {year}</h5>
        <button class="btn btn-sm btn-outline-secondary" on:click={toNext}>
            Next &raquo;
        </button>
    </div>
    
    <div class="calendar">
        <div class="weekdays">
            {#each labels as label}
                <div class="weekday">{label}</div>
            {/each}
        </div>
        
        <div class="days">
            {#each { length: 6 } as _, weekIdx}
                {#if current[weekIdx]}
                    {#each { length: 7 } as _, dayIdx}
                        {#if current[weekIdx][dayIdx] !== 0}
                            {@const day = current[weekIdx][dayIdx]}
                            {@const count = getGameCount(day)}
                            {@const dateStr = formatDate(year, month, day)}
                            {@const hasGames = count > 0}
                            
                            <a 
                                href={hasGames ? `/day/${dateStr}` : null} 
                                class="day-cell"
                                class:has-games={hasGames}
                                class:today={isToday(day)}
                                style={hasGames ? `--intensity: ${getColorIntensity(count)}` : ''}
                                tabindex={hasGames ? 0 : -1}
                            >
                                <span class="day-number">{day}</span>
                                {#if hasGames}
                                    <span class="game-count">{count}</span>
                                {/if}
                            </a>
                        {:else if weekIdx < 1}
                            <div class="day-cell other-month">
                                <span class="day-number">{prev[prev.length - 1][dayIdx]}</span>
                            </div>
                        {:else}
                            <div class="day-cell other-month">
                                <span class="day-number">{next[0][dayIdx]}</span>
                            </div>
                        {/if}
                    {/each}
                {/if}
            {/each}
        </div>
    </div>
</div>

<style>
    .calendar-container {
        max-width: 800px;
        margin: 0 auto;
    }
    
    .calendar {
        border-radius: 8px;
        overflow: hidden;
    }
    
    .weekdays {
        display: grid;
        grid-template-columns: repeat(7, 1fr);
        text-align: center;
        font-weight: 500;
        color: #6c757d;
        margin-bottom: 0.5rem;
    }
    
    .weekday {
        padding: 0.5rem 0;
        font-size: 0.85rem;
    }
    
    .days {
        display: grid;
        grid-template-columns: repeat(7, 1fr);
        gap: 4px;
    }
    
    .day-cell {
        aspect-ratio: 1;
        display: flex;
        flex-direction: column;
        justify-content: space-between;
        align-items: center;
        padding: 0.5rem;
        border-radius: 4px;
        border: 1px solid #dee2e6;
        text-decoration: none;
        color: inherit;
        position: relative;
        transition: all 0.2s ease;
    }
    
    .day-cell.has-games {
        background-color: rgba(13, 110, 253, var(--intensity));
        color: white;
        cursor: pointer;
        border-color: rgba(13, 110, 253, 0.5);
    }
    
    .day-cell.has-games:hover {
        transform: scale(1.05);
        z-index: 1;
        box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
    }
    
    .day-cell.today {
        border: 2px solid #0d6efd;
        font-weight: bold;
    }
    
    .day-cell.other-month {
        color: #adb5bd;
        background-color: #f8f9fa;
    }
    
    .day-number {
        font-weight: 500;
        font-size: 0.9rem;
    }
    
    .game-count {
        font-size: 0.7rem;
        font-weight: bold;
        background-color: rgba(255, 255, 255, 0.3);
        border-radius: 50%;
        width: 20px;
        height: 20px;
        display: flex;
        align-items: center;
        justify-content: center;
        position: absolute;
        bottom: 4px;
        right: 4px;
    }
    
    @media (max-width: 576px) {
        .day-cell {
            padding: 0.25rem;
        }
        
        .day-number {
            font-size: 0.8rem;
        }
        
        .game-count {
            width: 16px;
            height: 16px;
            font-size: 0.6rem;
        }
        
        .weekday {
            font-size: 0.75rem;
            padding: 0.25rem 0;
        }
    }
</style>

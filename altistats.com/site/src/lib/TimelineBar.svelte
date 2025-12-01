<script lang="ts">
    export let events: Array<{
        tick: number;
        type: "goal" | "sudden_death";
        team?: number;
        handle?: string;
    }> = [];
    export let duration: number = 0;
    export let stem: string;

    function getEventColor(event: { type: string; team?: number }): string {
        if (event.type === "goal") {
            return event.team === 3 ? "#dc2626" : "#2563eb";
        }
        return "#6b7280"; // grey for sudden death
    }

    function getEventPosition(tick: number): number {
        if (duration === 0) return 0;
        return Math.min((tick / duration) * 100, 100);
    }
</script>

<div class="timeline-bar">
    <div class="timeline-track">
        {#each events as event}
            <a
                href="/viewer/?f={stem}.pb&t={event.tick - 2 * 30}"
                class="timeline-dot"
                style="left: {getEventPosition(
                    event.tick,
                )}%; background-color: {getEventColor(event)};"
                title={event.type === "goal"
                    ? `goal by ${event.handle}`
                    : "sudden death"}
            ></a>
        {/each}
    </div>
</div>

<style>
    .timeline-bar {
        margin-bottom: 1rem;
    }

    .timeline-track {
        position: relative;
        height: 8px;
        background-color: #e5e7eb;
        border-radius: 4px;
        /*border: 1px solid #d1d5db;*/
    }

    .timeline-dot {
        position: absolute;
        width: 16px;
        height: 16px;
        border-radius: 50%;
        top: -4px;
        text-decoration: none;
        cursor: pointer;
    }
</style>

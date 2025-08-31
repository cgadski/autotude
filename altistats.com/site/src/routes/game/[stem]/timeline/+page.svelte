<script lang="ts">
    import { formatDurationFine, formatTimestamp } from "$lib";

    export let data;

    // Define types for timeline events
    type TimelineEvent = {
        type: "possession" | "goal";
        tick: number;
        handle: string;
        team: number;
        duration?: number;
    };

    type PossessionRun = {
        type: "possession";
        team: number;
        startTick: number;
        events: TimelineEvent[];
    };

    type GoalEvent = {
        type: "goal";
        team: number;
        startTick: number;
        handle: string;
    };

    type TimelineItem = PossessionRun | GoalEvent;

    // Process timeline events from unified timeline data
    let timelineEvents: TimelineEvent[] = [];

    if (data.timeline && data.timeline.length > 0) {
        data.timeline.forEach((event: any) => {
            if (event.event_type === "possession") {
                timelineEvents.push({
                    type: "possession",
                    tick: event.tick,
                    handle: event.handle,
                    team: event.team,
                    duration: event.duration,
                });
            } else if (event.event_type === "goal") {
                timelineEvents.push({
                    type: "goal",
                    tick: event.tick,
                    handle: event.handle,
                    team: event.team,
                });
            }
        });
    }

    // Group possession events by team runs
    let possessionRuns: TimelineItem[] = [];
    let currentRun: PossessionRun | null = null;

    timelineEvents.forEach((event) => {
        if (event.type === "goal") {
            // If there's a current run, add it to the list
            if (currentRun) {
                possessionRuns.push(currentRun);
                currentRun = null;
            }

            // Add the goal as its own "run"
            possessionRuns.push({
                type: "goal",
                team: event.team,
                startTick: event.tick,
                handle: event.handle,
            });
        } else if (event.type === "possession") {
            if (!currentRun) {
                // Start a new possession run
                currentRun = {
                    type: "possession",
                    team: event.team,
                    startTick: event.tick,
                    events: [event],
                };
            } else if (event.team === currentRun.team) {
                // Same team, add to current run
                currentRun.events.push(event);
            } else {
                // Different team, finish current run and start a new one
                possessionRuns.push(currentRun);
                currentRun = {
                    type: "possession",
                    team: event.team,
                    startTick: event.tick,
                    events: [event],
                };
            }
        }
    });

    // Add the last run if it exists
    if (currentRun) {
        possessionRuns.push(currentRun);
    }
</script>

<div class="table-responsive">
    <table class="table table-sm">
        <colgroup>
            <col style="width: 4em;" />
            <col />
        </colgroup>
        <tbody>
            {#each possessionRuns as run, i}
                {#if run.type === "goal"}
                    <tr class="table-warning">
                        <td class="text-nowrap text-end"
                            >{formatTimestamp(run.startTick)}</td
                        >
                        <td>
                            <strong>GOAL!</strong> by
                            <a href="/player/{encodeURIComponent(run.handle)}">
                                {run.handle}
                            </a>
                        </td>
                    </tr>
                {:else}
                    <tr class={run.team === 3 ? "team-red" : "team-blue"}>
                        <td class="text-nowrap text-end"
                            >{formatTimestamp(run.startTick)}</td
                        >
                        <td>
                            {#each run.events as event, j}
                                <span class="possession-event">
                                    <a
                                        href="/player/{encodeURIComponent(
                                            event.handle,
                                        )}">{event.handle}</a
                                    >
                                    <small class="text-muted ms-1">
                                        ({formatDurationFine(
                                            event.duration || 0,
                                        )})
                                    </small>
                                    <span class="d-none d-sm-inline">
                                        {j < run.events.length - 1 ? " → " : ""}
                                    </span>
                                </span>
                            {/each}
                        </td>
                    </tr>
                {/if}
            {/each}
        </tbody>
    </table>
</div>

<style>
    .possession-event {
        white-space: nowrap;
        display: inline-block;
        margin-right: 8px;
    }

    @media (max-width: 575.98px) {
        .possession-event {
            display: block;
            margin-bottom: 4px;
        }
        .possession-event:not(:last-child)::after {
            content: "↓";
            display: block;
            text-align: center;
            color: #6c757d;
            margin: 2px 0;
        }
    }
</style>

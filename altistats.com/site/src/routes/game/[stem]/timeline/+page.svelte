<script lang="ts">
    import { formatTimestamp, formatDurationFine } from "$lib";
    import TeamBar from "$lib/TeamBar.svelte";
    import LinkList from "$lib/LinkList.svelte";

    export let data;

    let showMessages = true;

    $: toggleItems = [
        {
            label: "Show chat",
            href: "#",
            active: showMessages,
        },
        {
            label: "Hide chat",
            href: "#",
            active: !showMessages,
        },
    ];

    function handleToggle(event: Event, show: boolean) {
        event.preventDefault();
        showMessages = show;
    }

    function getMessageTeamClass(team: number | null): string {
        if (team === 3) return "team-red";
        if (team === 4) return "team-blue";
        return "";
    }
</script>

<div class="message-toggle">
    <LinkList
        items={toggleItems}
        onclick={(event, item) =>
            handleToggle(event, item.label === "Show chat")}
    />
</div>

<div class="table-responsive">
    <table class="table table-sm no-bg">
        <colgroup>
            <col style="width: 4em;" />
            <col />
        </colgroup>
        <tbody>
            {#each data.timelineItems as item}
                {#if item.type !== "message" || showMessages}
                    <tr
                        class={item.type === "block_end" && item.endTeam === 3
                            ? "team-red"
                            : item.type === "block_end" && item.endTeam === 4
                              ? "team-blue"
                              : item.type === "message"
                                ? getMessageTeamClass(item.team)
                                : ""}
                    >
                        <td class="text-nowrap text-end text-muted">
                            <a href="/viewer/?f={data.stem}.pb&t={item.tick}">
                                {formatTimestamp(item.tick)}
                            </a>
                        </td>
                        <td>
                            {#if item.type === "message"}
                                {#if item.handle}
                                    <a
                                        href="/player/{encodeURIComponent(
                                            item.handle,
                                        )}"
                                    >
                                        {item.handle}
                                    </a>:
                                {:else}
                                    <span class="text-muted">Server</span>:
                                {/if}
                                {item.chat_message}
                            {:else if item.type === "block_end"}
                                <div class="block-info">
                                    {#if item.endType === "goal"}
                                        <strong>Goal</strong> by {item.endHandle}
                                    {:else if item.endType === "sudden_death"}
                                        <strong>Sudden Death</strong>
                                    {/if}
                                </div>
                                <div class="block-summary">
                                    Poss: {formatDurationFine(
                                        item.team3Duration,
                                    )}
                                    <TeamBar
                                        team3Value={item.team3Duration}
                                        team4Value={item.team4Duration}
                                    />
                                    {formatDurationFine(item.team4Duration)}
                                </div>
                                <div class="block-summary">
                                    Kills: {item.team3Kills}
                                    <TeamBar
                                        team3Value={item.team3Kills}
                                        team4Value={item.team4Kills}
                                    />
                                    {item.team4Kills}
                                </div>
                            {/if}
                        </td>
                    </tr>
                {/if}
            {/each}
        </tbody>
    </table>

    {#if data.timelineItems.length === 0}
        <div class="text-center text-muted py-4">
            <p>No timeline data available</p>
        </div>
    {/if}
</div>

<style>
    .message-toggle {
        margin-bottom: 1rem;
    }

    .block-info {
        margin-bottom: 4px;
    }

    .block-summary {
        display: flex;
        align-items: center;
        gap: 8px;
        margin-bottom: 4px;
    }

    .block-summary:last-child {
        margin-bottom: 0;
    }
</style>

<script lang="ts">
    import { formatTimestamp, formatDurationFine } from "$lib";
    import TeamBar from "$lib/TeamBar.svelte";
    import LinkList from "$lib/LinkList.svelte";
    import HorizontalList from "$lib/HorizontalList.svelte";

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
                            <a
                                href="/viewer/?f={data.stem}.pb&t={item.tick -
                                    2 * 30}"
                            >
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
                                <HorizontalList
                                    items={[
                                        {
                                            type: "possession",
                                            team3Value: item.team3Duration,
                                            team4Value: item.team4Duration,
                                        },
                                        {
                                            type: "kills",
                                            team3Value: item.team3Kills,
                                            team4Value: item.team4Kills,
                                        },
                                    ]}
                                    let:item={statItem}
                                >
                                    <div class="block-summary">
                                        {#if statItem.type === "possession"}
                                            Poss: {formatDurationFine(
                                                statItem.team3Value,
                                            )}
                                            <TeamBar
                                                team3Value={statItem.team3Value}
                                                team4Value={statItem.team4Value}
                                            />
                                            {formatDurationFine(
                                                statItem.team4Value,
                                            )}
                                        {:else if statItem.type === "kills"}
                                            Kills: {statItem.team3Value}
                                            <TeamBar
                                                team3Value={statItem.team3Value}
                                                team4Value={statItem.team4Value}
                                            />
                                            {statItem.team4Value}
                                        {/if}
                                    </div>
                                </HorizontalList>
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
    }
</style>

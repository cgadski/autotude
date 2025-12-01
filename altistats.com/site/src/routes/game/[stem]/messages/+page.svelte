<script lang="ts">
    import { formatTimestamp } from "$lib";

    export let data;
</script>

<div class="table-responsive">
    <table class="table table-sm no-bg">
        <colgroup>
            <col style="width: 4em;" />
            <col />
        </colgroup>
        <tbody>
            {#each data.messages as message}
                <tr>
                    <td class="text-nowrap text-end text-muted">
                        <a href="/viewer/?f={data.stem}.pb&t={message.tick}">
                            {formatTimestamp(message.tick)}
                        </a>
                    </td>
                    <td class="message-content">
                        {#if message.handle}
                            <a
                                href="/player/{encodeURIComponent(
                                    message.handle,
                                )}"
                            >
                                {message.handle}
                            </a>:
                        {:else}
                            <span class="text-muted">Server</span>:
                        {/if}
                        {message.chat_message}
                    </td>
                </tr>
            {/each}
        </tbody>
    </table>

    {#if data.messages.length === 0}
        <div class="text-center text-muted py-4">
            <p>No messages in this game</p>
        </div>
    {/if}
</div>

<style>
    .message-content {
        white-space: pre-wrap;
    }
</style>

<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import { formatDuration, formatDurationCoarse, planes } from "$lib";

    // @type {import('./$types').PageData}
    export let data;

    // Group data by month
    const monthlyData: Array<{
        month: string;
        total_time: number;
        planes: Map<
            number,
            {
                time_alive: number;
                scaled_proportion: number;
            }
        >;
    }> = (() => {
        const months = new Map();

        data.timeAliveByMonth.forEach((row) => {
            if (!months.has(row.time_bin_desc)) {
                months.set(row.time_bin_desc, {
                    month: row.time_bin_desc,
                    total_time: row.total_time,
                    planes: new Map(),
                });
            }
            months.get(row.time_bin_desc).planes.set(row.plane, {
                time_alive: row.time_alive,
                scaled_proportion: row.scaled_proportion,
            });
        });

        return Array.from(months.values()).sort((a, b) =>
            b.month.localeCompare(a.month),
        );
    })();

    $: allPlanes = planes.map((_, index) => index);
</script>

<SiteHeader />

<section>
    <h2>Stats: {data.handle}</h2>

    <nav class="mb-3">
        <a
            href="/player/{encodeURIComponent(data.handle)}"
            class="btn btn-outline-primary btn-sm"
        >
            ← Back to Player
        </a>
    </nav>
</section>

<section>
    <h3>Activity</h3>

    {#if monthlyData.length > 0}
        <div class="table-responsive">
            <table class="table table-sm monthly-table">
                <thead>
                    <tr>
                        <th scope="col" style="width: 6em"></th>
                        <th scope="col" style="width: 6em"></th>
                        {#each allPlanes as plane}
                            <th scope="col" class="text-center"
                                >{planes[plane]}</th
                            >
                        {/each}
                    </tr>
                </thead>
                <tbody>
                    {#each monthlyData as monthData}
                        <tr>
                            <td class="text-end align-middle">
                                {new Date(
                                    monthData.month + "-01",
                                ).toLocaleDateString("en-US", {
                                    month: "short",
                                    year: "numeric",
                                })}
                            </td>
                            <td class="text-center align-middle">
                                <div class="fw-medium">
                                    {formatDurationCoarse(monthData.total_time)}
                                </div>
                            </td>
                            {#each allPlanes as plane}
                                {@const planeData = monthData.planes.get(plane)}
                                <td
                                    class="position-relative align-middle"
                                    style="min-width: 120px;"
                                >
                                    {#if planeData}
                                        <div
                                            class="progress"
                                            style="height: 1.5rem;"
                                        >
                                            <div
                                                class="progress-bar"
                                                style="width: {planeData.scaled_proportion *
                                                    100}%; background-color: hsl(210, 70%, 60%);"
                                            ></div>
                                        </div>
                                        <small
                                            class="position-absolute top-50 start-50 translate-middle text-dark fw-medium"
                                        >
                                            {formatDuration(
                                                planeData.time_alive,
                                            )}
                                        </small>
                                    {/if}
                                </td>
                            {/each}
                        </tr>
                    {/each}
                </tbody>
            </table>
        </div>
    {:else}
        <p class="text-muted">No time played data available.</p>
    {/if}
</section>

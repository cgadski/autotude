<script lang="ts">
    import NavLinks from "$lib/NavLinks.svelte";
    import SiteHeader from "$lib/SiteHeader.svelte";
    import { formatStat } from "$lib";
    import * as d3 from "d3";
    import { onMount } from "svelte";

    // @type {import('./$types').PageData}
    export let data;

    let histogramElement: HTMLElement;

    function renderHistogram() {
        if (!histogramElement || !data.players.length) return;

        const containerWidth = histogramElement.clientWidth;
        const margin = { top: 20, right: 30, bottom: 40, left: 60 };
        const width = containerWidth - margin.left - margin.right;
        const height = 200 - margin.top - margin.bottom;

        // Clear previous chart
        d3.select(histogramElement).selectAll("*").remove();

        const svg = d3
            .select(histogramElement)
            .append("svg")
            .attr("width", "100%")
            .attr("height", height + margin.top + margin.bottom)
            .attr(
                "viewBox",
                `0 0 ${width + margin.left + margin.right} ${height + margin.top + margin.bottom}`,
            )
            .append("g")
            .attr("transform", `translate(${margin.left},${margin.top})`);

        // Get stat values
        const values = data.players.map((p) => p.stat);

        // Create histogram
        const x = d3.scaleLinear().domain(d3.extent(values)).range([0, width]);

        const histogram = d3
            .histogram()
            .value((d) => d)
            .domain(x.domain())
            .thresholds(x.ticks(40));

        const bins = histogram(values);

        const y = d3
            .scaleLinear()
            .range([height, 0])
            .domain([0, d3.max(bins, (d) => d.length)]);

        // Add bars
        svg.selectAll("rect")
            .data(bins)
            .enter()
            .append("rect")
            .attr("x", 1)
            .attr("transform", (d) => `translate(${x(d.x0)},${y(d.length)})`)
            .attr("width", (d) => Math.max(0, x(d.x1) - x(d.x0) - 1))
            .attr("height", (d) => height - y(d.length))
            .style("fill", "steelblue")
            .style("opacity", 0.7);

        // Add axes
        svg.append("g")
            .attr("transform", `translate(0,${height})`)
            .call(
                d3
                    .axisBottom(x)
                    .tickFormat((d) =>
                        formatStat(d, data.stat.attributes || []),
                    ),
            );

        svg.append("g").call(d3.axisLeft(y));
    }

    onMount(() => {
        renderHistogram();
    });

    $: if (data.players) {
        renderHistogram();
    }
</script>

<SiteHeader navPage="player" />

<section>
    <div class="d-flex flex-wrap gap-2">
        {#each data.statTypes as statType}
            <a
                href="?stat={statType.query_name}"
                class="btn {data.stat.query_name === statType.query_name
                    ? 'btn-primary'
                    : 'btn-outline-primary'}"
            >
                {statType.description}
            </a>
        {/each}
    </div>
</section>

<section class="no-bg">
    <div bind:this={histogramElement}></div>
</section>

<section class="narrow">
    <table class="table table-sm">
        <colgroup>
            <col style="width: 60px;" />
            <col />
            <col style="width: 120px;" />
        </colgroup>
        <tbody>
            {#each data.players as player, index}
                <tr>
                    <td class="text-muted">{index + 1}</td>
                    <td>
                        <a href="/player/{player.vapor}">
                            {player.name}
                        </a>
                    </td>
                    <td class="text-end">
                        {formatStat(player.stat, data.stat.attributes)}
                    </td>
                </tr>
            {/each}
        </tbody>
    </table>
</section>

<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import StatLinks from "$lib/StatLinks.svelte";
    import { formatStat } from "$lib";
    import { onMount } from "svelte";
    import * as d3 from "d3";

    // @type {import('./$types').PageData}
    export let data;

    let chartElement: HTMLElement;

    $: statItems = data.availableStats.map((stat) => {
        const urlParams = new URLSearchParams();
        urlParams.set("stat", stat.query_name);
        const queryString = urlParams.toString();
        const href = `/history?${queryString}`;

        return {
            label: stat.description,
            value: formatStat(stat.total, stat.attributes),
            href,
            active: data.selectedStat === stat.query_name,
        };
    });

    function getCurrentStatAttributes() {
        const currentStat = data.availableStats.find(
            (s) => s.query_name === data.selectedStat,
        );
        return currentStat?.attributes || [];
    }

    function renderChart() {
        if (!chartElement || !data.periodBreakdown.length) return;

        // Clear previous chart
        d3.select(chartElement).selectAll("*").remove();

        const containerWidth = chartElement.clientWidth;
        const containerHeight = chartElement.clientHeight;
        const margin = { top: 20, right: 30, bottom: 40, left: 80 };
        const width = Math.max(
            300,
            containerWidth - margin.left - margin.right,
        );
        const height = containerHeight - margin.top - margin.bottom;

        const svg = d3
            .select(chartElement)
            .append("svg")
            .attr("width", "100%")
            .attr("height", height + margin.top + margin.bottom)
            .attr(
                "viewBox",
                `0 0 ${width + margin.left + margin.right} ${height + margin.top + margin.bottom}`,
            )
            .attr("preserveAspectRatio", "xMidYMid meet");

        const g = svg
            .append("g")
            .attr("transform", `translate(${margin.left},${margin.top})`);

        // Scales
        const xScale = d3
            .scaleBand()
            .domain(data.periodBreakdown.map((d) => d.time_bin_desc || ""))
            .range([0, width])
            .padding(0.1);

        const yScale = d3
            .scaleLinear()
            .domain([0, d3.max(data.periodBreakdown, (d) => d.stat) || 0])
            .nice()
            .range([height, 0]);

        // Bars
        g.selectAll(".bar")
            .data(data.periodBreakdown)
            .enter()
            .append("rect")
            .attr("class", "bar")
            .attr("x", (d) => xScale(d.time_bin_desc || "") || 0)
            .attr("width", xScale.bandwidth())
            .attr("y", (d) => yScale(d.stat))
            .attr("height", (d) => height - yScale(d.stat))
            .attr("fill", "#0d6efd")
            .attr("rx", 4)
            .attr("ry", 4);

        // Value labels on bars
        g.selectAll(".bar-label")
            .data(data.periodBreakdown)
            .enter()
            .append("text")
            .attr("class", "bar-label")
            .attr(
                "x",
                (d) =>
                    (xScale(d.time_bin_desc || "") || 0) +
                    xScale.bandwidth() / 2,
            )
            .attr("y", (d) => yScale(d.stat) - 5)
            .attr("text-anchor", "middle")
            .style("font-size", "12px")
            .style("font-weight", "500")
            .style("fill", "#495057")
            .text((d) => formatStat(d.stat, getCurrentStatAttributes()));

        // X axis
        g.append("g")
            .attr("transform", `translate(0,${height})`)
            .call(d3.axisBottom(xScale))
            .selectAll("text")
            .style("font-size", "12px");

        // Y axis with better tick values for time stats
        const currentAttributes = getCurrentStatAttributes();
        const isTimeAttribute = currentAttributes.includes("time");

        let yAxis = d3.axisLeft(yScale);
        if (isTimeAttribute) {
            // For time stats, use fewer ticks and ensure they're at reasonable intervals
            const maxValue = d3.max(data.periodBreakdown, (d) => d.stat) || 0;
            let tickCount = 5;
            if (maxValue < 300)
                tickCount = 3; // Less than 10 seconds
            else if (maxValue < 1800) tickCount = 4; // Less than 1 minute

            yAxis = yAxis.ticks(tickCount);
        }

        g.append("g")
            .call(yAxis.tickFormat((d) => formatStat(d, currentAttributes)))
            .selectAll("text")
            .style("font-size", "12px");
    }

    onMount(() => {
        renderChart();

        const resizeObserver = new ResizeObserver(() => {
            renderChart();
        });

        if (chartElement) {
            resizeObserver.observe(chartElement);
        }

        return () => {
            if (chartElement) {
                resizeObserver.unobserve(chartElement);
            }
        };
    });

    $: if (data.periodBreakdown && chartElement) {
        renderChart();
    }

    // Calculate total for current stat
    $: currentTotal = data.periodBreakdown.reduce(
        (sum, row) => sum + row.stat,
        0,
    );
</script>

<SiteHeader navPage="history" />

<section class="narrow">
    <StatLinks items={statItems} />
</section>

<section class="narrow no-bg">
    <div
        class="w-100 bg-white rounded border p-2"
        style="height: 300px;"
        bind:this={chartElement}
    ></div>
</section>

<style>
    @media (max-width: 768px) {
        :global(div[style*="height: 300px"]) {
            height: 250px !important;
        }
    }
</style>

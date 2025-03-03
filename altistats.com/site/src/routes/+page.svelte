<script lang="ts">
    import SiteHeader from "$lib/SiteHeader.svelte";
    import { formatDuration } from "$lib";
    import * as d3 from "d3";
    import { onMount } from "svelte";
    import { invalidateAll } from "$app/navigation";

    // @type {import('./$types').PageData}
    export let data;
    let secondsAgo = 0;
    let chartElement: HTMLElement;
    let refreshInterval: number;

    function updateTimer() {
        if (data.lastUpdate) {
            const lastUpdate = new Date(data.lastUpdate);
            secondsAgo = Math.floor((new Date() - lastUpdate) / 1000);

            // Auto-refresh data when it's been over 60 seconds
            if (secondsAgo > 60) {
                invalidateAll();
            }
        }
    }

    // Update timer every second
    onMount(() => {
        refreshInterval = setInterval(updateTimer, 1000) as unknown as number;
        updateTimer();

        return () => {
            clearInterval(refreshInterval);
        };
    });

    // Function to render the chart
    function renderChart() {
        if (
            !chartElement ||
            !data.listingsSeries ||
            data.listingsSeries.length === 0
        )
            return;

        // Parse the data
        const chartData = data.listingsSeries
            .map((d) => ({
                date: new Date(d.bin),
                players: +d.players,
            }))
            .sort((a, b) => a.date.getTime() - b.date.getTime());

        // Set dimensions and margins with more top margin for the title
        const containerWidth = chartElement.clientWidth;
        const containerHeight = chartElement.clientHeight;
        const isMobile = containerWidth < 500;
        const margin = {
            top: 5,
            right: 10,
            bottom: 20,
            left: 40,
        };
        const width = Math.max(
            300,
            containerWidth - margin.left - margin.right,
        );
        const height = containerHeight - margin.top - margin.bottom;

        // Clear any existing SVG
        d3.select(chartElement).selectAll("*").remove();

        // Create SVG with responsive attributes
        const svg = d3
            .select(chartElement)
            .append("svg")
            .attr("width", "100%")
            .attr("height", height + margin.top + margin.bottom)
            .attr(
                "viewBox",
                `0 0 ${width + margin.left + margin.right} ${height + margin.top + margin.bottom}`,
            )
            .attr("preserveAspectRatio", "xMidYMid meet")
            .append("g")
            .attr("transform", `translate(${margin.left},${margin.top})`);

        // X scale
        const x = d3
            .scaleTime()
            .domain(d3.extent(chartData, (d) => d.date) as [Date, Date])
            .range([0, width]);

        // Y scale with padding at the top
        const maxPlayers = d3.max(chartData, (d) => d.players) || 10;
        const yMax = Math.ceil(maxPlayers / 5) * 5; // Round up to nearest 5

        const y = d3.scaleLinear().domain([0, yMax]).range([height, 0]);

        // Add X axis with time increments based on screen size
        svg.append("g")
            .attr("transform", `translate(0,${height})`)
            .call(
                d3
                    .axisBottom(x)
                    .ticks(d3.timeHour.every(isMobile ? 12 : 6))
                    .tickFormat((d) => d3.timeFormat("%Hh")(d) as string),
            );

        // Add Y axis with ticks adjusted for screen size
        var ruleStep = isMobile ? 10 : 5;
        svg.append("g").call(
            d3.axisLeft(y).tickValues(d3.range(ruleStep, yMax + 5, ruleStep)),
        );

        // Add Y axis label
        svg.append("text")
            .attr("transform", "rotate(-90)")
            .attr("y", 0 - margin.left)
            .attr("x", 0 - height / 2)
            .attr("dy", "1em")
            .style("text-anchor", "middle")
            .style("font-size", "12px")
            .text("Players");

        // Add horizontal grid lines with spacing based on screen size
        svg.append("g")
            .attr("class", "grid-lines")
            .selectAll("line")
            .data(d3.range(ruleStep, yMax + 5, ruleStep))
            .enter()
            .append("line")
            .attr("x1", 0)
            .attr("x2", width)
            .attr("y1", (d) => y(d))
            .attr("y2", (d) => y(d))
            .attr("stroke", "#e0e0e0")
            .attr("stroke-width", 1)
            .attr("stroke-dasharray", "3,3");

        // Add vertical day separator lines
        const days = d3.timeDay.range(
            d3.timeDay.floor(chartData[0].date),
            d3.timeDay.offset(
                d3.timeDay.ceil(chartData[chartData.length - 1].date),
                1,
            ),
        );

        // Add vertical lines for day boundaries
        svg.append("g")
            .attr("class", "day-separators")
            .selectAll("line")
            .data(days)
            .enter()
            .append("line")
            .attr("x1", (d) => x(d))
            .attr("x2", (d) => x(d))
            .attr("y1", 0)
            .attr("y2", height)
            .attr("stroke", "#e0e0e0")
            .attr("stroke-width", 1)
            .attr("stroke-dasharray", "3,3");

        // Add day of week labels at the top
        svg.append("g")
            .attr("class", "day-labels")
            .selectAll("text")
            .data(days)
            .enter()
            .append("text")
            .attr("x", (d) => x(d) + 5)
            .attr("y", 0)
            .attr("dy", "1em")
            .style("font-size", isMobile ? "8px" : "10px")
            .style("fill", "#666")
            .text((d) => d3.timeFormat("%a")(d));

        // Add a smooth line
        svg.append("path")
            .datum(chartData)
            .attr("fill", "none")
            .attr("stroke", "steelblue")
            .attr("stroke-width", 2)
            .attr(
                "d",
                d3
                    .line<{ date: Date; players: number }>()
                    .x((d) => x(d.date))
                    .y((d) => y(d.players))
                    .curve(d3.curveCatmullRom.alpha(0.5)),
            );

        // Add small points at each data point
        svg.selectAll("circle")
            .data(chartData)
            .enter()
            .append("circle")
            .attr("cx", (d) => x(d.date))
            .attr("cy", (d) => y(d.players))
            .attr("r", 2)
            .attr("fill", "steelblue");
    }

    // Set up resize observer to handle window resizing
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

    $: stats = [
        {
            value: data.totals.n_vapors,
            label: "players",
        },
        {
            value: data.totals.hours,
            label: "hours",
        },
        {
            value: data.totals.n_replays,
            label: "replays",
        },
    ];
</script>

<SiteHeader navPage="home" />

<section>
    <h2>Active servers</h2>
    <div class="d-flex flex-wrap gap-2">
        {#each data.listings as listing}
            <div class="card">
                <div class="card-body py-2 px-3 d-flex align-items-center">
                    <div class="me-2 server-info">
                        <span class="fw-medium server-name">{listing.name}</span
                        >
                        <small class="text-muted ms-2 map-name"
                            >{listing.map}</small
                        >
                    </div>
                    <span class="badge bg-primary rounded-pill ms-1"
                        >{listing.players}</span
                    >
                </div>
            </div>
        {/each}
    </div>
    <p class="text-muted small text-end mt-2 mb-0">
        (Update from {secondsAgo} seconds ago)
    </p>
</section>

<section>
    <h2>Past activity (3 days)</h2>
    <div class="chart-container" bind:this={chartElement}></div>
</section>

<section>
    <h2>Recording database</h2>

    <div class="row cols-2 g-2">
        {#each stats as stat}
            <div class="col">
                <div class="card stats-card">
                    <div class="card-body text-center">
                        <p class="h4 mb-0">{stat.value}</p>
                        <p class="mb-0 small">{stat.label}</p>
                    </div>
                </div>
            </div>
        {/each}
    </div>
</section>

<style>
    .chart-container {
        width: 100%;
        height: 200px;
        margin: 20px 0;
        box-sizing: border-box;
    }

    @media (max-width: 576px) {
        .chart-container {
            height: 150px;
        }
    }
</style>

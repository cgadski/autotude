import * as d3 from "d3";
import { formatStat, renderStat } from "$lib";

// Configuration for stat-specific visualization parameters
const STAT_CONFIG: Record<
  string,
  { min?: number; max?: number; bandwidth?: number }
> = {
  // Example configurations - adjust based on your actual stats
  p_kd: { min: 0.2, max: 2, bandwidth: 0.2 },
  deaths: { min: 0, max: 30, bandwidth: 1.5 },
  score: { min: 0, max: 10000, bandwidth: 500 },
  playtime: { min: 0, max: 7200, bandwidth: 300 }, // assuming playtime in seconds
  winrate: { min: 0, max: 1, bandwidth: 0.05 }, // assuming winrate as decimal 0-1
  // Add more stats as needed
};

// Simple kernel density estimation
function kernelDensityEstimator(kernel: (x: number) => number, X: number[]) {
  return function (V: number[]) {
    return X.map(function (x) {
      return [
        x,
        d3.mean(V, function (v) {
          return kernel(x - v);
        }) || 0,
      ];
    });
  };
}

function kernelEpanechnikov(k: number) {
  return function (v: number) {
    return Math.abs((v /= k)) <= 1 ? (0.75 * (1 - v * v)) / k : 0;
  };
}

// Calculate optimal bandwidth using Silverman's rule of thumb
function calculateBandwidth(data: number[]): number {
  const n = data.length;
  const stdDev = d3.deviation(data) || 1;
  // Silverman's rule: 1.06 * std * n^(-1/5)
  return 1.06 * stdDev * Math.pow(n, -1 / 5);
}

export function renderHistogram(element: HTMLElement, data: any): void {
  console.log("renderHistogram called", { element, data });

  if (!element || !data?.playerStats?.length) {
    console.log("Missing element or data, returning early");
    return;
  }

  // Clear previous chart
  d3.select(element).selectAll("*").remove();

  // Create tooltip
  const tooltip = d3
    .select("body")
    .append("div")
    .style("position", "absolute")
    .style("background", "rgba(0, 0, 0, 0.8)")
    .style("color", "white")
    .style("padding", "8px 12px")
    .style("border-radius", "4px")
    .style("font-size", "12px")
    .style("pointer-events", "none")
    .style("opacity", 0)
    .style("z-index", "1000");

  // Extract stat values
  const statValues = data.playerStats
    .map((player: any) => player.stat)
    .filter((stat: number) => stat != null && !isNaN(stat));

  if (statValues.length === 0) {
    d3.select(element)
      .append("div")
      .style("padding", "20px")
      .style("text-align", "center")
      .style("color", "#666")
      .text("No numeric data available for dot plot");
    return;
  }

  // Set up dimensions - use full container width
  const containerWidth = element.clientWidth || 800;
  const margin = { top: 10, right: 30, bottom: 30, left: 60 };
  const width = containerWidth - margin.left - margin.right;
  const height = 120; // Compact height for efficient space use

  // Create SVG - responsive and centered
  const svg = d3
    .select(element)
    .append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .style("display", "block")
    .style("margin", "0 auto");

  const g = svg
    .append("g")
    .attr("transform", `translate(${margin.left},${margin.top})`);

  // Get configuration for this stat
  const statConfig = STAT_CONFIG[data.stat?.query_name] || {};

  // Create scales with optional override from config
  const extent = d3.extent(statValues) as [number, number];
  const domain: [number, number] = [
    statConfig.min !== undefined ? statConfig.min : extent[0],
    statConfig.max !== undefined ? statConfig.max : extent[1],
  ];

  const xScale = d3.scaleLinear().domain(domain).range([0, width]);

  // Create kernel density estimation with configurable or calculated bandwidth
  const bandwidth = statConfig.bandwidth || calculateBandwidth(statValues);
  const numTicks = Math.min(100, statValues.length * 2); // More sample points
  const kde = kernelDensityEstimator(
    kernelEpanechnikov(bandwidth),
    xScale.ticks(numTicks),
  );
  let density = kde(statValues);

  // Ensure density curves start and end at zero for proper filling
  const [minX, maxX] = xScale.domain();
  if (density.length > 0) {
    // Add zero points at the beginning and end if they don't exist
    if (density[0][0] > minX) {
      density.unshift([minX, 0]);
    }
    if (density[density.length - 1][0] < maxX) {
      density.push([maxX, 0]);
    }
    // Ensure first and last points have zero density
    density[0][1] = 0;
    density[density.length - 1][1] = 0;
  }

  const maxDensity = d3.max(density, (d) => d[1]) || 0;
  console.log(
    `Using bandwidth: ${bandwidth}, density range: ${d3.extent(density, (d) => d[1])}, max: ${maxDensity}`,
  );

  // If density is too flat, use a simple histogram approach instead
  if (maxDensity < 0.001) {
    console.log("Density too flat, falling back to jittered dots");

    // Just show jittered dots without violin
    g.selectAll(".dot")
      .data(data.playerStats)
      .enter()
      .append("circle")
      .attr("class", "dot")
      .attr("cx", (d) => xScale(d.stat))
      .attr("cy", height * 0.5 + (Math.random() - 0.5) * 15) // Add some jitter
      .attr("r", 3)
      .attr("fill", "#4A90E2")
      .attr("opacity", 0.7)
      .attr("stroke", "#fff")
      .attr("stroke-width", 1)
      .on("mouseover", function (event, d) {
        // Find other players with similar values (within 2% of range)
        const range = xScale.domain()[1] - xScale.domain()[0];
        const tolerance = range * 0.02;
        const nearbyPlayers = data.playerStats.filter(
          (p: any) => Math.abs(p.stat - d.stat) <= tolerance,
        );

        const names = nearbyPlayers.map((p: any) => p.handle).join(", ");

        tooltip
          .style("opacity", 1)
          .html(`${names}`)
          .style("left", event.pageX + 10 + "px")
          .style("top", event.pageY - 10 + "px");
      })
      .on("mouseout", function () {
        tooltip.style("opacity", 0);
      });

    // Add x-axis
    g.append("g")
      .attr("transform", `translate(0,${height})`)
      .call(d3.axisBottom(xScale).tickFormat((d) => renderStat(d)));

    console.log(
      `Jittered dot plot rendered with ${statValues.length} data points`,
    );
    return;
  }

  const yScale = d3
    .scaleLinear()
    .domain([0, maxDensity])
    .range([0, height / 3]); // Use third of height for violin

  const centerY = height * 0.5; // Center the dots vertically

  // Draw violin plot (mirrored density curves)
  const line = d3
    .line()
    .x((d: any) => xScale(d[0]))
    .y((d: any) => centerY - yScale(d[1]))
    .curve(d3.curveBasis);

  // Top half of violin
  g.append("path")
    .datum(density)
    .attr("fill", "#4A90E2")
    .attr("fill-opacity", 0.2)
    .attr("stroke", "#4A90E2")
    .attr("stroke-width", 1)
    .attr("d", line);

  // Bottom half of violin (mirrored)
  const lineBottom = d3
    .line()
    .x((d: any) => xScale(d[0]))
    .y((d: any) => centerY + yScale(d[1]))
    .curve(d3.curveBasis);

  g.append("path")
    .datum(density)
    .attr("fill", "#4A90E2")
    .attr("fill-opacity", 0.2)
    .attr("stroke", "#4A90E2")
    .attr("stroke-width", 1)
    .attr("d", lineBottom);

  // Add dots for each data point with jitter
  g.selectAll(".dot")
    .data(data.playerStats)
    .enter()
    .append("circle")
    .attr("class", "dot")
    .attr("cx", (d) => xScale(d.stat))
    .attr("cy", () => centerY + (Math.random() - 0.5) * 12) // Add vertical jitter
    .attr("r", 4)
    .attr("fill", "#4A90E2")
    .attr("opacity", 0.6) // Reduced opacity for better overlapping visibility
    .attr("stroke", "#fff")
    .attr("stroke-width", 1)
    .on("mouseover", function (event, d) {
      // Find other players with similar values (within 2% of range)
      const range = xScale.domain()[1] - xScale.domain()[0];
      const tolerance = range * 0.02;
      const nearbyPlayers = data.playerStats.filter(
        (p: any) => Math.abs(p.stat - d.stat) <= tolerance,
      );

      const names = nearbyPlayers.map((p: any) => p.handle).join(", ");

      tooltip
        .style("opacity", 1)
        .html(`${names}`)
        .style("left", event.pageX + 10 + "px")
        .style("top", event.pageY - 10 + "px");
    })
    .on("mouseout", function () {
      tooltip.style("opacity", 0);
    });

  // Add x-axis
  g.append("g")
    .attr("transform", `translate(0,${height})`)
    .call(d3.axisBottom(xScale).tickFormat((d) => renderStat(d)));

  console.log(`Violin plot rendered with ${statValues.length} data points`);
}

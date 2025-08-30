import * as d3 from "d3";
import { renderStat } from "$lib";

// Configuration for stat-specific visualization parameters
const STAT_CONFIG: Record<
  string,
  { min?: number; max?: number; bandwidth?: number }
> = {
  p_kd: { min: 0.2, max: 2, bandwidth: 0.2 },
  p_win_rate: { min: 0, max: 1, bandwidth: 0.1 },
  p_death_rate: { min: 9, max: 35, bandwidth: 3 },
  p_kill_rate: { min: 9, max: 35, bandwidth: 3 },
  p_goal_rate: { min: 0, max: 6, bandwidth: 0.5 },
  p_possession: { min: 0, max: 0.4, bandwidth: 0.05 },
  p_possession_goal_rate: { min: 0, max: 35, bandwidth: 3 },
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

// Simple seeded random number generator
function seededRandom(seed: number): () => number {
  let x = Math.sin(seed++) * 10000;
  return function () {
    x = Math.sin(x) * 10000;
    return x - Math.floor(x);
  };
}

// Generate consistent y-jitter positions for data points
function generateConsistentJitter(
  playerStats: any[],
  centerY: number,
  jitterRange: number,
): Map<number, number> {
  // Sort by stat value to assign consistent positions left to right
  const sortedStats = [...playerStats].map((p) => p.stat).sort((a, b) => a - b);

  const jitterMap = new Map<number, number>();
  const rng = seededRandom(12345); // Fixed seed for consistency

  sortedStats.forEach((stat) => {
    if (!jitterMap.has(stat)) {
      jitterMap.set(stat, centerY + (rng() - 0.5) * jitterRange);
    }
  });

  return jitterMap;
}

// Use D3 force simulation to position labels without overlap
function positionLabelsWithForces(
  g: d3.Selection<SVGGElement, unknown, null, undefined>,
  selectedPlayers: any[],
  xScale: d3.ScaleLinear<number, number>,
  targetY: number,
  width: number,
  jitterMap: Map<number, number>,
): void {
  if (selectedPlayers.length === 0) return;

  // Create nodes for force simulation
  const nodes = selectedPlayers.map((d) => ({
    ...d,
    x: xScale(d.stat), // Start at actual data position
    y: targetY,
    fx: null, // Allow x to move
    fy: targetY, // Keep y fixed at target position
  }));

  // Custom boundary force to keep labels within plot area
  const boundaryForce = () => {
    nodes.forEach((node: any) => {
      const padding = 25; // Padding from edges to account for text width
      if (node.x < padding) {
        node.vx += (padding - node.x) * 1;
      }
      if (node.x > width - padding) {
        node.vx += (width - padding - node.x) * 1;
      }
    });
  };

  // Create force simulation
  const simulation = d3
    .forceSimulation(nodes)
    .force("collision", d3.forceCollide().radius(40)) // Prevent overlap, radius accounts for text width
    .force("x", d3.forceX((d: any) => xScale(d.stat)).strength(0.5)) // Pull toward actual data position
    .force("y", d3.forceY(targetY).strength(1)) // Keep at target y position
    .force("boundary", boundaryForce) // Keep labels within plot bounds
    .stop();

  // Run simulation to completion
  for (let i = 0; i < 300; ++i) simulation.tick();

  // Remove existing labels and leader lines
  g.selectAll(".player-label").remove();
  g.selectAll(".leader-line").remove();

  // Add leader lines first (so they appear behind labels)
  g.selectAll(".leader-line")
    .data(nodes)
    .enter()
    .append("line")
    .attr("class", "leader-line")
    .attr("x1", (d: any) => xScale(d.stat)) // From actual data position
    .attr("y1", (d: any) => jitterMap.get(d.stat) || targetY) // From actual circle position
    .attr("x2", (d: any) => d.x) // To final label position
    .attr("y2", (d: any) => d.y + 5)
    .attr("stroke", "#FF6B6B")
    .attr("stroke-width", 1)
    .attr("stroke-opacity", 0.7)
    .attr("stroke-dasharray", "2,2");

  // Add positioned labels
  g.selectAll(".player-label")
    .data(nodes)
    .enter()
    .append("text")
    .attr("class", "player-label")
    .attr("x", (d: any) => d.x)
    .attr("y", (d: any) => d.y)
    .attr("text-anchor", "middle")
    .attr("font-family", "system-ui, -apple-system, sans-serif")
    .attr("font-size", "12px")
    .attr("font-weight", "600")
    .attr("fill", "#FF6B6B")
    .attr("stroke", "white")
    .attr("stroke-width", "2")
    .attr("paint-order", "stroke fill")
    .text((d: any) => d.handle);
}

let resizeTimeout: number;
let currentResizeHandler: (() => void) | null = null;

export function renderHistogram(
  element: HTMLElement,
  data: any,
  selectedHandles: string[] = [],
): void {
  console.log("renderHistogram called", { element, data });

  if (!element || !data?.playerStats?.length) {
    console.log("Missing element or data, returning early");
    return;
  }

  // Clear previous chart
  d3.select(element).selectAll("*").remove();

  // Remove any existing tooltips to prevent accumulation
  d3.selectAll(".histogram-tooltip").remove();

  // Create tooltip - ensure it's properly attached to body
  const tooltip = d3
    .select("body")
    .append("div")
    .attr("class", "histogram-tooltip")
    .style("position", "absolute")
    .style("background", "rgba(0, 0, 0, 0.8)")
    .style("color", "white")
    .style("padding", "8px 12px")
    .style("border-radius", "4px")
    .style("font-size", "12px")
    .style("pointer-events", "none")
    .style("opacity", 0)
    .style("z-index", "1000");

  console.log("Tooltip created:", tooltip.node());

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
  const margin = { top: 10, right: 15, bottom: 30, left: 15 };
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

    // Generate consistent jitter positions
    const jitterMap = generateConsistentJitter(
      data.playerStats,
      height * 0.5,
      15,
    );

    // Just show jittered dots without violin
    // First render regular (non-selected) dots
    g.selectAll(".dot-regular")
      .data(
        data.playerStats.filter(
          (d: any) => !selectedHandles.includes(d.handle),
        ),
      )
      .enter()
      .append("circle")
      .attr("class", "dot-regular")
      .attr("cx", (d) => xScale(d.stat))
      .attr("cy", (d) => jitterMap.get(d.stat) || height * 0.5) // Use consistent jitter
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

    // Then render selected dots on top
    g.selectAll(".dot-selected")
      .data(
        data.playerStats.filter((d: any) => selectedHandles.includes(d.handle)),
      )
      .enter()
      .append("circle")
      .attr("class", "dot-selected")
      .attr("cx", (d) => xScale(d.stat))
      .attr("cy", (d) => jitterMap.get(d.stat) || height * 0.5) // Use consistent jitter
      .attr("r", 5)
      .attr("fill", "#FF6B6B")
      .attr("opacity", 1)
      .attr("stroke", "#fff")
      .attr("stroke-width", 2)
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

    // Add text labels for selected players using force simulation
    const selectedPlayers = data.playerStats.filter((d: any) =>
      selectedHandles.includes(d.handle),
    );
    positionLabelsWithForces(
      g,
      selectedPlayers,
      xScale,
      height * 0.5 - 20,
      width,
      jitterMap,
    );

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

  // Generate consistent jitter positions
  const jitterMap = generateConsistentJitter(data.playerStats, centerY, 12);

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
  // First render regular (non-selected) dots
  g.selectAll(".dot-regular")
    .data(
      data.playerStats.filter((d: any) => !selectedHandles.includes(d.handle)),
    )
    .enter()
    .append("circle")
    .attr("class", "dot-regular")
    .attr("cx", (d) => xScale(d.stat))
    .attr("cy", (d) => jitterMap.get(d.stat) || centerY) // Use consistent jitter
    .attr("r", 4)
    .attr("fill", "#4A90E2")
    .attr("opacity", 0.6)
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

  // Then render selected dots on top
  g.selectAll(".dot-selected")
    .data(
      data.playerStats.filter((d: any) => selectedHandles.includes(d.handle)),
    )
    .enter()
    .append("circle")
    .attr("class", "dot-selected")
    .attr("cx", (d) => xScale(d.stat))
    .attr("cy", (d) => jitterMap.get(d.stat) || centerY) // Use consistent jitter
    .attr("r", 6)
    .attr("fill", "#FF6B6B")
    .attr("opacity", 1)
    .attr("stroke", "#fff")
    .attr("stroke-width", 2)
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

  // Add text labels for selected players using force simulation
  const selectedPlayers = data.playerStats.filter((d: any) =>
    selectedHandles.includes(d.handle),
  );
  positionLabelsWithForces(
    g,
    selectedPlayers,
    xScale,
    centerY - height / 3 - 10,
    width,
    jitterMap,
  );

  // Add x-axis
  g.append("g")
    .attr("transform", `translate(0,${height})`)
    .call(d3.axisBottom(xScale).tickFormat((d) => renderStat(d)));

  console.log(`Violin plot rendered with ${statValues.length} data points`);

  // Clean up previous resize handler
  if (currentResizeHandler) {
    window.removeEventListener("resize", currentResizeHandler);
  }

  // Add resize handling with debouncing
  currentResizeHandler = () => {
    clearTimeout(resizeTimeout);
    resizeTimeout = window.setTimeout(() => {
      renderHistogram(element, data, selectedHandles);
    }, 150);
  };

  // Add new listener
  window.addEventListener("resize", currentResizeHandler);
}

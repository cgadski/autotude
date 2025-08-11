import * as d3 from "d3";
import { formatStat } from "$lib";

export function renderHistogram(element: HTMLElement, data: any): void {
  console.log("renderHistogram called", { element, data });

  if (!element || !data?.players?.length) {
    console.log("Missing element or data, returning early");
    return;
  }

  // Clear previous chart
  d3.select(element).selectAll("*").remove();

  // Simple test - just add text to confirm function is working
  d3.select(element)
    .append("div")
    .style("padding", "20px")
    .style("background", "#f0f0f0")
    .style("border-radius", "4px")
    .text(`Histogram loaded with ${data.players.length} players`);

  console.log("Test element added to DOM");
}

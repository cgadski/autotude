import * as d3 from "d3";

interface GameTimestampData {
  started_at: number;
}

export function renderGameScatterChart(
  data: { gameTimestamps: GameTimestampData[] },
  element: HTMLElement,
  daysToShow: number = 30,
) {
  // Clear previous chart
  d3.select(element).selectAll("*").remove();

  const gameTimestamps = data.gameTimestamps;
  if (!gameTimestamps || gameTimestamps.length === 0) return;

  // Set up dimensions
  const margin = { top: 20, right: 20, bottom: 40, left: 50 };
  const width = element.clientWidth - margin.left - margin.right;
  const height = element.clientHeight - margin.top - margin.bottom;

  // Create SVG
  const svg = d3
    .select(element)
    .append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .append("g")
    .attr("transform", `translate(${margin.left},${margin.top})`);

  // Process data
  const dates = gameTimestamps.map((d) => {
    const date = new Date(d.started_at * 1000);
    // Get hours as decimal (0-24) in UTC time
    const hour = date.getUTCHours() + date.getUTCMinutes() / 60;

    // For the day, shift by 12 hours so midnight is in the middle
    // If hour < 12, use the current day, otherwise use previous day
    const dayOffset = hour >= 12 ? 0 : -1;
    const dayDate = new Date(
      Date.UTC(
        date.getUTCFullYear(),
        date.getUTCMonth(),
        date.getUTCDate() + dayOffset,
      ),
    );

    // Calculate the centered hour
    const centeredHour = (hour + 12) % 24;

    return {
      day: dayDate,
      hour: centeredHour,
      rawDate: date, // Store the original date for potential use
    };
  });

  // Get current date at UTC midnight for the end of the x-axis
  const now = new Date();
  const currentUtcDay = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
  );

  // Get tomorrow's date at UTC midnight for the complete day display
  const tomorrowUtcDay = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1),
  );

  // Get current time with midnight centered (for current time indicator)
  const currentHour = now.getUTCHours() + now.getUTCMinutes() / 60;
  const currentCenteredHour = (currentHour + 12) % 24;

  // Set up scales
  // Calculate the start date based on the daysToShow parameter
  const minDate = d3.min(dates, (d) => d.day);
  const dateLimit = new Date(
    Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth(),
      now.getUTCDate() - daysToShow,
    ),
  );

  // Use either the earliest data point or the days limit, whichever is more recent
  let startDate = minDate && minDate > dateLimit ? minDate : dateLimit;

  // Make sure we have at least 7 days of data showing
  const minimumDays = 7;
  const minimumDaysAgo = new Date(tomorrowUtcDay);
  minimumDaysAgo.setDate(minimumDaysAgo.getDate() - minimumDays);
  if (startDate > minimumDaysAgo) {
    startDate = minimumDaysAgo;
  }

  const xScale = d3
    .scaleTime()
    .domain([startDate, tomorrowUtcDay])
    .range([0, width]);

  // Scale from 0-24 where 12 is midnight, 0 is noon previous day, 24 is noon next day
  const yScale = d3.scaleLinear().domain([0, 24]).range([height, 0]);

  // Only show hours that are multiples of 3
  const displayHours = [0, 3, 6, 9, 12, 15, 18, 21, 24];

  // Add axes
  const xAxis = d3
    .axisBottom(xScale)
    .ticks(d3.timeDay.every(1))
    .tickFormat(d3.timeFormat("%d"));

  svg
    .append("g")
    .attr("class", "x-axis")
    .attr("transform", `translate(0, ${height})`)
    .call(xAxis);

  // Add month labels
  const monthScale = d3
    .scaleTime()
    .domain([startDate, tomorrowUtcDay])
    .range([0, width]);

  const monthAxis = d3
    .axisBottom(monthScale)
    .ticks(d3.timeMonth.every(1))
    .tickFormat(d3.timeFormat("%b"));

  svg
    .append("g")
    .attr("class", "month-axis")
    .attr("transform", `translate(0, ${height + 20})`)
    .call(monthAxis);

  const yAxis = d3
    .axisLeft(yScale)
    .tickValues(displayHours)
    .tickFormat((d) => {
      // Convert back to actual UTC hour
      const utcHour = Math.floor((d + 12) % 24);
      return `${utcHour}h`;
    });

  // Create y-axis
  svg.append("g").attr("class", "y-axis").call(yAxis);

  // Add grid lines for hours at 3-hour intervals
  const hourGridLines = displayHours;

  svg
    .selectAll(".hour-grid-line")
    .data(hourGridLines)
    .enter()
    .append("line")
    .attr("class", "hour-grid-line")
    .attr("x1", 0)
    .attr("x2", width)
    .attr("y1", (d) => yScale(d))
    .attr("y2", (d) => yScale(d))
    .style("stroke", "#e0e0e0")
    .style("stroke-dasharray", "3,3")
    .style("stroke-width", 1);

  // Add vertical grid lines for days
  const days = d3.timeDay.range(
    startDate,
    d3.timeDay.offset(tomorrowUtcDay, 1),
  );

  svg
    .selectAll(".day-grid-line")
    .data(days)
    .enter()
    .append("line")
    .attr("class", "day-grid-line")
    .attr("x1", (d) => xScale(d))
    .attr("x2", (d) => xScale(d))
    .attr("y1", 0)
    .attr("y2", height)
    .style("stroke", "#e0e0e0")
    .style("stroke-dasharray", "3,3")
    .style("stroke-width", 1);

  // // Add current date vertical line
  // svg
  //   .append("line")
  // .attr("x1", xScale(currentUtcDay))
  // .attr("x2", xScale(currentUtcDay))
  //   .attr("y1", 0)
  //   .attr("y2", height)
  //   .style("stroke", "#ff3e41")
  //   .style("stroke-width", 2)
  //   .style("stroke-dasharray", "5,3");

  // // Add current time horizontal line
  // svg
  //   .append("line")
  //   .attr("x1", 0)
  //   .attr("x2", width)
  //   .attr("y1", yScale(currentCenteredHour))
  //   .attr("y2", yScale(currentCenteredHour))
  //   .style("stroke", "#ff3e41")
  //   .style("stroke-width", 2)
  //   .style("stroke-dasharray", "5,3");

  // Filter data to only include points within the chart range
  const visibleDates = dates.filter((d) => {
    const x = xScale(d.day);
    const y = yScale(d.hour);
    return (
      !isNaN(x) && !isNaN(y) && x >= 0 && x <= width && y >= 0 && y <= height
    );
  });

  // Add scatter plot points
  svg
    .selectAll("circle")
    .data(visibleDates)
    .enter()
    .append("circle")
    .attr("cx", (d) => xScale(d.day))
    .attr("cy", (d) => yScale(d.hour))
    .attr("r", 4)
    .style("fill", "#3a86ff")
    .style("opacity", 0.7)
    .style("stroke", "#1e429f")
    .style("stroke-width", 1);
}

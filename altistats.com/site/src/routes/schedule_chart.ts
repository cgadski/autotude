import * as d3 from "d3";

interface GameMeta {
  started_at: number; // unix epoch
  duration: number; // 30ths of second
  day_bin: string; // ISO date string YYYY-MM-DD
}

interface GameRun {
  day_bin: string;
  start_time: number;
  end_time: number;
  game_count: number;
}

function initRun(game: GameMeta): GameRun {
  return {
    day_bin: game.day_bin,
    start_time: game.started_at,
    end_time: game.started_at + Math.ceil(game.duration / 30),
    game_count: 1,
  };
}

export function getGameRuns(games: GameMeta[]): GameRun[] {
  const runs: GameRun[] = [];
  let currentRun: GameRun | null = null;
  const MAX_GAP_SECONDS = 10 * 60;

  games.forEach((game) => {
    const newRun = initRun(game);

    if (!currentRun) {
      currentRun = newRun;
      return;
    }

    let breakRuns = false;
    if (game.started_at - currentRun.end_time > MAX_GAP_SECONDS) {
      breakRuns = true;
    }
    if (game.day_bin != currentRun.day_bin) {
      breakRuns = true;
    }

    if (breakRuns) {
      runs.push(currentRun);
      currentRun = newRun;
    } else {
      currentRun.end_time = newRun.end_time;
      currentRun.game_count++;
    }
  });

  if (currentRun) {
    runs.push(currentRun);
  }

  return runs;
}

export function renderScheduleChart(
  data: { gameTimestamps: GameMeta[] },
  element: HTMLElement,
) {
  d3.select(element).selectAll("*").remove();

  const runs = getGameRuns(data.gameTimestamps);
  if (runs.length === 0) return;

  const margin = { top: 20, right: 30, bottom: 40, left: 50 };
  const width =
    element.clientWidth - margin.left - margin.right ||
    960 - margin.left - margin.right;
  const height = 400 - margin.top - margin.bottom;

  const runsByDay = d3.group(runs, (d) => d.day_bin);

  // Get the date range
  const allDates = runs.map((r) => r.day_bin);
  let minDate = new Date(
    Math.min(...allDates.map((d) => new Date(d).getTime())),
  );
  let maxDate = new Date(
    Math.max(...allDates.map((d) => new Date(d).getTime())),
  );

  // Generate all days in the range
  const days: string[] = [];
  const currentDate = new Date(maxDate);
  while (currentDate >= minDate) {
    const dateString = currentDate.toISOString().split("T")[0];
    days.push(dateString);
    currentDate.setDate(currentDate.getDate() - 1);
  }

  const svg = d3
    .select(element)
    .append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .append("g")
    .attr("transform", `translate(${margin.left},${margin.top})`);

  const timezoneOffsetHours = new Date().getTimezoneOffset() / -60;

  const xScale = d3.scaleLinear().domain([-6, 9]).range([0, width]);

  // Group days by month for labeling
  const daysByMonth = d3.group(days, (day) => day.substring(0, 7));
  const months = Array.from(daysByMonth.keys()).sort(d3.descending);

  const yScale = d3.scaleBand().domain(days).range([0, height]).padding(0);

  const formatHour = (hours: number) => {
    const localHour = (hours + timezoneOffsetHours + 24) % 24;
    return `${Math.floor(localHour)}:00`;
  };

  // Determine number of ticks based on screen width
  const isMobile = width < 600;
  const tickCount = isMobile ? 5 : 14; // Every 3rd hour on mobile (15 hours / 3 = 5 ticks)
  const gridTicks = isMobile ? xScale.ticks(5) : xScale.ticks(14);

  // Create bottom x-axis
  const xAxisBottom = d3
    .axisBottom(xScale)
    .ticks(tickCount)
    .tickFormat(formatHour);
  svg.append("g").attr("transform", `translate(0,${height})`).call(xAxisBottom);

  // Create top x-axis
  const xAxisTop = d3.axisTop(xScale).ticks(tickCount).tickFormat(formatHour);
  svg.append("g").call(xAxisTop);

  // Add vertical grid lines for hours
  svg
    .append("g")
    .attr("class", "grid-hours")
    .selectAll("line")
    .data(gridTicks)
    .enter()
    .append("line")
    .attr("x1", (d) => xScale(d))
    .attr("x2", (d) => xScale(d))
    .attr("y1", 0)
    .attr("y2", height)
    .attr("stroke", "#ddd")
    .attr("stroke-width", 1)
    .attr("opacity", 0.5);

  // Create a y-axis with dates but avoid showing too many ticks
  // Calculate appropriate tick intervals based on the number of days
  const totalDays = days.length;
  const tickInterval = Math.max(Math.ceil(totalDays / 10), 1); // Show approximately 10 ticks, adjust as needed

  // Format date labels
  const formatDate = (day: string) => {
    const date = new Date(day);
    return d3.timeFormat("%b %d")(date);
  };

  // Create the y-axis with filtered ticks
  const yAxis = d3
    .axisLeft(yScale)
    .tickValues(days.filter((_, i) => i % tickInterval === 0))
    .tickFormat(formatDate);

  svg.append("g").call(yAxis);

  const now = new Date();
  const currentTime = now.getUTCHours() + now.getUTCMinutes() / 60;
  const normalizedCurrentTime = ((currentTime + 12) % 24) - 12;

  // Add current time indicator line (on top of grid lines)
  svg
    .append("line")
    .attr("x1", xScale(normalizedCurrentTime))
    .attr("x2", xScale(normalizedCurrentTime))
    .attr("y1", 0)
    .attr("y2", height)
    .attr("stroke", "#f00")
    .attr("stroke-dasharray", "2,2")
    .attr("opacity", 0.9);

  days.forEach((day) => {
    const dayRuns = runsByDay.get(day) || [];

    svg
      .selectAll(`.run-${day.replace(/-/g, "")}`)
      .data(dayRuns)
      .enter()
      .append("rect")
      .attr("class", `run-${day.replace(/-/g, "")}`)
      .attr("x", (d) => {
        const dayStart = new Date(d.day_bin + "T00:00:00Z").getTime() / 1000;
        const hoursOffset = (d.start_time - dayStart) / 3600;
        const normalizedHours = ((hoursOffset + 12) % 24) - 12;
        return xScale(normalizedHours);
      })
      .attr("y", (d) => yScale(d.day_bin) || 0)
      .attr("width", (d) => {
        const dayStart = new Date(d.day_bin + "T00:00:00Z").getTime() / 1000;
        const startHoursOffset = (d.start_time - dayStart) / 3600;
        const endHoursOffset = (d.end_time - dayStart) / 3600;

        const normalizedStartHours = ((startHoursOffset + 12) % 24) - 12;
        const normalizedEndHours = ((endHoursOffset + 12) % 24) - 12;

        let width = xScale(normalizedEndHours) - xScale(normalizedStartHours);

        if (normalizedEndHours < normalizedStartHours) {
          width =
            xScale(8) -
            xScale(normalizedStartHours) +
            xScale(normalizedEndHours) -
            xScale(-6);
        }

        return Math.max(width, 2);
      })
      .attr("height", yScale.bandwidth())
      .attr("fill", "#e35d6a")
      .append("title");
  });
}

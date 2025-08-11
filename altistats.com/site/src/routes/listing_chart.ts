function renderChart(data: any, chartElement: any) {
  if (!chartElement || !data.listingsSeries || data.listingsSeries.length === 0)
    return;

  const chartData = data.listingsSeries
    .map((d) => ({
      date: new Date(d.bin),
      players: +d.players,
    }))
    .sort((a, b) => a.date.getTime() - b.date.getTime());

  const containerWidth = chartElement.clientWidth;
  const containerHeight = chartElement.clientHeight;
  const isMobile = containerWidth < 500;
  const margin = {
    top: 5,
    right: 10,
    bottom: 20,
    left: 40,
  };
  const width = Math.max(300, containerWidth - margin.left - margin.right);
  const height = containerHeight - margin.top - margin.bottom;

  d3.select(chartElement).selectAll("*").remove();

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

  const x = d3
    .scaleTime()
    .domain(d3.extent(chartData, (d) => d.date) as [Date, Date])
    .range([0, width]);

  const maxPlayers = d3.max(chartData, (d) => d.players) || 10;
  const yMax = Math.ceil(maxPlayers / 5) * 5;

  const y = d3.scaleLinear().domain([0, yMax]).range([height, 0]);

  svg
    .append("g")
    .attr("transform", `translate(0,${height})`)
    .call(
      d3
        .axisBottom(x)
        .ticks(d3.timeHour.every(isMobile ? 12 : 6))
        .tickFormat((d) => d3.timeFormat("%Hh")(d) as string),
    );

  var ruleStep = isMobile ? 10 : 5;
  svg
    .append("g")
    .call(d3.axisLeft(y).tickValues(d3.range(ruleStep, yMax + 5, ruleStep)));

  svg
    .append("text")
    .attr("transform", "rotate(-90)")
    .attr("y", 0 - margin.left)
    .attr("x", 0 - height / 2)
    .attr("dy", "1em")
    .style("text-anchor", "middle")
    .style("font-size", "12px")
    .text("Players");

  svg
    .append("g")
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

  const days = d3.timeDay.range(
    d3.timeDay.floor(chartData[0].date),
    d3.timeDay.offset(d3.timeDay.ceil(chartData[chartData.length - 1].date), 1),
  );

  svg
    .append("g")
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

  svg
    .append("g")
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

  svg
    .append("path")
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

  svg
    .selectAll("circle")
    .data(chartData)
    .enter()
    .append("circle")
    .attr("cx", (d) => x(d.date))
    .attr("cy", (d) => y(d.players))
    .attr("r", 2)
    .attr("fill", "steelblue");
}

export type Stat = {
  query_name: string;
  description: string;
  stat: number;
  attributes: string[];
};

export function formatStat(stat: Stat): string {
  if (stat.attributes.includes("duration")) {
    const totalMinutes = stat.stat / (30 * 60);
    const hours = Math.floor(totalMinutes / 60);
    const minutes = Math.floor(totalMinutes % 60);
    const seconds = Math.floor((totalMinutes % 1) * 60);

    const parts = [];
    if (hours > 0) parts.push(`${hours}h`);
    if (minutes > 0) parts.push(`${minutes}m`);
    if (hours == 0) parts.push(`${seconds}s`);

    return parts.join(" ") || "0s";
  }

  return Math.round(stat.stat).toLocaleString();
}

export type NavPage = "home" | "player" | "date" | "map" | null;

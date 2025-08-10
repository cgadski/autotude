export type StatMeta = {
  query_name: string;
  description: string;
  attributes: string[];
};

export type Stat = StatMeta & {
  stat: number;
};

export type Game = {
  started_at: number;
  map: string;
  stem: string;
  duration: number;
  winner: number;
  teams: {
    [key: string]: Array<{
      nick: string;
      vapor: string;
    }>;
  };
};

export function formatStat(stat: number, attributes: string[]): string {
  if (attributes.includes("percentage")) {
    return `${(stat * 100).toFixed(1)}%`;
  }

  if (attributes.includes("duration_fine")) {
    const seconds = stat / 30;
    return `${seconds.toFixed(2)} s`;
  }

  if (attributes.includes("duration")) {
    const totalMinutes = stat / (30 * 60);
    const hours = Math.floor(totalMinutes / 60);
    const minutes = Math.floor(totalMinutes % 60);
    const seconds = Math.floor((totalMinutes % 1) * 60);

    const parts = [];
    if (hours > 0) parts.push(`${hours}h`);
    if (minutes > 0) parts.push(`${minutes}m`);
    if (hours == 0) parts.push(`${seconds}s`);

    return parts.join(" ") || "0s";
  }

  return Math.round(stat).toLocaleString();
}

export function formatFullDate(unixEpoch: number): string {
  const date = new Date(unixEpoch * 1000);
  const month = new Intl.DateTimeFormat("en", { month: "short" }).format(date);
  const day = date.getDate();
  const hours = String(date.getHours()).padStart(2, "0");
  const minutes = String(date.getMinutes()).padStart(2, "0");
  return `${month} ${day} ${hours}h${minutes}`;
}

export type NavPage = "home" | "player" | "date" | "map" | null;

export type StatMeta = {
  query_name: string;
  description: string;
  attributes: string[];
};

export type Stat = StatMeta & {
  stat: number;
};

export type Game = {
  day_bin: string;
  started_at: number;
  map: string;
  stem: string;
  duration: number;
  winner: number;
  teams: {
    [key: string]: Array<string>;
  };
};

export function formatDuration(d: number): string {
  const totalMinutes = d / (30 * 60);
  const hours = Math.floor(totalMinutes / 60);
  const minutes = Math.floor(totalMinutes % 60);
  const seconds = Math.floor((totalMinutes % 1) * 60);

  const parts = [];
  if (hours > 0) parts.push(`${hours}h`);
  parts.push(`${minutes}m`);
  if (hours == 0) parts.push(`${seconds}s`);

  return parts.join(" ") || "0s";
}

export function formatDurationCoarse(d: number): string {
  const totalMinutes = d / (30 * 60);
  const hours = totalMinutes / 60;
  return `${hours.toFixed(1)}h`;
}

export function formatDurationFine(d: number): string {
  const seconds = d / 30;
  return `${seconds.toFixed(1)}s`;
}

export function formatTimestamp(d: number) {
  const totalSeconds = d / 30;
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = Math.floor(totalSeconds % 60);

  return `${minutes}:${seconds.toString().padStart(2, "0")}`;
}

export function formatDatetime(unixEpoch: number): string {
  const date = new Date(unixEpoch * 1000);
  const month = new Intl.DateTimeFormat("en", { month: "short" }).format(date);
  const day = date.getDate();
  const hours = String(date.getHours()).padStart(2, "0");
  const minutes = String(date.getMinutes()).padStart(2, "0");
  return `${month} ${day} ${hours}h${minutes}`;
}

export function formatShortDate(unixEpoch: number) {
  const date = new Date(unixEpoch * 1000);
  return date.toLocaleDateString("en-GB", {
    year: "numeric",
    month: "numeric",
    day: "numeric",
  });
}

export function formatTimeAgo(unixEpoch: number) {
  const now = Date.now();
  const timestamp = unixEpoch * 1000;
  const diffMs = now - timestamp;

  const days = Math.floor(diffMs / (1000 * 60 * 60 * 24));
  const hours = Math.floor((diffMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));

  if (days === 0) {
    return hours === 1 ? "1h ago" : `${hours}h ago`;
  } else {
    return `${days}d ${hours}h ago`;
  }
}

export const formatDate = (unixEpoch: number) => {
  const date = new Date(unixEpoch * 1000);
  return date.toLocaleDateString("en-US", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  });
};

export type NavPage = "home" | "players" | "history" | null;

export const planes = ["Loopy", "Bomber", "Whale", "Biplane", "Miranda"];

const statRules: Array<(word: string) => string | null> = [
  // durations
  (part: string) => {
    const durationMatch = part.match(/^(\d+(?:\.\d+)?)d$/);
    if (!durationMatch) return null;
    return formatDuration(parseFloat(part));
  },
  (part: string) => {
    const durationMatch = part.match(/^(\d+(?:\.\d+)?)df$/);
    if (!durationMatch) return null;
    return formatDurationFine(parseFloat(part));
  },
  (part: string) => {
    const durationMatch = part.match(/^(\d+(?:\.\d+)?)dc$/);
    if (!durationMatch) return null;
    return formatDurationCoarse(parseFloat(part));
  },
];

export function statValue(stat: string | number): number | null {
  if (typeof stat === "number") {
    return stat;
  }
  const firstWord = stat.split(/\s+/)[0];
  for (let rule of statRules) {
    let val = rule(firstWord);
    if (val?.value != null) {
      return val.value;
    }
  }
  return null;
}

export function renderStat(stat: string | number): string {
  if (typeof stat === "number") {
    return stat.toLocaleString();
  }

  return stat
    .split(/\s+/)
    .map((word) => {
      for (let rule of statRules) {
        let val = rule(word);
        if (val) {
          return val;
        }
      }

      // Check if word is a number and format with commas
      const numberMatch = word.match(/^\d+$/);
      if (numberMatch) {
        return parseInt(word).toLocaleString();
      }

      return word;
    })
    .join(" ");
}

// place files you want to import through the `$lib` alias in this folder.

export function formatDuration(dur: number): string {
  const totalSeconds = dur / 30;
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = Math.floor(totalSeconds % 60);

  if (hours > 0) {
    return `${hours}h ${minutes}m`;
  } else if (minutes > 0) {
    return seconds > 0 ? `${minutes}m ${seconds}s` : `${minutes}m`;
  } else {
    return `${seconds}s`;
  }
}

export type NavPage = "home" | "player" | "date" | "map" | null;

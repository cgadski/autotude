import { getReplayCalendar } from "$lib/db";

export async function load() {
  return {
    calendarData: await getReplayCalendar()
  };
}

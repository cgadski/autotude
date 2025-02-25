import { getFrontpageData } from "$lib/db";

export async function load() {
  return getFrontpageData();
}

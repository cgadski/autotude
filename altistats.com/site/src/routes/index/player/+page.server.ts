import { getPlayersList } from "$lib/db";

export async function load() {
  return {
    players: await getPlayersList()
  };
}

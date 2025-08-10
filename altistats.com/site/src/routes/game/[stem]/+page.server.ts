import { getGame } from "$lib/stats";
import { error } from "@sveltejs/kit";

export async function load({ params }) {
  const game = await getGame(params.stem);

  if (!game) {
    throw error(404, "Game not found");
  }

  return {
    game,
  };
}

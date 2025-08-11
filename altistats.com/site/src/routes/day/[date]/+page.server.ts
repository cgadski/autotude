import { error } from "@sveltejs/kit";

export async function load({ params }) {
  const date = params.date;

  return {
    date,
    games: [],
  };
}

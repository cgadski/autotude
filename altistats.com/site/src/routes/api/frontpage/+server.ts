import { json } from "@sveltejs/kit";
import { getFrontpageData } from "$lib/db";

export async function GET() {
  const data = await getFrontpageData();

  return json(data, {
    headers: {
      'Cache-Control': 'public, max-age=30' // Cache for 30 seconds
    }
  });
}

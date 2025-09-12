import { query } from "$lib/stats";

export async function load({ params, parent }) {
  const { stem } = params;
  await parent();

  return {
    messages: query(
      `
      SELECT 1
      `,
      { args: [stem] },
    ),
  };
}

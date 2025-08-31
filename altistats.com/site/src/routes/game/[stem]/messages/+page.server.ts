export async function load({ params, parent }) {
  const { stem } = params;
  await parent();

  return {
    // TODO: Add messages data queries here
  };
}

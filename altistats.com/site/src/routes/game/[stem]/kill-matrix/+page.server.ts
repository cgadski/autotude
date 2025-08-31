export async function load({ params, parent }) {
  const { stem } = params;
  await parent();

  return {
    // TODO: Add kill matrix data queries here
  };
}

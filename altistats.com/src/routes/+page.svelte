<script lang="ts">
	import GameCard from '$lib/GameCard.svelte';

	export let data;
	$: totalHours = Math.round(data.totalHours * 10) / 10;
</script>

<div class="flex min-h-screen items-center justify-center bg-gray-100">
	<div class="mx-4 w-full max-w-2xl rounded-lg bg-white p-6 shadow-lg">
		<h1 class="mb-8 text-center text-3xl font-bold text-gray-800">altistats.com</h1>

		<div class="grid grid-cols-1 gap-6 md:grid-cols-2">
			<div class="rounded-lg bg-gray-50 p-4 text-center">
				<div class="mb-2 text-4xl font-bold text-blue-600">
					{data.replayCount.toLocaleString()}
				</div>
				<div class="text-gray-600">Total replays</div>
			</div>

			<div class="rounded-lg bg-gray-50 p-4 text-center">
				<div class="mb-2 text-4xl font-bold text-green-600">
					{totalHours.toLocaleString()}
				</div>
				<div class="text-gray-600">Hours of gameplay</div>
			</div>
		</div>

		<div class="mt-8">
			<h2 class="mb-4 text-xl font-semibold text-gray-800">Recent Games</h2>
			<div class="space-y-4">
				{#each data.recentGames as game}
					<GameCard {game} />
				{/each}
			</div>
		</div>
	</div>
</div>

<script lang="ts">
	export let game: {
		map: string;
		datetime: string;
		minutes: string;
		players: string;
	};

	$: players = JSON.parse(game.players);
	$: team1 = players
		.filter((p: any) => p.team === 3)
		.sort((a: any, b: any) => b.ticks_alive - a.ticks_alive)
		.map((p: any) => p.nick);
	$: team2 = players
		.filter((p: any) => p.team === 4)
		.sort((a: any, b: any) => b.ticks_alive - a.ticks_alive)
		.map((p: any) => p.nick);
</script>

<a
	href="/game/{game.stem}"
	class="block rounded-lg bg-gray-50 p-4 transition-colors hover:bg-gray-100"
>
	<p>{game.map}</p>
	<div class="mb-2 flex items-center justify-between text-sm text-gray-600">
		<span class="text-gray-500"
			>{Math.floor(Number(game.minutes))}:{Math.round((Number(game.minutes) % 1) * 60)
				.toString()
				.padStart(2, '0')}</span
		>
		<span>{new Date(game.datetime).toLocaleString()}</span>
	</div>
	<div class="grid grid-cols-1 gap-2 md:grid-cols-2">
		{#if game.players}
			<div class="rounded bg-blue-50 p-2">
				{#if game.last_goal_team == 3}
					<span class="float-right"> won </span>
				{/if}
				<div class="text-sm text-gray-700">
					{#if team1.length > 0}
						{#each team1 as player}
							<div>{player}</div>
						{/each}
					{:else}
						No players
					{/if}
				</div>
			</div>
			<div class="rounded bg-red-50 p-2">
				{#if game.last_goal_team == 4}
					<span class="float-right"> won </span>
				{/if}
				<div class="text-sm text-gray-700">
					{#if team2.length > 0}
						{#each team2 as player}
							<div>{player}</div>
						{/each}
					{:else}
						No players
					{/if}
				</div>
			</div>
		{:else}
			<div class="col-span-2 text-center text-gray-500">No team data available</div>
		{/if}
	</div>
</a>

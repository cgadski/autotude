<script lang="ts">
	export let data;

	// Get players by team
	$: team3Players = [...new Set(data.kills
		.filter(k => k.killer_team === 3)
		.map(k => k.killer_name)
	)].sort();

	$: team4Players = [...new Set(data.kills
		.filter(k => k.victim_team === 4)
		.map(k => k.victim_name)
	)].sort();

	// Create kill matrices
	$: team3KillMatrix = team3Players.map(killer => ({
		killer,
		victims: team4Players.map(victim => {
			const entry = data.kills.find(k => 
				k.killer_name === killer && 
				k.victim_name === victim && 
				k.killer_team === 3
			);
			return entry ? entry.kill_count : 0;
		})
	}));

	$: team4KillMatrix = team4Players.map(killer => ({
		killer,
		victims: team3Players.map(victim => {
			const entry = data.kills.find(k => 
				k.killer_name === killer && 
				k.victim_name === victim && 
				k.killer_team === 4
			);
			return entry ? entry.kill_count : 0;
		})
	}));
</script>

<div class="min-h-screen bg-gray-100 py-8">
	<div class="mx-auto max-w-6xl px-4">
		<div class="mb-8 rounded-lg bg-white p-6 shadow-lg">
			<h1 class="mb-4 text-2xl font-bold text-gray-800">Game Details</h1>
			<div class="grid grid-cols-2 gap-4 md:grid-cols-3">
				<div>
					<span class="text-sm text-gray-500">Map</span>
					<div class="font-medium">{data.game.map}</div>
				</div>
				<div>
					<span class="text-sm text-gray-500">Duration</span>
					<div class="font-medium">{Math.floor(Number(data.game.minutes))}:{(Math.round((Number(data.game.minutes) % 1) * 60)).toString().padStart(2, '0')}</div>
				</div>
				<div>
					<span class="text-sm text-gray-500">Date</span>
					<div class="font-medium">{new Date(data.game.datetime).toLocaleString()}</div>
				</div>
			</div>
		</div>

		{#if team3Players.length > 0 || team4Players.length > 0}
			<div class="space-y-8">
				{#if team3KillMatrix.length > 0}
					<div class="overflow-x-auto rounded-lg bg-blue-50 p-6 shadow-lg">
						<h2 class="mb-4 text-xl font-semibold text-blue-800">Team 3 Kills</h2>
						<table class="min-w-full table-auto">
							<thead>
								<tr>
									<th class="border-b border-blue-200 p-2 text-left">Killer \ Victim</th>
									{#each team4Players as player}
										<th class="border-b border-blue-200 p-2 text-center">{player}</th>
									{/each}
									<th class="border-b border-blue-200 p-2 text-center">Total</th>
								</tr>
							</thead>
							<tbody>
								{#each team3KillMatrix as row}
									<tr>
										<td class="border-b border-blue-200 p-2 font-medium">{row.killer}</td>
										{#each row.victims as kills}
											<td class="border-b border-blue-200 p-2 text-center">{kills || '-'}</td>
										{/each}
										<td class="border-b border-blue-200 p-2 text-center font-medium">
											{row.victims.reduce((a, b) => a + b, 0)}
										</td>
									</tr>
								{/each}
								<tr>
									<td class="p-2 font-medium">Total Deaths</td>
									{#each team4Players as player}
										<td class="p-2 text-center font-medium">
											{team3KillMatrix.reduce((sum, row) => sum + row.victims[team4Players.indexOf(player)], 0)}
										</td>
									{/each}
									<td class="p-2" />
								</tr>
							</tbody>
						</table>
					</div>
				{/if}

				{#if team4KillMatrix.length > 0}
					<div class="overflow-x-auto rounded-lg bg-red-50 p-6 shadow-lg">
						<h2 class="mb-4 text-xl font-semibold text-red-800">Team 4 Kills</h2>
						<table class="min-w-full table-auto">
							<thead>
								<tr>
									<th class="border-b border-red-200 p-2 text-left">Killer \ Victim</th>
									{#each team3Players as player}
										<th class="border-b border-red-200 p-2 text-center">{player}</th>
									{/each}
									<th class="border-b border-red-200 p-2 text-center">Total</th>
								</tr>
							</thead>
							<tbody>
								{#each team4KillMatrix as row}
									<tr>
										<td class="border-b border-red-200 p-2 font-medium">{row.killer}</td>
										{#each row.victims as kills}
											<td class="border-b border-red-200 p-2 text-center">{kills || '-'}</td>
										{/each}
										<td class="border-b border-red-200 p-2 text-center font-medium">
											{row.victims.reduce((a, b) => a + b, 0)}
										</td>
									</tr>
								{/each}
								<tr>
									<td class="p-2 font-medium">Total Deaths</td>
									{#each team3Players as player}
										<td class="p-2 text-center font-medium">
											{team4KillMatrix.reduce((sum, row) => sum + row.victims[team3Players.indexOf(player)], 0)}
										</td>
									{/each}
									<td class="p-2" />
								</tr>
							</tbody>
						</table>
					</div>
				{/if}
			</div>
		{:else}
			<div class="rounded-lg bg-white p-6 text-center text-gray-500 shadow-lg">
				No kills recorded in this game
			</div>
		{/if}
	</div>
</div>

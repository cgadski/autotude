<script lang="ts">
    import { planes } from "$lib";
    import VerticalList from "$lib/VerticalList.svelte";

    export let data;

    $: totalGamesAllTime = data.activity.reduce(
        (sum: number, row: any) => sum + row.n_games,
        0,
    );

    $: monthlyData = (() => {
        const months = new Map();

        data.months.forEach((row: any) => {
            months.set(row.time_bin_desc, {
                month: row.time_bin_desc,
                total_games: 0,
                planes: new Map(),
            });
        });

        data.activity.forEach((row: any) => {
            const monthData = months.get(row.time_bin_desc);
            monthData.total_games += row.n_games;
            monthData.planes.set(row.plane, {
                n_games: row.n_games,
                n_won: row.n_won,
                game_fraction: row.n_games / totalGamesAllTime,
            });
        });

        return Array.from(months.values()).sort((a: any, b: any) =>
            b.month.localeCompare(a.month),
        );
    })();

    const planeImages = [
        "loopy.png",
        "bomber.png",
        "whale.png",
        "biplane.png",
        "randa.png",
    ];

    function formatMonth(monthDesc: string): string {
        return new Date(monthDesc + "-01").toLocaleDateString("en-US", {
            month: "short",
            year: "numeric",
        });
    }

    function getPlanesSortedByGames(
        planesMap: Map<
            number,
            { n_games: number; n_won: number; game_fraction: number }
        >,
    ): Array<{
        plane: number;
        n_games: number;
        n_won: number;
        game_fraction: number;
    }> {
        const planeData = [];
        for (let i = 0; i < 5; i++) {
            const data = planesMap.get(i);
            if (data && data.n_games > 0) {
                planeData.push({
                    plane: i,
                    n_games: data.n_games,
                    n_won: data.n_won,
                    game_fraction: data.game_fraction,
                });
            }
        }
        return planeData.sort((a, b) => a.plane - b.plane);
    }

    $: maxGameFraction = Math.max(
        ...data.activity.map((row: any) => row.n_games / totalGamesAllTime),
    );
</script>

<VerticalList items={monthlyData} let:item={monthData}>
    <td class="text-end align-middle fw-bold" style="width: 6em;">
        {formatMonth(monthData.month)}
    </td>
    <td class="align-middle d-flex flex-wrap gap-1">
        {#each getPlanesSortedByGames(monthData.planes) as { plane, n_games, n_won, game_fraction }}
            <span class="plane-pill">
                <span
                    class="pill-background"
                    style="width: {(game_fraction / maxGameFraction) * 100}%;"
                ></span>
                <img
                    src="/images/{planeImages[plane]}"
                    alt={planes[plane]}
                    class="plane-image"
                />
                <span class="game-count">
                    {n_games}
                </span>
            </span>
        {/each}
    </td>
</VerticalList>

<style>
    .plane-pill {
        background: linear-gradient(to right, #f8f9fa, #ffffff);
        border: 1px solid #e9ecef;
        border-radius: 50px;
        padding: 0em 0.5em;
        position: relative;
        overflow: hidden;
        display: flex;
        align-items: center;
        white-space: nowrap;
        width: 100px;
        height: 40px;
    }

    .pill-background {
        position: absolute;
        top: 0;
        left: 0;
        height: 100%;
        background-color: #6c757d;
        opacity: 0.6;
    }

    .plane-image {
        height: 35px;
        position: absolute;
        right: 45px;
        top: 50%;
        transform: translateY(-50%);
        z-index: 0;
    }

    .game-count {
        font-weight: 500;
        position: relative;
        z-index: 1;
        width: 100%;
        text-align: right;
        padding-right: 0.5rem;
    }
</style>

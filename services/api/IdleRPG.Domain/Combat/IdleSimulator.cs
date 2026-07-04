using IdleRPG.Domain.Enums;
using IdleRPG.Domain.GameData;

namespace IdleRPG.Domain.Combat;

/// <summary>
/// Advances an <see cref="IdleState"/> by a tick budget (1 tick = 1s),
/// fighting consecutive waves with the deterministic <see cref="CombatEngine"/>.
/// Battles are atomic: a battle that does not fit the remaining budget is
/// carried over (same seed) to the next advance, so results never depend on
/// how the budget was sliced.
/// </summary>
public static class IdleSimulator
{
    /// <summary>Downtime ticks between waves (loot pickup / walk time).</summary>
    public const int TravelTicks = 5;

    /// <summary>Rest ticks after a defeat before the team retries.</summary>
    public const int RetryRestTicks = 30;

    /// <summary>Consecutive losses after which the team stops burning time.</summary>
    public const int StuckThreshold = 3;

    /// <summary>Hard guard so one advance can never spin unbounded.</summary>
    public const int MaxBattlesPerAdvance = 5000;

    public static IdleAdvanceReport Advance(
        IdleState state, IReadOnlyList<HeroSpec> team, int ticks, int userSeed)
    {
        if (team.Count == 0 || ticks <= 0)
        {
            return new IdleAdvanceReport();
        }

        var budget = (long)ticks + state.CarryTicks;
        state.CarryTicks = 0;

        int won = 0, lost = 0, drops = 0, zonesCleared = 0;
        long xpGained = 0;

        for (var i = 0; i < MaxBattlesPerAdvance && budget > 0; i++)
        {
            if (state.IsStuck)
            {
                // The wall doesn't move until the player upgrades the team;
                // don't bank the idle time against it.
                budget = 0;
                break;
            }

            var enemies = EnemyCatalog.WaveFor(state.Zone, state.Wave);
            var seed = MixSeed(userSeed, state.BattleCounter);
            var result = CombatEngine.Simulate(team, enemies, seed);

            var cost = (long)result.Ticks + (result.Victory ? TravelTicks : RetryRestTicks);
            if (cost > budget)
            {
                // Battle doesn't fit: carry the budget over; the same seed
                // reproduces this exact battle on the next advance.
                state.CarryTicks = (int)budget;
                budget = 0;
                break;
            }

            budget -= cost;
            state.BattleCounter++;

            if (result.Victory)
            {
                state.ConsecutiveLosses = 0;
                state.LastOutcome = result.HeroesDown > 0 || result.LowestHeroHpFraction < 0.30f
                    ? IdleBattleOutcome.Danger
                    : IdleBattleOutcome.Winning;

                var lootRng = new Random(MixSeed(seed, 7919));
                foreach (var enemy in enemies)
                {
                    state.PendingXp += enemy.XpReward;
                    xpGained += enemy.XpReward;
                    state.TotalKills++;

                    if (RollDrop(lootRng, enemy, team, out var rarity))
                    {
                        var key = rarity.ToString();
                        state.PendingDrops[key] = state.PendingDrops.GetValueOrDefault(key) + 1;
                        drops++;
                    }
                }

                won++;
                state.Wave++;
                if (state.Wave > 10)
                {
                    state.Wave = 1;
                    state.Zone++;
                    zonesCleared++;
                }
            }
            else
            {
                lost++;
                state.ConsecutiveLosses++;
                state.LastOutcome = IdleBattleOutcome.Stuck;
            }
        }

        return new IdleAdvanceReport
        {
            BattlesWon = won,
            BattlesLost = lost,
            XpGained = xpGained,
            DropsRolled = drops,
            ZonesCleared = zonesCleared,
        };
    }

    /// <summary>
    /// Rolls whether an enemy drops an item and at which rarity. Team
    /// DropRate scales the drop chance; Luck weights the roll toward the
    /// rarer tradeable tiers. Only rolled-stat tiers (≤ Transcendent) drop.
    /// </summary>
    private static bool RollDrop(
        Random rng, EnemySpec enemy, IReadOnlyList<HeroSpec> team, out ItemRarity rarity)
    {
        rarity = ItemRarity.Broken;

        var dropRate = team.Average(h => MathF.Max(h.Stats.DropRate, 0f));
        if (rng.NextDouble() >= enemy.DropChance * dropRate)
        {
            return false;
        }

        var luck = Math.Max(team.Average(h => (double)h.Stats.Luck), 0.1);

        var tiers = Enum.GetValues<ItemRarity>()
            .Where(r => !ItemRarityData.HasFixedStats(r) && ItemRarityData.DropPercent(r) > 0)
            .ToArray();

        // Luck raises the weight of everything above the commons.
        double Weight(ItemRarity r) =>
            ItemRarityData.DropPercent(r) * (r >= ItemRarity.Rare ? luck : 1.0);

        var total = tiers.Sum(Weight);
        var roll = rng.NextDouble() * total;
        foreach (var tier in tiers)
        {
            roll -= Weight(tier);
            if (roll <= 0)
            {
                rarity = tier;
                return true;
            }
        }

        rarity = tiers[^1];
        return true;
    }

    private static int MixSeed(int seed, long counter)
    {
        // splitmix64-style scramble truncated to 31 bits.
        unchecked
        {
            var z = (ulong)seed * 0x9E3779B97F4A7C15UL + (ulong)counter;
            z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9UL;
            z = (z ^ (z >> 27)) * 0x94D049BB133111EBUL;
            z ^= z >> 31;
            return (int)(z & 0x7FFFFFFF);
        }
    }
}

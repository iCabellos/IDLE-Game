using IdleRPG.Domain.GameData;
using IdleRPG.Domain.Loot;

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

    /// <summary>Pending drops kept in full detail; the rest is summarised.</summary>
    public const int MaxPendingLoot = 100;

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

                    var drop = LootGenerator.TryGenerate(lootRng, enemy, team);
                    if (drop is not null)
                    {
                        if (state.PendingLoot.Count < MaxPendingLoot)
                        {
                            state.PendingLoot.Add(drop);
                        }
                        else
                        {
                            state.OverflowLoot++;
                        }

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

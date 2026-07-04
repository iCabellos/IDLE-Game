using IdleRPG.Application.DTOs.Combat;
using IdleRPG.Domain.Combat;
using IdleRPG.Domain.GameData;
using IdleRPG.Domain.Loot;

namespace IdleRPG.Application.UseCases.Combat;

/// <summary>
/// Maps idle state to the readable statuses of the UX rule (no raw numbers):
/// winning / danger / stuck / rewards_ready (steam_desynced arrives with F5).
/// </summary>
internal static class CombatText
{
    public static string Status(IdleState state)
    {
        if (state.IsStuck)
        {
            return "stuck";
        }

        if (state.LastOutcome == IdleBattleOutcome.Danger)
        {
            return "danger";
        }

        return HasRewards(state) ? "rewards_ready" : "winning";
    }

    public static string StatusText(IdleState state) => Status(state) switch
    {
        "stuck" => "Your team has hit a wall. Upgrade gear or level up to push further.",
        "danger" => "Your team is winning, but it was a close call. Consider better defenses.",
        "rewards_ready" => "Your team is cruising and rewards are piling up. Claim them!",
        _ => "Your team is winning steadily.",
    };

    public static bool HasRewards(IdleState state) =>
        state.PendingXp > 0 || state.PendingLoot.Count > 0 || state.OverflowLoot > 0;

    public static IReadOnlyList<string> RewardSummary(IdleState state)
    {
        var lines = new List<string>();

        if (state.PendingXp > 0)
        {
            lines.Add("Experience ready to claim.");
        }

        var drops = state.PendingLoot.Count + state.OverflowLoot;
        if (drops > 0)
        {
            lines.Add(drops == 1
                ? "1 item found — awaiting Steam sync."
                : $"{drops} items found — awaiting Steam sync.");

            // Showcase the best finds, ARPG drop-feed style.
            foreach (var drop in state.PendingLoot
                         .OrderByDescending(d => d.Rarity)
                         .Take(3))
            {
                lines.Add($"{drop.Name} — {drop.Rarity} {ArchetypeCatalog.For(drop.Archetype).DisplayName}");
            }
        }

        if (lines.Count == 0)
        {
            lines.Add("Nothing to claim yet — the team keeps fighting.");
        }

        return lines;
    }

    /// <summary>Maps a drop for the client: names and descriptions, no numbers.</summary>
    public static LootDropDto ToDto(LootDrop drop) => new()
    {
        Name = drop.Name,
        Rarity = drop.Rarity.ToString(),
        Archetype = ArchetypeCatalog.For(drop.Archetype).DisplayName,
        Slot = drop.Slot,
        Affixes = drop.AffixDescriptions,
    };

    public static EnemyPreviewDto EnemyPreview(IdleState state)
    {
        var wave = EnemyCatalog.WaveFor(state.Zone, state.Wave);

        return new EnemyPreviewDto
        {
            Enemies = wave.Select(e => e.Name).ToList(),
            Weaknesses = wave
                .SelectMany(e => e.Weaknesses)
                .Distinct()
                .Select(w => w.ToString())
                .ToList(),
        };
    }
}

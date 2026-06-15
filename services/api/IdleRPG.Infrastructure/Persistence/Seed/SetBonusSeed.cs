using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.ValueObjects;
using Microsoft.EntityFrameworkCore;

namespace IdleRPG.Infrastructure.Persistence.Seed;

/// <summary>
/// Seeds the items_set_bonuses thresholds. Ships the Ironclad set: 2-piece
/// grants +10% Defense; 4-piece grants +25% Defense and the "Unbreakable"
/// passive (+15% MaxHp). Idempotent — keyed by deterministic ids.
/// </summary>
public static class SetBonusSeed
{
    public static async Task SeedAsync(AppDbContext context, CancellationToken ct = default)
    {
        var bonuses = BuildSetBonuses();

        var existing = (await context.SetBonuses.Select(b => b.Id).ToListAsync(ct)).ToHashSet();
        var toAdd = bonuses.Where(b => !existing.Contains(b.Id)).ToList();

        if (toAdd.Count > 0)
        {
            await context.SetBonuses.AddRangeAsync(toAdd, ct);
            await context.SaveChangesAsync(ct);
        }
    }

    public static IReadOnlyList<SetBonus> BuildSetBonuses()
    {
        var twoPiece = new SetBonusPayload(
            new[] { new StatModifier("Defense", 0.10f, ModifierType.Percent) },
            Array.Empty<Passive>());

        var fourPiece = new SetBonusPayload(
            new[] { new StatModifier("Defense", 0.25f, ModifierType.Percent) },
            new[]
            {
                new Passive("Unbreakable", new[]
                {
                    new StatModifier("MaxHp", 0.15f, ModifierType.Percent),
                }),
            });

        return new List<SetBonus>
        {
            new()
            {
                Id = SeedIds.From("setbonus:ironclad:2"),
                SetId = ItemSeed.IroncladSetId,
                PiecesRequired = 2,
                StatBonusesJson = SetBonusPayload.Serialize(twoPiece),
            },
            new()
            {
                Id = SeedIds.From("setbonus:ironclad:4"),
                SetId = ItemSeed.IroncladSetId,
                PiecesRequired = 4,
                StatBonusesJson = SetBonusPayload.Serialize(fourPiece),
            },
        };
    }
}

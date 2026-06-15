using IdleRPG.Application.Interfaces.Items;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Interfaces;
using IdleRPG.Domain.ValueObjects;

namespace IdleRPG.Infrastructure.Items;

/// <summary>
/// Determines which set bonuses are active for an equipped loadout. Pieces are
/// grouped by <see cref="Item.SetId"/>; every threshold (pieces_required) at or
/// below the equipped count contributes an <see cref="ActiveSetBonus"/>.
/// </summary>
public sealed class SetBonusCalculator : ISetBonusCalculator
{
    private readonly IRepository<SetBonus>? _setBonuses;
    private IReadOnlyList<SetBonus>? _cached;

    public SetBonusCalculator(IRepository<SetBonus> setBonuses)
    {
        _setBonuses = setBonuses;
    }

    /// <summary>Test-friendly constructor with an in-memory threshold table.</summary>
    public SetBonusCalculator(IReadOnlyList<SetBonus> setBonuses)
    {
        _cached = setBonuses;
    }

    public IReadOnlyList<ActiveSetBonus> CalculateActiveBonuses(
        IEnumerable<ItemInstance> equipped,
        IEnumerable<Item> definitions)
    {
        var defById = definitions
            .GroupBy(d => d.Id)
            .ToDictionary(g => g.Key, g => g.First());

        // Count equipped pieces per set (ignoring items with no set membership).
        var piecesPerSet = new Dictionary<Guid, int>();
        foreach (var instance in equipped)
        {
            if (!defById.TryGetValue(instance.ItemId, out var def) || def.SetId is not { } setId)
            {
                continue;
            }

            piecesPerSet[setId] = piecesPerSet.GetValueOrDefault(setId) + 1;
        }

        if (piecesPerSet.Count == 0)
        {
            return Array.Empty<ActiveSetBonus>();
        }

        var thresholds = LoadThresholds();
        var active = new List<ActiveSetBonus>();

        foreach (var (setId, count) in piecesPerSet)
        {
            foreach (var threshold in thresholds
                         .Where(t => t.SetId == setId && t.PiecesRequired <= count)
                         .OrderBy(t => t.PiecesRequired))
            {
                var payload = SetBonusPayload.Parse(threshold.StatBonusesJson);
                active.Add(new ActiveSetBonus(
                    setId,
                    count,
                    threshold.PiecesRequired,
                    payload.Modifiers,
                    payload.Passives));
            }
        }

        return active;
    }

    private IReadOnlyList<SetBonus> LoadThresholds()
    {
        if (_cached is not null)
        {
            return _cached;
        }

        // Set-bonus thresholds are a tiny, static reference table; a one-time
        // synchronous load is acceptable and cached for the calculator's lifetime.
        _cached = _setBonuses!.GetAllAsync().GetAwaiter().GetResult();
        return _cached;
    }
}

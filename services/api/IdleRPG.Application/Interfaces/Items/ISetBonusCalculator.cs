using IdleRPG.Domain.Entities;
using IdleRPG.Domain.ValueObjects;

namespace IdleRPG.Application.Interfaces.Items;

/// <summary>Determines which set bonuses are active for an equipped loadout.</summary>
public interface ISetBonusCalculator
{
    IReadOnlyList<ActiveSetBonus> CalculateActiveBonuses(
        IEnumerable<ItemInstance> equipped,
        IEnumerable<Item> definitions);
}

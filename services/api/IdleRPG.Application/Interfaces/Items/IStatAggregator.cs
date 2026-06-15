using IdleRPG.Domain.Entities;
using IdleRPG.Domain.ValueObjects;

namespace IdleRPG.Application.Interfaces.Items;

/// <summary>Computes a character's effective stats from base + items + bonuses.</summary>
public interface IStatAggregator
{
    CharacterStats Aggregate(
        Character character,
        IEnumerable<ItemInstance> equipped,
        IEnumerable<Item> definitions,
        IEnumerable<ActiveSetBonus> bonuses);
}

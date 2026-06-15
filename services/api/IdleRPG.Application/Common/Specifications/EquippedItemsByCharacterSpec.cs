using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Specifications;

namespace IdleRPG.Application.Common.Specifications;

/// <summary>All item instances currently equipped to a given character.</summary>
public sealed class EquippedItemsByCharacterSpec : BaseSpecification<ItemInstance>
{
    public EquippedItemsByCharacterSpec(Guid characterId)
        : base(i => i.EquippedToCharacterId == characterId)
    {
        AddInclude(i => i.Item!);
    }
}

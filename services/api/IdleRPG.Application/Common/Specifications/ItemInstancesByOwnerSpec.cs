using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Specifications;

namespace IdleRPG.Application.Common.Specifications;

/// <summary>All item instances owned by a user, newest first, with definitions.</summary>
public sealed class ItemInstancesByOwnerSpec : BaseSpecification<ItemInstance>
{
    public ItemInstancesByOwnerSpec(Guid ownerId)
        : base(i => i.OwnerId == ownerId)
    {
        AddInclude(i => i.Item!);
        ApplyOrderByDescending(i => i.AcquiredAt);
    }
}

using IdleRPG.Domain.Enums;

namespace IdleRPG.Domain.Entities;

/// <summary>
/// A playable character owned by a <see cref="User"/>. Level is constrained
/// to 1-1000; team slot to 0-3.
/// </summary>
public class Character
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public CharacterClass Class { get; set; }
    public CharacterRole Role { get; set; }
    public int Level { get; set; } = 1;        // 1-1000
    public long Experience { get; set; }
    public int TeamSlot { get; set; }          // 0-3
    public bool IsActive { get; set; } = true;

    /// <summary>Serialized <see cref="ValueObjects.CharacterStats"/> snapshot.</summary>
    public string StatsJson { get; set; } = "{}";

    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? DeletedAt { get; set; }

    // Navigation
    public User? User { get; set; }
    public ICollection<ItemInstance> EquippedItems { get; set; } = new List<ItemInstance>();
}

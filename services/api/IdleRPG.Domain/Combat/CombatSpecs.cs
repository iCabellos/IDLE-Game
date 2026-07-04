using IdleRPG.Domain.Enums;
using IdleRPG.Domain.ValueObjects;

namespace IdleRPG.Domain.Combat;

/// <summary>A hero entering battle: identity + aggregated stats snapshot.</summary>
public sealed record HeroSpec
{
    public required Guid CharacterId { get; init; }
    public required string Name { get; init; }
    public required CharacterClass Class { get; init; }
    public required CharacterRole Role { get; init; }
    public required int Level { get; init; }
    public required CharacterStats Stats { get; init; }
}

/// <summary>An enemy entering battle, produced by the EnemyCatalog.</summary>
public sealed record EnemySpec
{
    public required string Name { get; init; }
    public required EnemyArchetype Archetype { get; init; }
    public required int Level { get; init; }
    public required CharacterStats Stats { get; init; }
    public required DamageType DamageType { get; init; }

    /// <summary>Damage types that deplete this enemy's toughness bar.</summary>
    public required IReadOnlyList<DamageType> Weaknesses { get; init; }

    public required float Toughness { get; init; }
    public required long XpReward { get; init; }

    /// <summary>Base probability [0..1] of dropping an item on death.</summary>
    public required float DropChance { get; init; }
}

using IdleRPG.Domain.Combat;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.GameData;

namespace IdleRPG.Tests.Domain.Combat;

/// <summary>Shared team builders for the F4 combat tests.</summary>
public static class CombatTestTeams
{
    /// <summary>
    /// The canonical starter composition (tank / dps / healer / dps) on bare
    /// class stats — the same team a fresh account gets provisioned with.
    /// </summary>
    public static IReadOnlyList<HeroSpec> Starter(int level) => new[]
    {
        Hero("Tank", CharacterClass.Warrior, CharacterRole.Tank, level),
        Hero("Blade", CharacterClass.Berserker, CharacterRole.DPS, level),
        Hero("Light", CharacterClass.Cleric, CharacterRole.Healer, level),
        Hero("Frost", CharacterClass.Mage, CharacterRole.DPS, level),
    };

    public static HeroSpec Hero(
        string name, CharacterClass characterClass, CharacterRole role, int level) => new()
    {
        CharacterId = Guid.NewGuid(),
        Name = name,
        Class = characterClass,
        Role = role,
        Level = level,
        Stats = ClassBaseStats.For(characterClass, level),
    };
}

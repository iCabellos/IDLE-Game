namespace IdleRPG.Domain.Enums;

/// <summary>
/// Elemental damage channel of an attack. Maps 1:1 to the resistance /
/// penetration channels in <see cref="ValueObjects.CharacterStats"/> and to
/// enemy weaknesses in the break system (F4).
/// </summary>
public enum DamageType
{
    Physical = 1,
    Fire = 2,
    Ice = 3,
    Lightning = 4,
    Poison = 5
}

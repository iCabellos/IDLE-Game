namespace IdleRPG.Domain.Enums;

/// <summary>
/// Enemy tier within a wave. Grunts are fodder, elites anchor mid waves and
/// bosses close every zone (wave 10). Toughness / HP / rewards scale by tier.
/// </summary>
public enum EnemyArchetype
{
    Grunt = 1,
    Elite = 2,
    Boss = 3
}

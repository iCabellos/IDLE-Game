namespace IdleRPG.Domain.Combat;

/// <summary>
/// Canonical combat / idle formulas (F4). These are the single source of
/// truth for damage math; the engine and any preview code must call these.
/// </summary>
public static class CombatFormulas
{
    /// <summary>Resistance cap after penetration, per the master plan.</summary>
    public const float ResistCap = 0.90f;

    /// <summary>EffectiveResistance = clamp(resist − pen, 0, 0.90).</summary>
    public static float EffectiveResistance(float resist, float penetration) =>
        Math.Clamp(resist - penetration, 0f, ResistCap);

    /// <summary>
    /// Fraction of incoming damage absorbed by defense. Scales against the
    /// attacker's level so defense never trivialises higher-level content.
    /// </summary>
    public static float DefenseReduction(float defense, int attackerLevel)
    {
        var def = Math.Max(defense, 0f);
        return def / (def + 10f * Math.Max(attackerLevel, 1) + 150f);
    }

    /// <summary>FinalDamage = base × (crit ? critMult : 1) × (1 − effResist).</summary>
    public static float FinalDamage(float baseDamage, bool crit, float critMultiplier, float effectiveResistance) =>
        baseDamage * (crit ? critMultiplier : 1f) * (1f - effectiveResistance);

    /// <summary>
    /// Damage dealt when an enemy's toughness bar is depleted (weakness
    /// break). Scales with attacker level, BreakEffect and how large the
    /// enemy's toughness bar was (bosses take proportionally bigger breaks).
    /// </summary>
    public static float BreakDamage(int attackerLevel, float breakEffect, float maxToughness) =>
        12f * Math.Max(attackerLevel, 1) * (1f + Math.Max(breakEffect, 0f)) * (maxToughness / 60f);

    /// <summary>
    /// Offline progression efficiency: 100% for the first 36 hours, then
    /// −5% per additional day, floored at 1%.
    /// </summary>
    public static float OfflineEfficiency(TimeSpan offline)
    {
        const double gracePeriodHours = 36.0;

        if (offline <= TimeSpan.Zero)
        {
            return 1f;
        }

        var hours = offline.TotalHours;
        if (hours <= gracePeriodHours)
        {
            return 1f;
        }

        var daysBeyond = (hours - gracePeriodHours) / 24.0;
        return (float)Math.Max(0.01, 1.0 - 0.05 * daysBeyond);
    }
}

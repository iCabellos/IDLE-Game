namespace IdleRPG.Domain.GameData;

/// <summary>
/// Character experience curve (F4). XP required to advance from level L to
/// L+1 grows polynomially so late levels take meaningfully longer without
/// ever hard-walling idle progression.
/// </summary>
public static class XpCurve
{
    public const int MaxLevel = 1000;

    /// <summary>XP needed to go from <paramref name="level"/> to level+1.</summary>
    public static long XpToNext(int level)
    {
        var l = Math.Clamp(level, 1, MaxLevel);
        return (long)(100.0 * Math.Pow(l, 1.5));
    }

    /// <summary>
    /// Applies <paramref name="gainedXp"/> on top of (level, experience) and
    /// returns the resulting level and leftover experience.
    /// </summary>
    public static (int Level, long Experience) Apply(int level, long experience, long gainedXp)
    {
        var lvl = Math.Clamp(level, 1, MaxLevel);
        var xp = Math.Max(experience, 0) + Math.Max(gainedXp, 0);

        while (lvl < MaxLevel && xp >= XpToNext(lvl))
        {
            xp -= XpToNext(lvl);
            lvl++;
        }

        // At the cap, excess XP is discarded.
        if (lvl >= MaxLevel)
        {
            xp = 0;
        }

        return (lvl, xp);
    }
}

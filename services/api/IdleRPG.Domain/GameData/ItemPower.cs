namespace IdleRPG.Domain.GameData;

/// <summary>
/// Server-side item power resolver. Turns (shape, rarity tier, level) into a
/// primary stat line and the rarity-stacked passive list shown on the slot
/// reel. Mirrors docs/item-power-architecture.md.
/// </summary>
public static class ItemPower
{
    public enum Stat
    {
        PhysAtk, MagAtk, Defense, MaxHp, Speed, Luck,
        CritRate, CritDmg, PhysPen, MagPen, PhysRes, MagRes, Lifesteal, Guard,
        DmgPctPhys, DmgPctMag, SpeedPct, ExtraHit, ActionAdvance, Execute,
        EffectHit, EffectRes, Heal, Reflect,
    }

    private static readonly HashSet<Stat> Percent = new()
    {
        Stat.CritRate, Stat.CritDmg, Stat.PhysPen, Stat.MagPen, Stat.PhysRes,
        Stat.MagRes, Stat.Lifesteal, Stat.Guard, Stat.DmgPctPhys, Stat.DmgPctMag,
        Stat.SpeedPct, Stat.ExtraHit, Stat.ActionAdvance, Stat.Execute,
        Stat.EffectHit, Stat.EffectRes, Stat.Heal, Stat.Reflect,
    };

    public static bool IsPercent(Stat s) => Percent.Contains(s);

    public static string Label(Stat s) => s switch
    {
        Stat.PhysAtk => "Phys Atk",
        Stat.MagAtk => "Mag Atk",
        Stat.Defense => "Defense",
        Stat.MaxHp => "Max HP",
        Stat.Speed => "Speed",
        Stat.Luck => "Luck",
        Stat.CritRate => "Crit Rate",
        Stat.CritDmg => "Crit Dmg",
        Stat.PhysPen => "Phys Pen",
        Stat.MagPen => "Mag Pen",
        Stat.PhysRes => "Phys Res",
        Stat.MagRes => "Mag Res",
        Stat.Lifesteal => "Lifesteal",
        Stat.Guard => "Guard",
        Stat.DmgPctPhys => "Phys Dmg",
        Stat.DmgPctMag => "Mag Dmg",
        Stat.SpeedPct => "Speed",
        Stat.ExtraHit => "Extra Hit",
        Stat.ActionAdvance => "Advance",
        Stat.Execute => "Execute",
        Stat.EffectHit => "Eff Hit",
        Stat.EffectRes => "Eff Res",
        Stat.Heal => "Heal",
        Stat.Reflect => "Reflect",
        _ => s.ToString(),
    };

    /// <summary>Formats a stat value (no sign): "5.5%" or "12".</summary>
    public static string FormatValue(Stat s, double v) => Percent.Contains(s)
        ? $"{(v * 100).ToString("0.#", System.Globalization.CultureInfo.InvariantCulture)}%"
        : Math.Round(v).ToString(System.Globalization.CultureInfo.InvariantCulture);

    private static string Describe(Stat s, double v) => $"+{FormatValue(s, v)} {Label(s)}";

    // Primary stat at item level 1 is ~30% of the shape base (so a Lv1 sword
    // reads "+2 Phys Atk"); +10% per 5 levels from there.
    private const double PrimaryScale = 0.30;

    private static readonly string[] RarityNames =
    {
        "Broken", "Worn", "Common", "Uncommon", "Rare", "Superior", "Epic",
        "Mythic", "Ancient", "Relic", "Legendary", "Ascended", "Divine",
        "Celestial", "Primordial", "Transcendent", "Unique", "Seasonal",
        "Founder", "Event", "1-of-1",
    };

    private static readonly Dictionary<Stat, double> PerkBase = new()
    {
        [Stat.PhysAtk] = 2.5, [Stat.MagAtk] = 2.5, [Stat.Defense] = 2.5,
        [Stat.MaxHp] = 12, [Stat.Speed] = 3, [Stat.Luck] = 3,
        [Stat.CritRate] = 0.012, [Stat.CritDmg] = 0.05, [Stat.PhysPen] = 0.015,
        [Stat.MagPen] = 0.015, [Stat.PhysRes] = 0.012, [Stat.MagRes] = 0.012,
        [Stat.Lifesteal] = 0.01, [Stat.Guard] = 0.02, [Stat.DmgPctPhys] = 0.02,
        [Stat.DmgPctMag] = 0.02, [Stat.SpeedPct] = 0.02, [Stat.ExtraHit] = 0.015,
        [Stat.ActionAdvance] = 0.02, [Stat.Execute] = 0.03, [Stat.EffectHit] = 0.02,
        [Stat.EffectRes] = 0.02, [Stat.Heal] = 0.02, [Stat.Reflect] = 0.02,
    };

    private sealed record Spec(Dictionary<Stat, double> Base, Stat[] Track);

    private static readonly Dictionary<string, Spec> Specs = new()
    {
        ["sword"] = new(new() { [Stat.PhysAtk] = 6.5 }, new[]
        {
            Stat.CritRate, Stat.PhysPen, Stat.CritDmg, Stat.DmgPctPhys,
            Stat.Lifesteal, Stat.ExtraHit, Stat.Execute,
        }),
        ["bow"] = new(new() { [Stat.PhysAtk] = 5.0, [Stat.CritRate] = 0.03 }, new[]
        {
            Stat.CritRate, Stat.CritDmg, Stat.PhysPen, Stat.ExtraHit, Stat.DmgPctPhys,
        }),
        ["staff"] = new(new() { [Stat.MagAtk] = 6.5 }, new[]
        {
            Stat.MagPen, Stat.DmgPctMag, Stat.CritRate, Stat.CritDmg, Stat.MagPen,
        }),
        ["shield"] = new(new() { [Stat.Defense] = 5, [Stat.Guard] = 0.04 }, new[]
        {
            Stat.Guard, Stat.Reflect, Stat.Defense, Stat.MagRes, Stat.PhysRes,
        }),
        ["amulet"] = new(new() { [Stat.MagAtk] = 3, [Stat.Luck] = 4 }, new[]
        {
            Stat.Luck, Stat.MagPen, Stat.Heal, Stat.EffectHit,
        }),
        ["earring"] = new(new() { [Stat.MagAtk] = 2, [Stat.Luck] = 4 }, new[]
        {
            Stat.Luck, Stat.EffectHit, Stat.MagPen, Stat.DmgPctMag,
        }),
        ["ring"] = new(new() { [Stat.CritRate] = 0.04, [Stat.CritDmg] = 0.08, [Stat.Luck] = 3 }, new[]
        {
            Stat.Luck, Stat.CritDmg, Stat.CritRate, Stat.DmgPctPhys,
        }),
        ["relic"] = new(new() { [Stat.PhysAtk] = 3, [Stat.MagAtk] = 3, [Stat.Speed] = 3, [Stat.Luck] = 6 }, new[]
        {
            Stat.Luck, Stat.DmgPctPhys, Stat.DmgPctMag, Stat.SpeedPct, Stat.CritDmg, Stat.ActionAdvance,
        }),
    };

    public static string RarityName(int tier) => RarityNames[Math.Clamp(tier, 1, 21) - 1];

    public static bool IsDamageStat(Stat s) => s is Stat.PhysAtk or Stat.MagAtk;

    public sealed record Perk(Stat Stat, double Value);

    public sealed record Resolved(
        Stat PrimaryStat, double PrimaryValue, string Primary, List<string> Passives, List<Perk> Perks);

    /// <summary>+10% per 5 item levels (linear).</summary>
    public static double LevelFactor(int level) => 1 + 0.10 * (Math.Clamp(level, 1, 1000) / 5);

    /// <summary>Sub-stats unlocked at this item level: one every 100 levels.</summary>
    public static int SubStatCount(int level) => Math.Clamp(level, 1, 1000) / 100;

    /// <summary>
    /// Resolves an item by LEVEL: a primary stat that grows +10% per 5 levels,
    /// plus one sub-stat per 100 levels (each also scaled by level).
    /// </summary>
    public static Resolved Resolve(string shape, int level)
    {
        var spec = Specs.TryGetValue(shape, out var s) ? s : Specs["sword"];
        level = Math.Clamp(level, 1, 1000);
        var lf = LevelFactor(level);

        var primaryStat = spec.Base.Keys.First();
        var primaryValue = spec.Base[primaryStat] * PrimaryScale * lf;

        var passives = new List<string>();
        var perks = new List<Perk>();
        var count = SubStatCount(level);
        for (var k = 0; k < count; k++)
        {
            var stat = spec.Track[k % spec.Track.Length];
            var v = PerkBase[stat] * lf;
            passives.Add(Describe(stat, v));
            perks.Add(new Perk(stat, v));
        }

        return new Resolved(primaryStat, primaryValue, Describe(primaryStat, primaryValue), passives, perks);
    }
}

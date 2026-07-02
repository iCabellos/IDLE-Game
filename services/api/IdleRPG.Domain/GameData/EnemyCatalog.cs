using IdleRPG.Domain.Combat;
using IdleRPG.Domain.Enums;
using IdleRPG.Domain.ValueObjects;

namespace IdleRPG.Domain.GameData;

/// <summary>
/// Procedural enemy catalog (F4). Every zone has 10 waves; waves 1-6 are
/// grunt packs, 7-9 introduce an elite anchor and wave 10 is the zone boss.
/// Enemy HP is deliberately tuned so a same-level team needs several full
/// action cycles per wave — enough turns for skill points, ultimates and
/// weakness breaks to matter — without idle progression ever stalling.
/// </summary>
public static class EnemyCatalog
{
    /// <summary>Levels gained per zone. Zone 1 = level 1, zone 2 = level 6, ...</summary>
    public const int LevelsPerZone = 5;

    private static readonly string[] ZoneNames =
    {
        "Emberfall Outskirts", "Frostbite Hollow", "Stormwrack Coast", "Vipermarsh",
        "Ashen Bastion", "Glacier Throat", "Thunderspine Ridge", "Rotwood Deep",
        "Cinder Citadel", "Everfrost Sanctum", "Tempest Crown", "Plaguelands",
    };

    private static readonly DamageType[] AllTypes =
    {
        DamageType.Physical, DamageType.Fire, DamageType.Ice,
        DamageType.Lightning, DamageType.Poison,
    };

    /// <summary>Human-readable zone name (themes cycle past zone 12).</summary>
    public static string ZoneName(int zone)
    {
        var z = Math.Max(zone, 1);
        var baseName = ZoneNames[(z - 1) % ZoneNames.Length];
        var cycle = (z - 1) / ZoneNames.Length;
        return cycle == 0 ? $"{baseName}" : $"{baseName} {ToRoman(cycle + 1)}";
    }

    /// <summary>Recommended character level for a zone.</summary>
    public static int ZoneLevel(int zone) => 1 + (Math.Max(zone, 1) - 1) * LevelsPerZone;

    /// <summary>Builds the enemy pack for (zone, wave). Wave is 1..10.</summary>
    public static IReadOnlyList<EnemySpec> WaveFor(int zone, int wave)
    {
        var z = Math.Max(zone, 1);
        var w = Math.Clamp(wave, 1, 10);
        var level = ZoneLevel(z) + (w - 1) / 2;

        var enemies = new List<EnemySpec>();

        switch (w)
        {
            case <= 3:
                enemies.Add(Grunt(z, w, level, 1));
                enemies.Add(Grunt(z, w, level, 2));
                break;
            case <= 6:
                enemies.Add(Grunt(z, w, level, 1));
                enemies.Add(Grunt(z, w, level, 2));
                enemies.Add(Grunt(z, w, level, 3));
                break;
            case <= 9:
                enemies.Add(Elite(z, w, level));
                enemies.Add(Grunt(z, w, level, 1));
                enemies.Add(Grunt(z, w, level, 2));
                break;
            default:
                enemies.Add(Boss(z, level));
                if (z >= 2)
                {
                    enemies.Add(Grunt(z, w, level, 1));
                }

                if (z >= 4)
                {
                    enemies.Add(Grunt(z, w, level, 2));
                }

                break;
        }

        return enemies;
    }

    /// <summary>
    /// Weaknesses rotate deterministically with zone and wave so gear and
    /// team-element choices matter, and every element gets its moment.
    /// </summary>
    public static IReadOnlyList<DamageType> WeaknessesFor(int zone, int wave, EnemyArchetype archetype)
    {
        var count = archetype == EnemyArchetype.Boss ? 3 : 2;
        var offset = zone * 2 + wave;

        var result = new DamageType[count];
        for (var i = 0; i < count; i++)
        {
            result[i] = AllTypes[(offset + i * 2) % AllTypes.Length];
        }

        return result;
    }

    private static EnemySpec Grunt(int zone, int wave, int level, int index)
    {
        var weaknesses = WeaknessesFor(zone, wave, EnemyArchetype.Grunt);
        return new EnemySpec
        {
            Name = $"{ZoneName(zone)} Grunt {index}",
            Archetype = EnemyArchetype.Grunt,
            Level = level,
            Stats = EnemyStats(level, hpPerLevel: 55f, hpFlat: 80f, atkPerLevel: 3.2f,
                atkFlat: 6f, defPerLevel: 2.0f, speed: 88f, baseResist: 0.05f, weaknesses),
            DamageType = AllTypes[(zone + wave + index) % AllTypes.Length],
            Weaknesses = weaknesses,
            Toughness = 60f,
            XpReward = 8L * level,
            DropChance = 0.06f,
        };
    }

    private static EnemySpec Elite(int zone, int wave, int level)
    {
        var weaknesses = WeaknessesFor(zone, wave, EnemyArchetype.Elite);
        return new EnemySpec
        {
            Name = $"{ZoneName(zone)} Elite",
            Archetype = EnemyArchetype.Elite,
            Level = level,
            Stats = EnemyStats(level, hpPerLevel: 190f, hpFlat: 200f, atkPerLevel: 4.4f,
                atkFlat: 8f, defPerLevel: 2.6f, speed: 96f, baseResist: 0.10f, weaknesses),
            DamageType = AllTypes[(zone + wave) % AllTypes.Length],
            Weaknesses = weaknesses,
            Toughness = 150f,
            XpReward = 30L * level,
            DropChance = 0.30f,
        };
    }

    private static EnemySpec Boss(int zone, int level)
    {
        var weaknesses = WeaknessesFor(zone, 10, EnemyArchetype.Boss);
        return new EnemySpec
        {
            Name = $"{ZoneName(zone)} Overlord",
            Archetype = EnemyArchetype.Boss,
            Level = level + 1,
            Stats = EnemyStats(level + 1, hpPerLevel: 620f, hpFlat: 500f, atkPerLevel: 5.4f,
                atkFlat: 10f, defPerLevel: 3.0f, speed: 104f, baseResist: 0.15f, weaknesses),
            DamageType = AllTypes[zone % AllTypes.Length],
            Weaknesses = weaknesses,
            Toughness = 300f,
            XpReward = 120L * (level + 1),
            DropChance = 1.0f,
        };
    }

    private static CharacterStats EnemyStats(
        int level, float hpPerLevel, float hpFlat, float atkPerLevel, float atkFlat,
        float defPerLevel, float speed, float baseResist, IReadOnlyList<DamageType> weaknesses)
    {
        // HSR rule: an enemy has no innate resistance to its weakness elements.
        float Resist(DamageType type) => weaknesses.Contains(type) ? 0f : baseResist;

        // Superlinear damage pressure: hero healing scales linearly with
        // level, so enemy attack must outgrow it or level gaps never wall.
        // Capped so endgame zones stay clearable by well-geared teams.
        var pressure = MathF.Min(1f + level / 150f, 4f);

        return new CharacterStats
        {
            Attack = (atkPerLevel * level + atkFlat) * pressure,
            Defense = defPerLevel * level,
            MaxHp = hpPerLevel * level + hpFlat,
            CritRate = 0.05f,
            CritMultiplier = 1.5f,
            Speed = speed,
            ResistPhysical = Resist(DamageType.Physical),
            ResistFire = Resist(DamageType.Fire),
            ResistIce = Resist(DamageType.Ice),
            ResistLightning = Resist(DamageType.Lightning),
            ResistPoison = Resist(DamageType.Poison),
        };
    }

    private static string ToRoman(int value) => value switch
    {
        <= 1 => "I",
        2 => "II",
        3 => "III",
        4 => "IV",
        5 => "V",
        _ => value.ToString(),
    };
}

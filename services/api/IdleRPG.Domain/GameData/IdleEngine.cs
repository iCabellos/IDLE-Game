namespace IdleRPG.Domain.GameData;

/// <summary>
/// Pure, deterministic-given-RNG idle combat engine. No I/O. Operates on a
/// <see cref="GameState"/>: starts a run, advances one tick, and projects a
/// paint-ready <see cref="GameSnapshot"/>. Implements the model described in
/// docs/item-power-architecture.md (archetypes, 1x3 reel, combo multipliers,
/// luck, 10-level campaign).
/// </summary>
public static class IdleEngine
{
    private sealed record LevelDef(
        string Name, string Theme, int PhaseCount, int WavesPerPhase,
        int EnemyCount, string[] Kinds, string BossKind, double HpScale);

    private static readonly LevelDef[] Campaign =
    {
        new("Verdant Approach", "meadow", 2, 2, 2, new[] { "slime", "bat" }, "goblin", 1.00),
        new("Whispering Crypts", "crypt", 2, 3, 2, new[] { "bat", "skeleton" }, "skeleton", 1.18),
        new("Hollow Pinewood", "forest", 2, 2, 3, new[] { "slime", "goblin" }, "orc", 1.36),
        new("Bonecold Catacombs", "crypt", 2, 3, 3, new[] { "skeleton", "bat" }, "skeleton", 1.54),
        new("Emberfall Caldera", "volcano", 3, 2, 3, new[] { "goblin", "orc" }, "orc", 1.72),
        new("Sunken Ramparts", "citadel", 3, 2, 3, new[] { "skeleton", "orc" }, "orc", 1.90),
        new("Gloomroot Thicket", "forest", 3, 3, 4, new[] { "goblin", "slime", "bat" }, "orc", 2.08),
        new("Ashen Bastion", "cavern", 3, 2, 4, new[] { "orc", "skeleton" }, "demon", 2.26),
        new("Obsidian Spire", "citadel", 3, 3, 4, new[] { "orc", "goblin", "bat" }, "demon", 2.44),
        new("Throne of Cinders", "volcano", 3, 3, 4, new[] { "demon", "orc" }, "demon", 2.62),
    };

    private static readonly string[] SlotKinds =
    {
        "mainWeapon", "secondaryWeapon", "amulet", "earring1", "earring2", "ring1", "ring2",
    };

    private static string Category(string kind) => kind switch
    {
        "mainWeapon" or "secondaryWeapon" => "weapon",
        "amulet" => "amulet",
        "earring1" or "earring2" => "earring",
        "ring1" or "ring2" => "ring",
        _ => "other",
    };

    // -- lifecycle ----------------------------------------------------------

    public static GameState Start(IReadOnlyList<(string Id, string Name, string Archetype, int Level)> heroes)
    {
        var state = new GameState();
        foreach (var h in heroes)
        {
            var maxHp = HeroMaxHp(h.Level);
            state.Heroes.Add(new HeroState
            {
                Id = h.Id,
                Name = h.Name,
                Archetype = h.Archetype,
                Level = h.Level,
                MaxHp = maxHp,
                Hp = maxHp,
                SlotKinds = SlotKinds.ToList(),
                Luck = 20 + h.Level * 8,
            });
        }
        SpawnWave(state, new Random());
        return state;
    }

    public static void Step(GameState s, Random rng)
    {
        s.Tick++;
        s.Status = "fighting";

        foreach (var h in s.Heroes)
        {
            if (h.Hp <= 0 && h.ReviveIn > 0)
            {
                h.ReviveIn--;
                if (h.ReviveIn == 0)
                {
                    h.Hp = h.MaxHp * 0.5;
                    h.ReviveIn = -1;
                }
            }
        }

        if (s.Enemies.All(e => e.Hp <= 0))
        {
            Advance(s, rng);
        }

        var heroesAlive = s.Heroes.Any(h => h.Hp > 0);
        var enemiesAlive = s.Enemies.Any(e => e.Hp > 0);
        if (!heroesAlive || !enemiesAlive)
        {
            return;
        }

        if (s.Tick % 4 == 0)
        {
            EnemyAttack(s, rng);
        }
        else
        {
            HeroAttack(s, rng);
        }
    }

    // -- actions ------------------------------------------------------------

    private static void HeroAttack(GameState s, Random rng)
    {
        var actor = NextAliveHero(s);
        if (actor is null) return;

        var (kinds, combo, mult) = RollReel(actor.SlotKinds, actor.Luck, rng);
        var items = BuildReelItems(kinds, actor);
        s.Reel = new ReelState
        {
            Items = items,
            Combo = combo,
            Multiplier = mult,
            MaxRarityTier = items.Count == 0 ? 1 : items.Max(i => i.RarityTier),
            ActorIsHero = true,
            ActorId = actor.Id,
        };
        s.Outcome = combo;

        var target = s.Enemies.First(e => e.Hp > 0);
        s.Reel.TargetId = target.Id;

        var dmg = Offense(actor) * mult * CritFactor(actor.Archetype, rng);

        // Synergy and jackpot strike the whole wave.
        if (combo is "SYNERGY" or "JACKPOT")
        {
            foreach (var e in s.Enemies.Where(e => e.Hp > 0))
            {
                e.Hp = Math.Max(0, e.Hp - dmg);
            }
        }
        else
        {
            target.Hp = Math.Max(0, target.Hp - dmg);
        }
    }

    private static void EnemyAttack(GameState s, Random rng)
    {
        var attackers = s.Enemies.Where(e => e.Hp > 0).ToList();
        if (attackers.Count == 0) return;
        var attacker = attackers[rng.Next(attackers.Count)];

        var victim = s.Heroes.Where(h => h.Hp > 0)
            .OrderBy(h => h.Hp / h.MaxHp)
            .FirstOrDefault();
        if (victim is null) return;

        var chip = (12 + s.LevelIndex * 4) * (attacker.IsBoss ? 2.4 : 1.0);
        victim.Hp = Math.Max(0, victim.Hp - chip);
        if (victim.Hp <= 0)
        {
            victim.ReviveIn = 5;
        }

        s.Reel = new ReelState
        {
            Items = s.Reel.Items,
            Combo = s.Reel.Combo,
            Multiplier = s.Reel.Multiplier,
            MaxRarityTier = s.Reel.MaxRarityTier,
            ActorIsHero = false,
            ActorId = attacker.Id,
            TargetId = victim.Id,
        };
        s.Outcome = "HIT";
    }

    private static HeroState? NextAliveHero(GameState s)
    {
        for (var i = 0; i < s.Heroes.Count; i++)
        {
            var h = s.Heroes[(s.Turn + i) % s.Heroes.Count];
            if (h.Hp > 0)
            {
                s.Turn = (s.Turn + i + 1) % s.Heroes.Count;
                return h;
            }
        }
        return null;
    }

    // -- reel ---------------------------------------------------------------

    private static (List<string> Items, string Combo, double Mult) RollReel(
        List<string> equipped, double luck, Random rng)
    {
        if (equipped.Count == 0)
        {
            return (new List<string>(), "MIXED", 1);
        }

        var copy = Math.Clamp(0.06 + luck * 0.0010, 0, 0.40);
        var cat = Math.Clamp(0.10 + luck * 0.0015, 0, 0.55);

        var draw = new List<string> { equipped[rng.Next(equipped.Count)] };
        for (var i = 1; i < 3; i++)
        {
            var r = rng.NextDouble();
            string pick;
            if (r < copy)
            {
                pick = draw[rng.Next(draw.Count)];
            }
            else if (r < copy + cat)
            {
                var shownCats = draw.Select(Category).ToHashSet();
                var candidates = equipped
                    .Where(k => shownCats.Contains(Category(k)) && !draw.Contains(k))
                    .ToList();
                pick = candidates.Count == 0
                    ? equipped[rng.Next(equipped.Count)]
                    : candidates[rng.Next(candidates.Count)];
            }
            else
            {
                pick = equipped[rng.Next(equipped.Count)];
            }
            draw.Add(pick);
        }

        return (draw, Evaluate(draw), Multiplier(Evaluate(draw)));
    }

    private static List<ReelItem> BuildReelItems(IReadOnlyList<string> kinds, HeroState actor)
    {
        var items = new List<ReelItem>(kinds.Count);
        foreach (var kind in kinds)
        {
            var shape = ShapeFor(kind, actor.Archetype);
            var slotIndex = Math.Max(0, actor.SlotKinds.IndexOf(kind));
            var tier = RarityTierFor(actor.Level, slotIndex);
            var (primary, passives) = ItemPower.Resolve(shape, tier, actor.Level);
            items.Add(new ReelItem
            {
                Kind = kind,
                Shape = shape,
                RarityTier = tier,
                Rarity = ItemPower.RarityName(tier),
                Primary = primary,
                Passives = passives,
            });
        }
        return items;
    }

    private static string ShapeFor(string kind, string archetype) => kind switch
    {
        "mainWeapon" => archetype switch
        {
            "magic" or "support" => "staff",
            "physical" => "bow",
            _ => "sword",
        },
        "secondaryWeapon" => "shield",
        "amulet" => "amulet",
        "earring1" or "earring2" => "earring",
        "ring1" or "ring2" => "ring",
        _ => "sword",
    };

    private static int RarityTierFor(int level, int slotIndex) =>
        Math.Clamp(2 + (int)Math.Round(level * 0.9) + (slotIndex % 3), 1, 21);

    private static string Evaluate(IReadOnlyList<string> draw)
    {
        var kindCounts = draw.GroupBy(k => k).ToDictionary(g => g.Key, g => g.Count());
        if (kindCounts.Values.Max() >= 3) return "JACKPOT";

        var hasCategory = draw
            .GroupBy(Category)
            .Any(g => g.Distinct().Count() >= 2);
        if (hasCategory) return "SYNERGY";

        if (kindCounts.Values.Max() >= 2) return "PAIR";
        return "MIXED";
    }

    private static double Multiplier(string combo) => combo switch
    {
        "JACKPOT" => 10,
        "SYNERGY" => 3,
        "PAIR" => 2,
        _ => 1,
    };

    // -- progression --------------------------------------------------------

    private static void Advance(GameState s, Random rng)
    {
        s.WaveIndex++;
        var lvl = Campaign[s.LevelIndex];
        if (s.WaveIndex >= lvl.WavesPerPhase)
        {
            s.WaveIndex = 0;
            s.PhaseIndex++;
            if (s.PhaseIndex >= lvl.PhaseCount)
            {
                s.PhaseIndex = 0;
                foreach (var h in s.Heroes)
                {
                    h.Level++;
                    h.MaxHp = HeroMaxHp(h.Level);
                    h.Hp = h.MaxHp;
                    h.Luck = 20 + h.Level * 8;
                }
                s.LevelIndex++;
                if (s.LevelIndex >= Campaign.Length)
                {
                    s.LevelIndex = 0;
                    s.Status = "campaignCleared";
                }
                else
                {
                    s.Status = "levelCleared";
                }
            }
        }
        SpawnWave(s, rng);
    }

    private static void SpawnWave(GameState s, Random rng)
    {
        var lvl = Campaign[s.LevelIndex];
        var isBoss = s.PhaseIndex == lvl.PhaseCount - 1 && s.WaveIndex == lvl.WavesPerPhase - 1;
        var baseHp = (52 + s.LevelIndex * 20 + s.PhaseIndex * 12 + s.WaveIndex * 8) * lvl.HpScale;

        s.Enemies = new List<EnemyState>();
        if (isBoss)
        {
            s.Enemies.Add(new EnemyState
            {
                Id = $"e_{s.Tick}_boss",
                Kind = lvl.BossKind,
                MaxHp = baseHp * 3.6,
                Hp = baseHp * 3.6,
                IsBoss = true,
            });
        }
        else
        {
            for (var i = 0; i < lvl.EnemyCount; i++)
            {
                var kind = lvl.Kinds[rng.Next(lvl.Kinds.Length)];
                var hp = baseHp * (0.85 + rng.NextDouble() * 0.4);
                s.Enemies.Add(new EnemyState
                {
                    Id = $"e_{s.Tick}_{i}",
                    Kind = kind,
                    MaxHp = hp,
                    Hp = hp,
                });
            }
        }
    }

    // -- power --------------------------------------------------------------

    private static double HeroMaxHp(int level) => 180 + level * 34;

    private static double Offense(HeroState h)
    {
        var baseOffense = h.Archetype switch
        {
            "fury" => 24.0,
            "physical" => 22.0,
            "magic" => 22.0,
            "critDamage" => 16.0,
            "support" => 14.0,
            "defense" => 14.0,
            _ => 18.0,
        };
        return baseOffense * (1 + 0.12 * (h.Level - 1));
    }

    private static double CritFactor(string archetype, Random rng)
    {
        if (archetype == "critDamage")
        {
            return 1.8; // assassin: scales crit damage, big spikes
        }
        return rng.NextDouble() < 0.12 ? 1.6 : 1.0;
    }

    // -- projection ---------------------------------------------------------

    public static GameSnapshot ToSnapshot(GameState s)
    {
        var lvl = Campaign[Math.Clamp(s.LevelIndex, 0, Campaign.Length - 1)];
        var actingId = s.Reel.ActorIsHero ? s.Reel.ActorId : null;
        var hitEnemyId = s.Reel.ActorIsHero ? s.Reel.TargetId : null;

        return new GameSnapshot(
            Tick: s.Tick,
            LevelIndex: s.LevelIndex,
            LevelName: lvl.Name,
            Theme: lvl.Theme,
            PhaseIndex: s.PhaseIndex,
            PhaseCount: lvl.PhaseCount,
            WaveIndex: s.WaveIndex,
            WavesPerPhase: lvl.WavesPerPhase,
            Heroes: s.Heroes.Select(h => new HeroView(
                h.Id, h.Name, h.Archetype, h.Level,
                h.MaxHp <= 0 ? 0 : Math.Clamp(h.Hp / h.MaxHp, 0, 1),
                h.Hp > 0, h.Id == actingId)).ToList(),
            Enemies: s.Enemies.Select(e => new EnemyView(
                e.Id, e.Kind,
                e.MaxHp <= 0 ? 0 : Math.Clamp(e.Hp / e.MaxHp, 0, 1),
                e.Hp > 0, e.IsBoss, e.Id == hitEnemyId)).ToList(),
            Reel: new ReelView(
                s.Reel.Items.Select(it => new ReelItemView(
                    it.Kind, it.Shape, it.RarityTier, it.Rarity, it.Primary, it.Passives)).ToList(),
                s.Reel.Combo,
                s.Reel.Multiplier,
                s.Reel.MaxRarityTier,
                s.Reel.ActorIsHero),
            Outcome: s.Outcome,
            Status: s.Status);
    }
}

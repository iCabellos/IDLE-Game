using IdleRPG.Domain.Enums;
using IdleRPG.Domain.GameData;
using IdleRPG.Domain.ValueObjects;

namespace IdleRPG.Domain.Combat;

/// <summary>
/// Deterministic HSR-style turn-based battle simulator (F4).
///
/// Mechanics:
/// - Action-value timeline: a combatant with Speed S acts every 10000/S AV;
///   1 idle tick (1s) = 10 AV, so a speed-100 unit acts every ~10s.
/// - Skill points: the hero team shares a 5-point pool (starts at 3);
///   basic attacks generate 1 SP, skills consume 1 SP.
/// - Ultimates: each hero charges energy (basic +20, skill +30, hit taken
///   +10, kill +10) and fires their ultimate as a free action at turn start
///   when full.
/// - Toughness / weakness break: attacks matching an enemy weakness deplete
///   its toughness bar (basic 30 / skill 60 / ult 90). At zero the enemy is
///   Broken: it takes break damage, its next action is delayed and it takes
///   +25% damage until it recovers at the start of its next turn.
/// - Role AI: healers heal, supports buff, tanks hold aggro and dump excess
///   SP, DPS spend SP on skills and focus broken / weak targets.
/// </summary>
public static class CombatEngine
{
    public const float BaseActionValue = 10000f;
    public const float AvPerTick = 10f;

    public const int SkillPointsMax = 5;
    public const int SkillPointsStart = 3;

    public const float BasicToughnessDamage = 30f;
    public const float SkillToughnessDamage = 60f;
    public const float UltToughnessDamage = 90f;

    public const float BrokenDamageTakenMultiplier = 1.25f;
    public const float BreakActionDelayAv = 3000f;

    /// <summary>Battles that outlast this many AV are declared a defeat (stall guard).</summary>
    public const float MaxBattleAv = 15000f;

    /// <summary>
    /// HpRegen is an out-of-combat stat; in battle it only works at 10%
    /// effectiveness so sustain comes from the healer, not passive regen.
    /// </summary>
    public const float InCombatRegenFactor = 0.10f;

    private const float MinSpeed = 40f;

    public static BattleResult Simulate(
        IReadOnlyList<HeroSpec> heroes, IReadOnlyList<EnemySpec> enemies, int seed)
    {
        var rng = new Random(seed);
        var units = new List<Unit>(heroes.Count + enemies.Count);
        units.AddRange(heroes.Select(Unit.From));
        units.AddRange(enemies.Select(Unit.From));

        var ctx = new Battle(units, rng);

        while (ctx.ElapsedAv < MaxBattleAv && ctx.HeroesAlive && ctx.EnemiesAlive)
        {
            var actor = ctx.NextActor();
            ctx.ElapsedAv = actor.NextActionAv;

            if (!actor.Alive)
            {
                continue;
            }

            TakeTurn(ctx, actor);
            actor.ScheduleNext(ctx.ElapsedAv);
        }

        var heroUnits = ctx.Units.Where(u => u.IsHero).ToList();
        var alive = heroUnits.Where(u => u.Alive).ToList();

        return new BattleResult
        {
            Victory = ctx.HeroesAlive && !ctx.EnemiesAlive,
            ElapsedAv = ctx.ElapsedAv,
            Ticks = (int)MathF.Ceiling(ctx.ElapsedAv / AvPerTick),
            HeroActions = ctx.HeroActions,
            BasicsCast = ctx.BasicsCast,
            SkillsCast = ctx.SkillsCast,
            UltimatesCast = ctx.UltimatesCast,
            HealsCast = ctx.HealsCast,
            BuffsCast = ctx.BuffsCast,
            BreaksTriggered = ctx.BreaksTriggered,
            DamageDealtByHeroes = ctx.DamageDealtByHeroes,
            DamageTakenByHeroes = ctx.DamageTakenByHeroes,
            HeroesDown = heroUnits.Count - alive.Count,
            LowestHeroHpFraction = heroUnits.Count == alive.Count && alive.Count > 0
                ? alive.Min(u => u.Hp / u.MaxHp)
                : 0f,
        };
    }

    // -----------------------------------------------------------------
    // Turn resolution
    // -----------------------------------------------------------------

    private static void TakeTurn(Battle ctx, Unit actor)
    {
        actor.TickRegen(ctx.ElapsedAv);

        if (actor.IsHero)
        {
            ctx.HeroActions++;

            // Ultimate is a free action fired before the normal turn.
            if (actor.Energy >= actor.UltimateEnergyCost)
            {
                CastUltimate(ctx, actor);
            }

            if (ctx.EnemiesAlive)
            {
                HeroAction(ctx, actor);
            }
        }
        else
        {
            // A broken enemy spends its turn recovering its toughness bar.
            if (actor.Broken)
            {
                actor.RecoverToughness();
                return;
            }

            EnemyAction(ctx, actor);
        }
    }

    private static void HeroAction(Battle ctx, Unit actor)
    {
        switch (actor.Role)
        {
            case CharacterRole.Healer:
                var wounded = ctx.LowestHpAlly(below: 0.65f);
                if (wounded is not null && ctx.SkillPoints >= 1)
                {
                    ctx.SkillPoints--;
                    ctx.HealsCast++;
                    ctx.SkillsCast++;
                    // Mostly MagicPower-scaled: healing must not outgrow enemy
                    // damage at high level gaps or progression walls vanish.
                    Heal(actor, wounded, actor.SkillMultiplier * 1.2f, flatFraction: 0.02f);
                    actor.GainEnergy(30);
                    return;
                }

                break;

            case CharacterRole.Support:
                if (!ctx.TeamBuffActive(ctx.ElapsedAv) && ctx.SkillPoints >= 2)
                {
                    ctx.SkillPoints--;
                    ctx.BuffsCast++;
                    ctx.SkillsCast++;
                    ctx.ApplyTeamBuff(attackPct: 0.25f, untilAv: ctx.ElapsedAv + 15000f);
                    actor.GainEnergy(30);
                    return;
                }

                break;

            case CharacterRole.Tank:
                if (ctx.SkillPoints >= 4)
                {
                    // Defensive skill: moderate hit plus a self shield.
                    ctx.SkillPoints--;
                    ctx.SkillsCast++;
                    actor.Shield += actor.MaxHp * 0.20f;
                    Attack(ctx, actor, PickTarget(ctx, actor), actor.SkillMultiplier, SkillToughnessDamage);
                    actor.GainEnergy(30);
                    return;
                }

                break;

            case CharacterRole.DPS:
                if (ctx.SkillPoints >= 2)
                {
                    ctx.SkillPoints--;
                    ctx.SkillsCast++;
                    Attack(ctx, actor, PickTarget(ctx, actor), actor.SkillMultiplier, SkillToughnessDamage);
                    actor.GainEnergy(30);
                    return;
                }

                break;

            default: // Hybrid
                if (ctx.SkillPoints >= 3)
                {
                    ctx.SkillPoints--;
                    ctx.SkillsCast++;
                    Attack(ctx, actor, PickTarget(ctx, actor), actor.SkillMultiplier, SkillToughnessDamage);
                    actor.GainEnergy(30);
                    return;
                }

                break;
        }

        // Fallback for every role: basic attack, generates a skill point.
        ctx.SkillPoints = Math.Min(SkillPointsMax, ctx.SkillPoints + 1);
        ctx.BasicsCast++;
        Attack(ctx, actor, PickTarget(ctx, actor), actor.BasicMultiplier, BasicToughnessDamage);
        actor.GainEnergy(20);
    }

    private static void CastUltimate(Battle ctx, Unit actor)
    {
        ctx.UltimatesCast++;
        actor.Energy = 5; // small carry-over, HSR style

        switch (actor.Role)
        {
            case CharacterRole.Healer:
                foreach (var ally in ctx.Units.Where(u => u.IsHero && u.Alive))
                {
                    Heal(actor, ally, actor.UltimateMultiplier * 0.6f, flatFraction: 0.04f);
                }

                ctx.HealsCast++;
                return;

            case CharacterRole.Support:
                ctx.ApplyTeamBuff(attackPct: 0.40f, untilAv: ctx.ElapsedAv + 20000f);
                ctx.BuffsCast++;
                return;

            case CharacterRole.Tank:
                actor.Shield += actor.MaxHp * 0.30f;
                if (ctx.EnemiesAlive)
                {
                    Attack(ctx, actor, PickTarget(ctx, actor), actor.UltimateMultiplier, UltToughnessDamage);
                }

                return;

            default: // DPS / Hybrid: nuke the priority target, splash the rest.
                if (!ctx.EnemiesAlive)
                {
                    return;
                }

                var primary = PickTarget(ctx, actor);
                Attack(ctx, actor, primary, actor.UltimateMultiplier, UltToughnessDamage);
                foreach (var other in ctx.Units.Where(u => !u.IsHero && u.Alive && u != primary))
                {
                    Attack(ctx, actor, other, actor.UltimateMultiplier * 0.4f, UltToughnessDamage * 0.5f);
                }

                return;
        }
    }

    private static void EnemyAction(Battle ctx, Unit actor)
    {
        actor.ActionCount++;

        var isSkillTurn = actor.ActionCount % 3 == 0;

        if (isSkillTurn && actor.Archetype == EnemyArchetype.Boss)
        {
            // Boss AoE sweep.
            foreach (var hero in ctx.Units.Where(u => u.IsHero && u.Alive).ToList())
            {
                Attack(ctx, actor, hero, 1.2f, toughnessDamage: 0f);
            }

            return;
        }

        var target = ctx.PickHeroByAggro();
        if (target is null)
        {
            return;
        }

        Attack(ctx, actor, target, isSkillTurn ? 1.8f : 1.0f, toughnessDamage: 0f);
    }

    // -----------------------------------------------------------------
    // Targeting
    // -----------------------------------------------------------------

    private static Unit PickTarget(Battle ctx, Unit attacker)
    {
        var enemies = ctx.Units.Where(u => !u.IsHero && u.Alive).ToList();

        // 1. A broken enemy takes bonus damage — focus it down.
        var broken = enemies.Where(e => e.Broken).OrderBy(e => e.Hp).FirstOrDefault();
        if (broken is not null)
        {
            return broken;
        }

        // 2. Prefer targets weak to my element whose bar can still be broken.
        var breakable = enemies
            .Where(e => e.Toughness > 0f && e.Weaknesses.Contains(attacker.DamageType))
            .OrderBy(e => e.Hp)
            .FirstOrDefault();

        return breakable ?? enemies.OrderBy(e => e.Hp).First();
    }

    // -----------------------------------------------------------------
    // Damage / healing pipeline
    // -----------------------------------------------------------------

    private static void Attack(Battle ctx, Unit attacker, Unit target, float multiplier, float toughnessDamage)
    {
        if (!target.Alive)
        {
            return;
        }

        var raw = attacker.ScalingStat * multiplier * (1f + attacker.AttackBuffPct(ctx.ElapsedAv));
        var baseDamage = raw * (1f - CombatFormulas.DefenseReduction(target.Defense, attacker.Level));

        var crit = ctx.Rng.NextDouble() < attacker.CritRate;
        var effResist = CombatFormulas.EffectiveResistance(
            target.ResistTo(attacker.DamageType), attacker.PenetrationFor(attacker.DamageType));

        var final = CombatFormulas.FinalDamage(baseDamage, crit, attacker.CritMultiplier, effResist);
        final *= target.Broken ? BrokenDamageTakenMultiplier : 1f;
        final = MathF.Max(final, 1f);

        // Weakness break: only attacks matching a weakness chip toughness.
        if (!target.IsHero && !target.Broken && target.Toughness > 0f
            && target.Weaknesses.Contains(attacker.DamageType) && toughnessDamage > 0f)
        {
            target.Toughness -= toughnessDamage;
            if (target.Toughness <= 0f)
            {
                target.Toughness = 0f;
                target.Broken = true;
                target.NextActionAv += BreakActionDelayAv;
                ctx.BreaksTriggered++;

                final += CombatFormulas.BreakDamage(
                    attacker.Level, attacker.BreakEffect, target.MaxToughness);
            }
        }

        ApplyDamage(ctx, attacker, target, final);
    }

    private static void ApplyDamage(Battle ctx, Unit attacker, Unit target, float amount)
    {
        if (target.Shield > 0f)
        {
            var absorbed = MathF.Min(target.Shield, amount);
            target.Shield -= absorbed;
            amount -= absorbed;
        }

        target.Hp -= amount;

        if (attacker.IsHero)
        {
            ctx.DamageDealtByHeroes += amount;
        }
        else
        {
            ctx.DamageTakenByHeroes += amount;
        }

        if (target.IsHero)
        {
            target.GainEnergy(10);
        }

        if (target.Hp <= 0f)
        {
            target.Hp = 0f;
            if (attacker.IsHero)
            {
                attacker.GainEnergy(10);
            }
        }
    }

    private static void Heal(Unit healer, Unit target, float multiplier, float flatFraction)
    {
        var amount = healer.ScalingStat * multiplier + target.MaxHp * flatFraction;
        target.Hp = MathF.Min(target.MaxHp, target.Hp + amount);
    }

    // -----------------------------------------------------------------
    // Internal battle state
    // -----------------------------------------------------------------

    private sealed class Battle
    {
        public Battle(List<Unit> units, Random rng)
        {
            Units = units;
            Rng = rng;
            SkillPoints = SkillPointsStart;

            foreach (var unit in units)
            {
                unit.AttachBattle(this);
                unit.ScheduleNext(0f);
            }
        }

        public List<Unit> Units { get; }
        public Random Rng { get; }
        public float ElapsedAv { get; set; }
        public int SkillPoints { get; set; }

        public int HeroActions { get; set; }
        public int BasicsCast { get; set; }
        public int SkillsCast { get; set; }
        public int UltimatesCast { get; set; }
        public int HealsCast { get; set; }
        public int BuffsCast { get; set; }
        public int BreaksTriggered { get; set; }
        public float DamageDealtByHeroes { get; set; }
        public float DamageTakenByHeroes { get; set; }

        private float _teamBuffPct;
        private float _teamBuffUntilAv;

        public bool HeroesAlive => Units.Any(u => u.IsHero && u.Alive);
        public bool EnemiesAlive => Units.Any(u => !u.IsHero && u.Alive);

        public Unit NextActor()
        {
            Unit? next = null;
            foreach (var unit in Units)
            {
                if (unit.Alive && (next is null || unit.NextActionAv < next.NextActionAv))
                {
                    next = unit;
                }
            }

            return next!;
        }

        public Unit? LowestHpAlly(float below)
        {
            Unit? worst = null;
            foreach (var unit in Units)
            {
                if (unit.IsHero && unit.Alive && unit.Hp / unit.MaxHp < below
                    && (worst is null || unit.Hp / unit.MaxHp < worst.Hp / worst.MaxHp))
                {
                    worst = unit;
                }
            }

            return worst;
        }

        public bool TeamBuffActive(float nowAv) => _teamBuffPct > 0f && nowAv < _teamBuffUntilAv;

        public void ApplyTeamBuff(float attackPct, float untilAv)
        {
            _teamBuffPct = attackPct;
            _teamBuffUntilAv = untilAv;
        }

        public float TeamBuffPct(float nowAv) => TeamBuffActive(nowAv) ? _teamBuffPct : 0f;

        public Unit? PickHeroByAggro()
        {
            var heroes = Units.Where(u => u.IsHero && u.Alive).ToList();
            if (heroes.Count == 0)
            {
                return null;
            }

            var total = heroes.Sum(h => h.Aggro);
            var roll = (float)(Rng.NextDouble() * total);
            foreach (var hero in heroes)
            {
                roll -= hero.Aggro;
                if (roll <= 0f)
                {
                    return hero;
                }
            }

            return heroes[^1];
        }
    }

    private sealed class Unit
    {
        private Battle? _battle;

        public required string Name { get; init; }
        public required bool IsHero { get; init; }
        public required int Level { get; init; }
        public required CharacterStats Stats { get; init; }
        public required CharacterRole Role { get; init; }
        public required DamageType DamageType { get; init; }
        public required IReadOnlyList<DamageType> Weaknesses { get; init; }
        public required float MaxToughness { get; init; }
        public required bool ScalesWithMagic { get; init; }
        public required float BasicMultiplier { get; init; }
        public required float SkillMultiplier { get; init; }
        public required float UltimateMultiplier { get; init; }
        public required int UltimateEnergyCost { get; init; }
        public required float Aggro { get; init; }
        public EnemyArchetype? Archetype { get; init; }

        public float Hp { get; set; }
        public float Shield { get; set; }
        public int Energy { get; set; }
        public float Toughness { get; set; }
        public bool Broken { get; set; }
        public float NextActionAv { get; set; }
        public int ActionCount { get; set; }

        private float _lastRegenAv;

        public bool Alive => Hp > 0f;
        public float MaxHp => MathF.Max(Stats.MaxHp, 1f);
        public float Defense => Stats.Defense;
        public float CritRate => Stats.CritRate;
        public float CritMultiplier => MathF.Max(Stats.CritMultiplier, 1f);
        public float BreakEffect => Stats.BreakEffect;
        public float Speed => MathF.Max(Stats.Speed, MinSpeed);
        public float ScalingStat => ScalesWithMagic ? Stats.MagicPower : Stats.Attack;

        public void ScheduleNext(float nowAv) => NextActionAv = nowAv + BaseActionValue / Speed;

        public void GainEnergy(int amount) => Energy = Math.Min(Energy + amount, 200);

        public void RecoverToughness()
        {
            Toughness = MaxToughness;
            Broken = false;
        }

        public void TickRegen(float nowAv)
        {
            if (IsHero && Stats.HpRegen > 0f && Alive)
            {
                var ticks = (nowAv - _lastRegenAv) / AvPerTick;
                Hp = MathF.Min(MaxHp, Hp + Stats.HpRegen * ticks * InCombatRegenFactor);
            }

            _lastRegenAv = nowAv;
        }

        public float AttackBuffPct(float nowAv) =>
            IsHero && _battle is not null ? _battle.TeamBuffPct(nowAv) : 0f;

        public float ResistTo(DamageType type) => type switch
        {
            DamageType.Physical => Stats.ResistPhysical,
            DamageType.Fire => Stats.ResistFire,
            DamageType.Ice => Stats.ResistIce,
            DamageType.Lightning => Stats.ResistLightning,
            _ => Stats.ResistPoison,
        };

        public float PenetrationFor(DamageType type) =>
            type == DamageType.Physical ? Stats.PenPhysical : Stats.PenMagic;

        public void AttachBattle(Battle battle) => _battle = battle;

        public static Unit From(HeroSpec hero)
        {
            var kit = ClassKits.For(hero.Class);
            return new Unit
            {
                Name = hero.Name,
                IsHero = true,
                Level = hero.Level,
                Stats = hero.Stats,
                Role = hero.Role,
                DamageType = kit.DamageType,
                Weaknesses = Array.Empty<DamageType>(),
                MaxToughness = 0f,
                ScalesWithMagic = kit.ScalesWithMagic,
                BasicMultiplier = kit.BasicMultiplier,
                SkillMultiplier = kit.SkillMultiplier,
                UltimateMultiplier = kit.UltimateMultiplier,
                UltimateEnergyCost = kit.UltimateEnergyCost,
                Aggro = hero.Role switch
                {
                    CharacterRole.Tank => 4.0f,
                    CharacterRole.Healer => 0.8f,
                    CharacterRole.Support => 0.8f,
                    CharacterRole.Hybrid => 1.2f,
                    _ => 1.0f,
                },
                Hp = MathF.Max(hero.Stats.MaxHp, 1f),
            };
        }

        public static Unit From(EnemySpec enemy) => new()
        {
            Name = enemy.Name,
            IsHero = false,
            Level = enemy.Level,
            Stats = enemy.Stats,
            Role = CharacterRole.DPS,
            DamageType = enemy.DamageType,
            Weaknesses = enemy.Weaknesses,
            MaxToughness = enemy.Toughness,
            ScalesWithMagic = false,
            BasicMultiplier = 1.0f,
            SkillMultiplier = 1.8f,
            UltimateMultiplier = 0f,
            UltimateEnergyCost = int.MaxValue,
            Aggro = 1f,
            Archetype = enemy.Archetype,
            Hp = MathF.Max(enemy.Stats.MaxHp, 1f),
            Toughness = enemy.Toughness,
        };
    }
}

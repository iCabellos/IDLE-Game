using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace IdleRPG.Infrastructure.Persistence.Seed;

/// <summary>
/// Seeds a deterministic "preview" user with a three-hero team so the public
/// game-state endpoint has real, per-user data to advance. Idempotent.
/// </summary>
public static class GameSeed
{
    public static readonly Guid PreviewUserId = SeedIds.From("user:preview");

    public static async Task SeedAsync(AppDbContext context, CancellationToken ct = default)
    {
        var exists = await context.Users.IgnoreQueryFilters().AnyAsync(u => u.Id == PreviewUserId, ct);
        if (exists)
        {
            return;
        }

        var now = DateTimeOffset.UtcNow;
        context.Users.Add(new User
        {
            Id = PreviewUserId,
            SteamId = "00000000000000001",
            Username = "Preview Hero",
            AvatarUrl = string.Empty,
            AccountLevel = 1,
            Status = AccountStatus.Active,
            CreatedAt = now,
            UpdatedAt = now,
            LastLoginAt = now,
        });

        var team = new (string Name, CharacterClass Class, CharacterRole Role)[]
        {
            ("Sir Cinder", CharacterClass.Warrior, CharacterRole.Tank),
            ("Lyra Vex", CharacterClass.Mage, CharacterRole.DPS),
            ("Fenn Wilde", CharacterClass.Ranger, CharacterRole.DPS),
        };

        for (var i = 0; i < team.Length; i++)
        {
            var (name, klass, role) = team[i];
            context.Characters.Add(new Character
            {
                Id = SeedIds.From($"character:preview:{i}"),
                UserId = PreviewUserId,
                Name = name,
                Class = klass,
                Role = role,
                Level = 1,
                TeamSlot = i,
                IsActive = true,
                CreatedAt = now,
                UpdatedAt = now,
            });
        }

        await context.SaveChangesAsync(ct);
    }
}

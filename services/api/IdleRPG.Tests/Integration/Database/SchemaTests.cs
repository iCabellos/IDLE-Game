using FluentAssertions;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using IdleRPG.Infrastructure.Persistence;
using IdleRPG.Infrastructure.Persistence.Seed;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace IdleRPG.Tests.Integration.Database;

[Trait("Phase", "F2")]
[Collection("Integration")]
public class SchemaTests : ApiTestBase
{
    private AppDbContext NewContext(out IServiceScope scope)
    {
        scope = Factory.Services.CreateScope();
        return scope.ServiceProvider.GetRequiredService<AppDbContext>();
    }

    [Fact]
    public async Task All_core_tables_exist()
    {
        using var _ = NewContext(out var scope);
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var tables = await db.Database
            .SqlQueryRaw<string>(
                "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
            .ToListAsync();

        tables.Should().Contain(new[]
        {
            "users", "characters", "items", "item_instances", "refresh_tokens", "anti_bot_events",
        });
    }

    [Fact]
    public async Task Updated_at_triggers_exist()
    {
        using var _ = NewContext(out var scope);
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var triggers = await db.Database
            .SqlQueryRaw<string>(
                "SELECT tgname FROM pg_trigger WHERE NOT tgisinternal")
            .ToListAsync();

        triggers.Should().Contain(new[]
        {
            "trg_users_updated_at", "trg_characters_updated_at", "trg_item_instances_updated_at",
        });
    }

    [Fact]
    public async Task Unique_steam_inventory_index_rejects_duplicates()
    {
        using var _ = NewContext(out var scope);
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var user = new User { Id = Guid.NewGuid(), SteamId = "76561197960287930", Username = "Owner" };
        db.Users.Add(user);
        var item = ItemSeed.BuildItems()[0];
        item.Id = Guid.NewGuid();
        item.SteamMarketHashName = $"unique-{item.Id}";
        db.Items.Add(item);
        await db.SaveChangesAsync();

        ItemInstance MakeInstance() => new()
        {
            Id = Guid.NewGuid(),
            ItemId = item.Id,
            OwnerId = user.Id,
            SteamInventoryId = "DUPLICATE-INV-ID",
            RolledRarity = ItemRarity.Common,
        };

        db.ItemInstances.Add(MakeInstance());
        await db.SaveChangesAsync();

        db.ItemInstances.Add(MakeInstance());
        var act = async () => await db.SaveChangesAsync();

        await act.Should().ThrowAsync<DbUpdateException>();
    }

    [Fact]
    public async Task Check_constraint_rejects_invalid_risk_score()
    {
        using var _ = NewContext(out var scope);
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        db.Users.Add(new User
        {
            Id = Guid.NewGuid(),
            SteamId = "76561197960287931",
            Username = "Bad",
            AntiBotRiskScore = 250, // violates BETWEEN 0 AND 100
        });

        var act = async () => await db.SaveChangesAsync();
        await act.Should().ThrowAsync<DbUpdateException>();
    }

    [Fact]
    public async Task Soft_deleted_rows_are_filtered_out()
    {
        using var _ = NewContext(out var scope);
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var user = new User
        {
            Id = Guid.NewGuid(),
            SteamId = "76561197960287932",
            Username = "Ghost",
            DeletedAt = DateTimeOffset.UtcNow,
        };
        db.Users.Add(user);
        await db.SaveChangesAsync();

        // The global query filter should hide the soft-deleted row.
        var found = await db.Users.FirstOrDefaultAsync(u => u.Id == user.Id);
        found.Should().BeNull();

        var foundIgnoringFilters = await db.Users
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(u => u.Id == user.Id);
        foundIgnoringFilters.Should().NotBeNull();
    }

    [Fact]
    public async Task Seeder_populates_item_catalogue_and_ironclad_set()
    {
        using var _ = NewContext(out var scope);
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        await DbSeeder.SeedAsync(Factory.Services);

        var items = await db.Items.ToListAsync();
        items.Count.Should().BeGreaterThanOrEqualTo(20);

        var ironclad = items.Where(i => i.SetId == ItemSeed.IroncladSetId).ToList();
        ironclad.Should().HaveCount(4);
        ironclad.Should().OnlyContain(i => i.CharacterRestriction == CharacterClass.Warrior);
        items.Should().OnlyContain(i => !string.IsNullOrEmpty(i.SteamMarketHashName));
    }

    [Fact]
    public async Task Seeder_is_idempotent()
    {
        using var _ = NewContext(out var scope);
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        await DbSeeder.SeedAsync(Factory.Services);
        var firstCount = await db.Items.CountAsync();

        await DbSeeder.SeedAsync(Factory.Services);
        var secondCount = await db.Items.CountAsync();

        secondCount.Should().Be(firstCount);
    }
}

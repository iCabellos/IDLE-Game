using FluentAssertions;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.ValueObjects;
using IdleRPG.Infrastructure.Persistence;
using IdleRPG.Infrastructure.Persistence.Seed;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace IdleRPG.Tests.Integration.Database;

[Trait("Phase", "F3")]
[Collection("Integration")]
public class SetBonusSchemaTests : ApiTestBase
{
    private AppDbContext NewContext(out IServiceScope scope)
    {
        scope = Factory.Services.CreateScope();
        return scope.ServiceProvider.GetRequiredService<AppDbContext>();
    }

    [Fact]
    public async Task Items_set_bonuses_table_exists()
    {
        using var _ = NewContext(out var scope);
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var tables = await db.Database
            .SqlQueryRaw<string>(
                "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
            .ToListAsync();

        tables.Should().Contain("items_set_bonuses");
    }

    [Fact]
    public async Task Seeder_populates_ironclad_set_bonuses()
    {
        using var _ = NewContext(out var scope);
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        await DbSeeder.SeedAsync(Factory.Services);

        var bonuses = await db.SetBonuses
            .Where(b => b.SetId == ItemSeed.IroncladSetId)
            .ToListAsync();

        bonuses.Should().HaveCount(2);
        bonuses.Select(b => b.PiecesRequired).Should().BeEquivalentTo(new[] { 2, 4 });

        var fourPiece = SetBonusPayload.Parse(
            bonuses.Single(b => b.PiecesRequired == 4).StatBonusesJson);
        fourPiece.Passives.Should().ContainSingle(p => p.Name == "Unbreakable");
    }

    [Fact]
    public async Task Set_bonus_threshold_uniqueness_is_enforced()
    {
        using var _ = NewContext(out var scope);
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        await DbSeeder.SeedAsync(Factory.Services);

        // A second (2-piece) threshold for the Ironclad set must be rejected.
        db.SetBonuses.Add(new SetBonus
        {
            Id = Guid.NewGuid(),
            SetId = ItemSeed.IroncladSetId,
            PiecesRequired = 2,
            StatBonusesJson = "{}",
        });

        var act = async () => await db.SaveChangesAsync();
        await act.Should().ThrowAsync<DbUpdateException>();
    }

    [Fact]
    public async Task Set_bonus_seeder_is_idempotent()
    {
        using var _ = NewContext(out var scope);
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        await DbSeeder.SeedAsync(Factory.Services);
        var first = await db.SetBonuses.CountAsync();

        await DbSeeder.SeedAsync(Factory.Services);
        var second = await db.SetBonuses.CountAsync();

        second.Should().Be(first);
    }
}

using FluentAssertions;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using IdleRPG.Infrastructure.Items;
using IdleRPG.Tests.Application;

namespace IdleRPG.Tests.Application.Items;

[Trait("Category", "ItemEngine")]
public sealed class ItemValidatorTests
{
    private static ItemValidator BuildValidator(
        FakeSteamInventoryService steam, FakeCacheService cache)
        // Zero backoff keeps retry tests fast.
        => new(steam, cache, _ => TimeSpan.Zero);

    [Fact]
    public async Task Ownership_succeeds_when_steam_confirms()
    {
        var steam = new FakeSteamInventoryService { Owns = true };
        var cache = new FakeCacheService();
        var validator = BuildValidator(steam, cache);

        var result = await validator.ValidateSteamOwnershipAsync("steam-1", "asset-1");

        result.IsValid.Should().BeTrue();
    }

    [Fact]
    public async Task Ownership_fails_when_steam_denies()
    {
        var steam = new FakeSteamInventoryService { Owns = false };
        var validator = BuildValidator(steam, new FakeCacheService());

        var result = await validator.ValidateSteamOwnershipAsync("steam-1", "asset-1");

        result.IsValid.Should().BeFalse();
    }

    [Fact]
    public async Task Ownership_result_is_cached()
    {
        var steam = new FakeSteamInventoryService { Owns = true };
        var cache = new FakeCacheService();
        var validator = BuildValidator(steam, cache);

        await validator.ValidateSteamOwnershipAsync("steam-1", "asset-1");
        await validator.ValidateSteamOwnershipAsync("steam-1", "asset-1");

        // Second call served from cache: Steam is only hit once.
        steam.Calls.Should().Be(1);
        cache.Store.Should().ContainKey("steam:owns:steam-1:asset-1");
    }

    [Fact]
    public async Task Ownership_retries_then_succeeds()
    {
        var attempts = 0;
        var steam = new FakeSteamInventoryService
        {
            Behavior = () =>
            {
                attempts++;
                if (attempts < 3)
                {
                    throw new HttpRequestException("transient");
                }
                return Task.FromResult(true);
            },
        };
        var validator = BuildValidator(steam, new FakeCacheService());

        var result = await validator.ValidateSteamOwnershipAsync("steam-1", "asset-1");

        result.IsValid.Should().BeTrue();
        attempts.Should().Be(3);
    }

    [Fact]
    public async Task Ownership_fails_after_exhausting_retries()
    {
        var steam = new FakeSteamInventoryService
        {
            Behavior = () => throw new HttpRequestException("down"),
        };
        var validator = BuildValidator(steam, new FakeCacheService());

        var result = await validator.ValidateSteamOwnershipAsync("steam-1", "asset-1");

        result.IsValid.Should().BeFalse();
        steam.Calls.Should().Be(3);
    }

    [Fact]
    public void Slot_compatibility_accepts_matching_slot()
    {
        var validator = BuildValidator(new FakeSteamInventoryService(), new FakeCacheService());
        var character = new Character { Class = CharacterClass.Warrior };
        var item = new Item { Name = "Helm", Slot = ItemSlot.Head };

        validator.ValidateSlotCompatibility(character, item, ItemSlot.Head).IsValid.Should().BeTrue();
    }

    [Fact]
    public void Slot_compatibility_rejects_mismatched_slot()
    {
        var validator = BuildValidator(new FakeSteamInventoryService(), new FakeCacheService());
        var character = new Character { Class = CharacterClass.Warrior };
        var item = new Item { Name = "Helm", Slot = ItemSlot.Head };

        validator.ValidateSlotCompatibility(character, item, ItemSlot.Chest).IsValid.Should().BeFalse();
    }

    [Fact]
    public void Restriction_blocks_other_classes()
    {
        var validator = BuildValidator(new FakeSteamInventoryService(), new FakeCacheService());
        var character = new Character { Class = CharacterClass.Mage };
        var item = new Item { Name = "Ironclad Helm", CharacterRestriction = CharacterClass.Warrior };

        validator.ValidateCharacterRestriction(character, item).IsValid.Should().BeFalse();
    }

    [Fact]
    public void Restriction_allows_matching_class_and_unrestricted_items()
    {
        var validator = BuildValidator(new FakeSteamInventoryService(), new FakeCacheService());
        var warrior = new Character { Class = CharacterClass.Warrior };

        validator.ValidateCharacterRestriction(
            warrior, new Item { CharacterRestriction = CharacterClass.Warrior }).IsValid.Should().BeTrue();
        validator.ValidateCharacterRestriction(
            warrior, new Item { CharacterRestriction = null }).IsValid.Should().BeTrue();
    }
}

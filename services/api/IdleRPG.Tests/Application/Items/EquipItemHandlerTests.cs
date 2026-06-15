using FluentAssertions;
using IdleRPG.Application.Common.Exceptions;
using IdleRPG.Application.Services;
using IdleRPG.Application.UseCases.Items.EquipItem;
using IdleRPG.Application.UseCases.Items.UnequipItem;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Enums;
using IdleRPG.Infrastructure.Items;
using IdleRPG.Tests.Application;

namespace IdleRPG.Tests.Application.Items;

[Trait("Category", "ItemEngine")]
public sealed class EquipItemHandlerTests
{
    private sealed class Harness
    {
        public Guid UserId { get; } = Guid.NewGuid();
        public Character Character { get; }
        public InMemoryRepository<Character> Characters { get; } = new(c => c.Id);
        public InMemoryRepository<Item> Items { get; } = new(i => i.Id);
        public InMemoryRepository<ItemInstance> Instances { get; } = new(i => i.Id);
        public FakeSteamInventoryService Steam { get; } = new() { Owns = true };
        public FakeCacheService Cache { get; } = new();
        public FakeCurrentUserService CurrentUser { get; }

        public Harness(CharacterClass cls = CharacterClass.Warrior)
        {
            Character = new Character
            {
                Id = Guid.NewGuid(),
                UserId = UserId,
                Class = cls,
                Level = 1,
                Name = "Hero",
                Role = CharacterRole.Tank,
            };
            Characters.Items.Add(Character);
            CurrentUser = new FakeCurrentUserService { UserId = UserId, SteamId = "steam-1" };
        }

        public Item AddItem(ItemSlot slot, CharacterClass? restriction = null)
        {
            var item = new Item { Id = Guid.NewGuid(), Name = $"{slot} item", Slot = slot, CharacterRestriction = restriction };
            Items.Items.Add(item);
            return item;
        }

        public ItemInstance AddInstance(Item def, Guid? ownerId = null, ItemSlot? equippedSlot = null)
        {
            var instance = new ItemInstance
            {
                Id = Guid.NewGuid(),
                ItemId = def.Id,
                OwnerId = ownerId ?? UserId,
                SteamInventoryId = $"asset-{Guid.NewGuid():N}",
                Item = def,
                EquippedToCharacterId = equippedSlot is null ? null : Character.Id,
                EquippedSlot = equippedSlot,
            };
            Instances.Items.Add(instance);
            return instance;
        }

        public EquipItemHandler BuildEquip()
        {
            var validator = new ItemValidator(Steam, Cache, _ => TimeSpan.Zero);
            var stats = new CharacterStatsService(
                Instances, new SetBonusCalculator(Array.Empty<SetBonus>()), new StatAggregator(), Cache);
            return new EquipItemHandler(
                CurrentUser, Characters, Instances, Items, validator, stats, new FakeUnitOfWork());
        }

        public UnequipItemHandler BuildUnequip()
        {
            var stats = new CharacterStatsService(
                Instances, new SetBonusCalculator(Array.Empty<SetBonus>()), new StatAggregator(), Cache);
            return new UnequipItemHandler(CurrentUser, Characters, Instances, stats, new FakeUnitOfWork());
        }
    }

    [Fact]
    public async Task Equip_assigns_slot_and_character()
    {
        var h = new Harness();
        var def = h.AddItem(ItemSlot.MainHand);
        var instance = h.AddInstance(def);

        var result = await h.BuildEquip().Handle(
            new EquipItemCommand(h.Character.Id, instance.Id, ItemSlot.MainHand), CancellationToken.None);

        result.CharacterId.Should().Be(h.Character.Id);
        instance.EquippedToCharacterId.Should().Be(h.Character.Id);
        instance.EquippedSlot.Should().Be(ItemSlot.MainHand);
        h.Cache.Store.Should().ContainKey($"stats:{h.Character.Id}");
    }

    [Fact]
    public async Task Equip_evicts_existing_item_in_same_slot()
    {
        var h = new Harness();
        var def = h.AddItem(ItemSlot.Head);
        var existing = h.AddInstance(def, equippedSlot: ItemSlot.Head);
        var incoming = h.AddInstance(def);

        await h.BuildEquip().Handle(
            new EquipItemCommand(h.Character.Id, incoming.Id, ItemSlot.Head), CancellationToken.None);

        existing.EquippedToCharacterId.Should().BeNull();
        existing.EquippedSlot.Should().BeNull();
        incoming.EquippedSlot.Should().Be(ItemSlot.Head);
    }

    [Fact]
    public async Task Equip_two_hander_evicts_main_and_off_hand()
    {
        var h = new Harness();
        var main = h.AddInstance(h.AddItem(ItemSlot.MainHand), equippedSlot: ItemSlot.MainHand);
        var off = h.AddInstance(h.AddItem(ItemSlot.OffHand), equippedSlot: ItemSlot.OffHand);
        var twoHander = h.AddInstance(h.AddItem(ItemSlot.TwoHand));

        await h.BuildEquip().Handle(
            new EquipItemCommand(h.Character.Id, twoHander.Id, ItemSlot.TwoHand), CancellationToken.None);

        main.EquippedToCharacterId.Should().BeNull();
        off.EquippedToCharacterId.Should().BeNull();
        twoHander.EquippedSlot.Should().Be(ItemSlot.TwoHand);
    }

    [Fact]
    public async Task Equip_main_hand_evicts_two_hander()
    {
        var h = new Harness();
        var twoHander = h.AddInstance(h.AddItem(ItemSlot.TwoHand), equippedSlot: ItemSlot.TwoHand);
        var main = h.AddInstance(h.AddItem(ItemSlot.MainHand));

        await h.BuildEquip().Handle(
            new EquipItemCommand(h.Character.Id, main.Id, ItemSlot.MainHand), CancellationToken.None);

        twoHander.EquippedToCharacterId.Should().BeNull();
        main.EquippedSlot.Should().Be(ItemSlot.MainHand);
    }

    [Fact]
    public async Task Equip_fails_when_steam_ownership_denied()
    {
        var h = new Harness();
        h.Steam.Owns = false;
        var instance = h.AddInstance(h.AddItem(ItemSlot.MainHand));

        var act = () => h.BuildEquip().Handle(
            new EquipItemCommand(h.Character.Id, instance.Id, ItemSlot.MainHand), CancellationToken.None);

        await act.Should().ThrowAsync<DomainValidationException>();
    }

    [Fact]
    public async Task Equip_fails_on_slot_mismatch()
    {
        var h = new Harness();
        var instance = h.AddInstance(h.AddItem(ItemSlot.Head));

        var act = () => h.BuildEquip().Handle(
            new EquipItemCommand(h.Character.Id, instance.Id, ItemSlot.Chest), CancellationToken.None);

        await act.Should().ThrowAsync<DomainValidationException>();
    }

    [Fact]
    public async Task Equip_fails_on_class_restriction()
    {
        var h = new Harness(CharacterClass.Mage);
        var instance = h.AddInstance(h.AddItem(ItemSlot.Head, restriction: CharacterClass.Warrior));

        var act = () => h.BuildEquip().Handle(
            new EquipItemCommand(h.Character.Id, instance.Id, ItemSlot.Head), CancellationToken.None);

        await act.Should().ThrowAsync<DomainValidationException>();
    }

    [Fact]
    public async Task Equip_fails_when_instance_not_owned()
    {
        var h = new Harness();
        var instance = h.AddInstance(h.AddItem(ItemSlot.Head), ownerId: Guid.NewGuid());

        var act = () => h.BuildEquip().Handle(
            new EquipItemCommand(h.Character.Id, instance.Id, ItemSlot.Head), CancellationToken.None);

        await act.Should().ThrowAsync<ForbiddenException>();
    }

    [Fact]
    public async Task Equip_fails_when_character_missing()
    {
        var h = new Harness();
        var instance = h.AddInstance(h.AddItem(ItemSlot.Head));

        var act = () => h.BuildEquip().Handle(
            new EquipItemCommand(Guid.NewGuid(), instance.Id, ItemSlot.Head), CancellationToken.None);

        await act.Should().ThrowAsync<NotFoundException>();
    }

    [Fact]
    public async Task Unequip_clears_slot_and_character()
    {
        var h = new Harness();
        var instance = h.AddInstance(h.AddItem(ItemSlot.Head), equippedSlot: ItemSlot.Head);

        await h.BuildUnequip().Handle(
            new UnequipItemCommand(h.Character.Id, instance.Id), CancellationToken.None);

        instance.EquippedToCharacterId.Should().BeNull();
        instance.EquippedSlot.Should().BeNull();
    }

    [Fact]
    public async Task Unequip_fails_when_item_not_equipped_here()
    {
        var h = new Harness();
        var instance = h.AddInstance(h.AddItem(ItemSlot.Head));

        var act = () => h.BuildUnequip().Handle(
            new UnequipItemCommand(h.Character.Id, instance.Id), CancellationToken.None);

        await act.Should().ThrowAsync<DomainValidationException>();
    }
}

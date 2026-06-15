using IdleRPG.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace IdleRPG.Infrastructure.Persistence.Configurations;

public sealed class ItemInstanceConfiguration : IEntityTypeConfiguration<ItemInstance>
{
    public void Configure(EntityTypeBuilder<ItemInstance> builder)
    {
        builder.ToTable("item_instances");
        builder.HasKey(i => i.Id);

        builder.Property(i => i.SteamInventoryId).HasMaxLength(64);
        builder.Property(i => i.RolledRarity).HasConversion<int>();
        builder.Property(i => i.RolledStatsJson).HasColumnType("jsonb");
        builder.Property(i => i.EquippedSlot).HasConversion<int?>();

        builder.HasIndex(i => i.OwnerId);
        builder.HasIndex(i => i.ItemId);
        builder.HasIndex(i => i.EquippedToCharacterId);

        builder.HasOne(i => i.Item)
            .WithMany()
            .HasForeignKey(i => i.ItemId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(i => i.Owner)
            .WithMany()
            .HasForeignKey(i => i.OwnerId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

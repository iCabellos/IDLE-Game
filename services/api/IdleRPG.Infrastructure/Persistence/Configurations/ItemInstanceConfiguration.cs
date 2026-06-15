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

        builder.Property(i => i.SteamInventoryId).IsRequired().HasMaxLength(32);
        builder.Property(i => i.RolledRarity).HasColumnType("smallint");
        builder.Property(i => i.RolledStatsJson).HasColumnType("jsonb").HasDefaultValueSql("'{}'");
        builder.Property(i => i.EquippedSlot).HasColumnType("smallint");
        builder.Property(i => i.IsListedOnMarket).HasDefaultValue(false);
        builder.Property(i => i.AcquiredAt).HasDefaultValueSql("now()");
        builder.Property(i => i.UpdatedAt).HasDefaultValueSql("now()");

        builder.HasIndex(i => i.SteamInventoryId)
            .HasDatabaseName("idx_item_instances_steam")
            .IsUnique();
        builder.HasIndex(i => i.OwnerId).HasDatabaseName("idx_item_instances_owner");
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

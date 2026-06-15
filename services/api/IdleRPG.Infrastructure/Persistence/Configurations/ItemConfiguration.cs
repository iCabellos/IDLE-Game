using IdleRPG.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace IdleRPG.Infrastructure.Persistence.Configurations;

public sealed class ItemConfiguration : IEntityTypeConfiguration<Item>
{
    public void Configure(EntityTypeBuilder<Item> builder)
    {
        builder.ToTable("items");
        builder.HasKey(i => i.Id);

        builder.Property(i => i.Name).IsRequired().HasMaxLength(128);
        builder.Property(i => i.Description).HasMaxLength(1024);
        builder.Property(i => i.Class).HasConversion<int>();
        builder.Property(i => i.BaseRarity).HasConversion<int>();
        builder.Property(i => i.Slot).HasConversion<int>();
        builder.Property(i => i.CharacterRestriction).HasConversion<int?>();
        builder.Property(i => i.BaseStatsJson).HasColumnType("jsonb");
        builder.Property(i => i.PassivesJson).HasColumnType("jsonb");
        builder.Property(i => i.SteamMarketHashName).HasMaxLength(256);

        builder.HasIndex(i => i.Name);
        builder.HasIndex(i => i.SetId);
    }
}

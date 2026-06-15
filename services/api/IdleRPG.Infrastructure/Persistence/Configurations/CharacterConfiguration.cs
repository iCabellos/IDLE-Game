using IdleRPG.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace IdleRPG.Infrastructure.Persistence.Configurations;

public sealed class CharacterConfiguration : IEntityTypeConfiguration<Character>
{
    public void Configure(EntityTypeBuilder<Character> builder)
    {
        builder.ToTable("characters");
        builder.HasKey(c => c.Id);

        builder.Property(c => c.Name).IsRequired().HasMaxLength(64);
        builder.Property(c => c.Class).HasConversion<int>();
        builder.Property(c => c.Role).HasConversion<int>();
        builder.Property(c => c.StatsJson).HasColumnType("jsonb");

        builder.HasIndex(c => c.UserId);

        builder.HasMany(c => c.EquippedItems)
            .WithOne(i => i.EquippedToCharacter!)
            .HasForeignKey(i => i.EquippedToCharacterId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasQueryFilter(c => c.DeletedAt == null);
    }
}

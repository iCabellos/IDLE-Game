using IdleRPG.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace IdleRPG.Infrastructure.Persistence.Configurations;

public sealed class CharacterConfiguration : IEntityTypeConfiguration<Character>
{
    public void Configure(EntityTypeBuilder<Character> builder)
    {
        builder.ToTable("characters", t =>
        {
            t.HasCheckConstraint("ck_characters_level", "level BETWEEN 1 AND 1000");
            t.HasCheckConstraint("ck_characters_team_slot", "team_slot BETWEEN 0 AND 3");
        });

        builder.HasKey(c => c.Id);

        builder.Property(c => c.Name).IsRequired().HasMaxLength(32);
        builder.Property(c => c.Class).HasColumnType("smallint");
        builder.Property(c => c.Role).HasColumnType("smallint");
        builder.Property(c => c.Level).HasDefaultValue(1);
        builder.Property(c => c.Experience).HasDefaultValue(0L);
        builder.Property(c => c.TeamSlot).HasColumnType("smallint").HasDefaultValue(0);
        builder.Property(c => c.IsActive).HasDefaultValue(true);
        builder.Property(c => c.StatsJson).HasColumnType("jsonb").HasDefaultValueSql("'{}'");

        builder.Property(c => c.CreatedAt).HasDefaultValueSql("now()");
        builder.Property(c => c.UpdatedAt).HasDefaultValueSql("now()");

        builder.HasIndex(c => c.UserId)
            .HasDatabaseName("idx_characters_user_id")
            .HasFilter("deleted_at IS NULL");

        builder.HasMany(c => c.EquippedItems)
            .WithOne(i => i.EquippedToCharacter!)
            .HasForeignKey(i => i.EquippedToCharacterId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasQueryFilter(c => c.DeletedAt == null);
    }
}

using IdleRPG.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace IdleRPG.Infrastructure.Persistence.Configurations;

public sealed class SetBonusConfiguration : IEntityTypeConfiguration<SetBonus>
{
    public void Configure(EntityTypeBuilder<SetBonus> builder)
    {
        builder.ToTable("items_set_bonuses", t =>
            t.HasCheckConstraint("ck_items_set_bonuses_pieces", "pieces_required >= 1"));

        builder.HasKey(b => b.Id);

        builder.Property(b => b.SetId).IsRequired();
        builder.Property(b => b.PiecesRequired).HasColumnType("smallint");
        builder.Property(b => b.StatBonusesJson).HasColumnType("jsonb").HasDefaultValueSql("'{}'");

        builder.HasIndex(b => new { b.SetId, b.PiecesRequired }).IsUnique();
    }
}

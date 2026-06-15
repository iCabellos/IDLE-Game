using IdleRPG.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace IdleRPG.Infrastructure.Persistence.Configurations;

public sealed class AntiBotEventConfiguration : IEntityTypeConfiguration<AntiBotEvent>
{
    public void Configure(EntityTypeBuilder<AntiBotEvent> builder)
    {
        builder.ToTable("anti_bot_events");
        builder.HasKey(e => e.Id);

        builder.Property(e => e.EventType).HasColumnType("smallint");
        builder.Property(e => e.ActionTaken).HasColumnType("smallint").HasDefaultValue(Domain.Enums.AntiBotRiskLevel.Normal);
        builder.Property(e => e.MetadataJson).HasColumnType("jsonb").HasDefaultValueSql("'{}'");
        builder.Property(e => e.CreatedAt).HasDefaultValueSql("now()");

        builder.HasIndex(e => new { e.UserId, e.CreatedAt })
            .HasDatabaseName("idx_antibot_user_created")
            .IsDescending(false, true);

        builder.HasOne(e => e.User)
            .WithMany()
            .HasForeignKey(e => e.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

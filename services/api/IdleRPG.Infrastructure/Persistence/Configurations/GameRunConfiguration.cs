using IdleRPG.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace IdleRPG.Infrastructure.Persistence.Configurations;

public sealed class GameRunConfiguration : IEntityTypeConfiguration<GameRun>
{
    public void Configure(EntityTypeBuilder<GameRun> builder)
    {
        builder.ToTable("game_runs");

        builder.HasKey(r => r.Id);

        builder.Property(r => r.LevelIndex).HasDefaultValue(0);
        builder.Property(r => r.PhaseIndex).HasDefaultValue(0);
        builder.Property(r => r.WaveIndex).HasDefaultValue(0);
        builder.Property(r => r.TickCount).HasDefaultValue(0L);
        builder.Property(r => r.StateJson).HasColumnType("jsonb").HasDefaultValueSql("'{}'");

        builder.Property(r => r.CreatedAt).HasDefaultValueSql("now()");
        builder.Property(r => r.UpdatedAt).HasDefaultValueSql("now()");

        // One run per user.
        builder.HasIndex(r => r.UserId)
            .IsUnique()
            .HasDatabaseName("idx_game_runs_user_id");

        builder.HasOne(r => r.User)
            .WithMany()
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

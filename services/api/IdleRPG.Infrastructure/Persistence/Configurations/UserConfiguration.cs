using IdleRPG.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace IdleRPG.Infrastructure.Persistence.Configurations;

public sealed class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("users", t =>
        {
            t.HasCheckConstraint("ck_users_account_level", "account_level >= 1");
            t.HasCheckConstraint("ck_users_risk_score", "risk_score BETWEEN 0 AND 100");
        });

        builder.HasKey(u => u.Id);

        builder.Property(u => u.SteamId).IsRequired().HasMaxLength(20);
        builder.HasIndex(u => u.SteamId).IsUnique();

        builder.Property(u => u.Username).IsRequired().HasMaxLength(64);
        builder.Property(u => u.AvatarUrl);
        builder.Property(u => u.Email).HasMaxLength(256);
        builder.Property(u => u.BanReason);

        builder.Property(u => u.AccountLevel).HasDefaultValue(1);
        builder.Property(u => u.Status).HasColumnType("smallint").HasDefaultValue(Domain.Enums.AccountStatus.Active);
        builder.Property(u => u.AntiBotRiskScore).HasColumnName("risk_score").HasDefaultValue(0);
        builder.Property(u => u.IsBanned).HasDefaultValue(false);

        builder.Property(u => u.CreatedAt).HasDefaultValueSql("now()");
        builder.Property(u => u.UpdatedAt).HasDefaultValueSql("now()");
        builder.Property(u => u.LastLoginAt).HasDefaultValueSql("now()");

        builder.HasMany(u => u.Characters)
            .WithOne(c => c.User!)
            .HasForeignKey(c => c.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Soft-delete filter.
        builder.HasQueryFilter(u => u.DeletedAt == null);
    }
}

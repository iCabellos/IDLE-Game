using IdleRPG.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace IdleRPG.Infrastructure.Persistence.Configurations;

public sealed class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("users");
        builder.HasKey(u => u.Id);

        builder.Property(u => u.SteamId).IsRequired().HasMaxLength(32);
        builder.HasIndex(u => u.SteamId).IsUnique();

        builder.Property(u => u.Username).IsRequired().HasMaxLength(128);
        builder.Property(u => u.AvatarUrl).HasMaxLength(512);
        builder.Property(u => u.Email).HasMaxLength(256);
        builder.Property(u => u.BanReason).HasMaxLength(512);

        builder.Property(u => u.Status).HasConversion<int>();

        builder.HasMany(u => u.Characters)
            .WithOne(c => c.User!)
            .HasForeignKey(c => c.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Soft-delete filter.
        builder.HasQueryFilter(u => u.DeletedAt == null);
    }
}

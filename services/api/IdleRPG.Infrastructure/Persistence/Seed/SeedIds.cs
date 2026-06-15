using System.Security.Cryptography;
using System.Text;

namespace IdleRPG.Infrastructure.Persistence.Seed;

/// <summary>
/// Produces stable, deterministic GUIDs from a name so seed data keeps the same
/// ids across runs (making the seeder idempotent).
/// </summary>
internal static class SeedIds
{
    public static Guid From(string name)
    {
        var hash = MD5.HashData(Encoding.UTF8.GetBytes("idlerpg-seed:" + name));
        return new Guid(hash);
    }
}

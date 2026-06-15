using System.Text.Json;
using System.Text.Json.Serialization;

namespace IdleRPG.Domain.ValueObjects;

/// <summary>
/// The per-instance, rolled payload stored in
/// <see cref="IdleRPG.Domain.Entities.ItemInstance.RolledStatsJson"/>: the
/// concrete rolled stat values plus the passives selected from the item
/// definition's pool.
/// </summary>
public sealed record RolledItemData(
    IReadOnlyDictionary<string, float> Stats,
    IReadOnlyList<Passive> Passives)
{
    public RolledItemData() : this(new Dictionary<string, float>(), Array.Empty<Passive>())
    {
    }

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = null,
        DefaultIgnoreCondition = JsonIgnoreCondition.Never,
    };

    /// <summary>Serializes to the JSON shape stored on the instance.</summary>
    public static string Serialize(RolledItemData data) =>
        JsonSerializer.Serialize(data, JsonOptions);

    /// <summary>
    /// Parses an <see cref="IdleRPG.Domain.Entities.ItemInstance.RolledStatsJson"/>
    /// value. Tolerates the legacy/simple shape where the JSON is a bare
    /// stat dictionary (no passives) by treating it as stats-only.
    /// </summary>
    public static RolledItemData Parse(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return new RolledItemData();
        }

        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;

        // Structured shape: { "Stats": {...}, "Passives": [...] }
        if (root.ValueKind == JsonValueKind.Object &&
            (root.TryGetProperty("Stats", out _) || root.TryGetProperty("Passives", out _)))
        {
            return JsonSerializer.Deserialize<RolledItemData>(json, JsonOptions)
                   ?? new RolledItemData();
        }

        // Legacy/simple shape: a bare stat dictionary.
        var stats = JsonSerializer.Deserialize<Dictionary<string, float>>(json, JsonOptions)
                    ?? new Dictionary<string, float>();
        return new RolledItemData(stats, Array.Empty<Passive>());
    }
}

using System.Text.Json;

namespace IdleRPG.Domain.ValueObjects;

/// <summary>
/// The deserialized contents of <see cref="IdleRPG.Domain.Entities.SetBonus.StatBonusesJson"/>:
/// the stat modifiers and passives granted when the set threshold is reached.
/// </summary>
public sealed record SetBonusPayload(
    IReadOnlyList<StatModifier> Modifiers,
    IReadOnlyList<Passive> Passives)
{
    public SetBonusPayload() : this(Array.Empty<StatModifier>(), Array.Empty<Passive>())
    {
    }

    public static string Serialize(SetBonusPayload payload) => JsonSerializer.Serialize(payload);

    public static SetBonusPayload Parse(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return new SetBonusPayload();
        }

        return JsonSerializer.Deserialize<SetBonusPayload>(json) ?? new SetBonusPayload();
    }
}

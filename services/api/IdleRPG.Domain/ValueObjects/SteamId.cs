namespace IdleRPG.Domain.ValueObjects;

/// <summary>
/// A validated Steam 64-bit community id. Steam64 ids are 17-digit numbers
/// in the 7656119... range.
/// </summary>
public readonly record struct SteamId
{
    public string Value { get; }

    private SteamId(string value) => Value = value;

    public static SteamId Create(string value)
    {
        if (!TryCreate(value, out var steamId))
        {
            throw new ArgumentException($"'{value}' is not a valid Steam64 id.", nameof(value));
        }

        return steamId;
    }

    public static bool TryCreate(string? value, out SteamId steamId)
    {
        steamId = default;

        if (string.IsNullOrWhiteSpace(value))
        {
            return false;
        }

        var trimmed = value.Trim();

        // Steam64 ids are 17-digit numerics beginning with 7656119.
        if (trimmed.Length != 17 || !trimmed.All(char.IsDigit))
        {
            return false;
        }

        if (!ulong.TryParse(trimmed, out _))
        {
            return false;
        }

        steamId = new SteamId(trimmed);
        return true;
    }

    public override string ToString() => Value;

    public static implicit operator string(SteamId steamId) => steamId.Value;
}

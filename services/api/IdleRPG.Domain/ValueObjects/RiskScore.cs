using IdleRPG.Domain.Enums;

namespace IdleRPG.Domain.ValueObjects;

/// <summary>
/// Anti-bot risk score, always clamped to the 0-100 range. Maps to an
/// <see cref="AntiBotRiskLevel"/> per the thresholds in Section F6.
/// </summary>
public readonly record struct RiskScore
{
    public const int Min = 0;
    public const int Max = 100;

    public int Value { get; }

    public RiskScore(int value) => Value = Math.Clamp(value, Min, Max);

    public static RiskScore Zero => new(0);

    public RiskScore Apply(int delta) => new(Value + delta);

    public AntiBotRiskLevel Level => Value switch
    {
        <= 20 => AntiBotRiskLevel.Normal,
        <= 40 => AntiBotRiskLevel.SilentMonitor,
        <= 60 => AntiBotRiskLevel.VisibleWarning,
        <= 70 => AntiBotRiskLevel.GameplayRestrict,
        <= 80 => AntiBotRiskLevel.MarketRestrict,
        <= 90 => AntiBotRiskLevel.TempSuspension,
        _ => AntiBotRiskLevel.PermanentBan
    };

    public override string ToString() => Value.ToString();

    public static implicit operator int(RiskScore score) => score.Value;
}

using IdleRPG.Domain.Enums;

namespace IdleRPG.Domain.Entities;

/// <summary>
/// An audit record of an anti-bot signal: the event type, the risk-score delta
/// it applied, the resulting score and any action taken.
/// </summary>
public class AntiBotEvent
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }

    public BotEventType EventType { get; set; }

    /// <summary>Change applied to the user's risk score (positive or negative).</summary>
    public int RiskDelta { get; set; }

    /// <summary>The user's resulting risk score after applying the delta.</summary>
    public int NewScore { get; set; }

    /// <summary>The enforcement action taken, mapped to <see cref="AntiBotRiskLevel"/>.</summary>
    public AntiBotRiskLevel ActionTaken { get; set; } = AntiBotRiskLevel.Normal;

    public string MetadataJson { get; set; } = "{}";

    public DateTimeOffset CreatedAt { get; set; }

    // Navigation
    public User? User { get; set; }
}

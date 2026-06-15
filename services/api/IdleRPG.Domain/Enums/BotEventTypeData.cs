namespace IdleRPG.Domain.Enums;

/// <summary>
/// Risk-score deltas applied when each <see cref="BotEventType"/> is recorded.
/// Values are taken from Section 2 / F6 of the implementation plan.
/// </summary>
public static class BotEventTypeData
{
    private static readonly IReadOnlyDictionary<BotEventType, int> Deltas =
        new Dictionary<BotEventType, int>
        {
            [BotEventType.AbnormalRequestFrequency] = 8,
            [BotEventType.OwnershipValidationFail] = 12,
            [BotEventType.SuspiciousSession] = 10,
            [BotEventType.ExcessiveSteamSync] = 6,
            [BotEventType.TimestampManipulation] = 15,
            [BotEventType.ImpossibleDropPattern] = 18,
            [BotEventType.MultipleIpSession] = 5,
            [BotEventType.VpnDetected] = 3
        };

    public static int Delta(BotEventType type) => Deltas[type];
}

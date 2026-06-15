namespace IdleRPG.Domain.Enums;

/// <summary>
/// Anti-bot event types. The associated risk-score delta is defined in
/// <see cref="BotEventTypeData"/>.
/// </summary>
public enum BotEventType
{
    AbnormalRequestFrequency = 1, // delta:+8
    OwnershipValidationFail = 2,  // delta:+12
    SuspiciousSession = 3,        // delta:+10
    ExcessiveSteamSync = 4,       // delta:+6
    TimestampManipulation = 5,    // delta:+15
    ImpossibleDropPattern = 6,    // delta:+18
    MultipleIpSession = 7,        // delta:+5
    VpnDetected = 8               // delta:+3
}

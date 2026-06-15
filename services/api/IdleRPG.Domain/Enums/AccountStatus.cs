namespace IdleRPG.Domain.Enums;

/// <summary>
/// Account moderation status. Serialized to UserDto as the lowercase
/// string: active | warned | restricted | banned.
/// </summary>
public enum AccountStatus
{
    Active = 1,
    Warned = 2,
    Restricted = 3,
    Banned = 4
}

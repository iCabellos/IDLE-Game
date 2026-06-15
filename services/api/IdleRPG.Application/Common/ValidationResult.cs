namespace IdleRPG.Application.Common;

/// <summary>Lightweight success/failure result with an optional error reason.</summary>
public sealed record ValidationResult(bool IsValid, string? Error = null)
{
    public static ValidationResult Success() => new(true);

    public static ValidationResult Fail(string error) => new(false, error);
}

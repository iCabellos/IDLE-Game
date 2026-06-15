namespace IdleRPG.Application.Common.Exceptions;

/// <summary>
/// Thrown when a domain rule (e.g. slot compatibility, class restriction,
/// Steam ownership) rejects an operation.
/// </summary>
public sealed class DomainValidationException : Exception
{
    public DomainValidationException(string message) : base(message)
    {
    }
}

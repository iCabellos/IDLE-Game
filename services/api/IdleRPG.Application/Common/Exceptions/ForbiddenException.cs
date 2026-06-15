namespace IdleRPG.Application.Common.Exceptions;

/// <summary>Thrown when the current user may not act on the target resource.</summary>
public sealed class ForbiddenException : Exception
{
    public ForbiddenException(string message) : base(message)
    {
    }
}

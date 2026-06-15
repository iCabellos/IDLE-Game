namespace IdleRPG.Application.Common.Exceptions;

/// <summary>Thrown when authentication fails (invalid OpenID, expired token, etc.).</summary>
public sealed class AuthenticationException : Exception
{
    public AuthenticationException(string message) : base(message)
    {
    }
}

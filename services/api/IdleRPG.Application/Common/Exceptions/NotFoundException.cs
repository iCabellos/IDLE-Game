namespace IdleRPG.Application.Common.Exceptions;

/// <summary>Thrown when a requested entity does not exist.</summary>
public sealed class NotFoundException : Exception
{
    public NotFoundException(string message) : base(message)
    {
    }
}

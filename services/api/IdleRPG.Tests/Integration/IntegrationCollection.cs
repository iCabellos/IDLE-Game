using Xunit;

namespace IdleRPG.Tests.Integration;

/// <summary>
/// Integration tests share process-global environment variables for container
/// connection strings, so they must not run in parallel with one another.
/// </summary>
[CollectionDefinition("Integration", DisableParallelization = true)]
public sealed class IntegrationCollection
{
}

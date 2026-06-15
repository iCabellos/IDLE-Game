using System.Globalization;
using IdleRPG.Application.Common.Exceptions;
using IdleRPG.Application.DTOs.Items;
using IdleRPG.Domain.Entities;
using IdleRPG.Domain.Interfaces;
using IdleRPG.Domain.ValueObjects;
using MediatR;

namespace IdleRPG.Application.UseCases.Items.CompareItems;

public sealed class CompareItemsHandler : IRequestHandler<CompareItemsQuery, ItemComparisonDto>
{
    private readonly ICurrentUserService _currentUser;
    private readonly IRepository<ItemInstance> _instances;

    public CompareItemsHandler(ICurrentUserService currentUser, IRepository<ItemInstance> instances)
    {
        _currentUser = currentUser;
        _instances = instances;
    }

    public async Task<ItemComparisonDto> Handle(CompareItemsQuery request, CancellationToken ct)
    {
        if (_currentUser.UserId is not { } userId)
        {
            throw new AuthenticationException("Not authenticated.");
        }

        var a = await Load(request.InstanceId1, userId, ct);
        var b = await Load(request.InstanceId2, userId, ct);

        var statsA = RolledItemData.Parse(a.RolledStatsJson).Stats;
        var statsB = RolledItemData.Parse(b.RolledStatsJson).Stats;

        var scoreA = statsA.Values.Sum();
        var scoreB = statsB.Values.Sum();

        // The better item is the higher-scoring one; ties report no winner.
        if (Math.Abs(scoreA - scoreB) < 0.001f)
        {
            return new ItemComparisonDto
            {
                BetterItem = null,
                Improvements = new[] { "The two items are roughly equivalent." },
            };
        }

        var betterIsA = scoreA > scoreB;
        var better = betterIsA ? a : b;
        var betterStats = betterIsA ? statsA : statsB;
        var worseStats = betterIsA ? statsB : statsA;

        return new ItemComparisonDto
        {
            BetterItem = better.Id,
            Improvements = BuildImprovements(betterStats, worseStats),
        };
    }

    private async Task<ItemInstance> Load(Guid id, Guid userId, CancellationToken ct)
    {
        var instance = await _instances.GetByIdAsync(id, ct)
            ?? throw new NotFoundException($"Item instance {id} not found.");
        if (instance.OwnerId != userId)
        {
            throw new ForbiddenException("Item instance does not belong to the current user.");
        }

        return instance;
    }

    /// <summary>
    /// Descriptive, percentage-based deltas (no absolute stat numbers), e.g.
    /// "Attack +23%" and "Better for crits".
    /// </summary>
    private static IReadOnlyList<string> BuildImprovements(
        IReadOnlyDictionary<string, float> better,
        IReadOnlyDictionary<string, float> worse)
    {
        var improvements = new List<string>();

        foreach (var (stat, value) in better)
        {
            var other = worse.GetValueOrDefault(stat);
            if (value <= other)
            {
                continue;
            }

            if (other <= 0f)
            {
                improvements.Add($"Adds {stat}");
            }
            else
            {
                var pct = (value - other) / other * 100f;
                improvements.Add($"{stat} +{pct.ToString("0", CultureInfo.InvariantCulture)}%");
            }
        }

        if (better.GetValueOrDefault(nameof(CharacterStats.CritRate)) >
            worse.GetValueOrDefault(nameof(CharacterStats.CritRate)))
        {
            improvements.Add("Better for crits");
        }

        if (improvements.Count == 0)
        {
            improvements.Add("Marginally better overall");
        }

        return improvements;
    }
}

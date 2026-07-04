using IdleRPG.Application.Common.Exceptions;
using IdleRPG.Application.DTOs.Combat;
using IdleRPG.Application.Interfaces.Combat;
using IdleRPG.Domain.GameData;
using IdleRPG.Domain.Interfaces;
using MediatR;

namespace IdleRPG.Application.UseCases.Combat.GetZones;

public sealed class GetZonesHandler : IRequestHandler<GetZonesQuery, IReadOnlyList<ZoneDto>>
{
    private readonly ICurrentUserService _currentUser;
    private readonly IIdleStateStore _stateStore;

    public GetZonesHandler(ICurrentUserService currentUser, IIdleStateStore stateStore)
    {
        _currentUser = currentUser;
        _stateStore = stateStore;
    }

    public async Task<IReadOnlyList<ZoneDto>> Handle(GetZonesQuery request, CancellationToken ct)
    {
        if (_currentUser.UserId is not { } userId)
        {
            throw new AuthenticationException("Not authenticated.");
        }

        var state = await _stateStore.GetAsync(userId, ct);
        var currentZone = state?.Zone ?? 1;

        // Cleared zones, the current one and a two-zone preview.
        var zones = new List<ZoneDto>();
        for (var z = 1; z <= currentZone + 2; z++)
        {
            zones.Add(new ZoneDto
            {
                Zone = z,
                Name = EnemyCatalog.ZoneName(z),
                Status = z < currentZone ? "cleared" : z == currentZone ? "current" : "locked",
            });
        }

        return zones;
    }
}

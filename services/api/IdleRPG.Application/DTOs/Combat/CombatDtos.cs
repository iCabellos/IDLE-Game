namespace IdleRPG.Application.DTOs.Combat;

/// <summary>
/// Readable idle-combat status. UX RULE: NEVER expose raw stat numbers —
/// only the readable states (winning / danger / stuck / rewards_ready /
/// steam_desynced) and descriptive text. Progression labels (zone, wave,
/// level) are allowed; damage/HP/XP amounts are not.
/// </summary>
public record CombatStateDto
{
    public string ZoneName { get; init; } = string.Empty;
    public int Zone { get; init; }
    public string WaveText { get; init; } = string.Empty; // e.g. "7/10"
    public bool BossWave { get; init; }

    /// <summary>winning | danger | stuck | rewards_ready | steam_desynced.</summary>
    public string Status { get; init; } = string.Empty;
    public string StatusText { get; init; } = string.Empty;

    public bool RewardsReady { get; init; }
    public IReadOnlyList<string> RewardSummary { get; init; } = Array.Empty<string>();

    public IReadOnlyList<TeamMemberDto> Team { get; init; } = Array.Empty<TeamMemberDto>();
    public EnemyPreviewDto EnemyPreview { get; init; } = new();
}

public record TeamMemberDto
{
    public Guid CharacterId { get; init; }
    public string Name { get; init; } = string.Empty;
    public string Class { get; init; } = string.Empty;
    public string Role { get; init; } = string.Empty;
    public int Level { get; init; }
    public string Element { get; init; } = string.Empty;
}

/// <summary>What the team is currently fighting — names and weaknesses only.</summary>
public record EnemyPreviewDto
{
    public IReadOnlyList<string> Enemies { get; init; } = Array.Empty<string>();
    public IReadOnlyList<string> Weaknesses { get; init; } = Array.Empty<string>();
}

/// <summary>Result of claiming pending idle rewards (descriptive, non-numeric).</summary>
public record ClaimRewardsResultDto
{
    public bool ClaimedAnything { get; init; }
    public IReadOnlyList<string> Highlights { get; init; } = Array.Empty<string>();
    public IReadOnlyList<TeamMemberDto> Team { get; init; } = Array.Empty<TeamMemberDto>();
}

/// <summary>A zone entry for the zone list.</summary>
public record ZoneDto
{
    public int Zone { get; init; }
    public string Name { get; init; } = string.Empty;

    /// <summary>cleared | current | locked.</summary>
    public string Status { get; init; } = string.Empty;
}

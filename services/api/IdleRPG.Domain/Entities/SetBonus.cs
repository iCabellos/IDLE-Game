namespace IdleRPG.Domain.Entities;

/// <summary>
/// A threshold-based set bonus (items_set_bonuses): when at least
/// <see cref="PiecesRequired"/> pieces of <see cref="SetId"/> are equipped the
/// bonuses described by <see cref="StatBonusesJson"/> apply.
/// </summary>
public class SetBonus
{
    public Guid Id { get; set; }
    public Guid SetId { get; set; }
    public int PiecesRequired { get; set; }

    /// <summary>
    /// JSON: { "modifiers": [ {"Stat","Value","Type"} ], "passives": [ {"Name","Modifiers":[...]} ] }
    /// </summary>
    public string StatBonusesJson { get; set; } = "{}";
}

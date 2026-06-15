using FluentValidation;

namespace IdleRPG.Application.UseCases.Items.EquipItem;

public sealed class EquipItemValidator : AbstractValidator<EquipItemCommand>
{
    public EquipItemValidator()
    {
        RuleFor(x => x.CharacterId).NotEmpty();
        RuleFor(x => x.ItemInstanceId).NotEmpty();
        RuleFor(x => x.TargetSlot).IsInEnum();
    }
}

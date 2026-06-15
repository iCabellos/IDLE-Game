using FluentValidation;

namespace IdleRPG.Application.UseCases.Items.UnequipItem;

public sealed class UnequipItemValidator : AbstractValidator<UnequipItemCommand>
{
    public UnequipItemValidator()
    {
        RuleFor(x => x.CharacterId).NotEmpty();
        RuleFor(x => x.ItemInstanceId).NotEmpty();
    }
}

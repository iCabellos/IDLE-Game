using FluentValidation;

namespace IdleRPG.Application.UseCases.Auth.SteamLogin;

public sealed class SteamLoginValidator : AbstractValidator<SteamLoginCommand>
{
    public SteamLoginValidator()
    {
        RuleFor(x => x.OpenIdPayload)
            .NotEmpty().WithMessage("The OpenID callback payload is required.");
    }
}

using FluentValidation;
using IdleRPG.Application.Common.Exceptions;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace IdleRPG.API.Middleware;

/// <summary>
/// Catches unhandled exceptions and returns a consistent ProblemDetails response.
/// </summary>
public class GlobalExceptionHandler : IExceptionHandler
{
    private readonly ILogger<GlobalExceptionHandler> _logger;

    public GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger)
    {
        _logger = logger;
    }

    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        var problemDetails = MapException(exception, httpContext, out var logAsError);

        if (logAsError)
        {
            _logger.LogError(exception, "Unhandled exception processing {Method} {Path}",
                httpContext.Request.Method, httpContext.Request.Path);
        }
        else
        {
            _logger.LogWarning("Handled {Type} on {Method} {Path}: {Message}",
                exception.GetType().Name, httpContext.Request.Method,
                httpContext.Request.Path, exception.Message);
        }

        httpContext.Response.StatusCode = problemDetails.Status!.Value;

        await httpContext.Response.WriteAsJsonAsync(problemDetails, cancellationToken);

        return true;
    }

    private static ProblemDetails MapException(Exception exception, HttpContext context, out bool logAsError)
    {
        switch (exception)
        {
            case ValidationException validation:
                logAsError = false;
                var problem = new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Validation failed",
                    Detail = "One or more validation errors occurred.",
                    Instance = context.Request.Path,
                };
                problem.Extensions["errors"] = validation.Errors
                    .GroupBy(e => e.PropertyName)
                    .ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).ToArray());
                return problem;

            case AuthenticationException auth:
                logAsError = false;
                return new ProblemDetails
                {
                    Status = StatusCodes.Status401Unauthorized,
                    Title = "Authentication failed",
                    Detail = auth.Message,
                    Instance = context.Request.Path,
                };

            default:
                logAsError = true;
                return new ProblemDetails
                {
                    Status = StatusCodes.Status500InternalServerError,
                    Title = "An unexpected error occurred",
                    Detail = "The server encountered an unexpected error. Please try again later.",
                    Instance = context.Request.Path,
                };
        }
    }
}

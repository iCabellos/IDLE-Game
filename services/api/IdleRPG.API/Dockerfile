# ---------------------------------------------------------------------
# Build stage
# ---------------------------------------------------------------------
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy solution + project files first for restore layer caching.
COPY IdleRPG.sln ./
COPY IdleRPG.Domain/IdleRPG.Domain.csproj IdleRPG.Domain/
COPY IdleRPG.Application/IdleRPG.Application.csproj IdleRPG.Application/
COPY IdleRPG.Infrastructure/IdleRPG.Infrastructure.csproj IdleRPG.Infrastructure/
COPY IdleRPG.API/IdleRPG.API.csproj IdleRPG.API/
COPY IdleRPG.Tests/IdleRPG.Tests.csproj IdleRPG.Tests/

RUN dotnet restore IdleRPG.API/IdleRPG.API.csproj

# Copy the rest of the source and publish.
COPY . .
RUN dotnet publish IdleRPG.API/IdleRPG.API.csproj -c Release -o /app/publish /p:UseAppHost=false

# ---------------------------------------------------------------------
# Runtime stage
# ---------------------------------------------------------------------
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish ./

# Logs directory (Serilog rolling file sink writes here).
RUN mkdir -p /app/logs

EXPOSE 5000
ENV ASPNETCORE_URLS=http://+:5000

ENTRYPOINT ["dotnet", "IdleRPG.API.dll"]

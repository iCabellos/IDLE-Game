# IdleRPG monorepo Makefile
# ---------------------------------------------------------------------
COMPOSE       := docker compose -f infra/docker/docker-compose.yml
API_DIR       := services/api
API_PROJECT   := $(API_DIR)/IdleRPG.API/IdleRPG.API.csproj
INFRA_PROJECT := $(API_DIR)/IdleRPG.Infrastructure/IdleRPG.Infrastructure.csproj
MOBILE_DIR    := apps/mobile

.PHONY: help dev down test-all test-api test-flutter build db-migrate db-reset clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

dev: ## Start the full stack (postgres, redis, api, pgadmin)
	$(COMPOSE) up --build -d
	@echo "Waiting for services to become healthy..."
	$(COMPOSE) ps

down: ## Stop the stack
	$(COMPOSE) down

test-all: test-api ## Run all test suites (api + flutter if available)
	@if command -v flutter >/dev/null 2>&1; then \
		$(MAKE) test-flutter; \
	else \
		echo "flutter not installed - skipping flutter tests"; \
	fi

test-api: ## Run .NET test suite
	cd $(API_DIR) && dotnet test

test-flutter: ## Run Flutter test suite
	cd $(MOBILE_DIR) && flutter test

build: ## Build the .NET solution in Release
	cd $(API_DIR) && dotnet build -c Release

db-migrate: ## Apply EF Core migrations
	cd $(API_DIR) && dotnet ef database update \
		--project IdleRPG.Infrastructure --startup-project IdleRPG.API

db-reset: ## Drop and recreate the database, then migrate + seed
	cd $(API_DIR) && dotnet ef database drop --force \
		--project IdleRPG.Infrastructure --startup-project IdleRPG.API
	$(MAKE) db-migrate

clean: ## Remove build artifacts and stop the stack
	cd $(API_DIR) && dotnet clean || true
	$(COMPOSE) down -v || true
	find . -type d \( -name bin -o -name obj \) -prune -exec rm -rf {} + 2>/dev/null || true

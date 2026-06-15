using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace IdleRPG.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class InitialSchema : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "items",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    description = table.Column<string>(type: "character varying(1024)", maxLength: 1024, nullable: false),
                    @class = table.Column<short>(name: "class", type: "smallint", nullable: false),
                    base_rarity = table.Column<short>(type: "smallint", nullable: false),
                    slot = table.Column<short>(type: "smallint", nullable: false),
                    character_restriction = table.Column<short>(type: "smallint", nullable: true),
                    set_id = table.Column<Guid>(type: "uuid", nullable: true),
                    base_stats_json = table.Column<string>(type: "jsonb", nullable: false, defaultValueSql: "'{}'"),
                    passives_json = table.Column<string>(type: "jsonb", nullable: false, defaultValueSql: "'[]'"),
                    is_unique = table.Column<bool>(type: "boolean", nullable: false),
                    is_seasonal = table.Column<bool>(type: "boolean", nullable: false),
                    steam_market_hash_name = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: true),
                    is_tradeable = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_items", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "users",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    steam_id = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    username = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    avatar_url = table.Column<string>(type: "text", nullable: false),
                    email = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: true),
                    account_level = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    status = table.Column<short>(type: "smallint", nullable: false, defaultValue: (short)1),
                    risk_score = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    is_banned = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    banned_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    ban_reason = table.Column<string>(type: "text", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    last_login_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    deleted_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_users", x => x.id);
                    table.CheckConstraint("ck_users_account_level", "account_level >= 1");
                    table.CheckConstraint("ck_users_risk_score", "risk_score BETWEEN 0 AND 100");
                });

            migrationBuilder.CreateTable(
                name: "anti_bot_events",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    event_type = table.Column<short>(type: "smallint", nullable: false),
                    risk_delta = table.Column<int>(type: "integer", nullable: false),
                    new_score = table.Column<int>(type: "integer", nullable: false),
                    action_taken = table.Column<short>(type: "smallint", nullable: false, defaultValue: (short)0),
                    metadata_json = table.Column<string>(type: "jsonb", nullable: false, defaultValueSql: "'{}'"),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_anti_bot_events", x => x.id);
                    table.ForeignKey(
                        name: "fk_anti_bot_events_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "characters",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    @class = table.Column<short>(name: "class", type: "smallint", nullable: false),
                    role = table.Column<short>(type: "smallint", nullable: false),
                    level = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    experience = table.Column<long>(type: "bigint", nullable: false, defaultValue: 0L),
                    team_slot = table.Column<short>(type: "smallint", nullable: false, defaultValue: (short)0),
                    is_active = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    stats_json = table.Column<string>(type: "jsonb", nullable: false, defaultValueSql: "'{}'"),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    deleted_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_characters", x => x.id);
                    table.CheckConstraint("ck_characters_level", "level BETWEEN 1 AND 1000");
                    table.CheckConstraint("ck_characters_team_slot", "team_slot BETWEEN 0 AND 3");
                    table.ForeignKey(
                        name: "fk_characters_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "refresh_tokens",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    token_hash = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    expires_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    revoked_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_refresh_tokens", x => x.id);
                    table.ForeignKey(
                        name: "fk_refresh_tokens_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "item_instances",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    item_id = table.Column<Guid>(type: "uuid", nullable: false),
                    owner_id = table.Column<Guid>(type: "uuid", nullable: false),
                    steam_inventory_id = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    rolled_rarity = table.Column<short>(type: "smallint", nullable: false),
                    rolled_stats_json = table.Column<string>(type: "jsonb", nullable: false, defaultValueSql: "'{}'"),
                    acquired_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    equipped_to_character_id = table.Column<Guid>(type: "uuid", nullable: true),
                    equipped_slot = table.Column<short>(type: "smallint", nullable: true),
                    is_listed_on_market = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    last_steam_validation = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_item_instances", x => x.id);
                    table.ForeignKey(
                        name: "fk_item_instances_characters_equipped_to_character_id",
                        column: x => x.equipped_to_character_id,
                        principalTable: "characters",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "fk_item_instances_items_item_id",
                        column: x => x.item_id,
                        principalTable: "items",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_item_instances_users_owner_id",
                        column: x => x.owner_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "idx_antibot_user_created",
                table: "anti_bot_events",
                columns: new[] { "user_id", "created_at" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "idx_characters_user_id",
                table: "characters",
                column: "user_id",
                filter: "deleted_at IS NULL");

            migrationBuilder.CreateIndex(
                name: "idx_item_instances_owner",
                table: "item_instances",
                column: "owner_id");

            migrationBuilder.CreateIndex(
                name: "idx_item_instances_steam",
                table: "item_instances",
                column: "steam_inventory_id",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_item_instances_equipped_to_character_id",
                table: "item_instances",
                column: "equipped_to_character_id");

            migrationBuilder.CreateIndex(
                name: "ix_item_instances_item_id",
                table: "item_instances",
                column: "item_id");

            migrationBuilder.CreateIndex(
                name: "ix_items_name",
                table: "items",
                column: "name");

            migrationBuilder.CreateIndex(
                name: "ix_items_set_id",
                table: "items",
                column: "set_id");

            migrationBuilder.CreateIndex(
                name: "ix_items_steam_market_hash_name",
                table: "items",
                column: "steam_market_hash_name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_refresh_tokens_token_hash",
                table: "refresh_tokens",
                column: "token_hash",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_refresh_tokens_user_id",
                table: "refresh_tokens",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "ix_users_steam_id",
                table: "users",
                column: "steam_id",
                unique: true);

            // updated_at trigger: refreshes updated_at on every UPDATE.
            migrationBuilder.Sql(@"
                CREATE OR REPLACE FUNCTION update_updated_at_column()
                RETURNS TRIGGER AS $$
                BEGIN
                    NEW.updated_at = now();
                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;");

            foreach (var table in new[] { "users", "characters", "item_instances" })
            {
                migrationBuilder.Sql($@"
                    CREATE TRIGGER trg_{table}_updated_at
                    BEFORE UPDATE ON {table}
                    FOR EACH ROW
                    EXECUTE FUNCTION update_updated_at_column();");
            }
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            foreach (var table in new[] { "users", "characters", "item_instances" })
            {
                migrationBuilder.Sql($"DROP TRIGGER IF EXISTS trg_{table}_updated_at ON {table};");
            }

            migrationBuilder.Sql("DROP FUNCTION IF EXISTS update_updated_at_column();");

            migrationBuilder.DropTable(
                name: "anti_bot_events");

            migrationBuilder.DropTable(
                name: "item_instances");

            migrationBuilder.DropTable(
                name: "refresh_tokens");

            migrationBuilder.DropTable(
                name: "characters");

            migrationBuilder.DropTable(
                name: "items");

            migrationBuilder.DropTable(
                name: "users");
        }
    }
}

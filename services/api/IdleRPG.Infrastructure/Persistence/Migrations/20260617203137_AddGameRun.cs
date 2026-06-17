using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace IdleRPG.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddGameRun : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "game_runs",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    level_index = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    phase_index = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    wave_index = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    tick_count = table.Column<long>(type: "bigint", nullable: false, defaultValue: 0L),
                    state_json = table.Column<string>(type: "jsonb", nullable: false, defaultValueSql: "'{}'"),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_game_runs", x => x.id);
                    table.ForeignKey(
                        name: "fk_game_runs_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "idx_game_runs_user_id",
                table: "game_runs",
                column: "user_id",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "game_runs");
        }
    }
}

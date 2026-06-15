using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace IdleRPG.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddSetBonuses : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "items_set_bonuses",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    set_id = table.Column<Guid>(type: "uuid", nullable: false),
                    pieces_required = table.Column<short>(type: "smallint", nullable: false),
                    stat_bonuses_json = table.Column<string>(type: "jsonb", nullable: false, defaultValueSql: "'{}'")
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_items_set_bonuses", x => x.id);
                    table.CheckConstraint("ck_items_set_bonuses_pieces", "pieces_required >= 1");
                });

            migrationBuilder.CreateIndex(
                name: "ix_items_set_bonuses_set_id_pieces_required",
                table: "items_set_bonuses",
                columns: new[] { "set_id", "pieces_required" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "items_set_bonuses");
        }
    }
}

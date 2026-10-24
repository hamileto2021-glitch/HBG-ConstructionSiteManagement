using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CSM.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class ExtendUserPreferences : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "AnalyticsConsent",
                table: "UserPreferences",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "ApprovalNotificationsEnabled",
                table: "UserPreferences",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "CompactMode",
                table: "UserPreferences",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "ConfirmActions",
                table: "UserPreferences",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "InventoryNotificationsEnabled",
                table: "UserPreferences",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "ProductImprovementConsent",
                table: "UserPreferences",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "RememberNavigation",
                table: "UserPreferences",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AnalyticsConsent",
                table: "UserPreferences");

            migrationBuilder.DropColumn(
                name: "ApprovalNotificationsEnabled",
                table: "UserPreferences");

            migrationBuilder.DropColumn(
                name: "CompactMode",
                table: "UserPreferences");

            migrationBuilder.DropColumn(
                name: "ConfirmActions",
                table: "UserPreferences");

            migrationBuilder.DropColumn(
                name: "InventoryNotificationsEnabled",
                table: "UserPreferences");

            migrationBuilder.DropColumn(
                name: "ProductImprovementConsent",
                table: "UserPreferences");

            migrationBuilder.DropColumn(
                name: "RememberNavigation",
                table: "UserPreferences");
        }
    }
}

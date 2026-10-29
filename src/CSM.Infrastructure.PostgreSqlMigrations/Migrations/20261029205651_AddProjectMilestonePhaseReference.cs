using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CSM.Infrastructure.PostgreSqlMigrations.Migrations
{
    /// <inheritdoc />
    public partial class AddProjectMilestonePhaseReference : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ProjectPhaseId",
                table: "ProjectMilestones",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_ProjectMilestones_ProjectPhaseId",
                table: "ProjectMilestones",
                column: "ProjectPhaseId");

            migrationBuilder.AddForeignKey(
                name: "FK_ProjectMilestones_ProjectPhases_ProjectPhaseId",
                table: "ProjectMilestones",
                column: "ProjectPhaseId",
                principalTable: "ProjectPhases",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ProjectMilestones_ProjectPhases_ProjectPhaseId",
                table: "ProjectMilestones");

            migrationBuilder.DropIndex(
                name: "IX_ProjectMilestones_ProjectPhaseId",
                table: "ProjectMilestones");

            migrationBuilder.DropColumn(
                name: "ProjectPhaseId",
                table: "ProjectMilestones");
        }
    }
}

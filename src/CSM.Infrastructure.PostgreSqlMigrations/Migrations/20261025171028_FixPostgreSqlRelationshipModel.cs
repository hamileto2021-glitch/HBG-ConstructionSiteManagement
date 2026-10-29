using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CSM.Infrastructure.PostgreSqlMigrations.Migrations
{
    /// <inheritdoc />
    public partial class FixPostgreSqlRelationshipModel : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ProjectEquipmentAssignments_Projects_ProjectId1",
                table: "ProjectEquipmentAssignments");

            migrationBuilder.DropForeignKey(
                name: "FK_ProjectMilestones_Projects_ProjectId1",
                table: "ProjectMilestones");

            migrationBuilder.DropIndex(
                name: "IX_ProjectMilestones_CompanyId_MilestoneNumber",
                table: "ProjectMilestones");

            migrationBuilder.DropIndex(
                name: "IX_ProjectMilestones_ProjectId1",
                table: "ProjectMilestones");

            migrationBuilder.DropIndex(
                name: "IX_ProjectEquipmentAssignments_ProjectId1",
                table: "ProjectEquipmentAssignments");

            migrationBuilder.DropColumn(
                name: "ProjectId1",
                table: "ProjectMilestones");

            migrationBuilder.DropColumn(
                name: "ProjectId1",
                table: "ProjectEquipmentAssignments");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ProjectId1",
                table: "ProjectMilestones",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ProjectId1",
                table: "ProjectEquipmentAssignments",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_ProjectMilestones_CompanyId_MilestoneNumber",
                table: "ProjectMilestones",
                columns: new[] { "CompanyId", "MilestoneNumber" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ProjectMilestones_ProjectId1",
                table: "ProjectMilestones",
                column: "ProjectId1");

            migrationBuilder.CreateIndex(
                name: "IX_ProjectEquipmentAssignments_ProjectId1",
                table: "ProjectEquipmentAssignments",
                column: "ProjectId1");

            migrationBuilder.AddForeignKey(
                name: "FK_ProjectEquipmentAssignments_Projects_ProjectId1",
                table: "ProjectEquipmentAssignments",
                column: "ProjectId1",
                principalTable: "Projects",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_ProjectMilestones_Projects_ProjectId1",
                table: "ProjectMilestones",
                column: "ProjectId1",
                principalTable: "Projects",
                principalColumn: "Id");
        }
    }
}

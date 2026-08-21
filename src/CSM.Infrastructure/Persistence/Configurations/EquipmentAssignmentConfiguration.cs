using CSM.Domain.Entities.Procurement;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CSM.Infrastructure.Persistence.Configurations;

public class EquipmentAssignmentConfiguration :
    IEntityTypeConfiguration<EquipmentAssignment>
{
    public void Configure(EntityTypeBuilder<EquipmentAssignment> builder)
    {
        builder.ToTable("EquipmentAssignments");
        builder.HasKey(x => x.Id);

        builder.Property(x => x.MeterReadingAtAssignment).HasPrecision(19, 4);
        builder.Property(x => x.MeterReadingAtRelease).HasPrecision(19, 4);
        builder.Property(x => x.AssignmentNumber)
            .HasMaxLength(30)
            .IsRequired();

        builder.HasIndex(x => new
        {
            x.CompanyId,
            x.AssignmentNumber
        }).IsUnique();

        builder.HasIndex(x => new
        {
            x.EquipmentId,
            x.ConstructionSiteId,
            x.AssignedAtUtc
        });

        builder.HasOne(x => x.Equipment)
            .WithMany(x => x.Assignments)
            .HasForeignKey(x => x.EquipmentId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.ConstructionSite)
            .WithMany(x => x.EquipmentAssignments)
            .HasForeignKey(x => x.ConstructionSiteId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Project)
            .WithMany(x => x.EquipmentAssignments)
            .HasForeignKey(x => x.ProjectId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasQueryFilter(x => !x.IsDeleted);
    }
}
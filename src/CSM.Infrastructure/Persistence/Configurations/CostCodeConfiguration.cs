using CSM.Domain.Entities.Finance;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CSM.Infrastructure.Persistence.Configurations;

public class CostCodeConfiguration :
    IEntityTypeConfiguration<CostCode>
{
    public void Configure(EntityTypeBuilder<CostCode> builder)
    {
        builder.ToTable("CostCodes");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Code)
            .HasMaxLength(30)
            .IsRequired();

        builder.Property(x => x.Name)
            .HasMaxLength(200)
            .IsRequired();

        builder.HasIndex(x => new { x.CompanyId, x.Code })
            .IsUnique();

        builder.HasOne(x => x.ParentCostCode)
            .WithMany(x => x.Children)
            .HasForeignKey(x => x.ParentCostCodeId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasQueryFilter(x => !x.IsDeleted);
    }
}
using CSM.Domain.Entities.Compliance;
using CSM.Domain.Entities.Finance;
using CSM.Domain.Entities.HRM;
using CSM.Domain.Entities.Organization;
using CSM.Domain.Entities.Procurement;
using CSM.Domain.Entities.Projects;
using Microsoft.EntityFrameworkCore;
using CSM.Domain.Common;
using CSM.Domain.Entities.Identity;
using CSM.Domain.Entities.Notifications;




namespace CSM.Infrastructure.Persistence;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(
        DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    // Organization
    public DbSet<Company> Companies => Set<Company>();
    public DbSet<BusinessUnit> BusinessUnits => Set<BusinessUnit>();
    public DbSet<ConstructionSite> ConstructionSites => Set<ConstructionSite>();

    // Projects
    public DbSet<Project> Projects => Set<Project>();
    public DbSet<ProjectPhase> ProjectPhases => Set<ProjectPhase>();
    public DbSet<Milestone> Milestones => Set<Milestone>();
    public DbSet<WorkTask> WorkTasks => Set<WorkTask>();
    public DbSet<WorkTaskDependency> WorkTaskDependencies => Set<WorkTaskDependency>();
    public DbSet<DailyProgressLog> DailyProgressLogs => Set<DailyProgressLog>();

    // HRM
    public DbSet<Employee> Employees => Set<Employee>();
    public DbSet<Contractor> Contractors => Set<Contractor>();
    public DbSet<SiteAssignment> SiteAssignments => Set<SiteAssignment>();
    public DbSet<Shift> Shifts => Set<Shift>();
    public DbSet<Attendance> Attendances => Set<Attendance>();
    public DbSet<LeaveRequest> LeaveRequests => Set<LeaveRequest>();
    public DbSet<Timesheet> Timesheets => Set<Timesheet>();
    public DbSet<PayrollRecord> PayrollRecords => Set<PayrollRecord>();
    public DbSet<PayrollAdjustment> PayrollAdjustments => Set<PayrollAdjustment>();

    // Finance
    public DbSet<CostCode> CostCodes => Set<CostCode>();
    public DbSet<Budget> Budgets => Set<Budget>();
    public DbSet<BudgetLine> BudgetLines => Set<BudgetLine>();
    public DbSet<Vendor> Vendors => Set<Vendor>();
    public DbSet<Expense> Expenses => Set<Expense>();
    public DbSet<Invoice> Invoices => Set<Invoice>();
    public DbSet<InvoiceLine> InvoiceLines => Set<InvoiceLine>();
    public DbSet<Payment> Payments => Set<Payment>();

    // Procurement
    public DbSet<Material> Materials => Set<Material>();
    public DbSet<RebarSpec> RebarSpecs => Set<RebarSpec>();
    public DbSet<StockItem> StockItems => Set<StockItem>();
    public DbSet<DailyMaterialUsage> DailyMaterialUsages =>
        Set<DailyMaterialUsage>();
    public DbSet<StockMovement> StockMovements => Set<StockMovement>();
    public DbSet<MaterialRequest> MaterialRequests => Set<MaterialRequest>();
    public DbSet<MaterialRequestLine> MaterialRequestLines => Set<MaterialRequestLine>();
    public DbSet<PurchaseOrder> PurchaseOrders => Set<PurchaseOrder>();
    public DbSet<PurchaseOrderLine> PurchaseOrderLines => Set<PurchaseOrderLine>();
    public DbSet<GoodsReceipt> GoodsReceipts => Set<GoodsReceipt>();
    public DbSet<GoodsReceiptLine> GoodsReceiptLines => Set<GoodsReceiptLine>();
    public DbSet<Equipment> Equipment => Set<Equipment>();
    public DbSet<EquipmentAssignment> EquipmentAssignments => Set<EquipmentAssignment>();
    public DbSet<EquipmentMaintenance> EquipmentMaintenanceRecords => Set<EquipmentMaintenance>();
    public DbSet<EquipmentDowntime> EquipmentDowntimeRecords => Set<EquipmentDowntime>();
    public DbSet<DocumentVersion> DocumentVersions => Set<DocumentVersion>();

    // Compliance
    public DbSet<Document> Documents => Set<Document>();
public DbSet<DocumentCategory> DocumentCategories => Set<DocumentCategory>();
    public DbSet<SafetyIncident> SafetyIncidents => Set<SafetyIncident>();
    public DbSet<Permit> Permits => Set<Permit>();
    public DbSet<Inspection> Inspections => Set<Inspection>();
    public DbSet<InspectionChecklistItem> InspectionChecklistItems =>
        Set<InspectionChecklistItem>();

    // Identity
    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
public DbSet<Notification> Notifications => Set<Notification>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.ApplyConfigurationsFromAssembly(
            typeof(ApplicationDbContext).Assembly);
    }

    public override int SaveChanges()
{
    ApplyAuditInformation();
    return base.SaveChanges();
}

public override Task<int> SaveChangesAsync(
    CancellationToken cancellationToken = default)
{
    ApplyAuditInformation();

    return base.SaveChangesAsync(cancellationToken);
}

private void ApplyAuditInformation()
{
    var utcNow = DateTime.UtcNow;

    foreach (var entry in ChangeTracker.Entries<AuditableEntity>())
    {
        switch (entry.State)
        {
            case EntityState.Added:
                entry.Entity.CreatedAtUtc = utcNow;
                entry.Entity.IsDeleted = false;
                break;

            case EntityState.Modified:
                entry.Entity.UpdatedAtUtc = utcNow;

                // Created audit fields must never change during an update.
                entry.Property(x => x.CreatedAtUtc).IsModified = false;
                entry.Property(x => x.CreatedBy).IsModified = false;
                break;

            case EntityState.Deleted:
                // Convert physical deletion into soft deletion.
                entry.State = EntityState.Modified;

                entry.Entity.IsDeleted = true;
                entry.Entity.DeletedAtUtc = utcNow;
                entry.Entity.UpdatedAtUtc = utcNow;

                entry.Property(x => x.CreatedAtUtc).IsModified = false;
                entry.Property(x => x.CreatedBy).IsModified = false;
                break;
        }
    }
}
}









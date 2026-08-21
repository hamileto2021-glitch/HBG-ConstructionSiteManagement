using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Application.Reporting;
using CSM.Application.Reporting.Dtos;
using CSM.Domain.Constants;
using CSM.Domain.Entities.Identity;
using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CSM.Infrastructure.Services;

public sealed class ReportingService : IReportingService
{
    private readonly ApplicationDbContext _dbContext;

    public ReportingService(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ExecutiveDashboardResponse> GetExecutiveDashboardAsync(
        Guid currentUserId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        EnsureCanRead(actor);

        var companyId = GetCompanyId(actor);

        var sites = _dbContext.ConstructionSites
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId);

        var projects = _dbContext.Projects
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId);

        var budgets = _dbContext.Budgets
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId);

        var expenses = _dbContext.Expenses
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId);

        var invoices = _dbContext.Invoices
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId);

        var payments = _dbContext.Payments
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId);

        var totalSites = await sites.CountAsync(
            cancellationToken);

        var activeSites = await sites.CountAsync(
            x => x.IsActive,
            cancellationToken);

        var totalProjects = await projects.CountAsync(
            cancellationToken);

        var totalContractValue = await projects
            .SumAsync(
                x => (decimal?)x.ContractValue,
                cancellationToken) ?? 0m;

        var totalBudget = await budgets
            .SumAsync(
                x => (decimal?)x.TotalAmount,
                cancellationToken) ?? 0m;

        var totalExpenses = await expenses
            .Where(x => x.Status != Domain.Enums.ExpenseStatus.Cancelled)
            .SumAsync(
                x => (decimal?)x.Amount + x.TaxAmount,
                cancellationToken) ?? 0m;

        var totalInvoices = await invoices
            .Where(x => x.Status != Domain.Enums.InvoiceStatus.Cancelled)
            .SumAsync(
                x => (decimal?)x.TotalAmount,
                cancellationToken) ?? 0m;

        var totalCompletedPayments = await payments
            .Where(x => x.Status == Domain.Enums.PaymentStatus.Completed)
            .SumAsync(
                x => (decimal?)x.Amount,
                cancellationToken) ?? 0m;

        var outstandingInvoices =
            Math.Max(
                0m,
                totalInvoices - totalCompletedPayments);

        var sitesByStatus = await sites
            .GroupBy(x => x.Status)
            .Select(
                x => new
                {
                    Status = x.Key,
                    Count = x.Count()
                })
            .ToDictionaryAsync(
                x => x.Status,
                x => x.Count,
                cancellationToken);

        var projectsByStatus = await projects
            .GroupBy(x => x.Status)
            .Select(
                x => new
                {
                    Status = x.Key,
                    Count = x.Count()
                })
            .ToDictionaryAsync(
                x => x.Status,
                x => x.Count,
                cancellationToken);

        return new ExecutiveDashboardResponse(
            totalSites,
            activeSites,
            totalProjects,
            totalContractValue,
            totalBudget,
            totalExpenses,
            totalInvoices,
            totalCompletedPayments,
            outstandingInvoices,
            sitesByStatus,
            projectsByStatus);
    }

    public async Task<FinancialSummaryResponse> GetFinancialSummaryAsync(
        Guid currentUserId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        EnsureCanRead(actor);

        var companyId = GetCompanyId(actor);

        var totalBudget = await _dbContext.Budgets
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId)
            .SumAsync(
                x => (decimal?)x.TotalAmount,
                cancellationToken) ?? 0m;

        var totalExpenses = await _dbContext.Expenses
            .AsNoTracking()
            .Where(
                x =>
                    x.CompanyId == companyId &&
                    x.Status != Domain.Enums.ExpenseStatus.Cancelled)
            .SumAsync(
                x => (decimal?)x.Amount + x.TaxAmount,
                cancellationToken) ?? 0m;

        var invoiceData = await _dbContext.Invoices
            .AsNoTracking()
            .Where(
                x =>
                    x.CompanyId == companyId &&
                    x.Status != Domain.Enums.InvoiceStatus.Cancelled)
            .GroupBy(x => 1)
            .Select(
                x => new
                {
                    TotalInvoices =
                        x.Sum(i => i.TotalAmount),

                    ClientInvoices =
                        x.Where(
                            i =>
                                i.Type ==
                                Domain.Enums.InvoiceType.ClientInvoice)
                            .Sum(i => i.TotalAmount),

                    VendorBills =
                        x.Where(
                            i =>
                                i.Type ==
                                Domain.Enums.InvoiceType.VendorBill)
                            .Sum(i => i.TotalAmount)
                })
            .FirstOrDefaultAsync(cancellationToken);

        var totalInvoices =
            invoiceData?.TotalInvoices ?? 0m;

        var clientInvoices =
            invoiceData?.ClientInvoices ?? 0m;

        var vendorBills =
            invoiceData?.VendorBills ?? 0m;

        var completedIncomingPayments =
            await _dbContext.Payments
                .AsNoTracking()
                .Where(
                    x =>
                        x.CompanyId == companyId &&
                        x.Status ==
                        Domain.Enums.PaymentStatus.Completed &&
                        x.Direction ==
                        Domain.Enums.PaymentDirection.Incoming)
                .SumAsync(
                    x => (decimal?)x.Amount,
                    cancellationToken) ?? 0m;

        var completedOutgoingPayments =
            await _dbContext.Payments
                .AsNoTracking()
                .Where(
                    x =>
                        x.CompanyId == companyId &&
                        x.Status ==
                        Domain.Enums.PaymentStatus.Completed &&
                        x.Direction ==
                        Domain.Enums.PaymentDirection.Outgoing)
                .SumAsync(
                    x => (decimal?)x.Amount,
                    cancellationToken) ?? 0m;

        var outstandingReceivables =
            Math.Max(
                0m,
                clientInvoices - completedIncomingPayments);

        var outstandingPayables =
            Math.Max(
                0m,
                vendorBills - completedOutgoingPayments);

        return new FinancialSummaryResponse(
            totalBudget,
            totalExpenses,
            totalInvoices,
            completedIncomingPayments,
            outstandingReceivables,
            outstandingPayables);
    }

    private async Task<User> GetActorAsync(
        Guid currentUserId,
        CancellationToken cancellationToken)
    {
        return await _dbContext.Users
            .Include(x => x.UserRoles)
            .ThenInclude(x => x.Role)
            .SingleOrDefaultAsync(
                x => x.Id == currentUserId,
                cancellationToken)
            ?? throw new ReportingManagementException(
                "Authenticated user was not found.");
    }

    private static void EnsureCanRead(User actor)
    {
        if (HasRole(actor, AppRoles.SuperAdmin) ||
            HasRole(actor, AppRoles.CompanyAdmin) ||
            HasRole(actor, AppRoles.SiteManager) ||
            HasRole(actor, AppRoles.Supervisor))
        {
            return;
        }

        throw new ReportingManagementException(
            "You are not authorized to view reports.");
    }

    private static Guid GetCompanyId(User actor)
    {
        if (!actor.CompanyId.HasValue)
        {
            throw new ReportingManagementException(
                "Current user is not assigned to a company.");
        }

        return actor.CompanyId.Value;
    }

    private static bool HasRole(
        User actor,
        string roleName)
    {
        return actor.UserRoles.Any(
            x =>
                !x.IsDeleted &&
                !x.Role.IsDeleted &&
                string.Equals(
                    x.Role.Name,
                    roleName,
                    StringComparison.OrdinalIgnoreCase));
    }
}

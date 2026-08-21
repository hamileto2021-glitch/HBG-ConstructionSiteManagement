using CSM.Application.Common.Exceptions;
using CSM.Application.Finance.Budgets;
using CSM.Application.Finance.Budgets.Dtos;
using CSM.Domain.Constants;
using CSM.Domain.Entities.Finance;
using CSM.Domain.Entities.Identity;
using CSM.Domain.Enums;
using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CSM.Infrastructure.Services;

public sealed class BudgetService : IBudgetService
{
    private readonly ApplicationDbContext _dbContext;

    public BudgetService(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IReadOnlyCollection<BudgetResponse>> GetAllAsync(
        Guid currentUserId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        EnsureCanRead(actor);

        IQueryable<Budget> query =
            _dbContext.Budgets.AsNoTracking();

        if (!IsSuperAdmin(actor))
        {
            query = query.Where(
                x => x.CompanyId == GetActorCompanyId(actor));
        }

        var budgets = await query
            .OrderBy(x => x.BudgetNumber)
            .ToListAsync(cancellationToken);

        return budgets
            .Select(Map)
            .ToArray();
    }

    public async Task<BudgetResponse> GetByIdAsync(
        Guid currentUserId,
        Guid budgetId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        EnsureCanRead(actor);

        var budget = await GetBudgetAsync(
            budgetId,
            cancellationToken);

        EnsureCompanyAccess(
            actor,
            budget.CompanyId);

        return Map(budget);
    }

    public async Task<BudgetResponse> CreateAsync(
        Guid currentUserId,
        CreateBudgetRequest request,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        EnsureCanModify(actor);

        var companyId = GetActorCompanyId(actor);

        var budgetNumber = CleanRequired(
            request.BudgetNumber,
            "Budget number");

        var name = CleanRequired(
            request.Name,
            "Budget name");

        var currencyCode = CleanRequired(
            request.CurrencyCode,
            "Currency code")
            .ToUpperInvariant();

        ValidateMoney(
            request.TotalAmount,
            "Total amount");

        ValidateDates(
            request.EffectiveFrom,
            request.EffectiveTo);

        if (currencyCode.Length != 3)
        {
            throw new BudgetManagementException(
                "Currency code must contain exactly 3 characters.");
        }

        var duplicateExists = await _dbContext.Budgets
            .AnyAsync(
                x =>
                    x.CompanyId == companyId &&
                    x.BudgetNumber == budgetNumber,
                cancellationToken);

        if (duplicateExists)
        {
            throw new BudgetManagementException(
                $"Budget number '{budgetNumber}' already exists.");
        }

        await EnsureSiteAccess(
            companyId,
            request.ConstructionSiteId,
            cancellationToken);

        await EnsureProjectAccess(
            companyId,
            request.ConstructionSiteId,
            request.ProjectId,
            cancellationToken);

        var budget = new Budget
        {
            CompanyId = companyId,
            ConstructionSiteId =
                request.ConstructionSiteId,
            ProjectId = request.ProjectId,
            BudgetNumber = budgetNumber,
            Name = name,
            Description = Clean(request.Description),
            TotalAmount = request.TotalAmount,
            CurrencyCode = currencyCode,
            EffectiveFrom = request.EffectiveFrom,
            EffectiveTo = request.EffectiveTo,
            Status = BudgetStatus.Draft
        };

        _dbContext.Budgets.Add(budget);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Map(budget);
    }

    public async Task<BudgetResponse> UpdateAsync(
        Guid currentUserId,
        Guid budgetId,
        UpdateBudgetRequest request,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        EnsureCanModify(actor);

        var budget = await GetBudgetAsync(
            budgetId,
            cancellationToken);

        EnsureCompanyAccess(
            actor,
            budget.CompanyId);

        EnsureEditable(budget);

        var name = CleanRequired(
            request.Name,
            "Budget name");

        var currencyCode = CleanRequired(
            request.CurrencyCode,
            "Currency code")
            .ToUpperInvariant();

        ValidateMoney(
            request.TotalAmount,
            "Total amount");

        ValidateDates(
            request.EffectiveFrom,
            request.EffectiveTo);

        if (currencyCode.Length != 3)
        {
            throw new BudgetManagementException(
                "Currency code must contain exactly 3 characters.");
        }

        budget.Name = name;
        budget.Description = Clean(request.Description);
        budget.TotalAmount = request.TotalAmount;
        budget.CurrencyCode = currencyCode;
        budget.EffectiveFrom = request.EffectiveFrom;
        budget.EffectiveTo = request.EffectiveTo;

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Map(budget);
    }

    public async Task<BudgetResponse> ChangeStatusAsync(
        Guid currentUserId,
        Guid budgetId,
        ChangeBudgetStatusRequest request,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        EnsureCanModify(actor);

        var budget = await GetBudgetAsync(
            budgetId,
            cancellationToken);

        EnsureCompanyAccess(
            actor,
            budget.CompanyId);

        ValidateStatusTransition(
            budget.Status,
            request.Status);

        if (request.Status == BudgetStatus.Approved)
        {
            budget.ApprovedBy = currentUserId;
            budget.ApprovedAtUtc = DateTime.UtcNow;
        }

        budget.Status = request.Status;

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Map(budget);
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
            ?? throw new BudgetManagementException(
                "Authenticated user was not found.");
    }

    private static void EnsureCanRead(User actor)
    {
        if (IsSuperAdmin(actor) ||
            HasRole(actor, AppRoles.CompanyAdmin) ||
            HasRole(actor, AppRoles.Accountant))
        {
            return;
        }

        throw new BudgetManagementException(
            "You are not authorized to view budgets.");
    }

    private static void EnsureCanModify(User actor)
    {
        if (IsSuperAdmin(actor) ||
            HasRole(actor, AppRoles.CompanyAdmin) ||
            HasRole(actor, AppRoles.Accountant))
        {
            return;
        }

        throw new BudgetManagementException(
            "You are not authorized to manage budgets.");
    }

    private static void EnsureCompanyAccess(
        User actor,
        Guid companyId)
    {
        if (IsSuperAdmin(actor))
        {
            return;
        }

        if (!actor.CompanyId.HasValue ||
            actor.CompanyId.Value != companyId)
        {
            throw new BudgetManagementException(
                "You are not authorized to access this budget.");
        }
    }

    private static Guid GetActorCompanyId(User actor)
    {
        if (!actor.CompanyId.HasValue)
        {
            throw new BudgetManagementException(
                "Current user is not assigned to a company.");
        }

        return actor.CompanyId.Value;
    }

    private async Task<Budget> GetBudgetAsync(
        Guid budgetId,
        CancellationToken cancellationToken)
    {
        return await _dbContext.Budgets
            .SingleOrDefaultAsync(
                x =>
                    x.Id == budgetId &&
                    !x.IsDeleted,
                cancellationToken)
            ?? throw new BudgetManagementException(
                "Budget was not found.");
    }

    private async Task EnsureSiteAccess(
        Guid companyId,
        Guid siteId,
        CancellationToken cancellationToken)
    {
        var exists = await _dbContext.ConstructionSites
            .AnyAsync(
                x =>
                    x.Id == siteId &&
                    x.CompanyId == companyId &&
                    !x.IsDeleted,
                cancellationToken);

        if (!exists)
        {
            throw new BudgetManagementException(
                "The selected construction site is invalid or inaccessible.");
        }
    }

    private async Task EnsureProjectAccess(
        Guid companyId,
        Guid siteId,
        Guid? projectId,
        CancellationToken cancellationToken)
    {
        if (!projectId.HasValue)
        {
            return;
        }

        var exists = await _dbContext.Projects
            .AnyAsync(
                x =>
                    x.Id == projectId.Value &&
                    x.CompanyId == companyId &&
                    x.ConstructionSiteId == siteId &&
                    !x.IsDeleted,
                cancellationToken);

        if (!exists)
        {
            throw new BudgetManagementException(
                "The selected project is invalid, inaccessible, or belongs to another construction site.");
        }
    }

    private static void EnsureEditable(Budget budget)
    {
        if (budget.Status != BudgetStatus.Draft &&
            budget.Status != BudgetStatus.PendingApproval)
        {
            throw new BudgetManagementException(
                "Only Draft or PendingApproval budgets can be edited.");
        }
    }

    private static void ValidateStatusTransition(
        BudgetStatus current,
        BudgetStatus next)
    {
        if (current == next)
        {
            throw new BudgetManagementException(
                $"Budget is already in {next} status.");
        }

        var valid = current switch
        {
            BudgetStatus.Draft =>
                next == BudgetStatus.PendingApproval ||
                next == BudgetStatus.Cancelled,

            BudgetStatus.PendingApproval =>
                next == BudgetStatus.Approved ||
                next == BudgetStatus.Draft ||
                next == BudgetStatus.Cancelled,

            BudgetStatus.Approved =>
                next == BudgetStatus.Active ||
                next == BudgetStatus.Cancelled,

            BudgetStatus.Active =>
                next == BudgetStatus.Closed,

            BudgetStatus.Closed =>
                false,

            BudgetStatus.Cancelled =>
                false,

            _ => false
        };

        if (!valid)
        {
            throw new BudgetManagementException(
                $"Invalid budget status transition from {current} to {next}.");
        }
    }

    private static void ValidateMoney(
        decimal amount,
        string fieldName)
    {
        if (amount < 0)
        {
            throw new BudgetManagementException(
                $"{fieldName} cannot be negative.");
        }
    }

    private static void ValidateDates(
        DateOnly? from,
        DateOnly? to)
    {
        if (from.HasValue &&
            to.HasValue &&
            to.Value < from.Value)
        {
            throw new BudgetManagementException(
                "EffectiveTo cannot be earlier than EffectiveFrom.");
        }
    }

    private static string CleanRequired(
        string? value,
        string fieldName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new BudgetManagementException(
                $"{fieldName} is required.");
        }

        return value.Trim();
    }

    private static string? Clean(string? value)
    {
        return string.IsNullOrWhiteSpace(value)
            ? null
            : value.Trim();
    }

    private static bool IsSuperAdmin(User actor)
    {
        return HasRole(actor, AppRoles.SuperAdmin);
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

    private static BudgetResponse Map(
        Budget budget)
    {
        return new BudgetResponse(
            budget.Id,
            budget.CompanyId,
            budget.ConstructionSiteId,
            budget.ProjectId,
            budget.BudgetNumber,
            budget.Name,
            budget.Description,
            budget.TotalAmount,
            budget.CurrencyCode,
            budget.EffectiveFrom,
            budget.EffectiveTo,
            budget.Status,
            budget.ApprovedBy,
            budget.ApprovedAtUtc,
            budget.CreatedAtUtc,
            budget.UpdatedAtUtc);
    }
}


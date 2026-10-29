using CSM.Application.Common.Exceptions;
using CSM.Application.Finance.Payments;
using CSM.Application.Finance.Payments.Dtos;
using CSM.Domain.Constants;
using CSM.Domain.Entities.Finance;
using CSM.Domain.Entities.Identity;
using CSM.Domain.Enums;
using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CSM.Infrastructure.Services;

/// <summary>
/// Payment rules
///   - A payment is created Pending. Only Completed payments are cash and
///     only they count toward an invoice's paid amount.
///   - A payment linked to an invoice follows the invoice: a client invoice
///     is money in, a vendor bill is money out.
///   - Every status change goes through ApplyStatusAsync, which also
///     recalculates the invoice (paid amount and status) and the payroll
///     record in the SAME save.
/// </summary>
public sealed class PaymentService : IPaymentService
{
    private const decimal Tolerance = 0.005m;

    private readonly ApplicationDbContext _dbContext;

    public PaymentService(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    // ------------------------------------------------------------------
    // Queries
    // ------------------------------------------------------------------

    public async Task<IReadOnlyCollection<PaymentResponse>> GetAllAsync(
        Guid currentUserId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(currentUserId, cancellationToken);

        EnsureCanRead(actor);

        IQueryable<Payment> query = _dbContext.Payments
            .AsNoTracking()
            .Include(x => x.Invoice);

        if (!IsSuperAdmin(actor))
        {
            var companyId = GetActorCompanyId(actor);

            query = query.Where(x => x.CompanyId == companyId);
        }

        // Site managers only see payments of the sites they are assigned to.
        var visibleSites = await GetVisibleSiteIdsAsync(actor, cancellationToken);

        if (visibleSites is not null)
        {
            query = query.Where(x =>
                (x.Invoice != null
                    ? x.Invoice.ConstructionSiteId
                    : x.ConstructionSiteId) != null &&
                visibleSites.Contains(
                    (x.Invoice != null
                        ? x.Invoice.ConstructionSiteId
                        : x.ConstructionSiteId)!.Value));
        }

        var payments = await query
            .OrderByDescending(x => x.PaymentDate)
            .ThenBy(x => x.PaymentNumber)
            .ToListAsync(cancellationToken);

        return payments.Select(Map).ToArray();
    }

    public async Task<PaymentResponse> GetByIdAsync(
        Guid currentUserId,
        Guid paymentId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(currentUserId, cancellationToken);

        EnsureCanRead(actor);

        var payment = await GetPaymentAsync(paymentId, cancellationToken);

        EnsureCompanyAccess(actor, payment.CompanyId);

        await EnsureSiteAccess(
            actor,
            EffectiveSiteId(payment),
            cancellationToken);

        return Map(payment);
    }

    // Company-level payments: not tied to a construction site. The site is
    // taken from the invoice when there is one, otherwise from the payment.
    public async Task<IReadOnlyCollection<PaymentResponse>> GetCompanyPaymentsAsync(
        Guid currentUserId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(currentUserId, cancellationToken);

        EnsureCanRead(actor);

        // Same rule as EnsureSiteAccess: site managers cannot see
        // company-level payments.
        await EnsureSiteAccess(actor, null, cancellationToken);

        var companyId = GetActorCompanyId(actor);

        var payments = await _dbContext.Payments
            .AsNoTracking()
            .Include(p => p.Invoice)
            .Where(p =>
                p.CompanyId == companyId &&
                !p.IsDeleted &&
                (p.Invoice != null
                    ? p.Invoice.ConstructionSiteId
                    : p.ConstructionSiteId) == null)
            .OrderByDescending(p => p.PaymentDate)
            .ToListAsync(cancellationToken);

        return payments.Select(Map).ToList();
    }

    // ------------------------------------------------------------------
    // Create / update / delete
    // ------------------------------------------------------------------

    public async Task<PaymentResponse> CreateAsync(
        Guid currentUserId,
        CreatePaymentRequest request,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(currentUserId, cancellationToken);

        EnsureCanModify(actor);

        var companyId = GetActorCompanyId(actor);

        var paymentNumber = CleanRequired(
            request.PaymentNumber,
            "Payment Number");

        // Create now runs the same checks as update. Before, it ran none:
        // wrong directions, zero amounts and other companies' invoices
        // could be saved.
        ValidatePayment(
            request.PaymentDate,
            request.Amount,
            request.ExchangeRate,
            request.Direction);

        await EnsureReferencesAsync(
            companyId,
            request.ConstructionSiteId,
            request.ProjectId,
            request.InvoiceId,
            request.VendorId,
            request.PayrollRecordId,
            request.Direction,
            cancellationToken);

        // Soft-deleted numbers stay reserved.
        var exists = await _dbContext.Payments
            .IgnoreQueryFilters()
            .AnyAsync(
                x =>
                    x.CompanyId == companyId &&
                    x.PaymentNumber == paymentNumber,
                cancellationToken);

        if (exists)
        {
            throw new PaymentManagementException(
                $"Payment Number '{paymentNumber}' already exists.");
        }

        var payment = new Payment
        {
            CompanyId = companyId,
            ConstructionSiteId = request.ConstructionSiteId,
            ProjectId = request.ProjectId,
            InvoiceId = request.InvoiceId,
            VendorId = request.VendorId,
            PayrollRecordId = request.PayrollRecordId,
            PaymentNumber = paymentNumber,
            PaymentDate = request.PaymentDate,
            Direction = request.Direction,
            Amount = request.Amount,
            CurrencyCode = CleanCurrencyCode(request.CurrencyCode),
            ExchangeRate = request.ExchangeRate,
            PaymentMethod = Clean(request.PaymentMethod),
            ReferenceNumber = Clean(request.ReferenceNumber),
            Notes = Clean(request.Notes),
            Status = PaymentStatus.Pending
        };

        _dbContext.Payments.Add(payment);

        // A Pending payment is not cash, so it changes nothing on the
        // invoice. (It used to trigger a recalculation that reset Draft and
        // Cancelled invoices to Issued.)
        await _dbContext.SaveChangesAsync(cancellationToken);

        if (payment.InvoiceId.HasValue)
        {
            await _dbContext.Entry(payment)
                .Reference(x => x.Invoice)
                .LoadAsync(cancellationToken);
        }

        return Map(payment);
    }

    public async Task<PaymentResponse> UpdateAsync(
        Guid currentUserId,
        Guid paymentId,
        UpdatePaymentRequest request,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(currentUserId, cancellationToken);

        EnsureCanModify(actor);

        var payment = await GetPaymentAsync(paymentId, cancellationToken);

        EnsureCompanyAccess(actor, payment.CompanyId);

        EnsureEditable(payment);

        ValidatePayment(
            request.PaymentDate,
            request.Amount,
            request.ExchangeRate,
            request.Direction);

        await EnsureReferencesAsync(
            payment.CompanyId,
            request.ConstructionSiteId,
            request.ProjectId,
            request.InvoiceId,
            request.VendorId,
            request.PayrollRecordId,
            request.Direction,
            cancellationToken);

        payment.ConstructionSiteId = request.ConstructionSiteId;
        payment.ProjectId = request.ProjectId;
        payment.InvoiceId = request.InvoiceId;
        payment.VendorId = request.VendorId;
        payment.PayrollRecordId = request.PayrollRecordId;
        payment.PaymentDate = request.PaymentDate;
        payment.Direction = request.Direction;
        payment.Amount = request.Amount;
        payment.CurrencyCode = CleanCurrencyCode(request.CurrencyCode);
        payment.ExchangeRate = request.ExchangeRate;
        payment.PaymentMethod = Clean(request.PaymentMethod);
        payment.ReferenceNumber = Clean(request.ReferenceNumber);
        payment.Notes = Clean(request.Notes);

        await _dbContext.SaveChangesAsync(cancellationToken);

        if (payment.InvoiceId.HasValue)
        {
            await _dbContext.Entry(payment)
                .Reference(x => x.Invoice)
                .LoadAsync(cancellationToken);
        }

        return Map(payment);
    }

    public async Task DeleteAsync(
        Guid currentUserId,
        Guid paymentId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(currentUserId, cancellationToken);

        EnsureCanModify(actor);

        var payment = await GetPaymentAsync(paymentId, cancellationToken);

        EnsureCompanyAccess(actor, payment.CompanyId);

        if (payment.Status != PaymentStatus.Pending)
        {
            throw new PaymentManagementException(
                "Only recorded payments can be deleted.");
        }

        // Only Pending payments can be deleted and they are not cash, so
        // no invoice recalculation is needed.
        payment.IsDeleted = true;
        payment.DeletedAtUtc = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    // ------------------------------------------------------------------
    // Status changes: ONE path for all three entry points
    // ------------------------------------------------------------------

    public async Task<PaymentResponse> ChangeStatusAsync(
        Guid currentUserId,
        Guid paymentId,
        ChangePaymentStatusRequest request,
        CancellationToken cancellationToken = default)
    {
        var payment = await LoadForStatusChangeAsync(
            currentUserId,
            paymentId,
            cancellationToken);

        await ApplyStatusAsync(payment, request.Status, cancellationToken);

        return Map(payment);
    }

    public async Task CompletePaymentAsync(
        Guid currentUserId,
        Guid paymentId,
        CancellationToken cancellationToken = default)
    {
        var payment = await LoadForStatusChangeAsync(
            currentUserId,
            paymentId,
            cancellationToken);

        await ApplyStatusAsync(
            payment,
            PaymentStatus.Completed,
            cancellationToken);
    }

    public async Task ReversePaymentAsync(
        Guid currentUserId,
        Guid paymentId,
        CancellationToken cancellationToken = default)
    {
        var payment = await LoadForStatusChangeAsync(
            currentUserId,
            paymentId,
            cancellationToken);

        await ApplyStatusAsync(
            payment,
            PaymentStatus.Reversed,
            cancellationToken);
    }

    private async Task<Payment> LoadForStatusChangeAsync(
        Guid currentUserId,
        Guid paymentId,
        CancellationToken cancellationToken)
    {
        var actor = await GetActorAsync(currentUserId, cancellationToken);

        EnsureCanModify(actor);

        var payment = await GetPaymentAsync(paymentId, cancellationToken);

        EnsureCompanyAccess(actor, payment.CompanyId);

        return payment;
    }

    private async Task ApplyStatusAsync(
        Payment payment,
        PaymentStatus newStatus,
        CancellationToken cancellationToken)
    {
        EnsureValidTransition(payment.Status, newStatus);

        if (newStatus == PaymentStatus.Completed)
        {
            await EnsureCanCompleteAsync(payment, cancellationToken);
        }

        payment.Status = newStatus;
        payment.UpdatedAtUtc = DateTime.UtcNow;

        // Payroll follows the payment: paid when completed, back to
        // Approved when the payment that paid it is reversed.
        if (payment.PayrollRecordId.HasValue)
        {
            if (newStatus == PaymentStatus.Completed)
            {
                await MarkPayrollPaidAsync(payment, cancellationToken);
            }
            else if (newStatus == PaymentStatus.Reversed)
            {
                await RevertPayrollAsync(payment, cancellationToken);
            }
        }

        // The invoice is recalculated from its completed payments, counting
        // this payment at its NEW status, so one save keeps everything
        // consistent.
        if (payment.InvoiceId.HasValue)
        {
            await RecalculateInvoiceAsync(
                payment.InvoiceId.Value,
                payment,
                cancellationToken);
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    // The single recalculation. Stages changes only; the caller saves.
    private async Task RecalculateInvoiceAsync(
        Guid invoiceId,
        Payment changing,
        CancellationToken cancellationToken)
    {
        var invoice = await _dbContext.Invoices
            .SingleOrDefaultAsync(
                x => x.Id == invoiceId && !x.IsDeleted,
                cancellationToken);

        if (invoice is null)
        {
            return;
        }

        // Completed payments already saved, except the one being changed...
        var paid = await _dbContext.Payments
            .Where(x =>
                x.InvoiceId == invoiceId &&
                x.Id != changing.Id &&
                x.Status == PaymentStatus.Completed &&
                !x.IsDeleted)
            .SumAsync(x => (decimal?)x.Amount, cancellationToken) ?? 0m;

        // ...plus that one, at its new status.
        if (changing.Status == PaymentStatus.Completed && !changing.IsDeleted)
        {
            paid += changing.Amount;
        }

        invoice.PaidAmount = paid;

        // Only invoices that are open for payment are re-statused. A
        // cancelled or not-yet-issued invoice keeps its status.
        if (invoice.Status is
            InvoiceStatus.Issued or
            InvoiceStatus.PartiallyPaid or
            InvoiceStatus.Paid)
        {
            invoice.Status =
                paid <= 0m
                    ? InvoiceStatus.Issued
                    : paid + Tolerance < invoice.TotalAmount
                        ? InvoiceStatus.PartiallyPaid
                        : InvoiceStatus.Paid;
        }

        invoice.UpdatedAtUtc = DateTime.UtcNow;
    }

    // A payment cannot be completed against a cancelled invoice, or in a
    // way that pays more than the invoice total.
    private async Task EnsureCanCompleteAsync(
        Payment payment,
        CancellationToken cancellationToken)
    {
        if (!payment.InvoiceId.HasValue)
        {
            return;
        }

        var invoice = await _dbContext.Invoices
            .AsNoTracking()
            .SingleOrDefaultAsync(
                x => x.Id == payment.InvoiceId.Value && !x.IsDeleted,
                cancellationToken)
            ?? throw new PaymentManagementException(
                "The invoice for this payment was not found.");

        if (invoice.Status == InvoiceStatus.Cancelled)
        {
            throw new PaymentManagementException(
                "A payment cannot be completed against a cancelled invoice.");
        }

        var paidByOthers = await _dbContext.Payments
            .Where(x =>
                x.InvoiceId == invoice.Id &&
                x.Id != payment.Id &&
                x.Status == PaymentStatus.Completed &&
                !x.IsDeleted)
            .SumAsync(x => (decimal?)x.Amount, cancellationToken) ?? 0m;

        var remaining = invoice.TotalAmount - paidByOthers;

        if (payment.Amount > remaining + Tolerance)
        {
            throw new PaymentManagementException(
                $"This payment exceeds the invoice balance. Remaining balance: {Math.Max(0m, remaining):N2}.");
        }
    }

    // ------------------------------------------------------------------
    // Payroll
    // ------------------------------------------------------------------

    private async Task MarkPayrollPaidAsync(
        Payment payment,
        CancellationToken cancellationToken)
    {
        var payroll = await _dbContext.PayrollRecords
            .SingleOrDefaultAsync(
                x =>
                    x.Id == payment.PayrollRecordId!.Value &&
                    x.CompanyId == payment.CompanyId &&
                    !x.IsDeleted,
                cancellationToken);

        if (payroll is null)
        {
            throw new PaymentManagementException(
                "Linked payroll record was not found or does not belong to the current company.");
        }

        if (payroll.Status != PayrollStatus.Approved)
        {
            throw new PaymentManagementException(
                "Linked payroll must be approved before the payment can be completed.");
        }

        payroll.Status = PayrollStatus.Paid;
        payroll.PaidAtUtc = DateTime.UtcNow;

        // The payment number, on every path. One path used to store the
        // word "Completed" here.
        payroll.PaymentReference = payment.PaymentNumber;
    }

    private async Task RevertPayrollAsync(
        Payment payment,
        CancellationToken cancellationToken)
    {
        var payroll = await _dbContext.PayrollRecords
            .SingleOrDefaultAsync(
                x =>
                    x.Id == payment.PayrollRecordId!.Value &&
                    x.CompanyId == payment.CompanyId &&
                    !x.IsDeleted,
                cancellationToken);

        if (payroll is null || payroll.Status != PayrollStatus.Paid)
        {
            return;
        }

        var paidByAnother = await _dbContext.Payments
            .AnyAsync(
                x =>
                    x.PayrollRecordId == payroll.Id &&
                    x.Id != payment.Id &&
                    x.Status == PaymentStatus.Completed &&
                    !x.IsDeleted,
                cancellationToken);

        if (paidByAnother)
        {
            return;
        }

        payroll.Status = PayrollStatus.Approved;
        payroll.PaidAtUtc = null;
        payroll.PaymentReference = null;
    }

    // ------------------------------------------------------------------
    // Access
    // ------------------------------------------------------------------

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
            ?? throw new PaymentManagementException(
                "Authenticated user was not found.");
    }

    private static void EnsureCanRead(User actor)
    {
        if (IsSuperAdmin(actor) ||
            HasRole(actor, AppRoles.CompanyAdmin) ||
            HasRole(actor, AppRoles.Accountant) ||
            HasRole(actor, AppRoles.SiteManager))
        {
            return;
        }

        throw new PaymentManagementException(
            "You are not authorized to view payments.");
    }

    private static void EnsureCanModify(User actor)
    {
        if (IsSuperAdmin(actor) ||
            HasRole(actor, AppRoles.CompanyAdmin) ||
            HasRole(actor, AppRoles.Accountant))
        {
            return;
        }

        throw new PaymentManagementException(
            "You are not authorized to manage payments.");
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
            throw new PaymentManagementException(
                "You are not authorized to access this payment.");
        }
    }

    // null = sees every site; otherwise only these sites.
    private async Task<List<Guid>?> GetVisibleSiteIdsAsync(
        User actor,
        CancellationToken cancellationToken)
    {
        var companyId = GetActorCompanyId(actor);

        var assignedSiteIds = await _dbContext.UserSiteAccesses
            .AsNoTracking()
            .Where(x =>
                x.UserId == actor.Id &&
                x.CompanyId == companyId &&
                x.IsActive &&
                !x.IsDeleted)
            .Select(x => x.SiteId)
            .ToListAsync(cancellationToken);

        if (assignedSiteIds.Count > 0)
        {
            return assignedSiteIds;
        }

        if (IsSuperAdmin(actor) ||
            HasRole(actor, AppRoles.CompanyAdmin) ||
            HasRole(actor, AppRoles.Accountant) ||
            HasRole(actor, AppRoles.SiteManager))
        {
            return null;
        }

        return assignedSiteIds;
    }

    private async Task EnsureSiteAccess(
        User actor,
        Guid? siteId,
        CancellationToken cancellationToken)
    {
        // A user with active site assignments cannot access unscoped payments.
        if (!siteId.HasValue)
        {
            var assignedSites = await GetVisibleSiteIdsAsync(
                actor,
                cancellationToken);

            if (assignedSites is { Count: > 0 })
            {
                throw new PaymentManagementException(
                    "Company-level payments are outside your assigned site scope.");
            }

            return;
        }

        var visibleSites = await GetVisibleSiteIdsAsync(
            actor,
            cancellationToken);

        if (visibleSites is not null &&
            !visibleSites.Contains(siteId.Value))
        {
            throw new PaymentManagementException(
                "You are not assigned to this site's payment scope.");
        }
    }

    // A payment on an invoice belongs to the invoice's site. Otherwise it
    // belongs to its own site. Reports use the same rule.
    private static Guid? EffectiveSiteId(Payment payment)
    {
        return payment.InvoiceId.HasValue && payment.Invoice is not null
            ? payment.Invoice.ConstructionSiteId
            : payment.ConstructionSiteId;
    }

    private static Guid GetActorCompanyId(User actor)
    {
        if (!actor.CompanyId.HasValue)
        {
            throw new PaymentManagementException(
                "Current user is not assigned to a company.");
        }

        return actor.CompanyId.Value;
    }

    private async Task<Payment> GetPaymentAsync(
        Guid paymentId,
        CancellationToken cancellationToken)
    {
        return await _dbContext.Payments
            .Include(x => x.Invoice)
            .SingleOrDefaultAsync(
                x =>
                    x.Id == paymentId &&
                    !x.IsDeleted,
                cancellationToken)
            ?? throw new PaymentManagementException(
                "Payment was not found.");
    }

    // ------------------------------------------------------------------
    // Validation
    // ------------------------------------------------------------------

    private async Task EnsureReferencesAsync(
        Guid companyId,
        Guid? constructionSiteId,
        Guid? projectId,
        Guid? invoiceId,
        Guid? vendorId,
        Guid? payrollRecordId,
        PaymentDirection direction,
        CancellationToken cancellationToken)
    {
        if (constructionSiteId.HasValue)
        {
            var siteExists = await _dbContext.ConstructionSites
                .AnyAsync(
                    x =>
                        x.Id == constructionSiteId.Value &&
                        x.CompanyId == companyId &&
                        !x.IsDeleted,
                    cancellationToken);

            if (!siteExists)
            {
                throw new PaymentManagementException(
                    "Construction site was not found or does not belong to the current company.");
            }
        }

        if (projectId.HasValue)
        {
            var projectExists = await _dbContext.Projects
                .AnyAsync(
                    x =>
                        x.Id == projectId.Value &&
                        x.CompanyId == companyId &&
                        !x.IsDeleted,
                    cancellationToken);

            if (!projectExists)
            {
                throw new PaymentManagementException(
                    "Project was not found or does not belong to the current company.");
            }
        }

        if (invoiceId.HasValue)
        {
            var invoice = await _dbContext.Invoices
                .AsNoTracking()
                .SingleOrDefaultAsync(
                    x =>
                        x.Id == invoiceId.Value &&
                        x.CompanyId == companyId &&
                        !x.IsDeleted,
                    cancellationToken);

            if (invoice is null)
            {
                throw new PaymentManagementException(
                    "Invoice was not found or does not belong to the current company.");
            }

            if (invoice.Status is
                InvoiceStatus.Cancelled or
                InvoiceStatus.Paid)
            {
                throw new PaymentManagementException(
                    $"Payments cannot be added to an invoice with status {invoice.Status}.");
            }

            if (invoice.Type == InvoiceType.ClientInvoice &&
                direction != PaymentDirection.Incoming)
            {
                throw new PaymentManagementException(
                    "Client Invoice payments must use Incoming direction.");
            }

            if (invoice.Type == InvoiceType.VendorBill &&
                direction != PaymentDirection.Outgoing)
            {
                throw new PaymentManagementException(
                    "Vendor Bill payments must use Outgoing direction.");
            }

            if (invoice.Type == InvoiceType.VendorBill)
            {
                if (!invoice.VendorId.HasValue)
                {
                    throw new PaymentManagementException(
                        "Vendor Bill does not have an associated vendor.");
                }

                if (vendorId.HasValue &&
                    vendorId.Value != invoice.VendorId.Value)
                {
                    throw new PaymentManagementException(
                        "Payment vendor must match the Vendor Bill vendor.");
                }
            }

            if (invoice.Type == InvoiceType.ClientInvoice &&
                vendorId.HasValue)
            {
                throw new PaymentManagementException(
                    "Client Invoice payments must not specify a vendor.");
            }

            if (invoice.ConstructionSiteId != constructionSiteId)
            {
                throw new PaymentManagementException(
                    "Payment construction site must match the invoice construction site.");
            }

            if (invoice.ProjectId.HasValue &&
                projectId.HasValue &&
                invoice.ProjectId.Value != projectId.Value)
            {
                throw new PaymentManagementException(
                    "Payment project must match the invoice project.");
            }
        }

        if (vendorId.HasValue)
        {
            var vendorExists = await _dbContext.Vendors
                .AnyAsync(
                    x =>
                        x.Id == vendorId.Value &&
                        x.CompanyId == companyId &&
                        !x.IsDeleted,
                    cancellationToken);

            if (!vendorExists)
            {
                throw new PaymentManagementException(
                    "Vendor was not found or does not belong to the current company.");
            }
        }

        if (payrollRecordId.HasValue)
        {
            if (invoiceId.HasValue || vendorId.HasValue)
            {
                throw new PaymentManagementException(
                    "Payroll payments cannot specify an invoice or vendor.");
            }

            if (direction != PaymentDirection.Outgoing)
            {
                throw new PaymentManagementException(
                    "Payroll payments must use Outgoing direction.");
            }

            var payroll = await _dbContext.PayrollRecords
                .SingleOrDefaultAsync(
                    x =>
                        x.Id == payrollRecordId.Value &&
                        x.CompanyId == companyId &&
                        !x.IsDeleted,
                    cancellationToken);

            if (payroll is null)
            {
                throw new PaymentManagementException(
                    "Payroll record was not found or does not belong to the current company.");
            }

            if (payroll.Status != PayrollStatus.Approved)
            {
                throw new PaymentManagementException(
                    "Only approved payroll can be paid.");
            }
        }

        if (!invoiceId.HasValue &&
            !vendorId.HasValue &&
            !payrollRecordId.HasValue)
        {
            throw new PaymentManagementException(
                "Payment must reference an invoice, vendor, or payroll record.");
        }
    }

    private static void ValidatePayment(
        DateOnly paymentDate,
        decimal amount,
        decimal exchangeRate,
        PaymentDirection direction)
    {
        if (!Enum.IsDefined(direction))
        {
            throw new PaymentManagementException(
                "Payment direction is invalid.");
        }

        if (amount <= 0)
        {
            throw new PaymentManagementException(
                "Payment amount must be greater than zero.");
        }

        if (exchangeRate <= 0)
        {
            throw new PaymentManagementException(
                "Exchange rate must be greater than zero.");
        }

        if (paymentDate > DateOnly.FromDateTime(DateTime.UtcNow.Date))
        {
            throw new PaymentManagementException(
                "Payment date cannot be in the future.");
        }
    }

    private static void EnsureEditable(Payment payment)
    {
        if (payment.Status != PaymentStatus.Pending)
        {
            throw new PaymentManagementException(
                $"Payment cannot be modified when status is {payment.Status}.");
        }
    }

    private static void EnsureValidTransition(
        PaymentStatus currentStatus,
        PaymentStatus requestedStatus)
    {
        var valid = currentStatus switch
        {
            PaymentStatus.Pending =>
                requestedStatus is
                    PaymentStatus.Completed or
                    PaymentStatus.Failed or
                    PaymentStatus.Cancelled,

            PaymentStatus.Completed =>
                requestedStatus is PaymentStatus.Reversed,

            PaymentStatus.Failed => false,
            PaymentStatus.Cancelled => false,
            PaymentStatus.Reversed => false,

            _ => false
        };

        if (!valid)
        {
            throw new PaymentManagementException(
                $"Invalid payment status transition: {currentStatus} -> {requestedStatus}.");
        }
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    private static string CleanRequired(
        string? value,
        string fieldName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new PaymentManagementException(
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

    private static string CleanCurrencyCode(string? value)
    {
        var currency = CleanRequired(value, "Currency code")
            .ToUpperInvariant();

        if (currency.Length != 3)
        {
            throw new PaymentManagementException(
                "Currency code must contain exactly 3 characters.");
        }

        return currency;
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

    private static PaymentResponse Map(Payment payment)
    {
        return new PaymentResponse(
            payment.Id,
            payment.CompanyId,
            payment.ConstructionSiteId,
            payment.ProjectId,
            payment.InvoiceId,
            payment.Invoice?.InvoiceNumber,
            payment.VendorId,
            payment.PayrollRecordId,
            payment.PaymentNumber,
            payment.PaymentDate,
            payment.Direction,
            payment.Amount,
            payment.CurrencyCode,
            payment.ExchangeRate,
            payment.PaymentMethod,
            payment.ReferenceNumber,
            payment.Notes,
            payment.Status,
            payment.CreatedAtUtc,
            payment.UpdatedAtUtc);
    }
}

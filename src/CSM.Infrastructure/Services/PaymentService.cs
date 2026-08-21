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

public sealed class PaymentService : IPaymentService
{
    private readonly ApplicationDbContext _dbContext;

    public PaymentService(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IReadOnlyCollection<PaymentResponse>> GetAllAsync(
        Guid currentUserId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        EnsureCanRead(actor);

        IQueryable<Payment> query =
            _dbContext.Payments.AsNoTracking();

        if (!IsSuperAdmin(actor))
        {
            var companyId = GetActorCompanyId(actor);

            query = query.Where(
                x => x.CompanyId == companyId);
        }

        var payments = await query
            .OrderByDescending(x => x.PaymentDate)
            .ThenBy(x => x.PaymentNumber)
            .ToListAsync(cancellationToken);

        return payments
            .Select(Map)
            .ToArray();
    }

    public async Task<PaymentResponse> GetByIdAsync(
        Guid currentUserId,
        Guid paymentId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        EnsureCanRead(actor);

        var payment = await GetPaymentAsync(
            paymentId,
            cancellationToken);

        EnsureCompanyAccess(
            actor,
            payment.CompanyId);

        return Map(payment);
    }

    public async Task<PaymentResponse> CreateAsync(
        Guid currentUserId,
        CreatePaymentRequest request,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        EnsureCanModify(actor);

        var companyId = GetActorCompanyId(actor);

        var paymentNumber = CleanRequired(
            request.PaymentNumber,
            "Payment number");

        ValidatePayment(
            request.PaymentDate,
            request.Amount,
            request.ExchangeRate,
            request.Direction);

        await EnsureReferencesAsync(
            companyId,
            request.InvoiceId,
            request.VendorId,
            request.Direction,
            cancellationToken);

        var duplicateExists = await _dbContext.Payments
            .AnyAsync(
                x =>
                    x.CompanyId == companyId &&
                    x.PaymentNumber == paymentNumber &&
                    !x.IsDeleted,
                cancellationToken);

        if (duplicateExists)
        {
            throw new PaymentManagementException(
                $"Payment number '{paymentNumber}' already exists.");
        }

        var payment = new Payment
        {
            CompanyId = companyId,
            InvoiceId = request.InvoiceId,
            VendorId = request.VendorId,
            PaymentNumber = paymentNumber,
            PaymentDate = request.PaymentDate,
            Direction = request.Direction,
            Amount = request.Amount,
            CurrencyCode = CleanCurrencyCode(
                request.CurrencyCode),
            ExchangeRate = request.ExchangeRate,
            PaymentMethod = Clean(request.PaymentMethod),
            ReferenceNumber =
                Clean(request.ReferenceNumber),
            Notes = Clean(request.Notes),
            Status = PaymentStatus.Pending
        };

        _dbContext.Payments.Add(payment);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Map(payment);
    }

    public async Task<PaymentResponse> UpdateAsync(
        Guid currentUserId,
        Guid paymentId,
        UpdatePaymentRequest request,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        EnsureCanModify(actor);

        var payment = await GetPaymentAsync(
            paymentId,
            cancellationToken);

        EnsureCompanyAccess(
            actor,
            payment.CompanyId);

        EnsureEditable(payment);

        ValidatePayment(
            request.PaymentDate,
            request.Amount,
            request.ExchangeRate,
            request.Direction);

        await EnsureReferencesAsync(
            payment.CompanyId,
            request.InvoiceId,
            request.VendorId,
            request.Direction,
            cancellationToken);

        payment.InvoiceId = request.InvoiceId;
        payment.VendorId = request.VendorId;
        payment.PaymentDate = request.PaymentDate;
        payment.Direction = request.Direction;
        payment.Amount = request.Amount;
        payment.CurrencyCode =
            CleanCurrencyCode(
                request.CurrencyCode);
        payment.ExchangeRate =
            request.ExchangeRate;
        payment.PaymentMethod =
            Clean(request.PaymentMethod);
        payment.ReferenceNumber =
            Clean(request.ReferenceNumber);
        payment.Notes =
            Clean(request.Notes);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Map(payment);
    }

    public async Task<PaymentResponse> ChangeStatusAsync(
        Guid currentUserId,
        Guid paymentId,
        ChangePaymentStatusRequest request,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        EnsureCanModify(actor);

        var payment = await GetPaymentAsync(
            paymentId,
            cancellationToken);

        EnsureCompanyAccess(
            actor,
            payment.CompanyId);

        EnsureValidTransition(
            payment.Status,
            request.Status);

        payment.Status = request.Status;

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        if (payment.InvoiceId.HasValue)
        {
            await SynchronizeInvoiceStatusAsync(
                payment.InvoiceId.Value,
                cancellationToken);
        }

        return Map(payment);
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
            ?? throw new PaymentManagementException(
                "Authenticated user was not found.");
    }

    private static void EnsureCanRead(
        User actor)
    {
        if (IsSuperAdmin(actor) ||
            HasRole(actor, AppRoles.CompanyAdmin) ||
            HasRole(actor, AppRoles.Accountant))
        {
            return;
        }

        throw new PaymentManagementException(
            "You are not authorized to view payments.");
    }

    private static void EnsureCanModify(
        User actor)
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

    private static Guid GetActorCompanyId(
        User actor)
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
            .SingleOrDefaultAsync(
                x =>
                    x.Id == paymentId &&
                    !x.IsDeleted,
                cancellationToken)
            ?? throw new PaymentManagementException(
                "Payment was not found.");
    }

    private async Task EnsureReferencesAsync(
        Guid companyId,
        Guid? invoiceId,
        Guid? vendorId,
        PaymentDirection direction,
        CancellationToken cancellationToken)
    {
        Invoice? invoice = null;

        if (invoiceId.HasValue)
        {
            invoice = await _dbContext.Invoices
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

        if (!invoiceId.HasValue &&
            !vendorId.HasValue)
        {
            throw new PaymentManagementException(
                "Payment must reference an invoice or vendor.");
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

        if (paymentDate > DateOnly.FromDateTime(
                DateTime.UtcNow.Date))
        {
            throw new PaymentManagementException(
                "Payment date cannot be in the future.");
        }
    }

    private static void EnsureEditable(
        Payment payment)
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
                requestedStatus is
                    PaymentStatus.Reversed,

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

    private async Task SynchronizeInvoiceStatusAsync(
        Guid invoiceId,
        CancellationToken cancellationToken)
    {
        var invoice = await _dbContext.Invoices
            .SingleOrDefaultAsync(
                x =>
                    x.Id == invoiceId &&
                    !x.IsDeleted,
                cancellationToken);

        if (invoice is null)
        {
            return;
        }

        var completedPayments = await _dbContext.Payments
            .Where(
                x =>
                    x.InvoiceId == invoiceId &&
                    x.Status == PaymentStatus.Completed &&
                    !x.IsDeleted)
            .SumAsync(
                x => (decimal?)x.Amount,
                cancellationToken)
            ?? 0m;

        if (completedPayments <= 0)
        {
            if (invoice.Status != InvoiceStatus.Cancelled)
            {
                invoice.Status =
                    InvoiceStatus.Issued;
            }
        }
        else if (completedPayments < invoice.TotalAmount)
        {
            invoice.Status =
                InvoiceStatus.PartiallyPaid;
        }
        else
        {
            invoice.Status =
                InvoiceStatus.Paid;
        }

        await _dbContext.SaveChangesAsync(
            cancellationToken);
    }

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

    private static string? Clean(
        string? value)
    {
        return string.IsNullOrWhiteSpace(value)
            ? null
            : value.Trim();
    }

    private static string CleanCurrencyCode(
        string? value)
    {
        var currency = CleanRequired(
            value,
            "Currency code")
            .ToUpperInvariant();

        if (currency.Length != 3)
        {
            throw new PaymentManagementException(
                "Currency code must contain exactly 3 characters.");
        }

        return currency;
    }

    private static bool IsSuperAdmin(
        User actor)
    {
        return HasRole(
            actor,
            AppRoles.SuperAdmin);
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

    private static PaymentResponse Map(
        Payment payment)
    {
        return new PaymentResponse(
            payment.Id,
            payment.CompanyId,
            payment.InvoiceId,
            payment.VendorId,
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

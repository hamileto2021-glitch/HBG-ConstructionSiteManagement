using CSM.Domain.Common;
using CSM.Domain.Enums;

namespace CSM.Domain.Entities.Finance;

public class Payment : TenantEntity
{
    public Guid? InvoiceId { get; set; }

    public Guid? VendorId { get; set; }

    public string PaymentNumber { get; set; } = string.Empty;

    public DateOnly PaymentDate { get; set; }

    public PaymentDirection Direction { get; set; }

    public decimal Amount { get; set; }

    public string CurrencyCode { get; set; } = "ETB";

    public decimal ExchangeRate { get; set; } = 1;

    public string? PaymentMethod { get; set; }

    public string? ReferenceNumber { get; set; }

    public string? Notes { get; set; }

    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;

    public Invoice? Invoice { get; set; }

    public Vendor? Vendor { get; set; }
}
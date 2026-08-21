using CSM.Domain.Enums;

namespace CSM.Application.Finance.Payments.Dtos;

public sealed record UpdatePaymentRequest(
    Guid? InvoiceId,
    Guid? VendorId,
    DateOnly PaymentDate,
    PaymentDirection Direction,
    decimal Amount,
    string CurrencyCode,
    decimal ExchangeRate,
    string? PaymentMethod,
    string? ReferenceNumber,
    string? Notes);

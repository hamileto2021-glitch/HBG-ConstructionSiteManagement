using CSM.Domain.Enums;

namespace CSM.Application.Finance.Payments.Dtos;

public sealed record CreatePaymentRequest(
    Guid? InvoiceId,
    Guid? VendorId,
    string PaymentNumber,
    DateOnly PaymentDate,
    PaymentDirection Direction,
    decimal Amount,
    string CurrencyCode,
    decimal ExchangeRate,
    string? PaymentMethod,
    string? ReferenceNumber,
    string? Notes);

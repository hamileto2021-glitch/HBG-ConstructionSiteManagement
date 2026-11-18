namespace CSM.Web.Models.Companies;

public sealed record CompanyLookupModel(
    Guid Id,
    string Name);

public sealed record CreateCompanyModel
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? LegalName { get; set; }
    public string? TaxIdentificationNumber { get; set; }
    public string? RegistrationNumber { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Email { get; set; }
    public string? Address { get; set; }
    public string? City { get; set; }
    public string? Country { get; set; }
    public string BaseCurrencyCode { get; set; } = "USD";
}

public sealed record CompanyResponseModel(
    Guid Id,
    string Code,
    string Name,
    string? LegalName,
    string? TaxIdentificationNumber,
    string? RegistrationNumber,
    string? PhoneNumber,
    string? Email,
    string? Address,
    string? City,
    string? Country,
    string BaseCurrencyCode,
    bool IsActive,
    DateTime CreatedAtUtc);

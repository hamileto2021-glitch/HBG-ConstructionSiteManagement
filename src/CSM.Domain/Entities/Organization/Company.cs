using CSM.Domain.Common;

namespace CSM.Domain.Entities.Organization;

public class Company : AuditableEntity
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

    public string BaseCurrencyCode { get; set; } = "ETB";

    public bool IsActive { get; set; } = true;

    public ICollection<BusinessUnit> BusinessUnits { get; set; }
        = new List<BusinessUnit>();

    public ICollection<ConstructionSite> ConstructionSites { get; set; }
        = new List<ConstructionSite>();
}
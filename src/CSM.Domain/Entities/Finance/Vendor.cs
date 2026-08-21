using CSM.Domain.Common;
using CSM.Domain.Entities.Procurement;
namespace CSM.Domain.Entities.Finance;

public class Vendor : TenantEntity
{
    public string VendorCode { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;

    public string? ContactPerson { get; set; }

    public string? PhoneNumber { get; set; }

    public string? Email { get; set; }

    public string? Address { get; set; }

    public string? TaxIdentificationNumber { get; set; }

    public string? RegistrationNumber { get; set; }

    public string? BankName { get; set; }

    public string? BankAccountNumber { get; set; }

    public bool IsActive { get; set; } = true;

    public ICollection<PurchaseOrder> PurchaseOrders { get; set; }
    = new List<PurchaseOrder>();

public ICollection<Equipment> Equipment { get; set; }
    = new List<Equipment>();

    public ICollection<Expense> Expenses { get; set; }
        = new List<Expense>();

    public ICollection<Invoice> Invoices { get; set; }
        = new List<Invoice>();
}
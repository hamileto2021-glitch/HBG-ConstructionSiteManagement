namespace CSM.Web.Models.Reporting;

public sealed class ManagementReportsResponse
{
    public ManagementReportSectionResponse? ProjectProgress { get; set; }
    public ManagementReportSectionResponse? SiteOperations { get; set; }
    public ManagementReportSectionResponse? HumanResources { get; set; }
    public ManagementReportSectionResponse? ProcurementInventory { get; set; }
    public ManagementReportSectionResponse? SafetyCompliance { get; set; }
}

public sealed class ManagementReportSectionResponse
{
    public List<ManagementReportMetricResponse> Metrics { get; set; } = [];
    public List<ManagementReportStatusResponse> Statuses { get; set; } = [];
}

public sealed class ManagementReportMetricResponse
{
    public string Label { get; set; } = string.Empty;
    public decimal Value { get; set; }
    public string Unit { get; set; } = string.Empty;
    public string? Hint { get; set; }
}

public sealed class ManagementReportStatusResponse
{
    public string Category { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int Count { get; set; }
}

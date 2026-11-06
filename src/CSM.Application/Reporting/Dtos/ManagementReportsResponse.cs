namespace CSM.Application.Reporting.Dtos;

public sealed record ManagementReportsResponse(
    ManagementReportSectionResponse? ProjectProgress,
    ManagementReportSectionResponse? SiteOperations,
    ManagementReportSectionResponse? HumanResources,
    ManagementReportSectionResponse? ProcurementInventory,
    ManagementReportSectionResponse? SafetyCompliance);

public sealed record ManagementReportSectionResponse(
    IReadOnlyCollection<ManagementReportMetricResponse> Metrics,
    IReadOnlyCollection<ManagementReportStatusResponse> Statuses);

public sealed record ManagementReportMetricResponse(
    string Label,
    decimal Value,
    string Unit,
    string? Hint = null);

public sealed record ManagementReportStatusResponse(
    string Category,
    string Status,
    int Count);

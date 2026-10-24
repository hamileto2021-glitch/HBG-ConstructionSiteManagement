using CSM.Web.Components;
using CSM.Web.Services;
using CSM.Web.Services.HRM;
using Microsoft.AspNetCore.Components.Server.ProtectedBrowserStorage;
using Microsoft.Extensions.Localization;
using System.Globalization;
using Microsoft.AspNetCore.Localization;


var builder = WebApplication.CreateBuilder(args);
builder.Services.AddLocalization();

var apiBaseUrl = builder.Configuration["ApiSettings:BaseUrl"];
var apiHost = builder.Configuration["CSM_API_HOST"];
if (string.IsNullOrWhiteSpace(apiBaseUrl) &&
    !builder.Environment.IsDevelopment() &&
    !string.IsNullOrWhiteSpace(apiHost))
{
    apiBaseUrl = $"https://{apiHost.TrimEnd('/')}/api/";
}

if (!Uri.TryCreate(apiBaseUrl, UriKind.Absolute, out var apiUri) ||
    !apiUri.AbsolutePath.EndsWith("/api/", StringComparison.OrdinalIgnoreCase) ||
    !string.IsNullOrEmpty(apiUri.Query) ||
    !string.IsNullOrEmpty(apiUri.Fragment) ||
    !string.IsNullOrEmpty(apiUri.UserInfo) ||
    (apiUri.Scheme != Uri.UriSchemeHttps &&
     !(builder.Environment.IsDevelopment() &&
       apiUri.Scheme == Uri.UriSchemeHttp)))
{
    throw new InvalidOperationException(
        "Configure ApiSettings:BaseUrl as an absolute API URL ending in /api/; Production requires HTTPS.");
}

var allowedHosts =
    builder.Configuration["AllowedHosts"] ??
    builder.Configuration["RENDER_EXTERNAL_HOSTNAME"];
if (!builder.Environment.IsDevelopment() &&
    (string.IsNullOrWhiteSpace(allowedHosts) ||
     allowedHosts.Split(',', StringSplitOptions.TrimEntries)
         .Any(host => host.Length == 0 || host.Contains('*'))))
{
    throw new InvalidOperationException(
        "Configure AllowedHosts with the deployed web hostname(s).");
}

var supportedCultures = new[]
{
    new CultureInfo("en"),
    new CultureInfo("am"),
    new CultureInfo("om")
};

builder.Services.Configure<RequestLocalizationOptions>(options =>
{
    options.DefaultRequestCulture =
        new RequestCulture("en");

    options.SupportedCultures = supportedCultures;
    options.SupportedUICultures = supportedCultures;
});

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddAuthorization();
builder.Services.AddCascadingAuthenticationState();

builder.Services.AddScoped(sp =>
{
    var factory = sp.GetRequiredService<IHttpClientFactory>();
    return factory.CreateClient("CSM.Api");
});

builder.Services.AddHttpClient("CSM.Api", client =>
{
    client.BaseAddress = apiUri;
});

builder.Services.AddScoped<UserPreferencesService>();
builder.Services.AddScoped<UserSessionsService>();
builder.Services.AddScoped<LoginHistoryService>();
builder.Services.AddScoped<AuditHistoryService>();
builder.Services.AddScoped<PersonalDataExportService>();
builder.Services.AddScoped<PrivacyDataRequestService>();
builder.Services.AddScoped<PasswordChangeService>();


builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<AuthService>(sp =>
    (AuthService)sp.GetRequiredService<IAuthService>());
builder.Services.AddScoped<ProtectedSessionStorage>();
builder.Services.AddScoped<CurrentUserProfileService>();
builder.Services.AddScoped<MyProfileService>();
builder.Services.AddScoped<OrganizationMembershipService>();
builder.Services.AddScoped<IExecutiveDashboardService,
    ExecutiveDashboardService>();

    builder.Services.AddScoped<IProjectService, ProjectService>();
    builder.Services.AddScoped<IProcurementService, ProcurementService>();
    builder.Services.AddScoped<IInventoryService, InventoryService>();

    builder.Services.AddScoped<IVendorService, VendorService>();

    builder.Services.AddScoped<IEquipmentService, EquipmentService>();

    builder.Services.AddScoped<UserWebService>();

    builder.Services.AddScoped<RoleWebService>();

builder.Services.AddScoped<IFinanceService, FinanceService>();
builder.Services.AddScoped<INotificationApiService, NotificationApiService>();

builder.Services.AddScoped<IEmployeeService, EmployeeService>();

builder.Services.AddScoped<
    IContractorService,
    ContractorService>();

builder.Services.AddScoped<IAttendanceService, AttendanceService>();
builder.Services.AddScoped<ISiteAssignmentService, SiteAssignmentService>();
builder.Services.AddScoped<IShiftService, ShiftService>();
builder.Services.AddScoped<ILeaveService, LeaveService>();
builder.Services.AddScoped<IPayrollService, PayrollService>();
builder.Services.AddScoped<ITimesheetService, TimesheetService>();
builder.Services.AddScoped<IComplianceService, ComplianceService>();

builder.Services.AddScoped<IReportingService, ReportingService>();

builder.Services.AddScoped<IOfflineSyncStore, OfflineSyncStore>();
builder.Services.AddScoped<IOfflineSyncService, OfflineSyncService>();
builder.Services.AddScoped<
    IOfflineSyncCoordinator,
    OfflineSyncCoordinator>();

builder.Services.AddScoped<IOfflineSyncApi, OfflineSyncApi>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    app.UseHsts();
}

app.UseStatusCodePagesWithReExecute("/not-found", createScopeForStatusCodePages: true);

app.UseHttpsRedirection();

app.UseRequestLocalization();

app.UseAntiforgery();

app.MapStaticAssets();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
using CSM.Infrastructure;
using CSM.Infrastructure.Persistence;
using System.Text.Json.Serialization;
using CSM.Application.Finance.Invoices;
using CSM.Application.Finance.Payments;
using CSM.Infrastructure.Services;
using CSM.Api.Controllers;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.EntityFrameworkCore;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddDataProtection()
    .PersistKeysToFileSystem(
        new DirectoryInfo(
            builder.Configuration["DataProtection:KeysPath"]
            ?? "/app/DataProtection-Keys"));

// Infrastructure
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddScoped<NotificationHelper>();
builder.Services.AddScoped<EquipmentFuelLogService>();
builder.Services.AddScoped<EquipmentHourLogService>();
builder.Services.AddScoped<EquipmentUtilizationService>();
builder.Services.AddScoped<ComplianceDashboardService>();
builder.Services.AddScoped<ComplianceViolationService>();
builder.Services.AddScoped<ComplianceAlertService>();
builder.Services.AddScoped<ComplianceReportService>();
builder.Services.AddScoped<IInvoicePdfService, InvoicePdfService>();
builder.Services.AddScoped<
    IPaymentReceiptPdfService,
    PaymentReceiptPdfService>();

builder.Services.AddHostedService<CSM.Api.BackgroundServices.MissedCheckInNotifier>();

// Controllers
builder.Services
    .AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(
            new JsonStringEnumConverter());
    });




// Built-in OpenAPI (.NET 10)
builder.Services.AddOpenApi();

var allowedOrigins = builder.Configuration
    .GetSection("Cors:AllowedOrigins")
    .Get<string[]>() ?? [];

var invalidOrigins = allowedOrigins
    .Where(origin =>
        !Uri.TryCreate(origin, UriKind.Absolute, out var uri) ||
        (uri.Scheme != Uri.UriSchemeHttps &&
         !(builder.Environment.IsDevelopment() &&
           uri.Scheme == Uri.UriSchemeHttp)) ||
        uri.AbsolutePath != "/" ||
        !string.IsNullOrEmpty(uri.Query) ||
        !string.IsNullOrEmpty(uri.Fragment) ||
        !string.IsNullOrEmpty(uri.UserInfo))
    .ToArray();

if (invalidOrigins.Length > 0)
{
    throw new InvalidOperationException(
        "Cors:AllowedOrigins must contain exact HTTPS origins (HTTP is allowed only in Development).");
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
        "Configure AllowedHosts with the deployed API hostname(s).");
}

builder.Services.AddCors(options =>
{
    options.AddPolicy("BrowserClients", policy =>
    {
        policy
            .WithOrigins(allowedOrigins)
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

var app = builder.Build();

// OpenAPI endpoint
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

if (!app.Environment.IsDevelopment() &&
    builder.Configuration.GetValue<bool>(
        "HttpsRedirection:Enabled", true))
{
    app.UseHttpsRedirection();
}

app.Use(async (context, next) =>
{
    if (context.Request.Path.StartsWithSegments(
            "/uploads/daily-progress"))
    {
        context.Response.StatusCode = StatusCodes.Status404NotFound;
        return;
    }

    await next();
});

app.UseStaticFiles();

app.UseCors("BrowserClients");

app.UseAuthentication();
app.Use(async (context, next) =>
{
    try
    {
        await next();
    }
    catch (UnauthorizedAccessException)
    {
        app.Logger.LogWarning(
            "A project-data access check denied an authenticated request.");
        if (context.Response.HasStarted)
            throw;

        context.Response.Clear();
        context.Response.StatusCode = StatusCodes.Status403Forbidden;
        await context.Response.WriteAsJsonAsync(new
        {
            message = "You are not authorized to access this resource."
        });
    }
});
app.Use(async (context, next) =>
{
    var mustChangePassword = string.Equals(
        context.User.FindFirst("must_change_password")?.Value,
        "true",
        StringComparison.OrdinalIgnoreCase);

    var endpointAllowsPasswordChange =
        context.GetEndpoint()?.Metadata
            .GetMetadata<MustChangePasswordAllowedAttribute>() is not null;

    if (context.User.Identity?.IsAuthenticated == true &&
        mustChangePassword &&
        !endpointAllowsPasswordChange)
    {
        context.Response.StatusCode = StatusCodes.Status403Forbidden;
        await context.Response.WriteAsJsonAsync(new
        {
            message = "Change your password before using this resource."
        });
        return;
    }

    await next();
});
app.UseAuthorization();

app.MapControllers();

app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));

if (app.Configuration.GetValue<bool>(
        "Database:ApplyMigrationsOnStartup"))
{
    await using var scope = app.Services.CreateAsyncScope();
    var dbContext =
        scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    await dbContext.Database.MigrateAsync();
}

await DatabaseInitializer.InitializeAsync(app.Services);

app.Run();
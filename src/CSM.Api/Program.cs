using CSM.Infrastructure;
using CSM.Infrastructure.Persistence;
using System.Text.Json.Serialization;
using CSM.Application.Finance.Invoices;
using CSM.Application.Finance.Payments;
using CSM.Infrastructure.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

builder.WebHost.UseUrls(
    "http://0.0.0.0:5065",
    "https://0.0.0.0:7051");

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

builder.Services.AddCors(options =>
{
    options.AddPolicy("FlutterWeb", policy =>
    {
        policy
            .AllowAnyOrigin()
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

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseStaticFiles();

app.UseCors("FlutterWeb");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

await DatabaseInitializer.InitializeAsync(app.Services);

app.Run();
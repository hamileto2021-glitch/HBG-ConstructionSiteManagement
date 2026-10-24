using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace CSM.Infrastructure.Persistence;

public sealed class ApplicationDbContextFactory
: IDesignTimeDbContextFactory<ApplicationDbContext>
{
public ApplicationDbContext CreateDbContext(string[] args)
{
var basePath = Directory.GetCurrentDirectory();

    var configuration = new ConfigurationBuilder()
        .SetBasePath(basePath)
        .AddJsonFile("appsettings.json", optional: true)
        .AddJsonFile(
            Path.Combine("src", "CSM.Api", "appsettings.json"),
            optional: true)
        .AddEnvironmentVariables()
        .Build();

    var connectionString =
        configuration.GetConnectionString("DefaultConnection");

    if (string.IsNullOrWhiteSpace(connectionString))
    {
        throw new InvalidOperationException(
            "ConnectionStrings:DefaultConnection was not found. " +
            "Check the API appsettings.json or environment variables.");
    }

    var optionsBuilder =
        new DbContextOptionsBuilder<ApplicationDbContext>();

    var provider =
        configuration["Database:Provider"] ?? "SqlServer";

    if (string.Equals(
            provider,
            "PostgreSQL",
            StringComparison.OrdinalIgnoreCase))
    {
        optionsBuilder.UseNpgsql(
            connectionString,
            postgresOptions =>
            {
                postgresOptions.MigrationsAssembly(
                    "CSM.Infrastructure.PostgreSqlMigrations");
                postgresOptions.EnableRetryOnFailure(
                    maxRetryCount: 5,
                    maxRetryDelay: TimeSpan.FromSeconds(10),
                    errorCodesToAdd: null);
            });
    }
    else if (string.Equals(
                 provider,
                 "SqlServer",
                 StringComparison.OrdinalIgnoreCase))
    {
        optionsBuilder.UseSqlServer(
            connectionString,
            sqlOptions => sqlOptions.EnableRetryOnFailure(
                maxRetryCount: 5,
                maxRetryDelay: TimeSpan.FromSeconds(10),
                errorNumbersToAdd: null));
    }
    else
    {
        throw new InvalidOperationException(
            $"Unsupported Database:Provider '{provider}'.");
    }

    return new ApplicationDbContext(optionsBuilder.Options);
}

}

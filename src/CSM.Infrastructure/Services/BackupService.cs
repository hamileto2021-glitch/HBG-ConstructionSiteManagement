using CSM.Application.Common.Backup;
using CSM.Infrastructure.Persistence;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.Data;

namespace CSM.Infrastructure.Services;

public sealed class BackupService : IBackupService
{
    private readonly IConfiguration _configuration;

    public BackupService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    private string BackupFolder =>
        Path.Combine(AppContext.BaseDirectory, "Backups");

    public async Task<IReadOnlyCollection<BackupInfoDto>> GetBackupsAsync(
        CancellationToken cancellationToken)
    {
        Directory.CreateDirectory(BackupFolder);

        var files = Directory.GetFiles(BackupFolder, "*.bak")
            .Select(x => new FileInfo(x))
            .OrderByDescending(x => x.CreationTimeUtc)
            .Select(x => new BackupInfoDto
            {
                FileName = x.Name,
                CreatedAtUtc = x.CreationTimeUtc,
                FileSizeBytes = x.Length
            })
            .ToList();

        return await Task.FromResult(files);
    }

    public async Task<string> CreateBackupAsync(
        CancellationToken cancellationToken)
    {
        Directory.CreateDirectory(BackupFolder);

        var builder = new SqlConnectionStringBuilder(
            _configuration.GetConnectionString("DefaultConnection"));

        var database = builder.InitialCatalog;

        var fileName =
            $"CSM_{DateTime.UtcNow:yyyyMMdd_HHmmss}.bak";

        var path = Path.Combine(BackupFolder, fileName);

        var databaseIdentifier =
            new SqlCommandBuilder().QuoteIdentifier(database);
        var sql = $"""
BACKUP DATABASE {databaseIdentifier}
TO DISK = @backupPath
WITH INIT, COMPRESSION;
""";

        await ExecuteSqlAsync(
            sql,
            new SqlParameter("@backupPath", SqlDbType.NVarChar, 4000)
            {
                Value = path
            },
            cancellationToken);

        return fileName;
    }

    public async Task RestoreBackupAsync(
        string backupFilePath,
        CancellationToken cancellationToken)
    {
        var builder = new SqlConnectionStringBuilder(
            _configuration.GetConnectionString("DefaultConnection"));

        var database = builder.InitialCatalog;
        var databaseIdentifier =
            new SqlCommandBuilder().QuoteIdentifier(database);

        var backupFolder = Path.GetFullPath(BackupFolder);
        var fullBackupPath = Path.GetFullPath(backupFilePath);
        var backupFolderPrefix = backupFolder.EndsWith(
            Path.DirectorySeparatorChar)
            ? backupFolder
            : backupFolder + Path.DirectorySeparatorChar;

        if (!fullBackupPath.StartsWith(
                backupFolderPrefix,
                StringComparison.OrdinalIgnoreCase) ||
            !string.Equals(
                Path.GetExtension(fullBackupPath),
                ".bak",
                StringComparison.OrdinalIgnoreCase) ||
            !File.Exists(fullBackupPath))
        {
            throw new InvalidOperationException(
                "The backup file path is invalid.");
        }

        builder.InitialCatalog = "master";

        var sql = $"""
ALTER DATABASE {databaseIdentifier}
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

BEGIN TRY
RESTORE DATABASE {databaseIdentifier}
FROM DISK = @backupPath
WITH REPLACE;

ALTER DATABASE {databaseIdentifier}
SET MULTI_USER;
END TRY
BEGIN CATCH
    ALTER DATABASE {databaseIdentifier}
    SET MULTI_USER;
    THROW;
END CATCH;
""";

        await using var connection =
            new SqlConnection(builder.ConnectionString);

        await connection.OpenAsync(cancellationToken);

        await using var command =
            new SqlCommand(sql, connection);

        command.Parameters.Add(
            new SqlParameter("@backupPath", SqlDbType.NVarChar, 4000)
            {
                Value = fullBackupPath
            });

        command.CommandTimeout = 0;

        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private async Task ExecuteSqlAsync(
        string sql,
        SqlParameter parameter,
        CancellationToken cancellationToken)
    {
        await using var connection =
            new SqlConnection(
                _configuration.GetConnectionString("DefaultConnection"));

        await connection.OpenAsync(cancellationToken);

        await using var command =
            new SqlCommand(sql, connection);

        command.Parameters.Add(parameter);
        command.CommandTimeout = 0;

        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
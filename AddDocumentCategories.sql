BEGIN TRANSACTION;
CREATE TABLE [Roles] (
    [Id] uniqueidentifier NOT NULL,
    [Name] nvarchar(100) NOT NULL,
    [NormalizedName] nvarchar(100) NOT NULL,
    [Description] nvarchar(500) NULL,
    [IsSystemRole] bit NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    CONSTRAINT [PK_Roles] PRIMARY KEY ([Id])
);

CREATE TABLE [Users] (
    [Id] uniqueidentifier NOT NULL,
    [CompanyId] uniqueidentifier NULL,
    [EmployeeId] uniqueidentifier NULL,
    [Email] nvarchar(256) NOT NULL,
    [NormalizedEmail] nvarchar(256) NOT NULL,
    [PasswordHash] nvarchar(1000) NOT NULL,
    [FirstName] nvarchar(100) NOT NULL,
    [LastName] nvarchar(100) NOT NULL,
    [IsActive] bit NOT NULL,
    [MustChangePassword] bit NOT NULL,
    [LastLoginAtUtc] datetime2 NULL,
    [FailedLoginAttempts] int NOT NULL,
    [LockedUntilUtc] datetime2 NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    CONSTRAINT [PK_Users] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Users_Companies_CompanyId] FOREIGN KEY ([CompanyId]) REFERENCES [Companies] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Users_Employees_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [Employees] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [RefreshTokens] (
    [Id] uniqueidentifier NOT NULL,
    [UserId] uniqueidentifier NOT NULL,
    [TokenHash] nvarchar(128) NOT NULL,
    [ExpiresAtUtc] datetime2 NOT NULL,
    [RevokedAtUtc] datetime2 NULL,
    [ReplacedByTokenHash] nvarchar(128) NULL,
    [RevocationReason] nvarchar(500) NULL,
    [CreatedByIp] nvarchar(100) NULL,
    [RevokedByIp] nvarchar(100) NULL,
    [DeviceName] nvarchar(300) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    CONSTRAINT [PK_RefreshTokens] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_RefreshTokens_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [UserRoles] (
    [Id] uniqueidentifier NOT NULL,
    [UserId] uniqueidentifier NOT NULL,
    [RoleId] uniqueidentifier NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    CONSTRAINT [PK_UserRoles] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_UserRoles_Roles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [Roles] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_UserRoles_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE NO ACTION
);

CREATE UNIQUE INDEX [IX_RefreshTokens_TokenHash] ON [RefreshTokens] ([TokenHash]);

CREATE INDEX [IX_RefreshTokens_UserId_ExpiresAtUtc] ON [RefreshTokens] ([UserId], [ExpiresAtUtc]);

CREATE UNIQUE INDEX [IX_Roles_NormalizedName] ON [Roles] ([NormalizedName]);

CREATE INDEX [IX_UserRoles_RoleId] ON [UserRoles] ([RoleId]);

CREATE UNIQUE INDEX [IX_UserRoles_UserId_RoleId] ON [UserRoles] ([UserId], [RoleId]);

CREATE INDEX [IX_Users_CompanyId_IsActive] ON [Users] ([CompanyId], [IsActive]);

CREATE INDEX [IX_Users_EmployeeId] ON [Users] ([EmployeeId]);

CREATE UNIQUE INDEX [IX_Users_NormalizedEmail] ON [Users] ([NormalizedEmail]);

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260801205816_AddAuthentication', N'10.0.10');

COMMIT;
GO

BEGIN TRANSACTION;
CREATE TABLE [Timesheets] (
    [Id] uniqueidentifier NOT NULL,
    [EmployeeId] uniqueidentifier NOT NULL,
    [PeriodStartDate] date NOT NULL,
    [PeriodEndDate] date NOT NULL,
    [RegularHours] decimal(10,2) NOT NULL,
    [OvertimeHours] decimal(10,2) NOT NULL,
    [TotalHours] decimal(10,2) NOT NULL,
    [Status] nvarchar(30) NOT NULL,
    [SubmittedBy] uniqueidentifier NULL,
    [SubmittedAtUtc] datetime2 NULL,
    [ApprovedBy] uniqueidentifier NULL,
    [ApprovedAtUtc] datetime2 NULL,
    [ApprovalRemarks] nvarchar(1000) NULL,
    [Remarks] nvarchar(1000) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Timesheets] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Timesheets_Employees_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [Employees] ([Id]) ON DELETE NO ACTION
);

CREATE INDEX [IX_Timesheets_CompanyId_EmployeeId_PeriodStartDate_PeriodEndDate] ON [Timesheets] ([CompanyId], [EmployeeId], [PeriodStartDate], [PeriodEndDate]);

CREATE INDEX [IX_Timesheets_EmployeeId] ON [Timesheets] ([EmployeeId]);

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260804002004_AddTimesheetModule', N'10.0.10');

COMMIT;
GO

BEGIN TRANSACTION;
CREATE TABLE [DocumentCategories] (
    [Id] uniqueidentifier NOT NULL,
    [CategoryCode] nvarchar(30) NOT NULL,
    [Name] nvarchar(200) NOT NULL,
    [Description] nvarchar(1000) NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_DocumentCategories] PRIMARY KEY ([Id])
);

CREATE UNIQUE INDEX [IX_DocumentCategories_CompanyId_CategoryCode] ON [DocumentCategories] ([CompanyId], [CategoryCode]);

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260808003450_AddDocumentCategories', N'10.0.10');

COMMIT;
GO


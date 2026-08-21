IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
CREATE TABLE [Companies] (
    [Id] uniqueidentifier NOT NULL,
    [Code] nvarchar(30) NOT NULL,
    [Name] nvarchar(200) NOT NULL,
    [LegalName] nvarchar(250) NULL,
    [TaxIdentificationNumber] nvarchar(100) NULL,
    [RegistrationNumber] nvarchar(100) NULL,
    [PhoneNumber] nvarchar(50) NULL,
    [Email] nvarchar(200) NULL,
    [Address] nvarchar(max) NULL,
    [City] nvarchar(max) NULL,
    [Country] nvarchar(max) NULL,
    [BaseCurrencyCode] nvarchar(3) NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    CONSTRAINT [PK_Companies] PRIMARY KEY ([Id])
);

CREATE TABLE [Contractors] (
    [Id] uniqueidentifier NOT NULL,
    [ContractorCode] nvarchar(30) NOT NULL,
    [Name] nvarchar(200) NOT NULL,
    [ContactPerson] nvarchar(150) NULL,
    [PhoneNumber] nvarchar(50) NULL,
    [Email] nvarchar(200) NULL,
    [TaxIdentificationNumber] nvarchar(max) NULL,
    [RegistrationNumber] nvarchar(max) NULL,
    [Address] nvarchar(max) NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Contractors] PRIMARY KEY ([Id])
);

CREATE TABLE [CostCodes] (
    [Id] uniqueidentifier NOT NULL,
    [Code] nvarchar(30) NOT NULL,
    [Name] nvarchar(200) NOT NULL,
    [Description] nvarchar(max) NULL,
    [ParentCostCodeId] uniqueidentifier NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_CostCodes] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_CostCodes_CostCodes_ParentCostCodeId] FOREIGN KEY ([ParentCostCodeId]) REFERENCES [CostCodes] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [Documents] (
    [Id] uniqueidentifier NOT NULL,
    [DocumentNumber] nvarchar(50) NOT NULL,
    [Name] nvarchar(250) NOT NULL,
    [DocumentType] nvarchar(50) NOT NULL,
    [FileName] nvarchar(255) NOT NULL,
    [StoragePath] nvarchar(1000) NOT NULL,
    [ContentType] nvarchar(150) NULL,
    [FileSizeBytes] bigint NOT NULL,
    [ConstructionSiteId] uniqueidentifier NULL,
    [ProjectId] uniqueidentifier NULL,
    [EmployeeId] uniqueidentifier NULL,
    [RelatedEntityId] uniqueidentifier NULL,
    [RelatedEntityType] nvarchar(100) NULL,
    [IssueDate] date NULL,
    [ExpiryDate] date NULL,
    [IsConfidential] bit NOT NULL,
    [Description] nvarchar(max) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Documents] PRIMARY KEY ([Id])
);

CREATE TABLE [Employees] (
    [Id] uniqueidentifier NOT NULL,
    [EmployeeNumber] nvarchar(30) NOT NULL,
    [FirstName] nvarchar(100) NOT NULL,
    [MiddleName] nvarchar(100) NULL,
    [LastName] nvarchar(100) NOT NULL,
    [PhoneNumber] nvarchar(50) NULL,
    [Email] nvarchar(200) NULL,
    [NationalIdNumber] nvarchar(max) NULL,
    [TaxIdentificationNumber] nvarchar(max) NULL,
    [DateOfBirth] date NULL,
    [HireDate] date NOT NULL,
    [TerminationDate] date NULL,
    [JobTitle] nvarchar(150) NULL,
    [Department] nvarchar(150) NULL,
    [EmployeeType] nvarchar(30) NOT NULL,
    [Status] nvarchar(30) NOT NULL,
    [WageType] nvarchar(20) NOT NULL,
    [BaseWage] decimal(19,4) NOT NULL,
    [CurrencyCode] nvarchar(3) NOT NULL,
    [BankName] nvarchar(max) NULL,
    [BankAccountNumber] nvarchar(max) NULL,
    [EmergencyContactName] nvarchar(max) NULL,
    [EmergencyContactPhone] nvarchar(max) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Employees] PRIMARY KEY ([Id])
);

CREATE TABLE [Shifts] (
    [Id] uniqueidentifier NOT NULL,
    [Code] nvarchar(30) NOT NULL,
    [Name] nvarchar(100) NOT NULL,
    [StartTime] time NOT NULL,
    [EndTime] time NOT NULL,
    [GracePeriodMinutes] int NOT NULL,
    [StandardHours] decimal(8,2) NOT NULL,
    [IsNightShift] bit NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Shifts] PRIMARY KEY ([Id])
);

CREATE TABLE [Vendors] (
    [Id] uniqueidentifier NOT NULL,
    [VendorCode] nvarchar(30) NOT NULL,
    [Name] nvarchar(200) NOT NULL,
    [ContactPerson] nvarchar(150) NULL,
    [PhoneNumber] nvarchar(50) NULL,
    [Email] nvarchar(200) NULL,
    [Address] nvarchar(max) NULL,
    [TaxIdentificationNumber] nvarchar(max) NULL,
    [RegistrationNumber] nvarchar(max) NULL,
    [BankName] nvarchar(max) NULL,
    [BankAccountNumber] nvarchar(max) NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Vendors] PRIMARY KEY ([Id])
);

CREATE TABLE [BusinessUnits] (
    [Id] uniqueidentifier NOT NULL,
    [Code] nvarchar(30) NOT NULL,
    [Name] nvarchar(200) NOT NULL,
    [Description] nvarchar(max) NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_BusinessUnits] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_BusinessUnits_Companies_CompanyId] FOREIGN KEY ([CompanyId]) REFERENCES [Companies] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [Materials] (
    [Id] uniqueidentifier NOT NULL,
    [MaterialCode] nvarchar(30) NOT NULL,
    [Name] nvarchar(200) NOT NULL,
    [Description] nvarchar(max) NULL,
    [Category] nvarchar(100) NOT NULL,
    [UnitOfMeasure] nvarchar(30) NOT NULL,
    [DefaultCostCodeId] uniqueidentifier NULL,
    [StandardUnitCost] decimal(19,4) NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Materials] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Materials_CostCodes_DefaultCostCodeId] FOREIGN KEY ([DefaultCostCodeId]) REFERENCES [CostCodes] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [LeaveRequests] (
    [Id] uniqueidentifier NOT NULL,
    [EmployeeId] uniqueidentifier NOT NULL,
    [LeaveType] nvarchar(50) NOT NULL,
    [StartDate] date NOT NULL,
    [EndDate] date NOT NULL,
    [NumberOfDays] decimal(8,2) NOT NULL,
    [Reason] nvarchar(max) NULL,
    [Status] nvarchar(30) NOT NULL,
    [ReviewedBy] uniqueidentifier NULL,
    [ReviewedAtUtc] datetime2 NULL,
    [ReviewRemarks] nvarchar(max) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_LeaveRequests] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_LeaveRequests_Employees_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [Employees] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [PayrollRecords] (
    [Id] uniqueidentifier NOT NULL,
    [EmployeeId] uniqueidentifier NOT NULL,
    [PeriodStart] date NOT NULL,
    [PeriodEnd] date NOT NULL,
    [BasePay] decimal(19,4) NOT NULL,
    [RegularHours] decimal(8,2) NOT NULL,
    [OvertimeHours] decimal(8,2) NOT NULL,
    [OvertimePay] decimal(19,4) NOT NULL,
    [Allowances] decimal(19,4) NOT NULL,
    [Bonuses] decimal(19,4) NOT NULL,
    [GrossPay] decimal(19,4) NOT NULL,
    [TaxDeduction] decimal(19,4) NOT NULL,
    [PensionDeduction] decimal(19,4) NOT NULL,
    [OtherDeductions] decimal(19,4) NOT NULL,
    [TotalDeductions] decimal(19,4) NOT NULL,
    [NetPay] decimal(19,4) NOT NULL,
    [CurrencyCode] nvarchar(3) NOT NULL,
    [Status] nvarchar(30) NOT NULL,
    [ApprovedBy] uniqueidentifier NULL,
    [ApprovedAtUtc] datetime2 NULL,
    [PaidAtUtc] datetime2 NULL,
    [PaymentReference] nvarchar(max) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_PayrollRecords] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_PayrollRecords_Employees_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [Employees] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [Equipment] (
    [Id] uniqueidentifier NOT NULL,
    [EquipmentCode] nvarchar(30) NOT NULL,
    [Name] nvarchar(200) NOT NULL,
    [Category] nvarchar(max) NULL,
    [Make] nvarchar(max) NULL,
    [Model] nvarchar(max) NULL,
    [SerialNumber] nvarchar(max) NULL,
    [RegistrationNumber] nvarchar(max) NULL,
    [OwnershipType] nvarchar(30) NOT NULL,
    [Status] nvarchar(30) NOT NULL,
    [VendorId] uniqueidentifier NULL,
    [PurchaseCost] decimal(19,4) NULL,
    [RentalRate] decimal(19,4) NULL,
    [RentalRateUnit] nvarchar(max) NULL,
    [RentalStartDate] date NULL,
    [RentalEndDate] date NULL,
    [CurrentMeterReading] decimal(19,4) NOT NULL,
    [MeterUnit] nvarchar(max) NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Equipment] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Equipment_Vendors_VendorId] FOREIGN KEY ([VendorId]) REFERENCES [Vendors] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [ConstructionSites] (
    [Id] uniqueidentifier NOT NULL,
    [SiteCode] nvarchar(30) NOT NULL,
    [Name] nvarchar(200) NOT NULL,
    [Description] nvarchar(max) NULL,
    [BusinessUnitId] uniqueidentifier NULL,
    [Address] nvarchar(max) NULL,
    [City] nvarchar(max) NULL,
    [Region] nvarchar(max) NULL,
    [Country] nvarchar(max) NULL,
    [Latitude] decimal(10,7) NULL,
    [Longitude] decimal(10,7) NULL,
    [GeofenceRadiusMeters] decimal(10,2) NULL,
    [PlannedStartDate] date NULL,
    [PlannedEndDate] date NULL,
    [ActualStartDate] date NULL,
    [ActualEndDate] date NULL,
    [Status] nvarchar(30) NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_ConstructionSites] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_ConstructionSites_BusinessUnits_BusinessUnitId] FOREIGN KEY ([BusinessUnitId]) REFERENCES [BusinessUnits] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_ConstructionSites_Companies_CompanyId] FOREIGN KEY ([CompanyId]) REFERENCES [Companies] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [PayrollAdjustments] (
    [Id] uniqueidentifier NOT NULL,
    [PayrollRecordId] uniqueidentifier NOT NULL,
    [Type] nvarchar(50) NOT NULL,
    [Description] nvarchar(300) NOT NULL,
    [Amount] decimal(19,4) NOT NULL,
    [IsDeduction] bit NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_PayrollAdjustments] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_PayrollAdjustments_PayrollRecords_PayrollRecordId] FOREIGN KEY ([PayrollRecordId]) REFERENCES [PayrollRecords] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [EquipmentMaintenance] (
    [Id] uniqueidentifier NOT NULL,
    [EquipmentId] uniqueidentifier NOT NULL,
    [MaintenanceType] nvarchar(100) NOT NULL,
    [ScheduledAtUtc] datetime2 NOT NULL,
    [StartedAtUtc] datetime2 NULL,
    [CompletedAtUtc] datetime2 NULL,
    [MeterReading] decimal(19,4) NULL,
    [Cost] decimal(19,4) NULL,
    [CurrencyCode] nvarchar(3) NOT NULL,
    [ServiceProvider] nvarchar(max) NULL,
    [Description] nvarchar(max) NULL,
    [PartsReplaced] nvarchar(max) NULL,
    [NextMaintenanceAtUtc] datetime2 NULL,
    [NextMaintenanceMeterReading] decimal(19,4) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_EquipmentMaintenance] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_EquipmentMaintenance_Equipment_EquipmentId] FOREIGN KEY ([EquipmentId]) REFERENCES [Equipment] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [Attendances] (
    [Id] uniqueidentifier NOT NULL,
    [EmployeeId] uniqueidentifier NOT NULL,
    [ConstructionSiteId] uniqueidentifier NOT NULL,
    [ShiftId] uniqueidentifier NULL,
    [AttendanceDate] date NOT NULL,
    [CheckInAtUtc] datetime2 NULL,
    [CheckOutAtUtc] datetime2 NULL,
    [CheckInLatitude] decimal(10,7) NULL,
    [CheckInLongitude] decimal(10,7) NULL,
    [CheckOutLatitude] decimal(10,7) NULL,
    [CheckOutLongitude] decimal(10,7) NULL,
    [CheckInAccuracyMeters] decimal(10,2) NULL,
    [CheckOutAccuracyMeters] decimal(10,2) NULL,
    [IsCheckInWithinGeofence] bit NOT NULL,
    [IsCheckOutWithinGeofence] bit NOT NULL,
    [Status] nvarchar(30) NOT NULL,
    [Source] nvarchar(30) NOT NULL,
    [RegularHours] decimal(8,2) NOT NULL,
    [OvertimeHours] decimal(8,2) NOT NULL,
    [BiometricReference] nvarchar(max) NULL,
    [RequiresApproval] bit NOT NULL,
    [IsApproved] bit NOT NULL,
    [ApprovedBy] uniqueidentifier NULL,
    [ApprovedAtUtc] datetime2 NULL,
    [ManualOverrideReason] nvarchar(max) NULL,
    [Remarks] nvarchar(max) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Attendances] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Attendances_ConstructionSites_ConstructionSiteId] FOREIGN KEY ([ConstructionSiteId]) REFERENCES [ConstructionSites] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Attendances_Employees_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [Employees] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Attendances_Shifts_ShiftId] FOREIGN KEY ([ShiftId]) REFERENCES [Shifts] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [EquipmentDowntime] (
    [Id] uniqueidentifier NOT NULL,
    [EquipmentId] uniqueidentifier NOT NULL,
    [ConstructionSiteId] uniqueidentifier NULL,
    [StartedAtUtc] datetime2 NOT NULL,
    [EndedAtUtc] datetime2 NULL,
    [Reason] nvarchar(500) NOT NULL,
    [Resolution] nvarchar(max) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_EquipmentDowntime] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_EquipmentDowntime_ConstructionSites_ConstructionSiteId] FOREIGN KEY ([ConstructionSiteId]) REFERENCES [ConstructionSites] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_EquipmentDowntime_Equipment_EquipmentId] FOREIGN KEY ([EquipmentId]) REFERENCES [Equipment] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [Projects] (
    [Id] uniqueidentifier NOT NULL,
    [ConstructionSiteId] uniqueidentifier NOT NULL,
    [ProjectCode] nvarchar(30) NOT NULL,
    [Name] nvarchar(250) NOT NULL,
    [Description] nvarchar(max) NULL,
    [PlannedStartDate] date NULL,
    [PlannedEndDate] date NULL,
    [ActualStartDate] date NULL,
    [ActualEndDate] date NULL,
    [ContractValue] decimal(19,4) NOT NULL,
    [ProgressPercentage] decimal(5,2) NOT NULL,
    [Status] nvarchar(30) NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Projects] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Projects_ConstructionSites_ConstructionSiteId] FOREIGN KEY ([ConstructionSiteId]) REFERENCES [ConstructionSites] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [SiteAssignments] (
    [Id] uniqueidentifier NOT NULL,
    [EmployeeId] uniqueidentifier NOT NULL,
    [ConstructionSiteId] uniqueidentifier NOT NULL,
    [StartDate] date NOT NULL,
    [EndDate] date NULL,
    [RoleAtSite] nvarchar(150) NULL,
    [IsPrimaryAssignment] bit NOT NULL,
    [Remarks] nvarchar(max) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_SiteAssignments] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_SiteAssignments_ConstructionSites_ConstructionSiteId] FOREIGN KEY ([ConstructionSiteId]) REFERENCES [ConstructionSites] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_SiteAssignments_Employees_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [Employees] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [StockItems] (
    [Id] uniqueidentifier NOT NULL,
    [ConstructionSiteId] uniqueidentifier NOT NULL,
    [MaterialId] uniqueidentifier NOT NULL,
    [QuantityOnHand] decimal(19,4) NOT NULL,
    [QuantityReserved] decimal(19,4) NOT NULL,
    [ReorderLevel] decimal(19,4) NOT NULL,
    [MaximumStockLevel] decimal(19,4) NULL,
    [AverageUnitCost] decimal(19,4) NOT NULL,
    [StorageLocation] nvarchar(100) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_StockItems] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_StockItems_ConstructionSites_ConstructionSiteId] FOREIGN KEY ([ConstructionSiteId]) REFERENCES [ConstructionSites] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_StockItems_Materials_MaterialId] FOREIGN KEY ([MaterialId]) REFERENCES [Materials] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [Budgets] (
    [Id] uniqueidentifier NOT NULL,
    [ConstructionSiteId] uniqueidentifier NOT NULL,
    [ProjectId] uniqueidentifier NULL,
    [BudgetNumber] nvarchar(50) NOT NULL,
    [Name] nvarchar(200) NOT NULL,
    [Description] nvarchar(max) NULL,
    [TotalAmount] decimal(19,4) NOT NULL,
    [CurrencyCode] nvarchar(3) NOT NULL,
    [EffectiveFrom] date NULL,
    [EffectiveTo] date NULL,
    [Status] nvarchar(30) NOT NULL,
    [ApprovedBy] uniqueidentifier NULL,
    [ApprovedAtUtc] datetime2 NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Budgets] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Budgets_ConstructionSites_ConstructionSiteId] FOREIGN KEY ([ConstructionSiteId]) REFERENCES [ConstructionSites] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Budgets_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [DailyProgressLogs] (
    [Id] uniqueidentifier NOT NULL,
    [ProjectId] uniqueidentifier NOT NULL,
    [LogDate] date NOT NULL,
    [WeatherCondition] nvarchar(max) NULL,
    [TemperatureCelsius] decimal(5,2) NULL,
    [LaborCount] int NOT NULL,
    [ContractorLaborCount] int NOT NULL,
    [ProgressPercentage] decimal(5,2) NOT NULL,
    [WorkCompleted] nvarchar(max) NULL,
    [WorkPlannedNext] nvarchar(max) NULL,
    [MaterialsUsedSummary] nvarchar(max) NULL,
    [EquipmentUsedSummary] nvarchar(max) NULL,
    [Delays] nvarchar(max) NULL,
    [Issues] nvarchar(max) NULL,
    [SafetyNotes] nvarchar(max) NULL,
    [Remarks] nvarchar(max) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_DailyProgressLogs] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_DailyProgressLogs_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [EquipmentAssignments] (
    [Id] uniqueidentifier NOT NULL,
    [EquipmentId] uniqueidentifier NOT NULL,
    [ConstructionSiteId] uniqueidentifier NOT NULL,
    [ProjectId] uniqueidentifier NULL,
    [AssignedAtUtc] datetime2 NOT NULL,
    [ReleasedAtUtc] datetime2 NULL,
    [MeterReadingAtAssignment] decimal(19,4) NULL,
    [MeterReadingAtRelease] decimal(19,4) NULL,
    [Remarks] nvarchar(max) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_EquipmentAssignments] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_EquipmentAssignments_ConstructionSites_ConstructionSiteId] FOREIGN KEY ([ConstructionSiteId]) REFERENCES [ConstructionSites] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_EquipmentAssignments_Equipment_EquipmentId] FOREIGN KEY ([EquipmentId]) REFERENCES [Equipment] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_EquipmentAssignments_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [Expenses] (
    [Id] uniqueidentifier NOT NULL,
    [ConstructionSiteId] uniqueidentifier NOT NULL,
    [ProjectId] uniqueidentifier NULL,
    [CostCodeId] uniqueidentifier NOT NULL,
    [VendorId] uniqueidentifier NULL,
    [ExpenseNumber] nvarchar(50) NOT NULL,
    [ExpenseDate] date NOT NULL,
    [Description] nvarchar(500) NOT NULL,
    [Amount] decimal(19,4) NOT NULL,
    [TaxAmount] decimal(19,4) NOT NULL,
    [CurrencyCode] nvarchar(3) NOT NULL,
    [ExchangeRate] decimal(19,8) NOT NULL,
    [ReferenceNumber] nvarchar(max) NULL,
    [ReceiptDocumentUrl] nvarchar(max) NULL,
    [Status] nvarchar(30) NOT NULL,
    [ApprovedBy] uniqueidentifier NULL,
    [ApprovedAtUtc] datetime2 NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Expenses] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Expenses_ConstructionSites_ConstructionSiteId] FOREIGN KEY ([ConstructionSiteId]) REFERENCES [ConstructionSites] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Expenses_CostCodes_CostCodeId] FOREIGN KEY ([CostCodeId]) REFERENCES [CostCodes] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Expenses_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Expenses_Vendors_VendorId] FOREIGN KEY ([VendorId]) REFERENCES [Vendors] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [Inspections] (
    [Id] uniqueidentifier NOT NULL,
    [ConstructionSiteId] uniqueidentifier NOT NULL,
    [ProjectId] uniqueidentifier NULL,
    [InspectionNumber] nvarchar(50) NOT NULL,
    [InspectionType] nvarchar(100) NOT NULL,
    [Title] nvarchar(200) NOT NULL,
    [ScheduledAtUtc] datetime2 NOT NULL,
    [StartedAtUtc] datetime2 NULL,
    [CompletedAtUtc] datetime2 NULL,
    [InspectorEmployeeId] uniqueidentifier NULL,
    [ExternalInspectorName] nvarchar(max) NULL,
    [ExternalOrganization] nvarchar(max) NULL,
    [Status] nvarchar(40) NOT NULL,
    [Summary] nvarchar(max) NULL,
    [CorrectiveActionRequired] nvarchar(max) NULL,
    [CorrectiveActionDueDate] date NULL,
    [SignedOffBy] uniqueidentifier NULL,
    [SignedOffAtUtc] datetime2 NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Inspections] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Inspections_ConstructionSites_ConstructionSiteId] FOREIGN KEY ([ConstructionSiteId]) REFERENCES [ConstructionSites] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Inspections_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [Invoices] (
    [Id] uniqueidentifier NOT NULL,
    [ConstructionSiteId] uniqueidentifier NOT NULL,
    [ProjectId] uniqueidentifier NULL,
    [VendorId] uniqueidentifier NULL,
    [InvoiceNumber] nvarchar(50) NOT NULL,
    [Type] nvarchar(30) NOT NULL,
    [InvoiceDate] date NOT NULL,
    [DueDate] date NULL,
    [Subtotal] decimal(19,4) NOT NULL,
    [TaxAmount] decimal(19,4) NOT NULL,
    [TotalAmount] decimal(19,4) NOT NULL,
    [CurrencyCode] nvarchar(3) NOT NULL,
    [ExchangeRate] decimal(19,8) NOT NULL,
    [Status] nvarchar(30) NOT NULL,
    [Description] nvarchar(max) NULL,
    [ExternalReference] nvarchar(max) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Invoices] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Invoices_ConstructionSites_ConstructionSiteId] FOREIGN KEY ([ConstructionSiteId]) REFERENCES [ConstructionSites] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Invoices_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Invoices_Vendors_VendorId] FOREIGN KEY ([VendorId]) REFERENCES [Vendors] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [MaterialRequests] (
    [Id] uniqueidentifier NOT NULL,
    [ConstructionSiteId] uniqueidentifier NOT NULL,
    [ProjectId] uniqueidentifier NULL,
    [RequestNumber] nvarchar(50) NOT NULL,
    [RequestDate] date NOT NULL,
    [RequiredByDate] date NULL,
    [Purpose] nvarchar(max) NULL,
    [Priority] nvarchar(20) NOT NULL,
    [Status] nvarchar(30) NOT NULL,
    [RequestedBy] uniqueidentifier NOT NULL,
    [ApprovedBy] uniqueidentifier NULL,
    [ApprovedAtUtc] datetime2 NULL,
    [ApprovalRemarks] nvarchar(max) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_MaterialRequests] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_MaterialRequests_ConstructionSites_ConstructionSiteId] FOREIGN KEY ([ConstructionSiteId]) REFERENCES [ConstructionSites] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_MaterialRequests_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [Permits] (
    [Id] uniqueidentifier NOT NULL,
    [ConstructionSiteId] uniqueidentifier NOT NULL,
    [ProjectId] uniqueidentifier NULL,
    [PermitNumber] nvarchar(100) NOT NULL,
    [PermitType] nvarchar(100) NOT NULL,
    [Name] nvarchar(200) NOT NULL,
    [IssuingAuthority] nvarchar(max) NULL,
    [ApplicationDate] date NULL,
    [IssueDate] date NULL,
    [ExpiryDate] date NULL,
    [Status] nvarchar(30) NOT NULL,
    [ExpiryAlertDays] int NOT NULL,
    [Conditions] nvarchar(max) NULL,
    [Notes] nvarchar(max) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Permits] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Permits_ConstructionSites_ConstructionSiteId] FOREIGN KEY ([ConstructionSiteId]) REFERENCES [ConstructionSites] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Permits_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [ProjectPhases] (
    [Id] uniqueidentifier NOT NULL,
    [ProjectId] uniqueidentifier NOT NULL,
    [Name] nvarchar(200) NOT NULL,
    [Description] nvarchar(max) NULL,
    [Sequence] int NOT NULL,
    [PlannedStartDate] date NULL,
    [PlannedEndDate] date NULL,
    [ActualStartDate] date NULL,
    [ActualEndDate] date NULL,
    [ProgressPercentage] decimal(5,2) NOT NULL,
    [Status] nvarchar(30) NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_ProjectPhases] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_ProjectPhases_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [SafetyIncidents] (
    [Id] uniqueidentifier NOT NULL,
    [ConstructionSiteId] uniqueidentifier NOT NULL,
    [ProjectId] uniqueidentifier NULL,
    [EmployeeId] uniqueidentifier NULL,
    [IncidentNumber] nvarchar(50) NOT NULL,
    [OccurredAtUtc] datetime2 NOT NULL,
    [ReportedAtUtc] datetime2 NOT NULL,
    [ReportedBy] uniqueidentifier NOT NULL,
    [LocationDescription] nvarchar(max) NOT NULL,
    [Description] nvarchar(max) NOT NULL,
    [Severity] nvarchar(30) NOT NULL,
    [Status] nvarchar(40) NOT NULL,
    [InjuryOccurred] bit NOT NULL,
    [MedicalTreatmentRequired] bit NOT NULL,
    [LostTimeIncident] bit NOT NULL,
    [ImmediateActionTaken] nvarchar(max) NULL,
    [RootCause] nvarchar(max) NULL,
    [CorrectiveAction] nvarchar(max) NULL,
    [InvestigatedBy] uniqueidentifier NULL,
    [InvestigationCompletedAtUtc] datetime2 NULL,
    [ClosedAtUtc] datetime2 NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_SafetyIncidents] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_SafetyIncidents_ConstructionSites_ConstructionSiteId] FOREIGN KEY ([ConstructionSiteId]) REFERENCES [ConstructionSites] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_SafetyIncidents_Employees_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [Employees] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_SafetyIncidents_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [StockMovements] (
    [Id] uniqueidentifier NOT NULL,
    [StockItemId] uniqueidentifier NOT NULL,
    [MovementType] nvarchar(30) NOT NULL,
    [MovementDateUtc] datetime2 NOT NULL,
    [Quantity] decimal(19,4) NOT NULL,
    [UnitCost] decimal(19,4) NULL,
    [ReferenceType] nvarchar(50) NULL,
    [ReferenceId] uniqueidentifier NULL,
    [ReferenceNumber] nvarchar(100) NULL,
    [Remarks] nvarchar(max) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_StockMovements] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_StockMovements_StockItems_StockItemId] FOREIGN KEY ([StockItemId]) REFERENCES [StockItems] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [BudgetLines] (
    [Id] uniqueidentifier NOT NULL,
    [BudgetId] uniqueidentifier NOT NULL,
    [CostCodeId] uniqueidentifier NOT NULL,
    [Description] nvarchar(300) NULL,
    [BudgetedAmount] decimal(19,4) NOT NULL,
    [RevisedAmount] decimal(19,4) NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_BudgetLines] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_BudgetLines_Budgets_BudgetId] FOREIGN KEY ([BudgetId]) REFERENCES [Budgets] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_BudgetLines_CostCodes_CostCodeId] FOREIGN KEY ([CostCodeId]) REFERENCES [CostCodes] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [InspectionChecklistItems] (
    [Id] uniqueidentifier NOT NULL,
    [InspectionId] uniqueidentifier NOT NULL,
    [Sequence] int NOT NULL,
    [Requirement] nvarchar(500) NOT NULL,
    [IsCompliant] bit NULL,
    [Observation] nvarchar(max) NULL,
    [CorrectiveAction] nvarchar(max) NULL,
    [DueDate] date NULL,
    [IsResolved] bit NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_InspectionChecklistItems] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_InspectionChecklistItems_Inspections_InspectionId] FOREIGN KEY ([InspectionId]) REFERENCES [Inspections] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [InvoiceLines] (
    [Id] uniqueidentifier NOT NULL,
    [InvoiceId] uniqueidentifier NOT NULL,
    [CostCodeId] uniqueidentifier NULL,
    [Description] nvarchar(500) NOT NULL,
    [Quantity] decimal(19,4) NOT NULL,
    [UnitPrice] decimal(19,4) NOT NULL,
    [TaxAmount] decimal(19,4) NOT NULL,
    [LineTotal] decimal(19,4) NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_InvoiceLines] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_InvoiceLines_CostCodes_CostCodeId] FOREIGN KEY ([CostCodeId]) REFERENCES [CostCodes] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_InvoiceLines_Invoices_InvoiceId] FOREIGN KEY ([InvoiceId]) REFERENCES [Invoices] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [Payments] (
    [Id] uniqueidentifier NOT NULL,
    [InvoiceId] uniqueidentifier NULL,
    [VendorId] uniqueidentifier NULL,
    [PaymentNumber] nvarchar(50) NOT NULL,
    [PaymentDate] date NOT NULL,
    [Direction] nvarchar(20) NOT NULL,
    [Amount] decimal(19,4) NOT NULL,
    [CurrencyCode] nvarchar(3) NOT NULL,
    [ExchangeRate] decimal(19,8) NOT NULL,
    [PaymentMethod] nvarchar(50) NULL,
    [ReferenceNumber] nvarchar(100) NULL,
    [Notes] nvarchar(max) NULL,
    [Status] nvarchar(20) NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Payments] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Payments_Invoices_InvoiceId] FOREIGN KEY ([InvoiceId]) REFERENCES [Invoices] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Payments_Vendors_VendorId] FOREIGN KEY ([VendorId]) REFERENCES [Vendors] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [MaterialRequestLines] (
    [Id] uniqueidentifier NOT NULL,
    [MaterialRequestId] uniqueidentifier NOT NULL,
    [MaterialId] uniqueidentifier NOT NULL,
    [RequestedQuantity] decimal(19,4) NOT NULL,
    [ApprovedQuantity] decimal(19,4) NOT NULL,
    [DeliveredQuantity] decimal(19,4) NOT NULL,
    [Remarks] nvarchar(max) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_MaterialRequestLines] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_MaterialRequestLines_MaterialRequests_MaterialRequestId] FOREIGN KEY ([MaterialRequestId]) REFERENCES [MaterialRequests] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_MaterialRequestLines_Materials_MaterialId] FOREIGN KEY ([MaterialId]) REFERENCES [Materials] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [PurchaseOrders] (
    [Id] uniqueidentifier NOT NULL,
    [ConstructionSiteId] uniqueidentifier NOT NULL,
    [ProjectId] uniqueidentifier NULL,
    [VendorId] uniqueidentifier NOT NULL,
    [MaterialRequestId] uniqueidentifier NULL,
    [PurchaseOrderNumber] nvarchar(50) NOT NULL,
    [OrderDate] date NOT NULL,
    [ExpectedDeliveryDate] date NULL,
    [CurrencyCode] nvarchar(3) NOT NULL,
    [ExchangeRate] decimal(19,8) NOT NULL,
    [Subtotal] decimal(19,4) NOT NULL,
    [TaxAmount] decimal(19,4) NOT NULL,
    [DiscountAmount] decimal(19,4) NOT NULL,
    [TotalAmount] decimal(19,4) NOT NULL,
    [Status] nvarchar(30) NOT NULL,
    [DeliveryAddress] nvarchar(max) NULL,
    [PaymentTerms] nvarchar(max) NULL,
    [Notes] nvarchar(max) NULL,
    [ApprovedBy] uniqueidentifier NULL,
    [ApprovedAtUtc] datetime2 NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_PurchaseOrders] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_PurchaseOrders_ConstructionSites_ConstructionSiteId] FOREIGN KEY ([ConstructionSiteId]) REFERENCES [ConstructionSites] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_PurchaseOrders_MaterialRequests_MaterialRequestId] FOREIGN KEY ([MaterialRequestId]) REFERENCES [MaterialRequests] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_PurchaseOrders_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_PurchaseOrders_Vendors_VendorId] FOREIGN KEY ([VendorId]) REFERENCES [Vendors] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [Milestones] (
    [Id] uniqueidentifier NOT NULL,
    [ProjectId] uniqueidentifier NOT NULL,
    [ProjectPhaseId] uniqueidentifier NULL,
    [Name] nvarchar(200) NOT NULL,
    [Description] nvarchar(max) NULL,
    [PlannedDate] date NOT NULL,
    [CompletedDate] date NULL,
    [IsCompleted] bit NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_Milestones] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Milestones_ProjectPhases_ProjectPhaseId] FOREIGN KEY ([ProjectPhaseId]) REFERENCES [ProjectPhases] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Milestones_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [GoodsReceipts] (
    [Id] uniqueidentifier NOT NULL,
    [PurchaseOrderId] uniqueidentifier NOT NULL,
    [ConstructionSiteId] uniqueidentifier NOT NULL,
    [ReceiptNumber] nvarchar(50) NOT NULL,
    [ReceivedAtUtc] datetime2 NOT NULL,
    [ReceivedBy] uniqueidentifier NOT NULL,
    [DeliveryNoteNumber] nvarchar(100) NULL,
    [VehiclePlateNumber] nvarchar(50) NULL,
    [Remarks] nvarchar(max) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_GoodsReceipts] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_GoodsReceipts_ConstructionSites_ConstructionSiteId] FOREIGN KEY ([ConstructionSiteId]) REFERENCES [ConstructionSites] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_GoodsReceipts_PurchaseOrders_PurchaseOrderId] FOREIGN KEY ([PurchaseOrderId]) REFERENCES [PurchaseOrders] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [PurchaseOrderLines] (
    [Id] uniqueidentifier NOT NULL,
    [PurchaseOrderId] uniqueidentifier NOT NULL,
    [MaterialId] uniqueidentifier NOT NULL,
    [CostCodeId] uniqueidentifier NULL,
    [OrderedQuantity] decimal(19,4) NOT NULL,
    [ReceivedQuantity] decimal(19,4) NOT NULL,
    [UnitPrice] decimal(19,4) NOT NULL,
    [TaxAmount] decimal(19,4) NOT NULL,
    [LineTotal] decimal(19,4) NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_PurchaseOrderLines] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_PurchaseOrderLines_CostCodes_CostCodeId] FOREIGN KEY ([CostCodeId]) REFERENCES [CostCodes] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_PurchaseOrderLines_Materials_MaterialId] FOREIGN KEY ([MaterialId]) REFERENCES [Materials] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_PurchaseOrderLines_PurchaseOrders_PurchaseOrderId] FOREIGN KEY ([PurchaseOrderId]) REFERENCES [PurchaseOrders] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [WorkTasks] (
    [Id] uniqueidentifier NOT NULL,
    [ProjectId] uniqueidentifier NOT NULL,
    [ProjectPhaseId] uniqueidentifier NULL,
    [MilestoneId] uniqueidentifier NULL,
    [TaskNumber] nvarchar(50) NOT NULL,
    [Title] nvarchar(250) NOT NULL,
    [Description] nvarchar(max) NULL,
    [PlannedStartDate] date NULL,
    [PlannedEndDate] date NULL,
    [ActualStartDate] date NULL,
    [ActualEndDate] date NULL,
    [ProgressPercentage] decimal(5,2) NOT NULL,
    [Priority] nvarchar(20) NOT NULL,
    [Status] nvarchar(30) NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_WorkTasks] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_WorkTasks_Milestones_MilestoneId] FOREIGN KEY ([MilestoneId]) REFERENCES [Milestones] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_WorkTasks_ProjectPhases_ProjectPhaseId] FOREIGN KEY ([ProjectPhaseId]) REFERENCES [ProjectPhases] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_WorkTasks_Projects_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Projects] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [GoodsReceiptLines] (
    [Id] uniqueidentifier NOT NULL,
    [GoodsReceiptId] uniqueidentifier NOT NULL,
    [PurchaseOrderLineId] uniqueidentifier NOT NULL,
    [MaterialId] uniqueidentifier NOT NULL,
    [ReceivedQuantity] decimal(19,4) NOT NULL,
    [AcceptedQuantity] decimal(19,4) NOT NULL,
    [RejectedQuantity] decimal(19,4) NOT NULL,
    [RejectionReason] nvarchar(max) NULL,
    [Remarks] nvarchar(max) NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_GoodsReceiptLines] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_GoodsReceiptLines_GoodsReceipts_GoodsReceiptId] FOREIGN KEY ([GoodsReceiptId]) REFERENCES [GoodsReceipts] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_GoodsReceiptLines_Materials_MaterialId] FOREIGN KEY ([MaterialId]) REFERENCES [Materials] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_GoodsReceiptLines_PurchaseOrderLines_PurchaseOrderLineId] FOREIGN KEY ([PurchaseOrderLineId]) REFERENCES [PurchaseOrderLines] ([Id]) ON DELETE NO ACTION
);

CREATE TABLE [WorkTaskDependencies] (
    [Id] uniqueidentifier NOT NULL,
    [WorkTaskId] uniqueidentifier NOT NULL,
    [DependsOnTaskId] uniqueidentifier NOT NULL,
    [CreatedAtUtc] datetime2 NOT NULL,
    [CreatedBy] uniqueidentifier NULL,
    [UpdatedAtUtc] datetime2 NULL,
    [UpdatedBy] uniqueidentifier NULL,
    [IsDeleted] bit NOT NULL,
    [DeletedAtUtc] datetime2 NULL,
    [DeletedBy] uniqueidentifier NULL,
    [CompanyId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_WorkTaskDependencies] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_WorkTaskDependencies_WorkTasks_DependsOnTaskId] FOREIGN KEY ([DependsOnTaskId]) REFERENCES [WorkTasks] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_WorkTaskDependencies_WorkTasks_WorkTaskId] FOREIGN KEY ([WorkTaskId]) REFERENCES [WorkTasks] ([Id]) ON DELETE NO ACTION
);

CREATE INDEX [IX_Attendances_ConstructionSiteId] ON [Attendances] ([ConstructionSiteId]);

CREATE UNIQUE INDEX [IX_Attendances_EmployeeId_ConstructionSiteId_AttendanceDate] ON [Attendances] ([EmployeeId], [ConstructionSiteId], [AttendanceDate]);

CREATE INDEX [IX_Attendances_ShiftId] ON [Attendances] ([ShiftId]);

CREATE UNIQUE INDEX [IX_BudgetLines_BudgetId_CostCodeId] ON [BudgetLines] ([BudgetId], [CostCodeId]);

CREATE INDEX [IX_BudgetLines_CostCodeId] ON [BudgetLines] ([CostCodeId]);

CREATE UNIQUE INDEX [IX_Budgets_CompanyId_BudgetNumber] ON [Budgets] ([CompanyId], [BudgetNumber]);

CREATE INDEX [IX_Budgets_ConstructionSiteId] ON [Budgets] ([ConstructionSiteId]);

CREATE INDEX [IX_Budgets_ProjectId] ON [Budgets] ([ProjectId]);

CREATE UNIQUE INDEX [IX_BusinessUnits_CompanyId_Code] ON [BusinessUnits] ([CompanyId], [Code]);

CREATE UNIQUE INDEX [IX_Companies_Code] ON [Companies] ([Code]);

CREATE INDEX [IX_ConstructionSites_BusinessUnitId] ON [ConstructionSites] ([BusinessUnitId]);

CREATE UNIQUE INDEX [IX_ConstructionSites_CompanyId_SiteCode] ON [ConstructionSites] ([CompanyId], [SiteCode]);

CREATE INDEX [IX_ConstructionSites_CompanyId_Status] ON [ConstructionSites] ([CompanyId], [Status]);

CREATE UNIQUE INDEX [IX_Contractors_CompanyId_ContractorCode] ON [Contractors] ([CompanyId], [ContractorCode]);

CREATE UNIQUE INDEX [IX_CostCodes_CompanyId_Code] ON [CostCodes] ([CompanyId], [Code]);

CREATE INDEX [IX_CostCodes_ParentCostCodeId] ON [CostCodes] ([ParentCostCodeId]);

CREATE UNIQUE INDEX [IX_DailyProgressLogs_ProjectId_LogDate] ON [DailyProgressLogs] ([ProjectId], [LogDate]);

CREATE UNIQUE INDEX [IX_Documents_CompanyId_DocumentNumber] ON [Documents] ([CompanyId], [DocumentNumber]);

CREATE INDEX [IX_Documents_ExpiryDate] ON [Documents] ([ExpiryDate]);

CREATE INDEX [IX_Documents_RelatedEntityType_RelatedEntityId] ON [Documents] ([RelatedEntityType], [RelatedEntityId]);

CREATE UNIQUE INDEX [IX_Employees_CompanyId_EmployeeNumber] ON [Employees] ([CompanyId], [EmployeeNumber]);

CREATE INDEX [IX_Employees_CompanyId_Status] ON [Employees] ([CompanyId], [Status]);

CREATE UNIQUE INDEX [IX_Equipment_CompanyId_EquipmentCode] ON [Equipment] ([CompanyId], [EquipmentCode]);

CREATE INDEX [IX_Equipment_VendorId] ON [Equipment] ([VendorId]);

CREATE INDEX [IX_EquipmentAssignments_ConstructionSiteId] ON [EquipmentAssignments] ([ConstructionSiteId]);

CREATE INDEX [IX_EquipmentAssignments_EquipmentId_ConstructionSiteId_AssignedAtUtc] ON [EquipmentAssignments] ([EquipmentId], [ConstructionSiteId], [AssignedAtUtc]);

CREATE INDEX [IX_EquipmentAssignments_ProjectId] ON [EquipmentAssignments] ([ProjectId]);

CREATE INDEX [IX_EquipmentDowntime_ConstructionSiteId] ON [EquipmentDowntime] ([ConstructionSiteId]);

CREATE INDEX [IX_EquipmentDowntime_EquipmentId] ON [EquipmentDowntime] ([EquipmentId]);

CREATE INDEX [IX_EquipmentMaintenance_EquipmentId_ScheduledAtUtc] ON [EquipmentMaintenance] ([EquipmentId], [ScheduledAtUtc]);

CREATE UNIQUE INDEX [IX_Expenses_CompanyId_ExpenseNumber] ON [Expenses] ([CompanyId], [ExpenseNumber]);

CREATE INDEX [IX_Expenses_ConstructionSiteId_CostCodeId_ExpenseDate] ON [Expenses] ([ConstructionSiteId], [CostCodeId], [ExpenseDate]);

CREATE INDEX [IX_Expenses_CostCodeId] ON [Expenses] ([CostCodeId]);

CREATE INDEX [IX_Expenses_ProjectId] ON [Expenses] ([ProjectId]);

CREATE INDEX [IX_Expenses_VendorId] ON [Expenses] ([VendorId]);

CREATE INDEX [IX_GoodsReceiptLines_GoodsReceiptId] ON [GoodsReceiptLines] ([GoodsReceiptId]);

CREATE INDEX [IX_GoodsReceiptLines_MaterialId] ON [GoodsReceiptLines] ([MaterialId]);

CREATE INDEX [IX_GoodsReceiptLines_PurchaseOrderLineId] ON [GoodsReceiptLines] ([PurchaseOrderLineId]);

CREATE UNIQUE INDEX [IX_GoodsReceipts_CompanyId_ReceiptNumber] ON [GoodsReceipts] ([CompanyId], [ReceiptNumber]);

CREATE INDEX [IX_GoodsReceipts_ConstructionSiteId] ON [GoodsReceipts] ([ConstructionSiteId]);

CREATE INDEX [IX_GoodsReceipts_PurchaseOrderId] ON [GoodsReceipts] ([PurchaseOrderId]);

CREATE UNIQUE INDEX [IX_InspectionChecklistItems_InspectionId_Sequence] ON [InspectionChecklistItems] ([InspectionId], [Sequence]);

CREATE UNIQUE INDEX [IX_Inspections_CompanyId_InspectionNumber] ON [Inspections] ([CompanyId], [InspectionNumber]);

CREATE INDEX [IX_Inspections_ConstructionSiteId] ON [Inspections] ([ConstructionSiteId]);

CREATE INDEX [IX_Inspections_ProjectId] ON [Inspections] ([ProjectId]);

CREATE INDEX [IX_InvoiceLines_CostCodeId] ON [InvoiceLines] ([CostCodeId]);

CREATE INDEX [IX_InvoiceLines_InvoiceId] ON [InvoiceLines] ([InvoiceId]);

CREATE UNIQUE INDEX [IX_Invoices_CompanyId_InvoiceNumber] ON [Invoices] ([CompanyId], [InvoiceNumber]);

CREATE INDEX [IX_Invoices_ConstructionSiteId] ON [Invoices] ([ConstructionSiteId]);

CREATE INDEX [IX_Invoices_ProjectId] ON [Invoices] ([ProjectId]);

CREATE INDEX [IX_Invoices_VendorId] ON [Invoices] ([VendorId]);

CREATE INDEX [IX_LeaveRequests_EmployeeId_StartDate_EndDate] ON [LeaveRequests] ([EmployeeId], [StartDate], [EndDate]);

CREATE INDEX [IX_MaterialRequestLines_MaterialId] ON [MaterialRequestLines] ([MaterialId]);

CREATE UNIQUE INDEX [IX_MaterialRequestLines_MaterialRequestId_MaterialId] ON [MaterialRequestLines] ([MaterialRequestId], [MaterialId]);

CREATE UNIQUE INDEX [IX_MaterialRequests_CompanyId_RequestNumber] ON [MaterialRequests] ([CompanyId], [RequestNumber]);

CREATE INDEX [IX_MaterialRequests_ConstructionSiteId] ON [MaterialRequests] ([ConstructionSiteId]);

CREATE INDEX [IX_MaterialRequests_ProjectId] ON [MaterialRequests] ([ProjectId]);

CREATE UNIQUE INDEX [IX_Materials_CompanyId_MaterialCode] ON [Materials] ([CompanyId], [MaterialCode]);

CREATE INDEX [IX_Materials_DefaultCostCodeId] ON [Materials] ([DefaultCostCodeId]);

CREATE INDEX [IX_Milestones_ProjectId] ON [Milestones] ([ProjectId]);

CREATE INDEX [IX_Milestones_ProjectPhaseId] ON [Milestones] ([ProjectPhaseId]);

CREATE UNIQUE INDEX [IX_Payments_CompanyId_PaymentNumber] ON [Payments] ([CompanyId], [PaymentNumber]);

CREATE INDEX [IX_Payments_InvoiceId] ON [Payments] ([InvoiceId]);

CREATE INDEX [IX_Payments_VendorId] ON [Payments] ([VendorId]);

CREATE INDEX [IX_PayrollAdjustments_PayrollRecordId] ON [PayrollAdjustments] ([PayrollRecordId]);

CREATE UNIQUE INDEX [IX_PayrollRecords_EmployeeId_PeriodStart_PeriodEnd] ON [PayrollRecords] ([EmployeeId], [PeriodStart], [PeriodEnd]);

CREATE UNIQUE INDEX [IX_Permits_CompanyId_PermitNumber] ON [Permits] ([CompanyId], [PermitNumber]);

CREATE INDEX [IX_Permits_ConstructionSiteId] ON [Permits] ([ConstructionSiteId]);

CREATE INDEX [IX_Permits_ExpiryDate] ON [Permits] ([ExpiryDate]);

CREATE INDEX [IX_Permits_ProjectId] ON [Permits] ([ProjectId]);

CREATE UNIQUE INDEX [IX_ProjectPhases_ProjectId_Sequence] ON [ProjectPhases] ([ProjectId], [Sequence]);

CREATE UNIQUE INDEX [IX_Projects_CompanyId_ProjectCode] ON [Projects] ([CompanyId], [ProjectCode]);

CREATE INDEX [IX_Projects_ConstructionSiteId] ON [Projects] ([ConstructionSiteId]);

CREATE INDEX [IX_PurchaseOrderLines_CostCodeId] ON [PurchaseOrderLines] ([CostCodeId]);

CREATE INDEX [IX_PurchaseOrderLines_MaterialId] ON [PurchaseOrderLines] ([MaterialId]);

CREATE INDEX [IX_PurchaseOrderLines_PurchaseOrderId_MaterialId] ON [PurchaseOrderLines] ([PurchaseOrderId], [MaterialId]);

CREATE UNIQUE INDEX [IX_PurchaseOrders_CompanyId_PurchaseOrderNumber] ON [PurchaseOrders] ([CompanyId], [PurchaseOrderNumber]);

CREATE INDEX [IX_PurchaseOrders_ConstructionSiteId] ON [PurchaseOrders] ([ConstructionSiteId]);

CREATE INDEX [IX_PurchaseOrders_MaterialRequestId] ON [PurchaseOrders] ([MaterialRequestId]);

CREATE INDEX [IX_PurchaseOrders_ProjectId] ON [PurchaseOrders] ([ProjectId]);

CREATE INDEX [IX_PurchaseOrders_VendorId] ON [PurchaseOrders] ([VendorId]);

CREATE UNIQUE INDEX [IX_SafetyIncidents_CompanyId_IncidentNumber] ON [SafetyIncidents] ([CompanyId], [IncidentNumber]);

CREATE INDEX [IX_SafetyIncidents_ConstructionSiteId] ON [SafetyIncidents] ([ConstructionSiteId]);

CREATE INDEX [IX_SafetyIncidents_EmployeeId] ON [SafetyIncidents] ([EmployeeId]);

CREATE INDEX [IX_SafetyIncidents_ProjectId] ON [SafetyIncidents] ([ProjectId]);

CREATE UNIQUE INDEX [IX_Shifts_CompanyId_Code] ON [Shifts] ([CompanyId], [Code]);

CREATE INDEX [IX_SiteAssignments_ConstructionSiteId] ON [SiteAssignments] ([ConstructionSiteId]);

CREATE INDEX [IX_SiteAssignments_EmployeeId_ConstructionSiteId_StartDate] ON [SiteAssignments] ([EmployeeId], [ConstructionSiteId], [StartDate]);

CREATE UNIQUE INDEX [IX_StockItems_ConstructionSiteId_MaterialId] ON [StockItems] ([ConstructionSiteId], [MaterialId]);

CREATE INDEX [IX_StockItems_MaterialId] ON [StockItems] ([MaterialId]);

CREATE INDEX [IX_StockMovements_StockItemId_MovementDateUtc] ON [StockMovements] ([StockItemId], [MovementDateUtc]);

CREATE UNIQUE INDEX [IX_Vendors_CompanyId_VendorCode] ON [Vendors] ([CompanyId], [VendorCode]);

CREATE INDEX [IX_WorkTaskDependencies_DependsOnTaskId] ON [WorkTaskDependencies] ([DependsOnTaskId]);

CREATE UNIQUE INDEX [IX_WorkTaskDependencies_WorkTaskId_DependsOnTaskId] ON [WorkTaskDependencies] ([WorkTaskId], [DependsOnTaskId]);

CREATE UNIQUE INDEX [IX_WorkTasks_CompanyId_TaskNumber] ON [WorkTasks] ([CompanyId], [TaskNumber]);

CREATE INDEX [IX_WorkTasks_MilestoneId] ON [WorkTasks] ([MilestoneId]);

CREATE INDEX [IX_WorkTasks_ProjectId] ON [WorkTasks] ([ProjectId]);

CREATE INDEX [IX_WorkTasks_ProjectPhaseId] ON [WorkTasks] ([ProjectPhaseId]);

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260801194422_InitialCreate', N'10.0.10');

COMMIT;
GO


BEGIN TRANSACTION;
ALTER TABLE [ProjectPhases] ADD [PhaseNumber] nvarchar(30) NULL;

ALTER TABLE [Milestones] ADD [MilestoneNumber] nvarchar(30) NULL;

ALTER TABLE [EquipmentDowntime] ADD [DowntimeNumber] nvarchar(30) NULL;

ALTER TABLE [EquipmentAssignments] ADD [AssignmentNumber] nvarchar(30) NULL;

ALTER TABLE [DailyProgressLogs] ADD [LogNumber] nvarchar(30) NULL;

ALTER TABLE [DailyMaterialUsages] ADD [UsageNumber] nvarchar(30) NULL;

;WITH Numbered AS
(
    SELECT
        Id,
        ROW_NUMBER() OVER (
            PARTITION BY CompanyId
            ORDER BY Id
        ) AS Number
    FROM DailyMaterialUsages
)
UPDATE d
SET UsageNumber =
    'DMU-' + RIGHT(
        '000000' + CAST(n.Number AS varchar(6)),
        6)
FROM DailyMaterialUsages d
INNER JOIN Numbered n
    ON n.Id = d.Id;

;WITH Numbered AS
(
    SELECT
        Id,
        ROW_NUMBER() OVER (
            PARTITION BY CompanyId
            ORDER BY Id
        ) AS Number
    FROM DailyProgressLogs
)
UPDATE d
SET LogNumber =
    'DPL-' + RIGHT(
        '000000' + CAST(n.Number AS varchar(6)),
        6)
FROM DailyProgressLogs d
INNER JOIN Numbered n
    ON n.Id = d.Id;

;WITH Numbered AS
(
    SELECT
        Id,
        ROW_NUMBER() OVER (
            PARTITION BY CompanyId
            ORDER BY Id
        ) AS Number
    FROM ProjectPhases
)
UPDATE p
SET PhaseNumber =
    'PH-' + RIGHT(
        '000000' + CAST(n.Number AS varchar(6)),
        6)
FROM ProjectPhases p
INNER JOIN Numbered n
    ON n.Id = p.Id;

;WITH Numbered AS
(
    SELECT
        Id,
        ROW_NUMBER() OVER (
            PARTITION BY CompanyId
            ORDER BY Id
        ) AS Number
    FROM Milestones
)
UPDATE m
SET MilestoneNumber =
    'MS-' + RIGHT(
        '000000' + CAST(n.Number AS varchar(6)),
        6)
FROM Milestones m
INNER JOIN Numbered n
    ON n.Id = m.Id;

ALTER TABLE DailyMaterialUsages
ALTER COLUMN UsageNumber nvarchar(30) NOT NULL;

ALTER TABLE DailyProgressLogs
ALTER COLUMN LogNumber nvarchar(30) NOT NULL;

ALTER TABLE ProjectPhases
ALTER COLUMN PhaseNumber nvarchar(30) NOT NULL;

ALTER TABLE Milestones
ALTER COLUMN MilestoneNumber nvarchar(30) NOT NULL;

ALTER TABLE EquipmentAssignments
ALTER COLUMN AssignmentNumber nvarchar(30) NOT NULL;

ALTER TABLE EquipmentDowntime
ALTER COLUMN DowntimeNumber nvarchar(30) NOT NULL;

CREATE UNIQUE INDEX [IX_ProjectPhases_CompanyId_PhaseNumber] ON [ProjectPhases] ([CompanyId], [PhaseNumber]);

CREATE UNIQUE INDEX [IX_Milestones_CompanyId_MilestoneNumber] ON [Milestones] ([CompanyId], [MilestoneNumber]);

CREATE UNIQUE INDEX [IX_EquipmentDowntime_CompanyId_DowntimeNumber] ON [EquipmentDowntime] ([CompanyId], [DowntimeNumber]);

CREATE UNIQUE INDEX [IX_EquipmentAssignments_CompanyId_AssignmentNumber] ON [EquipmentAssignments] ([CompanyId], [AssignmentNumber]);

CREATE UNIQUE INDEX [IX_DailyProgressLogs_CompanyId_LogNumber] ON [DailyProgressLogs] ([CompanyId], [LogNumber]);

CREATE UNIQUE INDEX [IX_DailyMaterialUsages_CompanyId_UsageNumber] ON [DailyMaterialUsages] ([CompanyId], [UsageNumber]);

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260817181349_AddBusinessIdentifiers', N'10.0.10');

COMMIT;
GO


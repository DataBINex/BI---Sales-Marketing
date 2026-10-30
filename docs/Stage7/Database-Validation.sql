/*==============================================================
  Food Distribution - Stage 7
  FINAL DATABASE VALIDATION
  Database: FoodDistributionDB
  SQL Server: 2022

  Purpose:
  1. Verify all 48 expected tables
  2. Detect unexpected tables
  3. Verify Primary Keys
  4. Report structural object counts
  5. Detect disabled/untrusted constraints
  6. Check database constraints and integrity

  READ ONLY - No CREATE / ALTER / DROP / DELETE / UPDATE
==============================================================*/

USE [FoodDistributionDB];
GO

SET NOCOUNT ON;

PRINT '================================================';
PRINT 'STAGE 7 - FINAL DATABASE VALIDATION';
PRINT '================================================';

------------------------------------------------------------
-- 1. Expected tables
------------------------------------------------------------

DECLARE @Expected TABLE
(
    SchemaName sysname,
    TableName  sysname,
    PRIMARY KEY (SchemaName, TableName)
);

INSERT INTO @Expected VALUES

-- TEAM 1: SALES & CUSTOMER
(N'ref',N'Province'),
(N'ref',N'City'),
(N'ref',N'CustomerSegment'),
(N'ref',N'SalesChannel'),
(N'ref',N'SalesRegion'),
(N'ref',N'SalesTerritory'),

(N'core',N'Calendar'),
(N'core',N'Branch'),
(N'core',N'Salesperson'),
(N'core',N'Customer'),

(N'sales',N'Lead'),
(N'sales',N'CustomerInteraction'),
(N'sales',N'SalesOpportunity'),
(N'sales',N'Contract'),
(N'sales',N'SalesOrder'),
(N'sales',N'SalesOrderItem'),
(N'sales',N'Invoice'),
(N'sales',N'InvoiceItem'),
(N'sales',N'Payment'),
(N'sales',N'ReturnRequest'),
(N'sales',N'CustomerFeedback'),
(N'sales',N'Commission'),
(N'sales',N'SalesTarget'),
(N'sales',N'SalesForecast'),

-- TEAM 2: PRODUCT & MARKETING
(N'ref',N'ProductCategory'),
(N'ref',N'Package'),

(N'core',N'Brand'),
(N'core',N'Product'),
(N'core',N'SKU'),

(N'marketing',N'ProductPrice'),
(N'marketing',N'CampaignChannel'),
(N'marketing',N'CampaignAudience'),
(N'marketing',N'MarketingCampaign'),
(N'marketing',N'MarketingCampaignChannel'),
(N'marketing',N'MarketingCampaignAudience'),
(N'marketing',N'CampaignBudget'),
(N'marketing',N'CampaignCost'),
(N'marketing',N'CampaignResult'),
(N'marketing',N'Promotion'),
(N'marketing',N'BrandActivity'),
(N'marketing',N'Market'),
(N'marketing',N'MarketSegment'),
(N'marketing',N'MarketResearch'),
(N'marketing',N'MarketSurvey'),
(N'marketing',N'ResearchResult'),
(N'marketing',N'Competitor'),
(N'marketing',N'CompetitorProduct'),
(N'marketing',N'MarketPrice');

------------------------------------------------------------
-- 2. Verify schemas
------------------------------------------------------------

PRINT '';
PRINT '1. SCHEMA VALIDATION';

SELECT
    v.SchemaName,
    CASE
        WHEN s.schema_id IS NOT NULL THEN 'EXISTS'
        ELSE 'MISSING'
    END AS ValidationStatus
FROM
(
    VALUES
    (N'ref'),
    (N'core'),
    (N'sales'),
    (N'marketing')
) v(SchemaName)
LEFT JOIN sys.schemas s
    ON s.name = v.SchemaName;

------------------------------------------------------------
-- 3. Missing expected tables
------------------------------------------------------------

PRINT '';
PRINT '2. MISSING EXPECTED TABLES';

SELECT
    e.SchemaName,
    e.TableName,
    'MISSING' AS Status
FROM @Expected e
LEFT JOIN sys.tables t
    ON t.name = e.TableName
   AND t.schema_id = SCHEMA_ID(e.SchemaName)
WHERE t.object_id IS NULL;

------------------------------------------------------------
-- 4. Unexpected tables
------------------------------------------------------------

PRINT '';
PRINT '3. UNEXPECTED TABLES';

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    'UNEXPECTED' AS Status
FROM sys.tables t
JOIN sys.schemas s
    ON s.schema_id = t.schema_id
WHERE s.name IN
(
    N'ref',
    N'core',
    N'sales',
    N'marketing'
)
AND NOT EXISTS
(
    SELECT 1
    FROM @Expected e
    WHERE e.SchemaName = s.name
      AND e.TableName = t.name
);

------------------------------------------------------------
-- 5. Primary Key validation
------------------------------------------------------------

PRINT '';
PRINT '4. TABLES WITHOUT PRIMARY KEY';

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    'MISSING PRIMARY KEY' AS Status
FROM @Expected e
JOIN sys.schemas s
    ON s.name = e.SchemaName
JOIN sys.tables t
    ON t.schema_id = s.schema_id
   AND t.name = e.TableName
LEFT JOIN sys.key_constraints pk
    ON pk.parent_object_id = t.object_id
   AND pk.type = 'PK'
WHERE pk.object_id IS NULL;

------------------------------------------------------------
-- 6. Structural summary
------------------------------------------------------------

PRINT '';
PRINT '5. DATABASE STRUCTURAL SUMMARY';

SELECT
    COUNT(DISTINCT t.object_id) AS TotalTables,
    (
        SELECT COUNT(*)
        FROM sys.columns c
        JOIN sys.tables t2
            ON t2.object_id = c.object_id
        JOIN sys.schemas s2
            ON s2.schema_id = t2.schema_id
        WHERE s2.name IN
        (N'ref',N'core',N'sales',N'marketing')
    ) AS TotalColumns,
    (
        SELECT COUNT(*)
        FROM sys.key_constraints k
        JOIN sys.tables t2
            ON t2.object_id = k.parent_object_id
        JOIN sys.schemas s2
            ON s2.schema_id = t2.schema_id
        WHERE s2.name IN
        (N'ref',N'core',N'sales',N'marketing')
          AND k.type = 'PK'
    ) AS PrimaryKeys,
    (
        SELECT COUNT(*)
        FROM sys.key_constraints k
        JOIN sys.tables t2
            ON t2.object_id = k.parent_object_id
        JOIN sys.schemas s2
            ON s2.schema_id = t2.schema_id
        WHERE s2.name IN
        (N'ref',N'core',N'sales',N'marketing')
          AND k.type = 'UQ'
    ) AS UniqueConstraints,
    (
        SELECT COUNT(*)
        FROM sys.foreign_keys fk
        JOIN sys.tables t2
            ON t2.object_id = fk.parent_object_id
        JOIN sys.schemas s2
            ON s2.schema_id = t2.schema_id
        WHERE s2.name IN
        (N'ref',N'core',N'sales',N'marketing')
    ) AS ForeignKeys,
    (
        SELECT COUNT(*)
        FROM sys.check_constraints ck
        JOIN sys.tables t2
            ON t2.object_id = ck.parent_object_id
        JOIN sys.schemas s2
            ON s2.schema_id = t2.schema_id
        WHERE s2.name IN
        (N'ref',N'core',N'sales',N'marketing')
    ) AS CheckConstraints,
    (
        SELECT COUNT(*)
        FROM sys.default_constraints df
        JOIN sys.tables t2
            ON t2.object_id = df.parent_object_id
        JOIN sys.schemas s2
            ON s2.schema_id = t2.schema_id
        WHERE s2.name IN
        (N'ref',N'core',N'sales',N'marketing')
    ) AS DefaultConstraints,
    (
        SELECT COUNT(*)
        FROM sys.indexes ix
        JOIN sys.tables t2
            ON t2.object_id = ix.object_id
        JOIN sys.schemas s2
            ON s2.schema_id = t2.schema_id
        WHERE s2.name IN
        (N'ref',N'core',N'sales',N'marketing')
          AND ix.index_id > 0
          AND ix.is_hypothetical = 0
    ) AS TotalIndexes
FROM sys.tables t
JOIN sys.schemas s
    ON s.schema_id = t.schema_id
WHERE s.name IN
(N'ref',N'core',N'sales',N'marketing');

------------------------------------------------------------
-- 7. Disabled or untrusted Foreign Keys
------------------------------------------------------------

PRINT '';
PRINT '6. DISABLED / UNTRUSTED FOREIGN KEYS';

SELECT
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS SchemaName,
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    fk.name AS ForeignKeyName,
    fk.is_disabled,
    fk.is_not_trusted
FROM sys.foreign_keys fk
WHERE fk.is_disabled = 1
   OR fk.is_not_trusted = 1;

------------------------------------------------------------
-- 8. Disabled or untrusted CHECK constraints
------------------------------------------------------------

PRINT '';
PRINT '7. DISABLED / UNTRUSTED CHECK CONSTRAINTS';

SELECT
    OBJECT_SCHEMA_NAME(ck.parent_object_id) AS SchemaName,
    OBJECT_NAME(ck.parent_object_id) AS TableName,
    ck.name AS ConstraintName,
    ck.is_disabled,
    ck.is_not_trusted
FROM sys.check_constraints ck
WHERE ck.is_disabled = 1
   OR ck.is_not_trusted = 1;

------------------------------------------------------------
-- 9. Disabled indexes
------------------------------------------------------------

PRINT '';
PRINT '8. DISABLED INDEXES';

SELECT
    OBJECT_SCHEMA_NAME(ix.object_id) AS SchemaName,
    OBJECT_NAME(ix.object_id) AS TableName,
    ix.name AS IndexName
FROM sys.indexes ix
JOIN sys.tables t
    ON t.object_id = ix.object_id
JOIN sys.schemas s
    ON s.schema_id = t.schema_id
WHERE s.name IN
(N'ref',N'core',N'sales',N'marketing')
  AND ix.is_disabled = 1;

------------------------------------------------------------
-- 10. Tables without rows / row counts
------------------------------------------------------------

PRINT '';
PRINT '9. TABLE ROW COUNTS';

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    SUM(p.rows) AS TotalRows
FROM sys.tables t
JOIN sys.schemas s
    ON s.schema_id = t.schema_id
JOIN sys.partitions p
    ON p.object_id = t.object_id
   AND p.index_id IN (0,1)
WHERE s.name IN
(N'ref',N'core',N'sales',N'marketing')
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

------------------------------------------------------------
-- 11. Constraint data validation
------------------------------------------------------------

PRINT '';
PRINT '10. DBCC CHECKCONSTRAINTS';
PRINT 'Any returned rows indicate constraint/data violations.';

DBCC CHECKCONSTRAINTS
WITH ALL_CONSTRAINTS;
GO

------------------------------------------------------------
-- 12. Database physical/logical integrity
------------------------------------------------------------

PRINT '';
PRINT '11. DBCC CHECKDB';

DBCC CHECKDB ([FoodDistributionDB])
WITH NO_INFOMSGS;
GO

------------------------------------------------------------
-- 13. Final message
------------------------------------------------------------

PRINT '';
PRINT '================================================';
PRINT 'FINAL VALIDATION SCRIPT COMPLETED';
PRINT 'Review all result sets for missing objects,';
PRINT 'unexpected objects, disabled constraints,';
PRINT 'constraint violations and CHECKDB errors.';
PRINT '================================================';
GO
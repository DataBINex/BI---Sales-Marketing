/*=============================================================================
 FOOD DISTRIBUTION BI - STAGE 9 - REPORTING LAYER VALIDATION
 File     : 09-02-RPT-Layer-Validate.sql      Version 1.0 (1405/08/30)
 Run      : after 09-01-RPT-Layer-Create.sql, in FoodDistributionDB. Read-only.
 Output   : one row per check: Check_Group | Object | Check | Expected | Actual | Result (PASS / FAIL / INFO)
 Checks   (guide section 9 + 13):
   V1 fact row count = source table row count
   V2 dim row count  = source rows (+1 when the dim has an unknown member)
   V3 dim key unique
   V4 no orphan dimension key in any fact
   V5 no orphan date key (every non-NULL *DateKey exists in Dim_Date)
   V6 amount totals equal OLTP
   V7 invoice header Total_Amount = sum of line Final_Amount (difference <= 1)
   V8 no personal column in any rpt view
   V9 view count = 38
   I1 INFO: dates outside the calendar range (key left NULL by design)
=============================================================================*/
SET NOCOUNT ON;
IF DB_NAME() NOT LIKE N'FoodDistributionDB%'
    THROW 50900, N'Wrong database context. Run this file in FoodDistributionDB.', 1;

DROP TABLE IF EXISTS #V;
CREATE TABLE #V (Seq int IDENTITY(1,1), Check_Group nvarchar(10), Object_Name nvarchar(80), Check_Name nvarchar(200),
                 Expected decimal(28,2), Actual decimal(28,2), Result nvarchar(10));
DECLARE @sql nvarchar(max), @e decimal(28,2), @a decimal(28,2);

/*---------------------------------------------------------------- V1 fact rows */
DECLARE @TF TABLE (v sysname, src nvarchar(200));
INSERT @TF VALUES
 (N'Fact_SalesOrderLine', N'sales.SalesOrderItem'), (N'Fact_Invoice', N'sales.Invoice'), (N'Fact_InvoiceLine', N'sales.InvoiceItem'),
 (N'Fact_Payment', N'sales.Payment'), (N'Fact_Return', N'sales.ReturnRequest'), (N'Fact_SalesTarget', N'sales.SalesTarget'),
 (N'Fact_SalesForecast', N'sales.SalesForecast'), (N'Fact_Commission', N'sales.Commission'), (N'Fact_Lead', N'sales.Lead'),
 (N'Fact_Opportunity', N'sales.SalesOpportunity'), (N'Fact_Contract', N'sales.Contract'),
 (N'Fact_CustomerInteraction', N'sales.CustomerInteraction'), (N'Fact_CustomerFeedback', N'sales.CustomerFeedback'),
 (N'Fact_CampaignBudget', N'marketing.CampaignBudget'), (N'Fact_CampaignCost', N'marketing.CampaignCost'),
 (N'Fact_CampaignResult', N'marketing.CampaignResult'), (N'Fact_BrandActivity', N'marketing.BrandActivity'),
 (N'Fact_ProductPrice', N'marketing.ProductPrice'), (N'Fact_MarketPrice', N'marketing.MarketPrice'),
 (N'Fact_MarketResearch', N'marketing.MarketResearch'), (N'Fact_MarketSurvey', N'marketing.MarketSurvey'),
 (N'Bridge_CampaignAudience', N'marketing.MarketingCampaignAudience');
DECLARE @v sysname, @src nvarchar(200), @k sysname, @dim sysname, @dk sysname, @unk int;
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT v, src FROM @TF;
OPEN c; FETCH c INTO @v, @src;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT @e = (SELECT COUNT_BIG(*) FROM ' + @src + N'), @a = (SELECT COUNT_BIG(*) FROM rpt.' + QUOTENAME(@v) + N');';
    EXEC sp_executesql @sql, N'@e decimal(28,2) OUTPUT, @a decimal(28,2) OUTPUT', @e OUTPUT, @a OUTPUT;
    INSERT #V VALUES (N'V1', @v, N'Row count = ' + @src, @e, @a, CASE WHEN @e = @a THEN N'PASS' ELSE N'FAIL' END);
    FETCH c INTO @v, @src;
END
CLOSE c; DEALLOCATE c;

/*---------------------------------------------------------------- V2 + V3 dims */
DECLARE @TD TABLE (v sysname, src nvarchar(200), k sysname, unk int);
INSERT @TD VALUES
 (N'Dim_Date', N'core.Calendar', N'DateKey', 0), (N'Dim_Customer', N'core.Customer', N'Customer_Key', 1),
 (N'Dim_Salesperson', N'core.Salesperson', N'Salesperson_Key', 1), (N'Dim_SalesRegion', N'ref.SalesRegion', N'SalesRegion_Key', 1),
 (N'Dim_SalesChannel', N'ref.SalesChannel', N'SalesChannel_Key', 1), (N'Dim_Product', N'core.Product', N'Product_Key', 1),
 (N'Dim_SKU', N'core.SKU', N'SKU_Key', 0), (N'Dim_Brand', N'core.Brand', N'Brand_Key', 0),
 (N'Dim_Campaign', N'marketing.MarketingCampaign', N'Campaign_Key', 0), (N'Dim_CampaignChannel', N'marketing.CampaignChannel', N'CampaignChannel_Key', 1),
 (N'Dim_CampaignAudience', N'marketing.CampaignAudience', N'CampaignAudience_Key', 0), (N'Dim_Promotion', N'marketing.Promotion', N'Promotion_Key', 1),
 (N'Dim_Market', N'marketing.Market', N'Market_Key', 0), (N'Dim_MarketSegment', N'marketing.MarketSegment', N'MarketSegment_Key', 1),
 (N'Dim_Competitor', N'marketing.Competitor', N'Competitor_Key', 0), (N'Dim_CompetitorProduct', N'marketing.CompetitorProduct', N'CompetitorProduct_Key', 1);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT v, src, k, unk FROM @TD;
OPEN c; FETCH c INTO @v, @src, @k, @unk;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT @e = (SELECT COUNT_BIG(*) FROM ' + @src + N') + ' + CAST(@unk AS nvarchar(5)) + N', @a = (SELECT COUNT_BIG(*) FROM rpt.' + QUOTENAME(@v) + N');';
    EXEC sp_executesql @sql, N'@e decimal(28,2) OUTPUT, @a decimal(28,2) OUTPUT', @e OUTPUT, @a OUTPUT;
    INSERT #V VALUES (N'V2', @v, N'Row count = ' + @src + CASE WHEN @unk = 1 THEN N' + 1 unknown' ELSE N'' END, @e, @a, CASE WHEN @e = @a THEN N'PASS' ELSE N'FAIL' END);
    SET @sql = N'SELECT @e = COUNT_BIG(*), @a = COUNT_BIG(DISTINCT ' + QUOTENAME(@k) + N') FROM rpt.' + QUOTENAME(@v) + N';';
    EXEC sp_executesql @sql, N'@e decimal(28,2) OUTPUT, @a decimal(28,2) OUTPUT', @e OUTPUT, @a OUTPUT;
    INSERT #V VALUES (N'V3', @v, N'Key ' + @k + N' is unique', @e, @a, CASE WHEN @e = @a THEN N'PASS' ELSE N'FAIL' END);
    FETCH c INTO @v, @src, @k, @unk;
END
CLOSE c; DEALLOCATE c;

/*---------------------------------------------------------------- V4 orphan dim keys (driven by column names) */
DECLARE @TK TABLE (k sysname, dim sysname, dk sysname);
INSERT @TK VALUES
 (N'Customer_Key', N'Dim_Customer', N'Customer_Key'), (N'Salesperson_Key', N'Dim_Salesperson', N'Salesperson_Key'),
 (N'SalesRegion_Key', N'Dim_SalesRegion', N'SalesRegion_Key'), (N'SalesChannel_Key', N'Dim_SalesChannel', N'SalesChannel_Key'),
 (N'Product_Key', N'Dim_Product', N'Product_Key'), (N'SKU_Key', N'Dim_SKU', N'SKU_Key'), (N'Brand_Key', N'Dim_Brand', N'Brand_Key'),
 (N'Campaign_Key', N'Dim_Campaign', N'Campaign_Key'), (N'CampaignChannel_Key', N'Dim_CampaignChannel', N'CampaignChannel_Key'),
 (N'CampaignAudience_Key', N'Dim_CampaignAudience', N'CampaignAudience_Key'), (N'Promotion_Key', N'Dim_Promotion', N'Promotion_Key'),
 (N'Market_Key', N'Dim_Market', N'Market_Key'), (N'MarketSegment_Key', N'Dim_MarketSegment', N'MarketSegment_Key'),
 (N'CompetitorProduct_Key', N'Dim_CompetitorProduct', N'CompetitorProduct_Key');
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT v.name, col.name, k.dim, k.dk
    FROM sys.views v JOIN sys.columns col ON col.object_id = v.object_id JOIN @TK k ON k.k = col.name
    WHERE v.schema_id = SCHEMA_ID(N'rpt') AND (v.name LIKE N'Fact[_]%' OR v.name LIKE N'Bridge[_]%')
    ORDER BY v.name, col.column_id;
OPEN c; FETCH c INTO @v, @k, @dim, @dk;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT @a = COUNT_BIG(*) FROM rpt.' + QUOTENAME(@v) + N' f WHERE f.' + QUOTENAME(@k)
             + N' IS NULL OR NOT EXISTS (SELECT 1 FROM rpt.' + QUOTENAME(@dim) + N' d WHERE d.' + QUOTENAME(@dk) + N' = f.' + QUOTENAME(@k) + N');';
    EXEC sp_executesql @sql, N'@a decimal(28,2) OUTPUT', @a OUTPUT;
    INSERT #V VALUES (N'V4', @v, N'No orphan/NULL ' + @k + N' (-> ' + @dim + N')', 0, @a, CASE WHEN @a = 0 THEN N'PASS' ELSE N'FAIL' END);
    FETCH c INTO @v, @k, @dim, @dk;
END
CLOSE c; DEALLOCATE c;

/*---------------------------------------------------------------- V5 orphan date keys */
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT v.name, col.name FROM sys.views v JOIN sys.columns col ON col.object_id = v.object_id
    WHERE v.schema_id = SCHEMA_ID(N'rpt') AND v.name LIKE N'Fact[_]%' AND col.name LIKE N'%DateKey'
    ORDER BY v.name, col.column_id;
OPEN c; FETCH c INTO @v, @k;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT @a = COUNT_BIG(*) FROM rpt.' + QUOTENAME(@v) + N' f WHERE f.' + QUOTENAME(@k)
             + N' IS NOT NULL AND NOT EXISTS (SELECT 1 FROM rpt.Dim_Date d WHERE d.DateKey = f.' + QUOTENAME(@k) + N');';
    EXEC sp_executesql @sql, N'@a decimal(28,2) OUTPUT', @a OUTPUT;
    INSERT #V VALUES (N'V5', @v, N'No orphan ' + @k, 0, @a, CASE WHEN @a = 0 THEN N'PASS' ELSE N'FAIL' END);
    FETCH c INTO @v, @k;
END
CLOSE c; DEALLOCATE c;

/*---------------------------------------------------------------- V6 amount totals */
DECLARE @TA TABLE (v sysname, vcol sysname, src nvarchar(200), scol nvarchar(200));
INSERT @TA VALUES
 (N'Fact_SalesOrderLine', N'Net_Amount', N'sales.SalesOrderItem', N'Net_Amount'),
 (N'Fact_SalesOrderLine', N'Quantity', N'sales.SalesOrderItem', N'Quantity'),
 (N'Fact_Invoice', N'Total_Amount', N'sales.Invoice', N'Total_Amount'),
 (N'Fact_Invoice', N'Subtotal', N'sales.Invoice', N'Subtotal'),
 (N'Fact_Invoice', N'Paid_Amount', N'sales.Payment WHERE Invoice_ID IS NOT NULL AND Payment_Status = N''Successful''', N'Amount'),
 (N'Fact_Invoice', N'Tax_Amount', N'sales.Invoice', N'ISNULL(Tax_Amount,0)'),
 (N'Fact_Invoice', N'Discount_Amount', N'sales.Invoice', N'ISNULL(Discount_Amount,0)'),
 (N'Fact_InvoiceLine', N'Final_Amount', N'sales.InvoiceItem', N'Final_Amount'),
 (N'Fact_InvoiceLine', N'Net_Amount', N'sales.InvoiceItem', N'Net_Amount'),
 (N'Fact_Payment', N'Amount', N'sales.Payment', N'Amount'),
 (N'Fact_Return', N'Refund_Amount', N'sales.ReturnRequest', N'ISNULL(Refund_Amount,0)'),
 (N'Fact_SalesTarget', N'Target_Value', N'sales.SalesTarget', N'ISNULL(Target_Value,0)'),
 (N'Fact_SalesForecast', N'Forecast_Amount', N'sales.SalesForecast', N'Forecast_Amount'),
 (N'Fact_Commission', N'Commission_Amount', N'sales.Commission', N'Commission_Amount'),
 (N'Fact_Opportunity', N'Expected_Value', N'sales.SalesOpportunity', N'ISNULL(Expected_Value,0)'),
 (N'Fact_Contract', N'Contract_Amount', N'sales.Contract', N'Contract_Amount'),
 (N'Fact_CampaignBudget', N'Total_Allocated_Amount', N'marketing.CampaignBudget', N'Total_Allocated_Amount'),
 (N'Fact_CampaignCost', N'Actual_Spent', N'marketing.CampaignCost', N'Actual_Spent'),
 (N'Fact_BrandActivity', N'Activity_Cost', N'marketing.BrandActivity', N'ISNULL(Activity_Cost,0)'),
 (N'Fact_MarketResearch', N'Research_Cost', N'marketing.MarketResearch', N'ISNULL(Research_Cost,0)'),
 (N'Fact_MarketSurvey', N'Sample_Size', N'marketing.MarketSurvey', N'Sample_Size');
DECLARE @vc sysname, @sc nvarchar(200);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT v, vcol, src, scol FROM @TA;
OPEN c; FETCH c INTO @v, @vc, @src, @sc;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT @e = (SELECT ISNULL(SUM(CAST(' + @sc + N' AS decimal(28,2))),0) FROM ' + @src + N'), @a = (SELECT ISNULL(SUM(CAST(' + QUOTENAME(@vc) + N' AS decimal(28,2))),0) FROM rpt.' + QUOTENAME(@v) + N');';
    EXEC sp_executesql @sql, N'@e decimal(28,2) OUTPUT, @a decimal(28,2) OUTPUT', @e OUTPUT, @a OUTPUT;
    INSERT #V VALUES (N'V6', @v, N'SUM(' + @vc + N') = ' + @src, @e, @a, CASE WHEN @e = @a THEN N'PASS' ELSE N'FAIL' END);
    FETCH c INTO @v, @vc, @src, @sc;
END
CLOSE c; DEALLOCATE c;

/*---------------------------------------------------------------- V7 header vs lines */
SELECT @a = COUNT_BIG(*)
FROM rpt.Fact_Invoice h
LEFT JOIN (SELECT Invoice_ID, SUM(Final_Amount) AS s FROM rpt.Fact_InvoiceLine GROUP BY Invoice_ID) l ON l.Invoice_ID = h.Invoice_ID
WHERE ABS(h.Total_Amount - ISNULL(l.s, 0)) > 1;
INSERT #V VALUES (N'V7', N'Fact_Invoice / Fact_InvoiceLine', N'Invoices where |Total_Amount - SUM(line Final_Amount)| > 1', 0, @a, CASE WHEN @a = 0 THEN N'PASS' ELSE N'FAIL' END);

/*---------------------------------------------------------------- V8 personal columns */
SELECT @a = COUNT_BIG(*)
FROM sys.views v JOIN sys.columns col ON col.object_id = v.object_id
WHERE v.schema_id = SCHEMA_ID(N'rpt')
  AND (col.name LIKE N'%Phone%' OR col.name LIKE N'%Mobile%' OR col.name LIKE N'%Email%' OR col.name LIKE N'%Address%'
    OR col.name LIKE N'%Postal%' OR col.name LIKE N'%Contact_Person%' OR col.name LIKE N'%Latitude%' OR col.name LIKE N'%Longitude%'
    OR col.name LIKE N'%Responsible_Person%' OR col.name LIKE N'%Lead_Name%' OR col.name LIKE N'%Feedback_Text%' OR col.name LIKE N'%Notes%');
INSERT #V VALUES (N'V8', N'rpt.*', N'No personal / free-text column in any view', 0, @a, CASE WHEN @a = 0 THEN N'PASS' ELSE N'FAIL' END);

/*---------------------------------------------------------------- V9 view count */
SELECT @a = COUNT_BIG(*) FROM sys.views WHERE schema_id = SCHEMA_ID(N'rpt');
INSERT #V VALUES (N'V9', N'rpt', N'38 views (16 Dim, 21 Fact, 1 Bridge)', 38, @a, CASE WHEN @a = 38 THEN N'PASS' ELSE N'FAIL' END);

/*---------------------------------------------------------------- I1 info: dates outside calendar range */
DECLARE @lo date = (SELECT MIN(Calendar_Date) FROM core.Calendar), @hi date = (SELECT MAX(Calendar_Date) FROM core.Calendar);
DECLARE @TI TABLE (obj nvarchar(80), col nvarchar(80), n bigint);
INSERT @TI SELECT N'sales.Invoice', N'Due_Date', COUNT_BIG(*) FROM sales.Invoice WHERE Due_Date NOT BETWEEN @lo AND @hi;
INSERT @TI SELECT N'sales.SalesOrder', N'Delivery_Date', COUNT_BIG(*) FROM sales.SalesOrder WHERE Delivery_Date NOT BETWEEN @lo AND @hi;
INSERT @TI SELECT N'sales.SalesOpportunity', N'Expected_Close_Date', COUNT_BIG(*) FROM sales.SalesOpportunity WHERE Expected_Close_Date NOT BETWEEN @lo AND @hi;
INSERT @TI SELECT N'sales.Contract', N'End_Date', COUNT_BIG(*) FROM sales.Contract WHERE End_Date NOT BETWEEN @lo AND @hi;
INSERT @TI SELECT N'sales.CustomerInteraction', N'Follow_Up_Date', COUNT_BIG(*) FROM sales.CustomerInteraction WHERE Follow_Up_Date NOT BETWEEN @lo AND @hi;
INSERT @TI SELECT N'marketing.ProductPrice', N'Effective_To', COUNT_BIG(*) FROM marketing.ProductPrice WHERE Effective_To NOT BETWEEN @lo AND @hi;
INSERT @TI SELECT N'marketing.BrandActivity', N'Activity_End_Date', COUNT_BIG(*) FROM marketing.BrandActivity WHERE Activity_End_Date NOT BETWEEN @lo AND @hi;
INSERT @TI SELECT N'marketing.MarketResearch', N'End_Date', COUNT_BIG(*) FROM marketing.MarketResearch WHERE End_Date NOT BETWEEN @lo AND @hi;
INSERT @TI SELECT N'marketing.ProductPrice', N'Effective_From', COUNT_BIG(*) FROM marketing.ProductPrice WHERE Effective_From NOT BETWEEN @lo AND @hi;
INSERT @TI SELECT N'marketing.CampaignBudget', N'Approval_Date', COUNT_BIG(*) FROM marketing.CampaignBudget WHERE Approval_Date NOT BETWEEN @lo AND @hi;
INSERT @TI SELECT N'sales.Lead', N'Created_Date', COUNT_BIG(*) FROM sales.Lead WHERE Created_Date NOT BETWEEN @lo AND @hi;
INSERT #V (Check_Group, Object_Name, Check_Name, Expected, Actual, Result)
SELECT N'I1', obj, col + N' outside calendar (date key left NULL, raw date kept)', NULL, n, N'INFO' FROM @TI WHERE n > 0;

/*---------------------------------------------------------------- output */
SELECT Check_Group, Object_Name, Check_Name, Expected, Actual, Result FROM #V ORDER BY Seq;
SELECT Result, COUNT(*) AS Checks FROM #V GROUP BY Result ORDER BY Result;

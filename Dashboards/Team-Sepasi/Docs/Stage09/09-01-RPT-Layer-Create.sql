/*=============================================================================
 FOOD DISTRIBUTION BI - STAGE 9 - REPORTING LAYER (schema rpt)
 File     : 09-01-RPT-Layer-Create.sql      Version 1.0 (1405/08/30)
 Input    : FoodDistributionDB, Stage 8 data v2 (1398/01/01 .. 1405/08/30 = 2019-03-21 .. 2026-11-21)
            core.Calendar must already have the Persian columns (Stage8-0-AddPersianDateToCalendar.sql).
 Output   : 38 views in schema rpt = 16 Dim_*, 21 Fact_*, 1 Bridge_*.
 Rules    : views only, no data copied, no OLTP table changed (guide section 4/5).
            Dim key = OLTP id named <Name>_Key; unknown member = -1 (UNION ALL) where a fact may have NULL.
            Date keys = int yyyymmdd. Every date key is taken from core.Calendar with a LEFT JOIN, so a
            date outside the calendar range gives a NULL key (never an orphan); the raw date stays in the view.
            No personal columns (phone, mobile, e-mail, address, postal code, contact person, coordinates).
            No KPI logic (percent, ratio) - that belongs to DAX (stage 10). Only additive base amounts.
 Re-run   : safe; every view is CREATE OR ALTER.
=============================================================================*/
SET NOCOUNT ON;
GO
IF DB_NAME() NOT LIKE N'FoodDistributionDB%'
    THROW 50900, N'Wrong database context. Run this file in FoodDistributionDB.', 1;
IF COL_LENGTH('core.Calendar', 'PersianYear') IS NULL OR COL_LENGTH('core.Calendar', 'DateKey') IS NULL
    THROW 50901, N'core.Calendar has no Persian columns. Run Stage8-0-AddPersianDateToCalendar.sql first.', 1;
GO
IF SCHEMA_ID(N'rpt') IS NULL EXEC (N'CREATE SCHEMA rpt AUTHORIZATION dbo;');
GO

/*=============================================================================
 PART A - DIMENSIONS (16)
=============================================================================*/

/*-----------------------------------------------------------------------------
 Dim_Date  - one row per calendar day (2,803). Key: DateKey. No unknown member.
 Persian week starts on Saturday (2000-01-01 was a Saturday). Weekend = Friday.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Dim_Date
AS
SELECT
    c.DateKey,
    c.Calendar_Date                                            AS [Date],
    c.Calendar_ID,
    c.Year_Number                                              AS Gregorian_Year,
    c.Quarter_Number                                           AS Gregorian_Quarter,
    c.Month_Number                                             AS Gregorian_Month,
    c.Day_Number                                               AS Gregorian_Day,
    c.Week_Number                                              AS ISO_Week_Number,
    c.PersianYear,
    (c.PersianMonth - 1) / 3 + 1                               AS PersianQuarter,
    CASE (c.PersianMonth - 1) / 3 + 1 WHEN 1 THEN N'بهار' WHEN 2 THEN N'تابستان'
                                      WHEN 3 THEN N'پاییز' ELSE N'زمستان' END AS PersianQuarterName,
    c.PersianMonth,
    c.PersianMonthName,
    c.PersianDay,
    c.PersianYear * 100 + c.PersianMonth                       AS PersianYearMonthKey,
    c.PersianYear * 12 + c.PersianMonth                        AS PersianMonthSeq,
    c.PersianYear * 10 + (c.PersianMonth - 1) / 3 + 1          AS PersianYearQuarterKey,
    CONCAT(c.PersianYear, N'-', RIGHT(CONCAT(N'0', c.PersianMonth), 2))           AS PersianYearMonth,
    CONCAT(c.PersianMonthName, N' ', c.PersianYear)            AS PersianMonthYearLabel,
    c.PersianYear * 10000 + c.PersianMonth * 100 + c.PersianDay AS PersianDateKey,
    CONCAT(c.PersianYear, N'/', RIGHT(CONCAT(N'0', c.PersianMonth), 2), N'/', RIGHT(CONCAT(N'0', c.PersianDay), 2)) AS PersianDate,
    CASE WHEN c.PersianMonth <= 6 THEN (c.PersianMonth - 1) * 31 + c.PersianDay
         ELSE 186 + (c.PersianMonth - 7) * 30 + c.PersianDay END AS PersianDayOfYear,
    DATEDIFF(DAY, '2000-01-01', c.Calendar_Date) % 7 + 1       AS PersianWeekdayNumber,
    CASE DATEDIFF(DAY, '2000-01-01', c.Calendar_Date) % 7
         WHEN 0 THEN N'شنبه' WHEN 1 THEN N'یکشنبه' WHEN 2 THEN N'دوشنبه' WHEN 3 THEN N'سه‌شنبه'
         WHEN 4 THEN N'چهارشنبه' WHEN 5 THEN N'پنجشنبه' ELSE N'جمعه' END AS PersianWeekdayName,
    CAST(CASE WHEN DATEDIFF(DAY, '2000-01-01', c.Calendar_Date) % 7 = 6 THEN 1 ELSE 0 END AS bit) AS IsWeekend,
    CAST(CASE
            WHEN LEAD(c.PersianMonth) OVER (ORDER BY c.Calendar_Date) IS NULL
                 THEN CASE WHEN (c.PersianMonth <= 6 AND c.PersianDay = 31)
                             OR (c.PersianMonth BETWEEN 7 AND 11 AND c.PersianDay = 30)
                             OR (c.PersianMonth = 12 AND c.PersianDay >= 29) THEN 1 ELSE 0 END
            WHEN LEAD(c.PersianMonth) OVER (ORDER BY c.Calendar_Date) <> c.PersianMonth THEN 1
            ELSE 0 END AS bit)                                 AS IsPersianMonthEnd
FROM core.Calendar AS c;
GO

/*-----------------------------------------------------------------------------
 Dim_SalesRegion - one row per sales region (Region > Area > Team), flattened. Unknown -1.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Dim_SalesRegion
AS
SELECT
    r.Sales_Region_ID                                          AS SalesRegion_Key,
    r.Sales_Region_Code,
    r.Sales_Region_Name,
    r.Region_Level,
    CASE r.Region_Level WHEN N'Region' THEN r.Sales_Region_Name
                        WHEN N'Area'   THEN p.Sales_Region_Name
                        WHEN N'Team'   THEN gp.Sales_Region_Name END AS Region_Name,
    CASE r.Region_Level WHEN N'Area'   THEN r.Sales_Region_Name
                        WHEN N'Team'   THEN p.Sales_Region_Name END  AS Area_Name,
    CASE r.Region_Level WHEN N'Team'   THEN r.Sales_Region_Name END  AS Team_Name,
    r.Region_Status
FROM ref.SalesRegion AS r
LEFT JOIN ref.SalesRegion AS p  ON p.Sales_Region_ID  = r.Parent_Sales_Region_ID
LEFT JOIN ref.SalesRegion AS gp ON gp.Sales_Region_ID = p.Parent_Sales_Region_ID
UNION ALL
SELECT -1, N'N/A', N'نامشخص', N'Unknown', N'نامشخص', N'نامشخص', N'نامشخص', N'Unknown';
GO

/*-----------------------------------------------------------------------------
 Dim_SalesChannel - one row per sales channel. Unknown -1.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Dim_SalesChannel
AS
SELECT
    ch.Sales_Channel_ID                                        AS SalesChannel_Key,
    ch.Sales_Channel_Code,
    ch.Sales_Channel_Name,
    ch.Sales_Channel_Type,
    ch.Channel_Status
FROM ref.SalesChannel AS ch
UNION ALL
SELECT -1, N'N/A', N'نامشخص', N'Unknown', N'Unknown';
GO

/*-----------------------------------------------------------------------------
 Dim_Salesperson - one row per salesperson. Organisation = region of the branch. Unknown -1.
 No e-mail / phone.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Dim_Salesperson
AS
SELECT
    sp.Salesperson_ID                                          AS Salesperson_Key,
    sp.Salesperson_Code,
    sp.Salesperson_Name,
    sp.Role,
    sp.Employment_Status,
    sp.Hire_Date,
    m.Salesperson_Name                                         AS Manager_Name,
    b.Branch_Code,
    b.Branch_Name,
    b.Branch_Status,
    ISNULL(sr.Team_Name,   sr.Sales_Region_Name)               AS Org_Team_Name,
    sr.Area_Name                                               AS Org_Area_Name,
    sr.Region_Name                                             AS Org_Region_Name
FROM core.Salesperson AS sp
LEFT JOIN core.Salesperson     AS m  ON m.Salesperson_ID   = sp.Manager_Salesperson_ID
LEFT JOIN core.Branch          AS b  ON b.Branch_ID        = sp.Branch_ID
LEFT JOIN rpt.Dim_SalesRegion  AS sr ON sr.SalesRegion_Key = b.Sales_Region_ID
UNION ALL
SELECT -1, N'N/A', N'نامشخص', N'Unknown', N'Unknown', NULL, NULL, N'N/A', N'نامشخص', N'Unknown', N'نامشخص', N'نامشخص', N'نامشخص';
GO

/*-----------------------------------------------------------------------------
 Dim_Customer - one row per customer, SCD1. Unknown -1.
 City_Level = 'District' -> the parent row is the city. No phone, e-mail, address, contact person.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Dim_Customer
AS
SELECT
    cu.Customer_ID                                             AS Customer_Key,
    cu.Customer_Code,
    cu.Customer_Name,
    cu.Customer_Type,
    cu.Customer_Status,
    cu.Business_Type,
    cu.Industry,
    cu.Customer_Size,
    cu.Credit_Status,
    cu.Registration_Date,
    COALESCE(pc.City_Name, ci.City_Name)                       AS City_Name,
    CASE WHEN ci.City_Level = N'District' THEN ci.City_Name END AS District_Name,
    pv.Province_Name,
    sg.Segment_Name                                            AS Customer_Segment_Name,
    ch.Sales_Channel_Name,
    te.Territory_Name,
    sp.Salesperson_Name                                        AS Account_Salesperson_Name
FROM core.Customer AS cu
LEFT JOIN ref.City             AS ci ON ci.City_ID              = cu.City_ID
LEFT JOIN ref.City             AS pc ON pc.City_ID              = ci.Parent_City_ID
LEFT JOIN ref.Province         AS pv ON pv.Province_ID          = ci.Province_ID
LEFT JOIN ref.CustomerSegment  AS sg ON sg.Customer_Segment_ID  = cu.Customer_Segment_ID
LEFT JOIN ref.SalesChannel     AS ch ON ch.Sales_Channel_ID     = cu.Sales_Channel_ID
LEFT JOIN ref.SalesTerritory   AS te ON te.Sales_Territory_ID   = cu.Sales_Territory_ID
LEFT JOIN core.Salesperson     AS sp ON sp.Salesperson_ID       = cu.Salesperson_ID
UNION ALL
SELECT -1, N'N/A', N'نامشخص', N'Unknown', N'Unknown', NULL, NULL, NULL, NULL, NULL,
       N'نامشخص', NULL, N'نامشخص', N'نامشخص', N'نامشخص', N'نامشخص', N'نامشخص';
GO

/*-----------------------------------------------------------------------------
 Dim_Brand - one row per brand.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Dim_Brand
AS
SELECT
    br.Brand_ID                                                AS Brand_Key,
    br.Brand_Code,
    br.Brand_Name,
    br.Brand_Type,
    br.Brand_Status,
    br.Brand_Owner,
    br.Brand_Positioning,
    br.Target_Market,
    br.Target_Segment,
    br.Brand_Country,
    br.Brand_Start_Date,
    br.Brand_End_Date
FROM core.Brand AS br;
GO

/*-----------------------------------------------------------------------------
 Dim_Product - one row per product; category up to 3 levels. Unknown -1.
 Sales are analysed at product level (order/invoice lines have no SKU).
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Dim_Product
AS
SELECT
    p.Product_ID                                               AS Product_Key,
    p.Product_Code,
    p.Product_Name,
    p.Product_Type,
    p.Unit_Of_Measure,
    p.Product_Status,
    p.Launch_Date,
    p.Tax_Rate,
    p.Brand_ID                                                 AS Brand_Key,
    br.Brand_Name,
    br.Brand_Type,
    CASE c.Category_Level WHEN 1 THEN c.Category_Name WHEN 2 THEN c1.Category_Name WHEN 3 THEN c2.Category_Name END AS Category_Level1,
    CASE c.Category_Level WHEN 2 THEN c.Category_Name WHEN 3 THEN c1.Category_Name END                             AS Category_Level2,
    CASE c.Category_Level WHEN 3 THEN c.Category_Name END                                                         AS Category_Level3,
    c.Category_Name                                            AS Category_Name
FROM core.Product AS p
JOIN      ref.ProductCategory AS c  ON c.Product_Category_ID  = p.Product_Category_ID
LEFT JOIN ref.ProductCategory AS c1 ON c1.Product_Category_ID = c.Parent_Category_ID
LEFT JOIN ref.ProductCategory AS c2 ON c2.Product_Category_ID = c1.Parent_Category_ID
LEFT JOIN core.Brand          AS br ON br.Brand_ID            = p.Brand_ID
UNION ALL
SELECT -1, N'N/A', N'نامشخص', N'Unknown', N'Unknown', N'Unknown', NULL, NULL, NULL,
       N'نامشخص', N'Unknown', N'نامشخص', NULL, NULL, N'نامشخص';
GO

/*-----------------------------------------------------------------------------
 Dim_SKU - one row per SKU. Used only for prices (Fact_ProductPrice).
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Dim_SKU
AS
SELECT
    s.SKU_ID                                                   AS SKU_Key,
    s.SKU_Code,
    s.SKU_Name,
    s.Product_ID                                               AS Product_Key,
    pk.Package_Code,
    pk.Package_Name,
    s.Barcode,
    s.Weight,
    s.Standard_Cost,
    s.Currency,
    s.SKU_Status
FROM core.SKU AS s
LEFT JOIN ref.Package AS pk ON pk.Package_ID = s.Package_ID;
GO

/*-----------------------------------------------------------------------------
 Dim_Campaign - one row per marketing campaign.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Dim_Campaign
AS
SELECT
    mc.Marketing_Campaign_ID                                   AS Campaign_Key,
    mc.Campaign_Name,
    mc.Campaign_Type,
    mc.Campaign_Purpose,
    mc.Campaign_Objective,
    mc.Start_Date,
    mc.End_Date,
    mc.Campaign_Status,
    ISNULL(mc.Brand_ID, -1)                                    AS Brand_Key,
    ISNULL(br.Brand_Name, N'نامشخص')                           AS Brand_Name
FROM marketing.MarketingCampaign AS mc
LEFT JOIN core.Brand AS br ON br.Brand_ID = mc.Brand_ID;
GO

/*-----------------------------------------------------------------------------
 Dim_CampaignChannel - one row per marketing channel (not a sales channel). Unknown -1.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Dim_CampaignChannel
AS
SELECT
    cc.Campaign_Channel_ID                                     AS CampaignChannel_Key,
    cc.Channel_Name                                            AS Campaign_Channel_Name,
    cc.Channel_Type                                            AS Campaign_Channel_Type,
    cc.Channel_Status                                          AS Campaign_Channel_Status
FROM marketing.CampaignChannel AS cc
UNION ALL
SELECT -1, N'نامشخص', N'Unknown', N'Unknown';
GO

/*-----------------------------------------------------------------------------
 Dim_CampaignAudience - one row per audience; linked to campaigns through Bridge_CampaignAudience.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Dim_CampaignAudience
AS
SELECT
    ca.Campaign_Audience_ID                                    AS CampaignAudience_Key,
    ca.Audience_Name,
    ca.Audience_Type,
    ca.Audience_Status,
    ca.Age_Range,
    ca.Gender,
    ca.Geographic_Location
FROM marketing.CampaignAudience AS ca;
GO

/*-----------------------------------------------------------------------------
 Dim_Promotion - one row per promotion. -1 = order without promotion (Team 1 depends on it).
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Dim_Promotion
AS
SELECT
    pr.Promotion_ID                                            AS Promotion_Key,
    pr.Promotion_Code,
    pr.Promotion_Name,
    pr.Promotion_Type,
    pr.Discount_Type,
    pr.Discount_Value,
    pr.Start_Date,
    pr.End_Date,
    pr.Promotion_Status,
    ISNULL(pr.Marketing_Campaign_ID, -1)                       AS Campaign_Key,
    mc.Campaign_Name,
    br.Brand_Name,
    CAST(1 AS bit)                                             AS Has_Promotion
FROM marketing.Promotion AS pr
LEFT JOIN marketing.MarketingCampaign AS mc ON mc.Marketing_Campaign_ID = pr.Marketing_Campaign_ID
LEFT JOIN core.Brand                  AS br ON br.Brand_ID              = mc.Brand_ID
UNION ALL
SELECT -1, N'N/A', N'بدون پروموشن', N'None', N'None', NULL, NULL, NULL, N'None', -1, N'بدون کمپین', N'نامشخص', CAST(0 AS bit);
GO

/*-----------------------------------------------------------------------------
 Dim_Market - one row per market.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Dim_Market
AS
SELECT
    mk.Market_ID                                               AS Market_Key,
    mk.Market_Code,
    mk.Market_Name,
    mk.Market_Type,
    mk.Market_Status
FROM marketing.Market AS mk;
GO

/*-----------------------------------------------------------------------------
 Dim_MarketSegment - one row per market segment. Unknown -1 (survey without segment).
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Dim_MarketSegment
AS
SELECT
    ms.Market_Segment_ID                                       AS MarketSegment_Key,
    ms.Segment_Code                                            AS Market_Segment_Code,
    ms.Segment_Name                                            AS Market_Segment_Name,
    ms.Segmentation_Basis,
    ms.Segment_Status                                          AS Market_Segment_Status,
    ms.Market_ID                                               AS Market_Key,
    mk.Market_Name
FROM marketing.MarketSegment AS ms
JOIN marketing.Market AS mk ON mk.Market_ID = ms.Market_ID
UNION ALL
SELECT -1, N'N/A', N'نامشخص', N'Unknown', N'Unknown', -1, N'نامشخص';
GO

/*-----------------------------------------------------------------------------
 Dim_Competitor - one row per competitor.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Dim_Competitor
AS
SELECT
    co.Competitor_ID                                           AS Competitor_Key,
    co.Competitor_Name,
    co.Competitor_Type,
    co.Competitor_Status,
    ISNULL(co.Market_ID, -1)                                   AS Market_Key,
    ISNULL(mk.Market_Name, N'نامشخص')                          AS Market_Name
FROM marketing.Competitor AS co
LEFT JOIN marketing.Market AS mk ON mk.Market_ID = co.Market_ID;
GO

/*-----------------------------------------------------------------------------
 Dim_CompetitorProduct - one row per competitor product. -1 = our own product (price rows of our products).
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Dim_CompetitorProduct
AS
SELECT
    cp.Competitor_Product_ID                                   AS CompetitorProduct_Key,
    cp.Competitor_Product_Name,
    cp.Category                                                AS Competitor_Product_Category,
    cp.Competitor_ID                                           AS Competitor_Key,
    co.Competitor_Name,
    co.Competitor_Type,
    CAST(0 AS bit)                                             AS Is_Own_Product
FROM marketing.CompetitorProduct AS cp
JOIN marketing.Competitor AS co ON co.Competitor_ID = cp.Competitor_ID
UNION ALL
SELECT -1, N'محصول خودمان', NULL, -1, N'خودمان', N'Own', CAST(1 AS bit);
GO

/*=============================================================================
 PART B - FACTS (21)
=============================================================================*/

/*-----------------------------------------------------------------------------
 Fact_SalesOrderLine - Grain: one row = one sales order line (SalesOrderItem).
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_SalesOrderLine
AS
SELECT
    soi.Sales_Order_Item_ID,
    so.Sales_Order_ID,
    so.Sales_Order_Number,
    soi.Line_Number,
    cal.DateKey                                                AS OrderDateKey,
    dd.DateKey                                                 AS DeliveryDateKey,
    so.Customer_ID                                             AS Customer_Key,
    soi.Product_ID                                             AS Product_Key,
    ISNULL(so.Salesperson_ID, -1)                              AS Salesperson_Key,
    ISNULL(so.Sales_Channel_ID, -1)                            AS SalesChannel_Key,
    ISNULL(so.Sales_Region_ID, -1)                             AS SalesRegion_Key,
    ISNULL(so.Promotion_ID, -1)                                AS Promotion_Key,
    so.Order_Status,
    soi.Item_Status,
    soi.Quantity,
    soi.Unit_Price,
    soi.Quantity * soi.Unit_Price                              AS Gross_Amount,
    ISNULL(soi.Discount_Amount, 0)                             AS Discount_Amount,
    soi.Net_Amount
FROM sales.SalesOrderItem AS soi
JOIN sales.SalesOrder     AS so  ON so.Sales_Order_ID = soi.Sales_Order_ID
JOIN core.Calendar        AS cal ON cal.Calendar_ID   = so.Calendar_ID
LEFT JOIN core.Calendar   AS dd  ON dd.Calendar_Date  = so.Delivery_Date;
GO

/*-----------------------------------------------------------------------------
 Fact_Invoice - Grain: one row = one invoice (header). Use for sales amount and target comparison.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_Invoice
AS
SELECT
    i.Invoice_ID,
    i.Sales_Order_ID,
    i.Invoice_Number,
    di.DateKey                                                 AS InvoiceDateKey,
    du.DateKey                                                 AS DueDateKey,
    i.Invoice_Date,
    i.Due_Date,
    i.Customer_ID                                              AS Customer_Key,
    ISNULL(so.Salesperson_ID, -1)                              AS Salesperson_Key,
    ISNULL(so.Sales_Channel_ID, -1)                            AS SalesChannel_Key,
    ISNULL(so.Sales_Region_ID, -1)                             AS SalesRegion_Key,
    ISNULL(so.Promotion_ID, -1)                                AS Promotion_Key,
    i.Invoice_Type,
    i.Invoice_Status,
    i.Subtotal,
    ISNULL(i.Discount_Amount, 0)                               AS Discount_Amount,
    ISNULL(i.Tax_Amount, 0)                                    AS Tax_Amount,
    i.Total_Amount,
    ISNULL(pa.Paid_Amount, 0)                                  AS Paid_Amount,
    i.Total_Amount - ISNULL(pa.Paid_Amount, 0)                 AS Outstanding_Amount
FROM sales.Invoice      AS i
JOIN sales.SalesOrder   AS so ON so.Sales_Order_ID = i.Sales_Order_ID
OUTER APPLY (SELECT SUM(p.Amount) AS Paid_Amount
             FROM sales.Payment AS p
             WHERE p.Invoice_ID = i.Invoice_ID AND p.Payment_Status = N'Successful') AS pa
LEFT JOIN core.Calendar AS di ON di.Calendar_Date  = i.Invoice_Date
LEFT JOIN core.Calendar AS du ON du.Calendar_Date  = i.Due_Date;
GO

/*-----------------------------------------------------------------------------
 Fact_InvoiceLine - Grain: one row = one invoice line (InvoiceItem). Use for product analysis.
 Never add it to Fact_Invoice in one visual (double counting).
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_InvoiceLine
AS
SELECT
    ii.Invoice_Item_ID,
    i.Invoice_ID,
    i.Invoice_Number,
    di.DateKey                                                 AS InvoiceDateKey,
    i.Customer_ID                                              AS Customer_Key,
    ii.Product_ID                                              AS Product_Key,
    ISNULL(so.Salesperson_ID, -1)                              AS Salesperson_Key,
    ISNULL(so.Sales_Channel_ID, -1)                            AS SalesChannel_Key,
    ISNULL(so.Sales_Region_ID, -1)                             AS SalesRegion_Key,
    ISNULL(so.Promotion_ID, -1)                                AS Promotion_Key,
    i.Invoice_Status,
    ii.Quantity,
    ii.Unit_Price,
    ISNULL(ii.Discount_Amount, 0)                              AS Discount_Amount,
    ii.Net_Amount,
    ISNULL(ii.Tax_Amount, 0)                                   AS Tax_Amount,
    ii.Final_Amount
FROM sales.InvoiceItem  AS ii
JOIN sales.Invoice      AS i  ON i.Invoice_ID      = ii.Invoice_ID
JOIN sales.SalesOrder   AS so ON so.Sales_Order_ID = i.Sales_Order_ID
LEFT JOIN core.Calendar AS di ON di.Calendar_Date  = i.Invoice_Date;
GO

/*-----------------------------------------------------------------------------
 Fact_Payment - Grain: one row = one payment (successful or failed).
 Order is taken from the payment or, if empty, from its invoice.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_Payment
AS
SELECT
    p.Payment_ID,
    p.Invoice_ID,
    COALESCE(p.Sales_Order_ID, i.Sales_Order_ID)               AS Sales_Order_ID,
    dp.DateKey                                                 AS PaymentDateKey,
    p.Payment_Date,
    p.Customer_ID                                              AS Customer_Key,
    ISNULL(so.Salesperson_ID, -1)                              AS Salesperson_Key,
    ISNULL(so.Sales_Channel_ID, -1)                            AS SalesChannel_Key,
    ISNULL(so.Sales_Region_ID, -1)                             AS SalesRegion_Key,
    p.Payment_Method,
    p.Payment_Status,
    p.Amount
FROM sales.Payment           AS p
LEFT JOIN sales.Invoice      AS i  ON i.Invoice_ID      = p.Invoice_ID
LEFT JOIN sales.SalesOrder   AS so ON so.Sales_Order_ID = COALESCE(p.Sales_Order_ID, i.Sales_Order_ID)
LEFT JOIN core.Calendar      AS dp ON dp.Calendar_Date  = p.Payment_Date;
GO

/*-----------------------------------------------------------------------------
 Fact_Return - Grain: one row = one return request. Customer/salesperson through order line -> order.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_Return
AS
SELECT
    rr.Return_Request_ID,
    so.Sales_Order_ID,
    soi.Sales_Order_Item_ID,
    rr.Payment_ID,
    cal.DateKey                                                AS ReturnDateKey,
    drf.DateKey                                                AS RefundDateKey,
    so.Customer_ID                                             AS Customer_Key,
    soi.Product_ID                                             AS Product_Key,
    ISNULL(so.Salesperson_ID, -1)                              AS Salesperson_Key,
    ISNULL(so.Sales_Channel_ID, -1)                            AS SalesChannel_Key,
    ISNULL(so.Sales_Region_ID, -1)                             AS SalesRegion_Key,
    rr.Return_Reason,
    rr.Return_Status,
    rr.Refund_Status,
    rr.Refund_Method,
    rr.Requested_Quantity,
    ISNULL(rr.Approved_Quantity, 0)                            AS Approved_Quantity,
    ISNULL(rr.Return_Shipping_Cost, 0)                         AS Return_Shipping_Cost,
    ISNULL(rr.Refund_Amount, 0)                                AS Refund_Amount
FROM sales.ReturnRequest  AS rr
JOIN sales.SalesOrderItem AS soi ON soi.Sales_Order_Item_ID = rr.Sales_Order_Item_ID
JOIN sales.SalesOrder     AS so  ON so.Sales_Order_ID       = soi.Sales_Order_ID
JOIN core.Calendar        AS cal ON cal.Calendar_ID         = rr.Calendar_ID
LEFT JOIN core.Calendar   AS drf ON drf.Calendar_Date       = rr.Refund_Date;
GO

/*-----------------------------------------------------------------------------
 Fact_SalesTarget - Grain: one row = one target period (last day of a Persian month or year) x Target_Level.
 ALWAYS filter on ONE Target_Level (Annual / Region / Team / Salesperson / Channel); levels repeat the total.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_SalesTarget
AS
SELECT
    st.Sales_Target_ID,
    cal.DateKey                                                AS PeriodEndDateKey,
    st.Target_Level,
    st.Fiscal_Year,
    st.Plan_Title,
    st.Target_Version,
    st.Target_Status,
    ISNULL(st.Sales_Region_ID, -1)                             AS SalesRegion_Key,
    ISNULL(st.Salesperson_ID, -1)                              AS Salesperson_Key,
    ISNULL(st.Sales_Channel_ID, -1)                            AS SalesChannel_Key,
    ISNULL(st.Product_ID, -1)                                  AS Product_Key,
    ISNULL(st.Target_Value, 0)                                 AS Target_Value,
    ISNULL(st.Target_Quantity, 0)                              AS Target_Quantity
FROM sales.SalesTarget AS st
JOIN core.Calendar     AS cal ON cal.Calendar_ID = st.Calendar_ID;
GO

/*-----------------------------------------------------------------------------
 Fact_SalesForecast - Grain: one row = one period x forecast version. Filter one version.
 Forecast_Accuracy_Percent is NOT additive (average only).
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_SalesForecast
AS
SELECT
    f.Sales_Forecast_ID,
    cal.DateKey                                                AS PeriodEndDateKey,
    f.Forecast_Version,
    f.Forecast_Amount,
    f.Forecast_Accuracy_Percent
FROM sales.SalesForecast AS f
JOIN core.Calendar       AS cal ON cal.Calendar_ID = f.Calendar_ID;
GO

/*-----------------------------------------------------------------------------
 Fact_Commission - Grain: one row = one salesperson x period. Commission_Rate is NOT additive.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_Commission
AS
SELECT
    cm.Commission_ID,
    cal.DateKey                                                AS PeriodEndDateKey,
    cm.Salesperson_ID                                          AS Salesperson_Key,
    cm.Commission_Base_Amount,
    cm.Commission_Rate,
    cm.Commission_Amount
FROM sales.Commission AS cm
JOIN core.Calendar    AS cal ON cal.Calendar_ID = cm.Calendar_ID;
GO

/*-----------------------------------------------------------------------------
 Fact_Lead - Grain: one row = one lead. Lead name is not exposed.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_Lead
AS
SELECT
    l.Lead_ID,
    l.Lead_Code,
    dc.DateKey                                                 AS CreatedDateKey,
    dv.DateKey                                                 AS ConversionDateKey,
    ISNULL(l.Salesperson_ID, -1)                               AS Salesperson_Key,
    l.Lead_Source,
    l.Lead_Status,
    CAST(CASE WHEN l.Lead_Status = N'Converted' THEN 1 ELSE 0 END AS int) AS Is_Converted,
    l.Lead_Score,
    ISNULL(l.Expected_Value, 0)                                AS Expected_Value
FROM sales.Lead         AS l
LEFT JOIN core.Calendar AS dc ON dc.Calendar_Date = l.Created_Date
LEFT JOIN core.Calendar AS dv ON dv.Calendar_Date = l.Conversion_Date;
GO

/*-----------------------------------------------------------------------------
 Fact_Opportunity - Grain: one row = one sales opportunity. Probability is NOT additive.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_Opportunity
AS
SELECT
    o.Sales_Opportunity_ID,
    o.Opportunity_Code,
    o.Lead_ID,
    dO.DateKey                                                 AS OpportunityDateKey,
    dE.DateKey                                                 AS ExpectedCloseDateKey,
    dP.DateKey                                                 AS ProposalDateKey,
    o.Opportunity_Date,
    o.Expected_Close_Date,
    ISNULL(o.Customer_ID, -1)                                  AS Customer_Key,
    o.Salesperson_ID                                           AS Salesperson_Key,
    o.Opportunity_Stage,
    o.Opportunity_Status,
    o.Opportunity_Type,
    o.Opportunity_Source,
    o.Proposal_Status,
    CAST(CASE WHEN o.Opportunity_Status = N'Won' THEN 1 ELSE 0 END AS int) AS Is_Won,
    CAST(CASE WHEN o.Opportunity_Status IN (N'Won', N'Lost') THEN 1 ELSE 0 END AS int) AS Is_Closed,
    ISNULL(o.Expected_Value, 0)                                AS Expected_Value,
    o.Probability,
    o.Proposed_Price,
    ISNULL(o.Proposal_Discount_Amount, 0)                      AS Proposal_Discount_Amount
FROM sales.SalesOpportunity AS o
LEFT JOIN core.Calendar     AS dO ON dO.Calendar_Date = o.Opportunity_Date
LEFT JOIN core.Calendar     AS dE ON dE.Calendar_Date = o.Expected_Close_Date
LEFT JOIN core.Calendar     AS dP ON dP.Calendar_Date = o.Proposal_Date;
GO

/*-----------------------------------------------------------------------------
 Fact_Contract - Grain: one row = one contract.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_Contract
AS
SELECT
    ct.Contract_ID,
    ct.Contract_Number,
    ct.Sales_Opportunity_ID,
    dS.DateKey                                                 AS StartDateKey,
    dE.DateKey                                                 AS EndDateKey,
    dC.DateKey                                                 AS ClosedDateKey,
    ct.Start_Date,
    ct.End_Date,
    ct.Customer_ID                                             AS Customer_Key,
    ISNULL(ct.Product_ID, -1)                                  AS Product_Key,
    ct.Contract_Type,
    ct.Contract_Status,
    ct.Payment_Terms,
    ct.Contract_Amount,
    ISNULL(ct.Item_Quantity, 0)                                AS Item_Quantity,
    ct.Item_Unit_Price,
    DATEDIFF(DAY, so.Opportunity_Date, ct.Start_Date)          AS Days_Opportunity_To_Contract
FROM sales.Contract     AS ct
LEFT JOIN sales.SalesOpportunity AS so ON so.Sales_Opportunity_ID = ct.Sales_Opportunity_ID
LEFT JOIN core.Calendar AS dS ON dS.Calendar_Date = ct.Start_Date
LEFT JOIN core.Calendar AS dE ON dE.Calendar_Date = ct.End_Date
LEFT JOIN core.Calendar AS dC ON dC.Calendar_Date = ct.Closed_Date;
GO

/*-----------------------------------------------------------------------------
 Fact_CustomerInteraction - Grain: one row = one customer interaction. Notes are not exposed.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_CustomerInteraction
AS
SELECT
    ci.Customer_Interaction_ID,
    dI.DateKey                                                 AS InteractionDateKey,
    dF.DateKey                                                 AS FollowUpDateKey,
    ci.Customer_ID                                             AS Customer_Key,
    ISNULL(ci.Salesperson_ID, -1)                              AS Salesperson_Key,
    ci.Interaction_Type,
    ci.Interaction_Channel,
    ci.Interaction_Purpose,
    ci.Interaction_Status,
    ci.Interaction_Result,
    CAST(ISNULL(ci.Follow_Up_Required, 0) AS int)              AS Follow_Up_Required,
    ISNULL(ci.Interaction_Duration_Minutes, 0)                 AS Interaction_Duration_Minutes,
    ISNULL(ci.Participants_Count, 0)                           AS Participants_Count
FROM sales.CustomerInteraction AS ci
LEFT JOIN core.Calendar        AS dI ON dI.Calendar_Date = CAST(ci.Interaction_DateTime AS date)
LEFT JOIN core.Calendar        AS dF ON dF.Calendar_Date = ci.Follow_Up_Date;
GO

/*-----------------------------------------------------------------------------
 Fact_CustomerFeedback - Grain: one row = one feedback. Rating is NOT additive (average).
 Free text (Feedback_Text, Moderation_Comment) is not exposed.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_CustomerFeedback
AS
SELECT
    fb.Customer_Feedback_ID,
    fb.Sales_Order_ID,
    dF.DateKey                                                 AS FeedbackDateKey,
    dR.DateKey                                                 AS ResolutionDateKey,
    fb.Customer_ID                                             AS Customer_Key,
    ISNULL(fb.Product_ID, -1)                                  AS Product_Key,
    fb.Feedback_Type,
    fb.Feedback_Channel,
    fb.Feedback_Category,
    fb.Priority,
    fb.Feedback_Status,
    fb.SLA_Status,
    fb.Rating,
    DATEDIFF(DAY, fb.Feedback_Date, fb.Resolution_Date)        AS Resolution_Days
FROM sales.CustomerFeedback AS fb
LEFT JOIN core.Calendar     AS dF ON dF.Calendar_Date = fb.Feedback_Date
LEFT JOIN core.Calendar     AS dR ON dR.Calendar_Date = fb.Resolution_Date;
GO

/*-----------------------------------------------------------------------------
 Fact_CampaignBudget - Grain: one row = one campaign x marketing channel budget.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_CampaignBudget
AS
SELECT
    cb.Campaign_Budget_ID,
    dA.DateKey                                                 AS ApprovalDateKey,
    cb.Marketing_Campaign_ID                                   AS Campaign_Key,
    ISNULL(cb.Campaign_Channel_ID, -1)                         AS CampaignChannel_Key,
    cb.Currency,
    cb.Total_Allocated_Amount
FROM marketing.CampaignBudget AS cb
LEFT JOIN core.Calendar       AS dA ON dA.Calendar_Date = cb.Approval_Date;
GO

/*-----------------------------------------------------------------------------
 Fact_CampaignCost - Grain: one row = one recorded campaign cost.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_CampaignCost
AS
SELECT
    cc.Campaign_Cost_ID,
    dC.DateKey                                                 AS CostDateKey,
    cc.Marketing_Campaign_ID                                   AS Campaign_Key,
    ISNULL(cc.Campaign_Channel_ID, -1)                         AS CampaignChannel_Key,
    cc.Currency,
    cc.Actual_Spent
FROM marketing.CampaignCost AS cc
LEFT JOIN core.Calendar     AS dC ON dC.Calendar_Date = cc.Cost_Date;
GO

/*-----------------------------------------------------------------------------
 Fact_CampaignResult - Grain: one row = one measured metric of a campaign.
 Never sum Metric_Value across different Metric_Name values.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_CampaignResult
AS
SELECT
    cr.Campaign_Result_ID,
    dM.DateKey                                                 AS MeasurementDateKey,
    cr.Marketing_Campaign_ID                                   AS Campaign_Key,
    cr.Metric_Name,
    cr.Metric_Value
FROM marketing.CampaignResult AS cr
LEFT JOIN core.Calendar       AS dM ON dM.Calendar_Date = cr.Measurement_Date;
GO

/*-----------------------------------------------------------------------------
 Fact_BrandActivity - Grain: one row = one brand activity.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_BrandActivity
AS
SELECT
    ba.Brand_Activity_ID,
    dS.DateKey                                                 AS StartDateKey,
    dE.DateKey                                                 AS EndDateKey,
    ba.Brand_ID                                                AS Brand_Key,
    ba.Activity_Type,
    ba.Activity_Channel,
    ba.Activity_Status,
    ba.Currency,
    ISNULL(ba.Activity_Cost, 0)                                AS Activity_Cost
FROM marketing.BrandActivity AS ba
LEFT JOIN core.Calendar      AS dS ON dS.Calendar_Date = ba.Activity_Start_Date
LEFT JOIN core.Calendar      AS dE ON dE.Calendar_Date = ba.Activity_End_Date;
GO

/*-----------------------------------------------------------------------------
 Fact_ProductPrice - Grain: one row = one price version of one SKU. Unit_Price is NOT additive.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_ProductPrice
AS
SELECT
    pp.Product_Price_ID,
    dF.DateKey                                                 AS EffectiveFromDateKey,
    dT.DateKey                                                 AS EffectiveToDateKey,
    pp.Effective_From,
    pp.Effective_To,
    pp.SKU_ID                                                  AS SKU_Key,
    s.Product_ID                                               AS Product_Key,
    pp.Price_Type,
    pp.Price_Status,
    pp.Currency,
    pp.Unit_Price
FROM marketing.ProductPrice AS pp
JOIN core.SKU               AS s  ON s.SKU_ID         = pp.SKU_ID
LEFT JOIN core.Calendar     AS dF ON dF.Calendar_Date = pp.Effective_From
LEFT JOIN core.Calendar     AS dT ON dT.Calendar_Date = pp.Effective_To;
GO

/*-----------------------------------------------------------------------------
 Fact_MarketPrice - Grain: one row = one observed market price (ours: CompetitorProduct_Key = -1).
 Price_Value is NOT additive.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_MarketPrice
AS
SELECT
    mp.Market_Price_ID,
    dP.DateKey                                                 AS PriceDateKey,
    ISNULL(mp.Product_ID, -1)                                  AS Product_Key,
    ISNULL(mp.Competitor_Product_ID, -1)                       AS CompetitorProduct_Key,
    mp.Market_ID                                               AS Market_Key,
    CAST(CASE WHEN mp.Competitor_Product_ID IS NULL THEN 1 ELSE 0 END AS bit) AS Is_Own_Product,
    mp.Price_Source,
    mp.Currency,
    mp.Price_Value
FROM marketing.MarketPrice AS mp
LEFT JOIN core.Calendar    AS dP ON dP.Calendar_Date = CAST(mp.Price_Date AS date);
GO

/*-----------------------------------------------------------------------------
 Fact_MarketResearch - Grain: one row = one research project. Responsible person is not exposed.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_MarketResearch
AS
SELECT
    mr.Market_Research_ID,
    mr.Research_Title,
    dS.DateKey                                                 AS StartDateKey,
    dE.DateKey                                                 AS EndDateKey,
    mr.Market_ID                                               AS Market_Key,
    mr.Research_Type,
    mr.Research_Status,
    mr.Currency,
    ISNULL(mr.Research_Cost, 0)                                AS Research_Cost
FROM marketing.MarketResearch AS mr
LEFT JOIN core.Calendar       AS dS ON dS.Calendar_Date = mr.Start_Date
LEFT JOIN core.Calendar       AS dE ON dE.Calendar_Date = mr.End_Date;
GO

/*-----------------------------------------------------------------------------
 Fact_MarketSurvey - Grain: one row = one survey. Market comes from its research project.
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Fact_MarketSurvey
AS
SELECT
    sv.Market_Survey_ID,
    sv.Market_Research_ID,
    sv.Survey_Title,
    dS.DateKey                                                 AS SurveyDateKey,
    mr.Market_ID                                               AS Market_Key,
    ISNULL(sv.Market_Segment_ID, -1)                           AS MarketSegment_Key,
    sv.Survey_Method,
    sv.Survey_Status,
    sv.Sample_Size
FROM marketing.MarketSurvey   AS sv
JOIN marketing.MarketResearch AS mr ON mr.Market_Research_ID = sv.Market_Research_ID
LEFT JOIN core.Calendar       AS dS ON dS.Calendar_Date      = sv.Survey_Date;
GO

/*=============================================================================
 PART C - BRIDGE (1)
=============================================================================*/
/*-----------------------------------------------------------------------------
 Bridge_CampaignAudience - Grain: one row = one campaign x audience (many-to-many).
-----------------------------------------------------------------------------*/
CREATE OR ALTER VIEW rpt.Bridge_CampaignAudience
AS
SELECT
    mca.Marketing_Campaign_ID                                  AS Campaign_Key,
    mca.Campaign_Audience_ID                                   AS CampaignAudience_Key
FROM marketing.MarketingCampaignAudience AS mca;
GO

SELECT N'rpt views created' AS Info, COUNT(*) AS View_Count
FROM sys.views WHERE schema_id = SCHEMA_ID(N'rpt');
GO

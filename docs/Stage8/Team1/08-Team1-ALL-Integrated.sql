/*=============================================================================
 Project   : Food Distribution (FoodDistributionDB)  -  Stage 8 Mock Data
 Team      : Team 1 - Sales & Customer
 File      : 08-03-T1-ALL-Integrated.sql
 Version   : MockData_v1.1_Integrated (data version tag: MockData_v1.0_Seed20261031)
 Purpose   : ONE file that runs every Team 1 Stage 8 generator in dependency order:
               8.1 Reference + Calendar/Org -> 8.2 Customer/Lead -> 8.3 Funnel
               -> 8.4 Orders -> 8.5 Invoices -> 8.6 Payment/Return/Feedback
               -> 8.7 SalesTarget/SalesForecast/Commission
 Run order : Team 2 08-04-Load-Data.sql FIRST (Product, SKU, ProductPrice,
             Promotion on a clean DB), then this file, in ONE SSMS session
             (the settings live in the temp table #T1Cfg, which exists only
             in this session - do not split the file across sessions).
 Settings  : edit ONLY section 0 below (Seed / Scale / dates / approval gate).
 Policy    : no schema change, no IDENTITY_INSERT, no NEWID/RAND/GETDATE,
             no constraint/trigger disabled, no hard-coded parent IDs, set-based.
             Each section = its own transaction. If one section fails, it is
             rolled back, #T1Cfg.Abort is set and ALL later sections are skipped.
             Re-run: stops if any Team 1 table already has rows (clean with the
             lead's Reset script only - nothing is deleted by this file).
 Status    : NOT executed against SQL Server in the preparation environment.
=============================================================================*/
USE [FoodDistributionDB];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
/* ===================== SECTION 0 : settings and global guards ============== */
DROP TABLE IF EXISTS #T1Cfg, #T1Log, #T1NoOrder;
CREATE TABLE #T1Cfg
(
    DataVersion nvarchar(50) NOT NULL,
    Seed        int          NOT NULL,
    Scale       decimal(5,2) NOT NULL,   -- 0.10 = pilot (10%), 1.00 = full run
    FromDate    date         NOT NULL,   -- 1398/01/01
    ToDate      date         NOT NULL,   -- 1405/12/29
    AsOfDate    date         NOT NULL,   -- status reference date
    AllowProvisionalAssumptions bit NOT NULL,  -- 8.7 approval gate (D-01/D-02/D-07/OI-17..20)
    Abort       bit          NOT NULL
);
INSERT INTO #T1Cfg VALUES (N'MockData_v1.0_Seed20261031', 20261031, 0.10,
                           '2019-03-21', '2027-03-20', '2027-03-20', 1, 0);
CREATE TABLE #T1Log (Step nvarchar(10) NOT NULL, Table_Name sysname NOT NULL, Rows_Inserted int NOT NULL);
CREATE TABLE #T1NoOrder (Customer_ID int NOT NULL PRIMARY KEY);   -- filled by 8.2, read by 8.4
GO
BEGIN TRY
    IF DB_NAME() <> N'FoodDistributionDB' THROW 54000, 'Wrong database context.', 1;
    IF EXISTS (SELECT 1 FROM #T1Cfg WHERE Scale <= 0 OR Scale > 1)
        THROW 54001, '@Scale must be > 0 and <= 1.', 1;

    /* Team 1 tables must be empty (no deletes are performed by this file). */
    IF EXISTS (SELECT 1 FROM ref.Province) OR EXISTS (SELECT 1 FROM ref.City) OR EXISTS (SELECT 1 FROM ref.CustomerSegment)
       OR EXISTS (SELECT 1 FROM ref.SalesChannel) OR EXISTS (SELECT 1 FROM ref.SalesRegion) OR EXISTS (SELECT 1 FROM ref.SalesTerritory)
       OR EXISTS (SELECT 1 FROM core.Calendar) OR EXISTS (SELECT 1 FROM core.Branch) OR EXISTS (SELECT 1 FROM core.Salesperson)
       OR EXISTS (SELECT 1 FROM core.Customer) OR EXISTS (SELECT 1 FROM sales.Lead)
       OR EXISTS (SELECT 1 FROM sales.CustomerInteraction) OR EXISTS (SELECT 1 FROM sales.SalesOpportunity) OR EXISTS (SELECT 1 FROM sales.Contract)
       OR EXISTS (SELECT 1 FROM sales.SalesOrder) OR EXISTS (SELECT 1 FROM sales.SalesOrderItem)
       OR EXISTS (SELECT 1 FROM sales.Invoice) OR EXISTS (SELECT 1 FROM sales.InvoiceItem)
       OR EXISTS (SELECT 1 FROM sales.Payment) OR EXISTS (SELECT 1 FROM sales.ReturnRequest) OR EXISTS (SELECT 1 FROM sales.CustomerFeedback)
       OR EXISTS (SELECT 1 FROM sales.SalesTarget) OR EXISTS (SELECT 1 FROM sales.SalesForecast) OR EXISTS (SELECT 1 FROM sales.Commission)
        THROW 54002, 'At least one Team 1 target table already contains rows. Nothing was deleted; use the lead''s Reset script.', 1;

    /* Team 2 prerequisites (Product / SKU / ProductPrice / Promotion). */
    IF OBJECT_ID(N'core.Product',N'U') IS NULL OR OBJECT_ID(N'core.SKU',N'U') IS NULL
       OR OBJECT_ID(N'marketing.ProductPrice',N'U') IS NULL OR OBJECT_ID(N'marketing.Promotion',N'U') IS NULL
        THROW 54003, 'Team 2 tables are missing.', 1;
    IF NOT EXISTS (SELECT 1 FROM core.Product WHERE Product_Status = N'Active')
       OR NOT EXISTS (SELECT 1 FROM marketing.ProductPrice WHERE Price_Type = N'Standard')
        THROW 54004, 'Team 2 data not loaded. Run Team 2 08-04-Load-Data.sql first (Product, SKU, ProductPrice, Promotion).', 1;
END TRY
BEGIN CATCH
    UPDATE #T1Cfg SET Abort = 1;
    PRINT CONCAT(N'ERROR ', ERROR_NUMBER(), N' | ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO

GO
/* ===================== SECTION 1 : 8.1 Reference data ====================== */
SET NOCOUNT ON; SET XACT_ABORT ON;
IF EXISTS (SELECT 1 FROM #T1Cfg WHERE Abort = 1) BEGIN PRINT N'SKIPPED section 1 (earlier failure)'; RETURN; END;
BEGIN TRY
    IF OBJECT_ID(N'ref.Province',N'U') IS NULL OR OBJECT_ID(N'ref.City',N'U') IS NULL OR OBJECT_ID(N'ref.CustomerSegment',N'U') IS NULL
       OR OBJECT_ID(N'ref.SalesChannel',N'U') IS NULL OR OBJECT_ID(N'ref.SalesRegion',N'U') IS NULL OR OBJECT_ID(N'ref.SalesTerritory',N'U') IS NULL
        THROW 51000, 'One or more required reference tables do not exist.', 1;
    DROP TABLE IF EXISTS #CityStg, #RegionStg;
    BEGIN TRANSACTION;

    /* IDs are generated by SQL Server (no IDENTITY_INSERT); parents are resolved by business code. */
    INSERT INTO ref.Province (Province_Code, Province_Name, Province_Status)
    SELECT Province_Code, Province_Name, Province_Status
    FROM (VALUES
        (N'PR001', N'آذربایجان شرقی', N'Active'),
        (N'PR002', N'آذربایجان غربی', N'Active'),
        (N'PR003', N'اردبیل', N'Active'),
        (N'PR004', N'اصفهان', N'Active'),
        (N'PR005', N'البرز', N'Active'),
        (N'PR006', N'ایلام', N'Active'),
        (N'PR007', N'بوشهر', N'Active'),
        (N'PR008', N'تهران', N'Active'),
        (N'PR009', N'چهارمحال و بختیاری', N'Active'),
        (N'PR010', N'خراسان جنوبی', N'Active'),
        (N'PR011', N'خراسان رضوی', N'Active'),
        (N'PR012', N'خراسان شمالی', N'Active'),
        (N'PR013', N'خوزستان', N'Active'),
        (N'PR014', N'زنجان', N'Active'),
        (N'PR015', N'سمنان', N'Active'),
        (N'PR016', N'سیستان و بلوچستان', N'Active'),
        (N'PR017', N'فارس', N'Active'),
        (N'PR018', N'قزوین', N'Active'),
        (N'PR019', N'قم', N'Active'),
        (N'PR020', N'کردستان', N'Active'),
        (N'PR021', N'کرمان', N'Active'),
        (N'PR022', N'کرمانشاه', N'Active'),
        (N'PR023', N'کهگیلویه و بویراحمد', N'Active'),
        (N'PR024', N'گلستان', N'Active'),
        (N'PR025', N'گیلان', N'Active'),
        (N'PR026', N'لرستان', N'Active'),
        (N'PR027', N'مازندران', N'Active'),
        (N'PR028', N'مرکزی', N'Active'),
        (N'PR029', N'هرمزگان', N'Active'),
        (N'PR030', N'همدان', N'Active'),
        (N'PR031', N'یزد', N'Active')
    ) v (Province_Code, Province_Name, Province_Status)
    ORDER BY Province_Code;

    SELECT * INTO #CityStg
    FROM (VALUES
        (N'PR001', NULL, N'CT0001', N'تبریز', N'City', N'Active'),
        (N'PR001', NULL, N'CT0002', N'مراغه', N'City', N'Active'),
        (N'PR001', NULL, N'CT0003', N'مرند', N'City', N'Active'),
        (N'PR001', NULL, N'CT0004', N'میانه', N'City', N'Active'),
        (N'PR001', NULL, N'CT0005', N'اهر', N'City', N'Active'),
        (N'PR001', NULL, N'CT0006', N'شبستر', N'City', N'Active'),
        (N'PR001', NULL, N'CT0007', N'بناب', N'City', N'Active'),
        (N'PR001', NULL, N'CT0008', N'سراب', N'City', N'Active'),
        (N'PR001', NULL, N'CT0009', N'آذرشهر', N'City', N'Active'),
        (N'PR002', NULL, N'CT0010', N'ارومیه', N'City', N'Active'),
        (N'PR002', NULL, N'CT0011', N'خوی', N'City', N'Active'),
        (N'PR002', NULL, N'CT0012', N'بوکان', N'City', N'Active'),
        (N'PR002', NULL, N'CT0013', N'مهاباد', N'City', N'Active'),
        (N'PR002', NULL, N'CT0014', N'میاندوآب', N'City', N'Active'),
        (N'PR002', NULL, N'CT0015', N'سلماس', N'City', N'Active'),
        (N'PR002', NULL, N'CT0016', N'نقده', N'City', N'Active'),
        (N'PR002', NULL, N'CT0017', N'پیرانشهر', N'City', N'Active'),
        (N'PR003', NULL, N'CT0018', N'اردبیل', N'City', N'Active'),
        (N'PR003', NULL, N'CT0019', N'پارس‌آباد', N'City', N'Active'),
        (N'PR003', NULL, N'CT0020', N'مشگین‌شهر', N'City', N'Active'),
        (N'PR003', NULL, N'CT0021', N'خلخال', N'City', N'Active'),
        (N'PR003', NULL, N'CT0022', N'گرمی', N'City', N'Active'),
        (N'PR003', NULL, N'CT0023', N'بیله‌سوار', N'City', N'Active'),
        (N'PR004', NULL, N'CT0024', N'اصفهان', N'City', N'Active'),
        (N'PR004', NULL, N'CT0025', N'کاشان', N'City', N'Active'),
        (N'PR004', NULL, N'CT0026', N'خمینی‌شهر', N'City', N'Active'),
        (N'PR004', NULL, N'CT0027', N'نجف‌آباد', N'City', N'Active'),
        (N'PR004', NULL, N'CT0028', N'شاهین‌شهر', N'City', N'Active'),
        (N'PR004', NULL, N'CT0029', N'فلاورجان', N'City', N'Active'),
        (N'PR004', NULL, N'CT0030', N'زرین‌شهر', N'City', N'Active'),
        (N'PR004', NULL, N'CT0031', N'مبارکه', N'City', N'Active'),
        (N'PR004', NULL, N'CT0032', N'فولادشهر', N'City', N'Active'),
        (N'PR004', NULL, N'CT0033', N'گلپایگان', N'City', N'Active'),
        (N'PR005', NULL, N'CT0034', N'کرج', N'City', N'Active'),
        (N'PR005', NULL, N'CT0035', N'فردیس', N'City', N'Active'),
        (N'PR005', NULL, N'CT0036', N'نظرآباد', N'City', N'Active'),
        (N'PR005', NULL, N'CT0037', N'ساوجبلاغ', N'City', N'Active'),
        (N'PR006', NULL, N'CT0038', N'ایلام', N'City', N'Active'),
        (N'PR006', NULL, N'CT0039', N'دهلران', N'City', N'Active'),
        (N'PR006', NULL, N'CT0040', N'آبدانان', N'City', N'Active'),
        (N'PR006', NULL, N'CT0041', N'ایوان', N'City', N'Active'),
        (N'PR007', NULL, N'CT0042', N'بوشهر', N'City', N'Active'),
        (N'PR007', NULL, N'CT0043', N'برازجان', N'City', N'Active'),
        (N'PR007', NULL, N'CT0044', N'گناوه', N'City', N'Active'),
        (N'PR007', NULL, N'CT0045', N'کنگان', N'City', N'Active'),
        (N'PR007', NULL, N'CT0046', N'عسلویه', N'City', N'Active'),
        (N'PR007', NULL, N'CT0047', N'دیر', N'City', N'Active'),
        (N'PR008', NULL, N'CT0048', N'تهران', N'City', N'Active'),
        (N'PR008', NULL, N'CT0049', N'ری', N'City', N'Active'),
        (N'PR008', NULL, N'CT0050', N'شهریار', N'City', N'Active'),
        (N'PR008', NULL, N'CT0051', N'اسلام‌شهر', N'City', N'Active'),
        (N'PR008', NULL, N'CT0052', N'قدس', N'City', N'Active'),
        (N'PR008', NULL, N'CT0053', N'ملارد', N'City', N'Active'),
        (N'PR008', NULL, N'CT0054', N'ورامین', N'City', N'Active'),
        (N'PR008', NULL, N'CT0055', N'پاکدشت', N'City', N'Active'),
        (N'PR009', NULL, N'CT0056', N'شهرکرد', N'City', N'Active'),
        (N'PR009', NULL, N'CT0057', N'بروجن', N'City', N'Active'),
        (N'PR009', NULL, N'CT0058', N'فارسان', N'City', N'Active'),
        (N'PR009', NULL, N'CT0059', N'لردگان', N'City', N'Active'),
        (N'PR009', NULL, N'CT0060', N'اردل', N'City', N'Active'),
        (N'PR010', NULL, N'CT0061', N'بیرجند', N'City', N'Active'),
        (N'PR010', NULL, N'CT0062', N'قائن', N'City', N'Active'),
        (N'PR010', NULL, N'CT0063', N'فردوس', N'City', N'Active'),
        (N'PR010', NULL, N'CT0064', N'طبس', N'City', N'Active'),
        (N'PR010', NULL, N'CT0065', N'نهبندان', N'City', N'Active'),
        (N'PR010', NULL, N'CT0066', N'سربیشه', N'City', N'Active'),
        (N'PR011', NULL, N'CT0067', N'مشهد', N'City', N'Active'),
        (N'PR011', NULL, N'CT0068', N'نیشابور', N'City', N'Active'),
        (N'PR011', NULL, N'CT0069', N'سبزوار', N'City', N'Active'),
        (N'PR011', NULL, N'CT0070', N'تربت حیدریه', N'City', N'Active'),
        (N'PR011', NULL, N'CT0071', N'کاشمر', N'City', N'Active'),
        (N'PR011', NULL, N'CT0072', N'قوچان', N'City', N'Active'),
        (N'PR011', NULL, N'CT0073', N'تربت جام', N'City', N'Active'),
        (N'PR011', NULL, N'CT0074', N'چناران', N'City', N'Active'),
        (N'PR011', NULL, N'CT0075', N'گناباد', N'City', N'Active'),
        (N'PR011', NULL, N'CT0076', N'خواف', N'City', N'Active'),
        (N'PR012', NULL, N'CT0077', N'بجنورد', N'City', N'Active'),
        (N'PR012', NULL, N'CT0078', N'شیروان', N'City', N'Active'),
        (N'PR012', NULL, N'CT0079', N'اسفراین', N'City', N'Active'),
        (N'PR012', NULL, N'CT0080', N'جاجرم', N'City', N'Active'),
        (N'PR013', NULL, N'CT0081', N'اهواز', N'City', N'Active'),
        (N'PR013', NULL, N'CT0082', N'دزفول', N'City', N'Active'),
        (N'PR013', NULL, N'CT0083', N'آبادان', N'City', N'Active'),
        (N'PR013', NULL, N'CT0084', N'خرمشهر', N'City', N'Active'),
        (N'PR013', NULL, N'CT0085', N'ماهشهر', N'City', N'Active'),
        (N'PR013', NULL, N'CT0086', N'بهبهان', N'City', N'Active'),
        (N'PR013', NULL, N'CT0087', N'اندیمشک', N'City', N'Active'),
        (N'PR013', NULL, N'CT0088', N'شوشتر', N'City', N'Active'),
        (N'PR013', NULL, N'CT0089', N'ایذه', N'City', N'Active'),
        (N'PR014', NULL, N'CT0090', N'زنجان', N'City', N'Active'),
        (N'PR014', NULL, N'CT0091', N'ابهر', N'City', N'Active'),
        (N'PR014', NULL, N'CT0092', N'خرمدره', N'City', N'Active'),
        (N'PR014', NULL, N'CT0093', N'قیدار', N'City', N'Active'),
        (N'PR015', NULL, N'CT0094', N'سمنان', N'City', N'Active'),
        (N'PR015', NULL, N'CT0095', N'شاهرود', N'City', N'Active'),
        (N'PR015', NULL, N'CT0096', N'دامغان', N'City', N'Active'),
        (N'PR015', NULL, N'CT0097', N'گرمسار', N'City', N'Active'),
        (N'PR016', NULL, N'CT0098', N'زاهدان', N'City', N'Active'),
        (N'PR016', NULL, N'CT0099', N'چابهار', N'City', N'Active'),
        (N'PR016', NULL, N'CT0100', N'ایرانشهر', N'City', N'Active'),
        (N'PR016', NULL, N'CT0101', N'زابل', N'City', N'Active'),
        (N'PR016', NULL, N'CT0102', N'سراوان', N'City', N'Active'),
        (N'PR016', NULL, N'CT0103', N'خاش', N'City', N'Active'),
        (N'PR016', NULL, N'CT0104', N'کنارک', N'City', N'Active'),
        (N'PR017', NULL, N'CT0105', N'شیراز', N'City', N'Active'),
        (N'PR017', NULL, N'CT0106', N'مرودشت', N'City', N'Active'),
        (N'PR017', NULL, N'CT0107', N'کازرون', N'City', N'Active'),
        (N'PR017', NULL, N'CT0108', N'جهرم', N'City', N'Active'),
        (N'PR017', NULL, N'CT0109', N'فسا', N'City', N'Active'),
        (N'PR017', NULL, N'CT0110', N'لار', N'City', N'Active'),
        (N'PR017', NULL, N'CT0111', N'داراب', N'City', N'Active'),
        (N'PR017', NULL, N'CT0112', N'فیروزآباد', N'City', N'Active'),
        (N'PR017', NULL, N'CT0113', N'آباده', N'City', N'Active'),
        (N'PR017', NULL, N'CT0114', N'اقلید', N'City', N'Active'),
        (N'PR018', NULL, N'CT0115', N'قزوین', N'City', N'Active'),
        (N'PR018', NULL, N'CT0116', N'تاکستان', N'City', N'Active'),
        (N'PR018', NULL, N'CT0117', N'الوند', N'City', N'Active'),
        (N'PR018', NULL, N'CT0118', N'آبیک', N'City', N'Active'),
        (N'PR019', NULL, N'CT0119', N'قم', N'City', N'Active'),
        (N'PR019', NULL, N'CT0120', N'جعفریه', N'City', N'Active'),
        (N'PR019', NULL, N'CT0121', N'دستجرد', N'City', N'Active'),
        (N'PR020', NULL, N'CT0122', N'سنندج', N'City', N'Active'),
        (N'PR020', NULL, N'CT0123', N'سقز', N'City', N'Active'),
        (N'PR020', NULL, N'CT0124', N'مریوان', N'City', N'Active'),
        (N'PR020', NULL, N'CT0125', N'بانه', N'City', N'Active'),
        (N'PR020', NULL, N'CT0126', N'قروه', N'City', N'Active'),
        (N'PR020', NULL, N'CT0127', N'بیجار', N'City', N'Active'),
        (N'PR021', NULL, N'CT0128', N'کرمان', N'City', N'Active'),
        (N'PR021', NULL, N'CT0129', N'رفسنجان', N'City', N'Active'),
        (N'PR021', NULL, N'CT0130', N'سیرجان', N'City', N'Active'),
        (N'PR021', NULL, N'CT0131', N'جیرفت', N'City', N'Active'),
        (N'PR021', NULL, N'CT0132', N'بم', N'City', N'Active'),
        (N'PR021', NULL, N'CT0133', N'زرند', N'City', N'Active'),
        (N'PR021', NULL, N'CT0134', N'کهنوج', N'City', N'Active'),
        (N'PR021', NULL, N'CT0135', N'شهربابک', N'City', N'Active'),
        (N'PR021', NULL, N'CT0136', N'بردسیر', N'City', N'Active'),
        (N'PR022', NULL, N'CT0137', N'کرمانشاه', N'City', N'Active'),
        (N'PR022', NULL, N'CT0138', N'اسلام‌آباد غرب', N'City', N'Active'),
        (N'PR022', NULL, N'CT0139', N'جوانرود', N'City', N'Active'),
        (N'PR022', NULL, N'CT0140', N'کنگاور', N'City', N'Active'),
        (N'PR022', NULL, N'CT0141', N'هرسین', N'City', N'Active'),
        (N'PR022', NULL, N'CT0142', N'سنقر', N'City', N'Active'),
        (N'PR022', NULL, N'CT0143', N'صحنه', N'City', N'Active'),
        (N'PR023', NULL, N'CT0144', N'یاسوج', N'City', N'Active'),
        (N'PR023', NULL, N'CT0145', N'دوگنبدان', N'City', N'Active'),
        (N'PR023', NULL, N'CT0146', N'دهدشت', N'City', N'Active'),
        (N'PR023', NULL, N'CT0147', N'لیکک', N'City', N'Active'),
        (N'PR024', NULL, N'CT0148', N'گرگان', N'City', N'Active'),
        (N'PR024', NULL, N'CT0149', N'گنبد کاووس', N'City', N'Active'),
        (N'PR024', NULL, N'CT0150', N'علی‌آباد کتول', N'City', N'Active'),
        (N'PR024', NULL, N'CT0151', N'آق‌قلا', N'City', N'Active'),
        (N'PR024', NULL, N'CT0152', N'بندر ترکمن', N'City', N'Active'),
        (N'PR024', NULL, N'CT0153', N'کردکوی', N'City', N'Active'),
        (N'PR025', NULL, N'CT0154', N'رشت', N'City', N'Active'),
        (N'PR025', NULL, N'CT0155', N'بندر انزلی', N'City', N'Active'),
        (N'PR025', NULL, N'CT0156', N'لاهیجان', N'City', N'Active'),
        (N'PR025', NULL, N'CT0157', N'لنگرود', N'City', N'Active'),
        (N'PR025', NULL, N'CT0158', N'آستارا', N'City', N'Active'),
        (N'PR025', NULL, N'CT0159', N'تالش', N'City', N'Active'),
        (N'PR025', NULL, N'CT0160', N'رودسر', N'City', N'Active'),
        (N'PR025', NULL, N'CT0161', N'صومعه‌سرا', N'City', N'Active'),
        (N'PR026', NULL, N'CT0162', N'خرم‌آباد', N'City', N'Active'),
        (N'PR026', NULL, N'CT0163', N'بروجرد', N'City', N'Active'),
        (N'PR026', NULL, N'CT0164', N'دورود', N'City', N'Active'),
        (N'PR026', NULL, N'CT0165', N'الیگودرز', N'City', N'Active'),
        (N'PR026', NULL, N'CT0166', N'ازنا', N'City', N'Active'),
        (N'PR026', NULL, N'CT0167', N'کوهدشت', N'City', N'Active'),
        (N'PR027', NULL, N'CT0168', N'ساری', N'City', N'Active'),
        (N'PR027', NULL, N'CT0169', N'بابل', N'City', N'Active'),
        (N'PR027', NULL, N'CT0170', N'آمل', N'City', N'Active'),
        (N'PR027', NULL, N'CT0171', N'قائم‌شهر', N'City', N'Active'),
        (N'PR027', NULL, N'CT0172', N'بهشهر', N'City', N'Active'),
        (N'PR027', NULL, N'CT0173', N'نوشهر', N'City', N'Active'),
        (N'PR027', NULL, N'CT0174', N'چالوس', N'City', N'Active'),
        (N'PR027', NULL, N'CT0175', N'تنکابن', N'City', N'Active'),
        (N'PR027', NULL, N'CT0176', N'رامسر', N'City', N'Active'),
        (N'PR028', NULL, N'CT0177', N'اراک', N'City', N'Active'),
        (N'PR028', NULL, N'CT0178', N'ساوه', N'City', N'Active'),
        (N'PR028', NULL, N'CT0179', N'خمین', N'City', N'Active'),
        (N'PR028', NULL, N'CT0180', N'محلات', N'City', N'Active'),
        (N'PR028', NULL, N'CT0181', N'دلیجان', N'City', N'Active'),
        (N'PR028', NULL, N'CT0182', N'شازند', N'City', N'Active'),
        (N'PR029', NULL, N'CT0183', N'بندرعباس', N'City', N'Active'),
        (N'PR029', NULL, N'CT0184', N'میناب', N'City', N'Active'),
        (N'PR029', NULL, N'CT0185', N'دهبارز', N'City', N'Active'),
        (N'PR029', NULL, N'CT0186', N'بندر لنگه', N'City', N'Active'),
        (N'PR029', NULL, N'CT0187', N'قشم', N'City', N'Active'),
        (N'PR029', NULL, N'CT0188', N'کیش', N'City', N'Active'),
        (N'PR029', NULL, N'CT0189', N'جاسک', N'City', N'Active'),
        (N'PR030', NULL, N'CT0190', N'همدان', N'City', N'Active'),
        (N'PR030', NULL, N'CT0191', N'ملایر', N'City', N'Active'),
        (N'PR030', NULL, N'CT0192', N'نهاوند', N'City', N'Active'),
        (N'PR030', NULL, N'CT0193', N'تویسرکان', N'City', N'Active'),
        (N'PR030', NULL, N'CT0194', N'اسدآباد', N'City', N'Active'),
        (N'PR031', NULL, N'CT0195', N'یزد', N'City', N'Active'),
        (N'PR031', NULL, N'CT0196', N'میبد', N'City', N'Active'),
        (N'PR031', NULL, N'CT0197', N'اردکان', N'City', N'Active'),
        (N'PR031', NULL, N'CT0198', N'بافق', N'City', N'Active'),
        (N'PR031', NULL, N'CT0199', N'مهریز', N'City', N'Active'),
        (N'PR031', NULL, N'CT0200', N'ابرکوه', N'City', N'Active'),
        (N'PR004', N'CT0027', N'CT0201', N'ناحیه مرکزی نجف‌آباد 01', N'District', N'Active'),
        (N'PR008', N'CT0049', N'CT0202', N'ناحیه شمالی ری 02', N'District', N'Active'),
        (N'PR008', N'CT0055', N'CT0203', N'ناحیه جنوبی پاکدشت 03', N'District', N'Active'),
        (N'PR008', N'CT0055', N'CT0204', N'ناحیه شرقی پاکدشت 04', N'District', N'Active'),
        (N'PR011', N'CT0067', N'CT0205', N'ناحیه غربی مشهد 05', N'District', N'Active'),
        (N'PR007', N'CT0045', N'CT0206', N'ناحیه صنعتی کنگان 06', N'District', N'Active'),
        (N'PR002', N'CT0016', N'CT0207', N'ناحیه تجاری نقده 07', N'District', N'Active'),
        (N'PR029', N'CT0184', N'CT0208', N'ناحیه دانشگاهی میناب 08', N'District', N'Active'),
        (N'PR013', N'CT0085', N'CT0209', N'ناحیه مسکونی ماهشهر 09', N'District', N'Active'),
        (N'PR029', N'CT0184', N'CT0210', N'ناحیه حومه میناب 10', N'District', N'Active'),
        (N'PR027', N'CT0176', N'CT0211', N'ناحیه مرکزی رامسر 11', N'District', N'Active'),
        (N'PR005', N'CT0035', N'CT0212', N'ناحیه شمالی فردیس 12', N'District', N'Active'),
        (N'PR010', N'CT0062', N'CT0213', N'ناحیه جنوبی قائن 13', N'District', N'Active'),
        (N'PR025', N'CT0158', N'CT0214', N'ناحیه شرقی آستارا 14', N'District', N'Active'),
        (N'PR010', N'CT0066', N'CT0215', N'ناحیه غربی سربیشه 15', N'District', N'Active'),
        (N'PR017', N'CT0110', N'CT0216', N'ناحیه صنعتی لار 16', N'District', N'Active'),
        (N'PR027', N'CT0174', N'CT0217', N'ناحیه تجاری چالوس 17', N'District', N'Active'),
        (N'PR010', N'CT0062', N'CT0218', N'ناحیه دانشگاهی قائن 18', N'District', N'Active'),
        (N'PR017', N'CT0107', N'CT0219', N'ناحیه مسکونی کازرون 19', N'District', N'Active'),
        (N'PR017', N'CT0109', N'CT0220', N'ناحیه حومه فسا 20', N'District', N'Active'),
        (N'PR025', N'CT0158', N'CT0221', N'ناحیه مرکزی آستارا 21', N'District', N'Active'),
        (N'PR018', N'CT0115', N'CT0222', N'ناحیه شمالی قزوین 22', N'District', N'Active'),
        (N'PR025', N'CT0158', N'CT0223', N'ناحیه جنوبی آستارا 23', N'District', N'Active'),
        (N'PR011', N'CT0070', N'CT0224', N'ناحیه شرقی تربت حیدریه 24', N'District', N'Active'),
        (N'PR013', N'CT0082', N'CT0225', N'ناحیه غربی دزفول 25', N'District', N'Active'),
        (N'PR029', N'CT0184', N'CT0226', N'ناحیه صنعتی میناب 26', N'District', N'Active'),
        (N'PR005', N'CT0037', N'CT0227', N'ناحیه تجاری ساوجبلاغ 27', N'District', N'Active'),
        (N'PR001', N'CT0009', N'CT0228', N'ناحیه دانشگاهی آذرشهر 28', N'District', N'Active'),
        (N'PR004', N'CT0024', N'CT0229', N'ناحیه مسکونی اصفهان 29', N'District', N'Active'),
        (N'PR017', N'CT0107', N'CT0230', N'ناحیه حومه کازرون 30', N'District', N'Active'),
        (N'PR011', N'CT0073', N'CT0231', N'ناحیه مرکزی تربت جام 31', N'District', N'Active'),
        (N'PR028', N'CT0182', N'CT0232', N'ناحیه شمالی شازند 32', N'District', N'Active'),
        (N'PR027', N'CT0169', N'CT0233', N'ناحیه جنوبی بابل 33', N'District', N'Active'),
        (N'PR011', N'CT0076', N'CT0234', N'ناحیه شرقی خواف 34', N'District', N'Active'),
        (N'PR005', N'CT0035', N'CT0235', N'ناحیه غربی فردیس 35', N'District', N'Active'),
        (N'PR022', N'CT0137', N'CT0236', N'ناحیه صنعتی کرمانشاه 36', N'District', N'Active'),
        (N'PR020', N'CT0127', N'CT0237', N'ناحیه تجاری بیجار 37', N'District', N'Active'),
        (N'PR002', N'CT0012', N'CT0238', N'ناحیه دانشگاهی بوکان 38', N'District', N'Active'),
        (N'PR004', N'CT0026', N'CT0239', N'ناحیه مسکونی خمینی‌شهر 39', N'District', N'Active'),
        (N'PR027', N'CT0169', N'CT0240', N'ناحیه حومه بابل 40', N'District', N'Active'),
        (N'PR007', N'CT0043', N'CT0241', N'ناحیه مرکزی برازجان 41', N'District', N'Active'),
        (N'PR011', N'CT0068', N'CT0242', N'ناحیه شمالی نیشابور 42', N'District', N'Active'),
        (N'PR016', N'CT0098', N'CT0243', N'ناحیه جنوبی زاهدان 43', N'District', N'Active'),
        (N'PR013', N'CT0088', N'CT0244', N'ناحیه شرقی شوشتر 44', N'District', N'Active'),
        (N'PR002', N'CT0013', N'CT0245', N'ناحیه غربی مهاباد 45', N'District', N'Active'),
        (N'PR004', N'CT0033', N'CT0246', N'ناحیه صنعتی گلپایگان 46', N'District', N'Active'),
        (N'PR017', N'CT0114', N'CT0247', N'ناحیه تجاری اقلید 47', N'District', N'Active'),
        (N'PR011', N'CT0071', N'CT0248', N'ناحیه دانشگاهی کاشمر 48', N'District', N'Active'),
        (N'PR024', N'CT0152', N'CT0249', N'ناحیه مسکونی بندر ترکمن 49', N'District', N'Active'),
        (N'PR012', N'CT0078', N'CT0250', N'ناحیه حومه شیروان 50', N'District', N'Active'),
        (N'PR027', N'CT0168', N'CT0251', N'ناحیه مرکزی ساری 51', N'District', N'Active'),
        (N'PR001', N'CT0005', N'CT0252', N'ناحیه شمالی اهر 52', N'District', N'Active'),
        (N'PR027', N'CT0172', N'CT0253', N'ناحیه جنوبی بهشهر 53', N'District', N'Active'),
        (N'PR009', N'CT0056', N'CT0254', N'ناحیه شرقی شهرکرد 54', N'District', N'Active'),
        (N'PR002', N'CT0012', N'CT0255', N'ناحیه غربی بوکان 55', N'District', N'Active'),
        (N'PR007', N'CT0045', N'CT0256', N'ناحیه صنعتی کنگان 56', N'District', N'Active'),
        (N'PR027', N'CT0175', N'CT0257', N'ناحیه تجاری تنکابن 57', N'District', N'Active'),
        (N'PR004', N'CT0032', N'CT0258', N'ناحیه دانشگاهی فولادشهر 58', N'District', N'Active'),
        (N'PR022', N'CT0139', N'CT0259', N'ناحیه مسکونی جوانرود 59', N'District', N'Active'),
        (N'PR004', N'CT0033', N'CT0260', N'ناحیه حومه گلپایگان 60', N'District', N'Active'),
        (N'PR029', N'CT0183', N'CT0261', N'ناحیه مرکزی بندرعباس 61', N'District', N'Active'),
        (N'PR004', N'CT0031', N'CT0262', N'ناحیه شمالی مبارکه 62', N'District', N'Active'),
        (N'PR020', N'CT0122', N'CT0263', N'ناحیه جنوبی سنندج 63', N'District', N'Active'),
        (N'PR007', N'CT0042', N'CT0264', N'ناحیه شرقی بوشهر 64', N'District', N'Active'),
        (N'PR010', N'CT0061', N'CT0265', N'ناحیه غربی بیرجند 65', N'District', N'Active'),
        (N'PR017', N'CT0111', N'CT0266', N'ناحیه صنعتی داراب 66', N'District', N'Active'),
        (N'PR003', N'CT0018', N'CT0267', N'ناحیه تجاری اردبیل 67', N'District', N'Active'),
        (N'PR002', N'CT0017', N'CT0268', N'ناحیه دانشگاهی پیرانشهر 68', N'District', N'Active'),
        (N'PR011', N'CT0072', N'CT0269', N'ناحیه مسکونی قوچان 69', N'District', N'Active'),
        (N'PR010', N'CT0061', N'CT0270', N'ناحیه حومه بیرجند 70', N'District', N'Active'),
        (N'PR028', N'CT0178', N'CT0271', N'ناحیه مرکزی ساوه 71', N'District', N'Active'),
        (N'PR024', N'CT0149', N'CT0272', N'ناحیه شمالی گنبد کاووس 72', N'District', N'Active'),
        (N'PR002', N'CT0016', N'CT0273', N'ناحیه جنوبی نقده 73', N'District', N'Active'),
        (N'PR020', N'CT0123', N'CT0274', N'ناحیه شرقی سقز 74', N'District', N'Active'),
        (N'PR013', N'CT0084', N'CT0275', N'ناحیه غربی خرمشهر 75', N'District', N'Active'),
        (N'PR011', N'CT0075', N'CT0276', N'ناحیه صنعتی گناباد 76', N'District', N'Active'),
        (N'PR017', N'CT0109', N'CT0277', N'ناحیه تجاری فسا 77', N'District', N'Active'),
        (N'PR031', N'CT0200', N'CT0278', N'ناحیه دانشگاهی ابرکوه 78', N'District', N'Active'),
        (N'PR025', N'CT0156', N'CT0279', N'ناحیه مسکونی لاهیجان 79', N'District', N'Active'),
        (N'PR027', N'CT0172', N'CT0280', N'ناحیه حومه بهشهر 80', N'District', N'Active'),
        (N'PR020', N'CT0122', N'CT0281', N'ناحیه مرکزی سنندج 81', N'District', N'Active'),
        (N'PR022', N'CT0143', N'CT0282', N'ناحیه شمالی صحنه 82', N'District', N'Active'),
        (N'PR013', N'CT0083', N'CT0283', N'ناحیه جنوبی آبادان 83', N'District', N'Active'),
        (N'PR027', N'CT0168', N'CT0284', N'ناحیه شرقی ساری 84', N'District', N'Active'),
        (N'PR003', N'CT0023', N'CT0285', N'ناحیه غربی بیله‌سوار 85', N'District', N'Active'),
        (N'PR029', N'CT0187', N'CT0286', N'ناحیه صنعتی قشم 86', N'District', N'Active'),
        (N'PR004', N'CT0029', N'CT0287', N'ناحیه تجاری فلاورجان 87', N'District', N'Active'),
        (N'PR006', N'CT0040', N'CT0288', N'ناحیه دانشگاهی آبدانان 88', N'District', N'Active'),
        (N'PR029', N'CT0186', N'CT0289', N'ناحیه مسکونی بندر لنگه 89', N'District', N'Active'),
        (N'PR017', N'CT0105', N'CT0290', N'ناحیه حومه شیراز 90', N'District', N'Active'),
        (N'PR021', N'CT0135', N'CT0291', N'ناحیه مرکزی شهربابک 91', N'District', N'Active'),
        (N'PR003', N'CT0018', N'CT0292', N'ناحیه شمالی اردبیل 92', N'District', N'Active'),
        (N'PR017', N'CT0109', N'CT0293', N'ناحیه جنوبی فسا 93', N'District', N'Active'),
        (N'PR020', N'CT0126', N'CT0294', N'ناحیه شرقی قروه 94', N'District', N'Active'),
        (N'PR021', N'CT0128', N'CT0295', N'ناحیه غربی کرمان 95', N'District', N'Active'),
        (N'PR029', N'CT0187', N'CT0296', N'ناحیه صنعتی قشم 96', N'District', N'Active'),
        (N'PR016', N'CT0098', N'CT0297', N'ناحیه تجاری زاهدان 97', N'District', N'Active'),
        (N'PR031', N'CT0195', N'CT0298', N'ناحیه دانشگاهی یزد 98', N'District', N'Active'),
        (N'PR017', N'CT0112', N'CT0299', N'ناحیه مسکونی فیروزآباد 99', N'District', N'Active'),
        (N'PR027', N'CT0171', N'CT0300', N'ناحیه حومه قائم‌شهر 100', N'District', N'Active')
    ) v (Province_Code, Parent_City_Code, City_Code, City_Name, City_Level, City_Status);

    /* roots first (City), then District rows that point to an already inserted City */
    INSERT INTO ref.City (Province_ID, Parent_City_ID, City_Code, City_Name, City_Level, City_Status)
    SELECT p.Province_ID, NULL, s.City_Code, s.City_Name, s.City_Level, s.City_Status
    FROM #CityStg s JOIN ref.Province p ON p.Province_Code = s.Province_Code
    WHERE s.Parent_City_Code IS NULL
    ORDER BY s.City_Code;

    INSERT INTO ref.City (Province_ID, Parent_City_ID, City_Code, City_Name, City_Level, City_Status)
    SELECT p.Province_ID, pc.City_ID, s.City_Code, s.City_Name, s.City_Level, s.City_Status
    FROM #CityStg s
    JOIN ref.Province p ON p.Province_Code = s.Province_Code
    JOIN ref.City pc    ON pc.City_Code = s.Parent_City_Code
    WHERE s.Parent_City_Code IS NOT NULL
    ORDER BY s.City_Code;

    INSERT INTO ref.CustomerSegment (Segment_Code, Segment_Name, Segment_Type, Segment_Level, Segment_Criteria, Segment_Description, Priority, Segment_Status, Created_Date, End_Date)
    SELECT Segment_Code, Segment_Name, Segment_Type, Segment_Level, Segment_Criteria, Segment_Description, Priority, Segment_Status, Created_Date, End_Date
    FROM (VALUES
        (N'SEG01', N'خرده‌فروشی', NULL, NULL, NULL, N'فروشگاه‌های خرده‌فروشی و واحدهای کوچک عرضه', 1, N'Active', N'2018-01-01', NULL),
        (N'SEG02', N'سوپرمارکت', NULL, NULL, NULL, N'سوپرمارکت‌ها و فروشگاه‌های مواد غذایی محلی', 2, N'Active', N'2018-01-01', NULL),
        (N'SEG03', N'هایپرمارکت', NULL, NULL, NULL, N'فروشگاه‌های بزرگ و زنجیره‌ای', 3, N'Active', N'2018-01-01', NULL),
        (N'SEG04', N'هتل و رستوران', NULL, NULL, NULL, N'مراکز پذیرایی و خدمات غذایی', 4, N'Active', N'2018-01-01', NULL),
        (N'SEG05', N'عمده‌فروش', NULL, NULL, NULL, N'مشتریان عمده‌فروش و پخش‌کنندگان', 5, N'Active', N'2018-01-01', NULL),
        (N'SEG06', N'فروشگاه تخصصی', NULL, NULL, NULL, N'فروشگاه‌های تخصصی مواد غذایی', 7, N'Active', N'2018-01-01', NULL),
        (N'SEG07', N'سازمانی', NULL, NULL, NULL, N'مشتریان سازمانی و مجموعه‌های چندشعبه‌ای', 8, N'Active', N'2018-01-01', NULL),
        (N'SEG08', N'مشتری کم‌تکرار', NULL, NULL, NULL, N'سناریوی مشتری با خرید کم‌تکرار؛ برای داده تاریخی', 10, N'Inactive', N'2018-01-01', N'2024-12-31')
    ) v (Segment_Code, Segment_Name, Segment_Type, Segment_Level, Segment_Criteria, Segment_Description, Priority, Segment_Status, Created_Date, End_Date)
    ORDER BY Segment_Code;

    INSERT INTO ref.SalesChannel (Sales_Channel_Code, Sales_Channel_Name, Sales_Channel_Type, Channel_Status, Campaign_Name)
    SELECT Sales_Channel_Code, Sales_Channel_Name, Sales_Channel_Type, Channel_Status, Campaign_Name
    FROM (VALUES
        (N'CH01', N'ویزیتوری', N'Field Sales', N'Active', NULL),
        (N'CH02', N'تلفنی', N'Tele Sales', N'Active', NULL),
        (N'CH03', N'آنلاین', N'Online', N'Active', NULL),
        (N'CH04', N'عمده', N'Wholesale', N'Active', NULL),
        (N'CH05', N'سفارش مستقیم', N'Direct', N'Active', NULL),
        (N'CH06', N'نمایندگی', N'Agency', N'Active', NULL)
    ) v (Sales_Channel_Code, Sales_Channel_Name, Sales_Channel_Type, Channel_Status, Campaign_Name)
    ORDER BY Sales_Channel_Code;

    SELECT * INTO #RegionStg
    FROM (VALUES
        (NULL, N'SR001', N'منطقه کلان شمال', N'Region', N'Active'),
        (NULL, N'SR002', N'منطقه کلان جنوب و مرکز', N'Region', N'Active'),
        (N'SR001', N'SR003', N'ناحیه شمال‌غرب', N'Area', N'Active'),
        (N'SR001', N'SR004', N'ناحیه شمال‌شرق', N'Area', N'Active'),
        (N'SR002', N'SR005', N'ناحیه مرکز', N'Area', N'Active'),
        (N'SR002', N'SR006', N'ناحیه جنوب', N'Area', N'Active'),
        (N'SR003', N'SR007', N'تیم فروش شمال‌غرب', N'Team', N'Active'),
        (N'SR004', N'SR008', N'تیم فروش شمال‌شرق', N'Team', N'Active'),
        (N'SR005', N'SR009', N'تیم فروش تهران و مرکز', N'Team', N'Active'),
        (N'SR006', N'SR010', N'تیم فروش جنوب', N'Team', N'Active')
    ) v (Parent_Region_Code, Sales_Region_Code, Sales_Region_Name, Region_Level, Region_Status);

    INSERT INTO ref.SalesRegion (Parent_Sales_Region_ID, Sales_Region_Code, Sales_Region_Name, Region_Level, Region_Status)
    SELECT NULL, s.Sales_Region_Code, s.Sales_Region_Name, s.Region_Level, s.Region_Status
    FROM #RegionStg s WHERE s.Parent_Region_Code IS NULL ORDER BY s.Sales_Region_Code;

    INSERT INTO ref.SalesRegion (Parent_Sales_Region_ID, Sales_Region_Code, Sales_Region_Name, Region_Level, Region_Status)
    SELECT pr.Sales_Region_ID, s.Sales_Region_Code, s.Sales_Region_Name, s.Region_Level, s.Region_Status
    FROM #RegionStg s JOIN ref.SalesRegion pr ON pr.Sales_Region_Code = s.Parent_Region_Code
    WHERE s.Region_Level = N'Area' ORDER BY s.Sales_Region_Code;

    INSERT INTO ref.SalesRegion (Parent_Sales_Region_ID, Sales_Region_Code, Sales_Region_Name, Region_Level, Region_Status)
    SELECT pr.Sales_Region_ID, s.Sales_Region_Code, s.Sales_Region_Name, s.Region_Level, s.Region_Status
    FROM #RegionStg s JOIN ref.SalesRegion pr ON pr.Sales_Region_Code = s.Parent_Region_Code
    WHERE s.Region_Level = N'Team' ORDER BY s.Sales_Region_Code;

    INSERT INTO ref.SalesTerritory (Territory_Code, Territory_Name, Territory_Type, Territory_Manager_Name, Route_Code, Route_Name, Visit_Frequency, Territory_Status)
    SELECT Territory_Code, Territory_Name, Territory_Type, Territory_Manager_Name, Route_Code, Route_Name, Visit_Frequency, Territory_Status
    FROM (VALUES
        (N'TR001', N'قلمرو تهران - مرکز', NULL, N'سرپرست مسیر تهران 1', N'RT001', N'مسیر مرکز تهران', 2, N'Active'),
        (N'TR002', N'قلمرو تهران - شمال', NULL, N'سرپرست مسیر تهران 2', N'RT002', N'مسیر شمال تهران', 3, N'Active'),
        (N'TR003', N'قلمرو تهران - جنوب', NULL, N'سرپرست مسیر تهران 3', N'RT003', N'مسیر جنوب تهران', 4, N'Active'),
        (N'TR004', N'قلمرو تهران - شرق', NULL, N'سرپرست مسیر تهران 4', N'RT004', N'مسیر شرق تهران', 5, N'Active'),
        (N'TR005', N'قلمرو تهران - غرب', NULL, N'سرپرست مسیر تهران 5', N'RT005', N'مسیر غرب تهران', 6, N'Active'),
        (N'TR006', N'قلمرو مشهد - مرکز', NULL, N'سرپرست مسیر مشهد 1', N'RT006', N'مسیر مرکز مشهد', 2, N'Active'),
        (N'TR007', N'قلمرو مشهد - شمال', NULL, N'سرپرست مسیر مشهد 2', N'RT007', N'مسیر شمال مشهد', 3, N'Active'),
        (N'TR008', N'قلمرو مشهد - جنوب', NULL, N'سرپرست مسیر مشهد 3', N'RT008', N'مسیر جنوب مشهد', 4, N'Active'),
        (N'TR009', N'قلمرو مشهد - شرق', NULL, N'سرپرست مسیر مشهد 4', N'RT009', N'مسیر شرق مشهد', 5, N'Active'),
        (N'TR010', N'قلمرو مشهد - غرب', NULL, N'سرپرست مسیر مشهد 5', N'RT010', N'مسیر غرب مشهد', 6, N'Active'),
        (N'TR011', N'قلمرو اصفهان - مرکز', NULL, N'سرپرست مسیر اصفهان 1', N'RT011', N'مسیر مرکز اصفهان', 2, N'Active'),
        (N'TR012', N'قلمرو اصفهان - شمال', NULL, N'سرپرست مسیر اصفهان 2', N'RT012', N'مسیر شمال اصفهان', 3, N'Active'),
        (N'TR013', N'قلمرو اصفهان - جنوب', NULL, N'سرپرست مسیر اصفهان 3', N'RT013', N'مسیر جنوب اصفهان', 4, N'Active'),
        (N'TR014', N'قلمرو اصفهان - شرق', NULL, N'سرپرست مسیر اصفهان 4', N'RT014', N'مسیر شرق اصفهان', 5, N'Active'),
        (N'TR015', N'قلمرو اصفهان - غرب', NULL, N'سرپرست مسیر اصفهان 5', N'RT015', N'مسیر غرب اصفهان', 6, N'Active'),
        (N'TR016', N'قلمرو شیراز - مرکز', NULL, N'سرپرست مسیر شیراز 1', N'RT016', N'مسیر مرکز شیراز', 2, N'Active'),
        (N'TR017', N'قلمرو شیراز - شمال', NULL, N'سرپرست مسیر شیراز 2', N'RT017', N'مسیر شمال شیراز', 3, N'Active'),
        (N'TR018', N'قلمرو شیراز - جنوب', NULL, N'سرپرست مسیر شیراز 3', N'RT018', N'مسیر جنوب شیراز', 4, N'Active'),
        (N'TR019', N'قلمرو شیراز - شرق', NULL, N'سرپرست مسیر شیراز 4', N'RT019', N'مسیر شرق شیراز', 5, N'Active'),
        (N'TR020', N'قلمرو شیراز - غرب', NULL, N'سرپرست مسیر شیراز 5', N'RT020', N'مسیر غرب شیراز', 6, N'Active'),
        (N'TR021', N'قلمرو تبریز - مرکز', NULL, N'سرپرست مسیر تبریز 1', N'RT021', N'مسیر مرکز تبریز', 2, N'Active'),
        (N'TR022', N'قلمرو تبریز - شمال', NULL, N'سرپرست مسیر تبریز 2', N'RT022', N'مسیر شمال تبریز', 3, N'Active'),
        (N'TR023', N'قلمرو تبریز - جنوب', NULL, N'سرپرست مسیر تبریز 3', N'RT023', N'مسیر جنوب تبریز', 4, N'Active'),
        (N'TR024', N'قلمرو تبریز - شرق', NULL, N'سرپرست مسیر تبریز 4', N'RT024', N'مسیر شرق تبریز', 5, N'Active'),
        (N'TR025', N'قلمرو تبریز - غرب', NULL, N'سرپرست مسیر تبریز 5', N'RT025', N'مسیر غرب تبریز', 6, N'Active'),
        (N'TR026', N'قلمرو کرج - مرکز', NULL, N'سرپرست مسیر کرج 1', N'RT026', N'مسیر مرکز کرج', 2, N'Active'),
        (N'TR027', N'قلمرو کرج - شمال', NULL, N'سرپرست مسیر کرج 2', N'RT027', N'مسیر شمال کرج', 3, N'Active'),
        (N'TR028', N'قلمرو کرج - جنوب', NULL, N'سرپرست مسیر کرج 3', N'RT028', N'مسیر جنوب کرج', 4, N'Active'),
        (N'TR029', N'قلمرو کرج - شرق', NULL, N'سرپرست مسیر کرج 4', N'RT029', N'مسیر شرق کرج', 5, N'Active'),
        (N'TR030', N'قلمرو کرج - غرب', NULL, N'سرپرست مسیر کرج 5', N'RT030', N'مسیر غرب کرج', 6, N'Active'),
        (N'TR031', N'قلمرو اهواز - مرکز', NULL, N'سرپرست مسیر اهواز 1', N'RT031', N'مسیر مرکز اهواز', 2, N'Active'),
        (N'TR032', N'قلمرو اهواز - شمال', NULL, N'سرپرست مسیر اهواز 2', N'RT032', N'مسیر شمال اهواز', 3, N'Active'),
        (N'TR033', N'قلمرو اهواز - جنوب', NULL, N'سرپرست مسیر اهواز 3', N'RT033', N'مسیر جنوب اهواز', 4, N'Active'),
        (N'TR034', N'قلمرو اهواز - شرق', NULL, N'سرپرست مسیر اهواز 4', N'RT034', N'مسیر شرق اهواز', 5, N'Active'),
        (N'TR035', N'قلمرو اهواز - غرب', NULL, N'سرپرست مسیر اهواز 5', N'RT035', N'مسیر غرب اهواز', 6, N'Active'),
        (N'TR036', N'قلمرو رشت - مرکز', NULL, N'سرپرست مسیر رشت 1', N'RT036', N'مسیر مرکز رشت', 2, N'Active'),
        (N'TR037', N'قلمرو رشت - شمال', NULL, N'سرپرست مسیر رشت 2', N'RT037', N'مسیر شمال رشت', 3, N'Active'),
        (N'TR038', N'قلمرو رشت - جنوب', NULL, N'سرپرست مسیر رشت 3', N'RT038', N'مسیر جنوب رشت', 4, N'Active'),
        (N'TR039', N'قلمرو رشت - شرق', NULL, N'سرپرست مسیر رشت 4', N'RT039', N'مسیر شرق رشت', 5, N'Active'),
        (N'TR040', N'قلمرو رشت - غرب', NULL, N'سرپرست مسیر رشت 5', N'RT040', N'مسیر غرب رشت', 6, N'Active'),
        (N'TR041', N'قلمرو قم - مرکز', NULL, N'سرپرست مسیر قم 1', N'RT041', N'مسیر مرکز قم', 2, N'Active'),
        (N'TR042', N'قلمرو قم - شمال', NULL, N'سرپرست مسیر قم 2', N'RT042', N'مسیر شمال قم', 3, N'Active'),
        (N'TR043', N'قلمرو قم - جنوب', NULL, N'سرپرست مسیر قم 3', N'RT043', N'مسیر جنوب قم', 4, N'Active'),
        (N'TR044', N'قلمرو قم - شرق', NULL, N'سرپرست مسیر قم 4', N'RT044', N'مسیر شرق قم', 5, N'Active'),
        (N'TR045', N'قلمرو قم - غرب', NULL, N'سرپرست مسیر قم 5', N'RT045', N'مسیر غرب قم', 6, N'Active'),
        (N'TR046', N'قلمرو کرمان - مرکز', NULL, N'سرپرست مسیر کرمان 1', N'RT046', N'مسیر مرکز کرمان', 2, N'Active'),
        (N'TR047', N'قلمرو کرمان - شمال', NULL, N'سرپرست مسیر کرمان 2', N'RT047', N'مسیر شمال کرمان', 3, N'Active'),
        (N'TR048', N'قلمرو کرمان - جنوب', NULL, N'سرپرست مسیر کرمان 3', N'RT048', N'مسیر جنوب کرمان', 4, N'Active'),
        (N'TR049', N'قلمرو کرمان - شرق', NULL, N'سرپرست مسیر کرمان 4', N'RT049', N'مسیر شرق کرمان', 5, N'Active'),
        (N'TR050', N'قلمرو کرمان - غرب', NULL, N'سرپرست مسیر کرمان 5', N'RT050', N'مسیر غرب کرمان', 6, N'Active')
    ) v (Territory_Code, Territory_Name, Territory_Type, Territory_Manager_Name, Route_Code, Route_Name, Visit_Frequency, Territory_Status)
    ORDER BY Territory_Code;


    /* Validation - all checks execute before COMMIT. */
    IF (SELECT COUNT(*) FROM ref.Province) <> 31
       OR (SELECT COUNT(*) FROM ref.City) <> 300
       OR (SELECT COUNT(*) FROM ref.CustomerSegment) <> 8
       OR (SELECT COUNT(*) FROM ref.SalesChannel) <> 6
       OR (SELECT COUNT(*) FROM ref.SalesRegion) <> 10
       OR (SELECT COUNT(*) FROM ref.SalesTerritory) <> 50
        THROW 51002, 'Reference table row-count validation failed.', 1;

    IF EXISTS (SELECT Province_Code FROM ref.Province GROUP BY Province_Code HAVING COUNT(*) > 1)
       OR EXISTS (SELECT Province_Name FROM ref.Province GROUP BY Province_Name HAVING COUNT(*) > 1)
       OR EXISTS (SELECT City_Code FROM ref.City GROUP BY City_Code HAVING COUNT(*) > 1)
       OR EXISTS (SELECT Segment_Code FROM ref.CustomerSegment GROUP BY Segment_Code HAVING COUNT(*) > 1)
       OR EXISTS (SELECT Sales_Channel_Code FROM ref.SalesChannel GROUP BY Sales_Channel_Code HAVING COUNT(*) > 1)
       OR EXISTS (SELECT Sales_Region_Code FROM ref.SalesRegion GROUP BY Sales_Region_Code HAVING COUNT(*) > 1)
       OR EXISTS (SELECT Territory_Code FROM ref.SalesTerritory GROUP BY Territory_Code HAVING COUNT(*) > 1)
        THROW 51003, 'Duplicate reference code/name detected.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM ref.City c
        LEFT JOIN ref.Province p ON p.Province_ID = c.Province_ID
        WHERE p.Province_ID IS NULL
    )
        THROW 51004, 'City references a missing Province.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM ref.City d
        LEFT JOIN ref.City p ON p.City_ID = d.Parent_City_ID
        WHERE d.Parent_City_ID IS NOT NULL
          AND (p.City_ID IS NULL OR p.City_Level <> N'City'
               OR p.Province_ID <> d.Province_ID OR d.City_Level <> N'District')
    )
        THROW 51005, 'District parent must be a City in the same Province.', 1;

    IF EXISTS
    (
        SELECT 1 FROM ref.SalesRegion child
        LEFT JOIN ref.SalesRegion parent
          ON parent.Sales_Region_ID = child.Parent_Sales_Region_ID
        WHERE (child.Region_Level = N'Region' AND child.Parent_Sales_Region_ID IS NOT NULL)
           OR (child.Region_Level = N'Area' AND ISNULL(parent.Region_Level,N'') <> N'Region')
           OR (child.Region_Level = N'Team' AND ISNULL(parent.Region_Level,N'') <> N'Area')
           OR (child.Region_Level IN (N'Area',N'Team') AND parent.Sales_Region_ID IS NULL)
    )
        THROW 51006, 'SalesRegion hierarchy levels are inconsistent.', 1;

    IF EXISTS (SELECT 1 FROM ref.SalesTerritory WHERE Visit_Frequency <= 0)
        THROW 51007, 'Visit_Frequency must be greater than zero.', 1;

    IF EXISTS (SELECT 1 FROM ref.CustomerSegment
               WHERE Created_Date IS NOT NULL AND End_Date IS NOT NULL AND End_Date < Created_Date)
        THROW 51008, 'CustomerSegment date range is invalid.', 1;


    COMMIT TRANSACTION;
    INSERT INTO #T1Log VALUES (N'8.1a', N'ref.* (6 tables)', (SELECT COUNT(*) FROM ref.Province)+(SELECT COUNT(*) FROM ref.City)+(SELECT COUNT(*) FROM ref.CustomerSegment)+(SELECT COUNT(*) FROM ref.SalesChannel)+(SELECT COUNT(*) FROM ref.SalesRegion)+(SELECT COUNT(*) FROM ref.SalesTerritory));
    PRINT CONCAT(N'8.1a Reference inserted: Province=', (SELECT COUNT(*) FROM ref.Province), N' City=', (SELECT COUNT(*) FROM ref.City),
                 N' Segment=', (SELECT COUNT(*) FROM ref.CustomerSegment), N' Channel=', (SELECT COUNT(*) FROM ref.SalesChannel),
                 N' Region=', (SELECT COUNT(*) FROM ref.SalesRegion), N' Territory=', (SELECT COUNT(*) FROM ref.SalesTerritory));
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    UPDATE #T1Cfg SET Abort = 1;
    PRINT CONCAT(N'ERROR ', ERROR_NUMBER(), N' | LINE ', ERROR_LINE(), N' | ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO


/* ===================== SECTION 2 : 8.1 Calendar, Branch, Salesperson ======= */
SET NOCOUNT ON; SET XACT_ABORT ON;
IF EXISTS (SELECT 1 FROM #T1Cfg WHERE Abort = 1) BEGIN PRINT N'SKIPPED section 2 (earlier failure)'; RETURN; END;
DECLARE @StartDate DATE, @EndDate DATE, @ExpectedCalendarCount INT = 2922;
SELECT @StartDate = FromDate, @EndDate = ToDate FROM #T1Cfg;
BEGIN TRY
    IF OBJECT_ID(N'core.Calendar',N'U') IS NULL OR OBJECT_ID(N'core.Branch',N'U') IS NULL
       OR OBJECT_ID(N'core.Salesperson',N'U') IS NULL OR OBJECT_ID(N'ref.SalesRegion',N'U') IS NULL
        THROW 51100, 'One or more required tables do not exist.', 1;
    IF DATEDIFF(DAY,@StartDate,@EndDate)+1 <> @ExpectedCalendarCount
        THROW 51102, 'Calendar date range does not contain 2,922 days.', 1;
    DROP TABLE IF EXISTS #CalendarSource, #SpStg;
    BEGIN TRANSACTION;

    /* Gregorian columns (CK_Calendar_Calendar_Date); Week_Number = ISO week (OI-18 still open). */
    ;WITH DateSequence AS
    (
        SELECT @StartDate AS Calendar_Date
        UNION ALL
        SELECT DATEADD(DAY,1,Calendar_Date) FROM DateSequence WHERE Calendar_Date < @EndDate
    )
    SELECT Calendar_Date, DAY(Calendar_Date) AS Day_Number, MONTH(Calendar_Date) AS Month_Number,
           DATEPART(QUARTER,Calendar_Date) AS Quarter_Number, DATEPART(ISO_WEEK,Calendar_Date) AS Week_Number,
           YEAR(Calendar_Date) AS Year_Number
    INTO #CalendarSource
    FROM DateSequence
    OPTION (MAXRECURSION 0);

    IF (SELECT COUNT(*) FROM #CalendarSource) <> @ExpectedCalendarCount
        THROW 51103, 'Calendar staging row count validation failed.', 1;

    INSERT INTO core.Calendar (Calendar_Date,Day_Number,Month_Number,Quarter_Number,Week_Number,Year_Number)
    SELECT Calendar_Date,Day_Number,Month_Number,Quarter_Number,Week_Number,Year_Number
    FROM #CalendarSource ORDER BY Calendar_Date;

    INSERT INTO core.Branch (Sales_Region_ID, Branch_Code, Branch_Name, Branch_Status)
    SELECT r.Sales_Region_ID, v.Branch_Code, v.Branch_Name, v.Branch_Status
    FROM (VALUES
        (N'SR009', N'BR001', N'شعبه تهران - مرکزی', N'Active'),
        (N'SR009', N'BR002', N'شعبه مشهد - شرق', N'Active'),
        (N'SR009', N'BR003', N'شعبه اصفهان - غرب', N'Active'),
        (N'SR009', N'BR004', N'شعبه شیراز - مرکزی', N'Active'),
        (N'SR009', N'BR005', N'شعبه تبریز - شرق', N'Active'),
        (N'SR009', N'BR006', N'شعبه کرج - غرب', N'Active'),
        (N'SR009', N'BR007', N'شعبه اهواز - مرکزی', N'Active'),
        (N'SR008', N'BR008', N'شعبه رشت - شرق', N'Active'),
        (N'SR008', N'BR009', N'شعبه قم - غرب', N'Active'),
        (N'SR008', N'BR010', N'شعبه کرمان - مرکزی', N'Active'),
        (N'SR008', N'BR011', N'شعبه اراک - شرق', N'Active'),
        (N'SR007', N'BR012', N'شعبه یزد - غرب', N'Active'),
        (N'SR007', N'BR013', N'شعبه قزوین - مرکزی', N'Active'),
        (N'SR007', N'BR014', N'شعبه ساری - شرق', N'Active'),
        (N'SR007', N'BR015', N'شعبه بندرعباس - غرب', N'Active'),
        (N'SR010', N'BR016', N'شعبه همدان - مرکزی', N'Active'),
        (N'SR010', N'BR017', N'شعبه سنندج - شرق', N'Active'),
        (N'SR010', N'BR018', N'شعبه اردبیل - غرب', N'Active'),
        (N'SR010', N'BR019', N'شعبه زنجان - مرکزی', N'Inactive'),
        (N'SR010', N'BR020', N'شعبه بوشهر - شرق', N'Inactive')
    ) v (Region_Code, Branch_Code, Branch_Name, Branch_Status)
    JOIN ref.SalesRegion r ON r.Sales_Region_Code = v.Region_Code
    ORDER BY v.Branch_Code;

    SELECT * INTO #SpStg
    FROM (VALUES
        (0, N'BR001', NULL, N'SP0001', N'بردیا بهرامی', N'Manager', N'Active', N'2018-05-19', N'sp001@example.com', N'000-555-0001'),
        (0, N'BR004', NULL, N'SP0002', N'کیان فرهی', N'Manager', N'Active', N'2018-05-09', N'sp002@example.com', N'000-555-0002'),
        (0, N'BR008', NULL, N'SP0003', N'مریم کیانی', N'Manager', N'Active', N'2018-03-02', N'sp003@example.com', N'000-555-0003'),
        (0, N'BR011', NULL, N'SP0004', N'بهاره شایسته', N'Manager', N'Active', N'2018-07-31', N'sp004@example.com', N'000-555-0004'),
        (0, N'BR014', NULL, N'SP0005', N'هومن آرمان‌خواه', N'Manager', N'Active', N'2017-03-02', N'sp005@example.com', N'000-555-0005'),
        (0, N'BR016', NULL, N'SP0006', N'یاسین شایسته', N'Manager', N'Active', N'2017-05-14', N'sp006@example.com', N'000-555-0006'),
        (0, N'BR018', NULL, N'SP0007', N'آریا نیک‌پی', N'Manager', N'Active', N'2018-01-12', N'sp007@example.com', N'000-555-0007'),
        (0, N'BR020', NULL, N'SP0008', N'نازنین شایسته', N'Manager', N'Active', N'2018-03-04', N'sp008@example.com', N'000-555-0008'),
        (1, N'BR001', N'SP0001', N'SP0009', N'ترانه پویان', N'Sales Supervisor', N'Active', N'2020-12-01', N'sp009@example.com', N'000-555-0009'),
        (1, N'BR002', N'SP0001', N'SP0010', N'ماهان نصیری', N'Sales Supervisor', N'Active', N'2018-11-08', N'sp010@example.com', N'000-555-0010'),
        (1, N'BR003', N'SP0001', N'SP0011', N'آریا دادگر', N'Sales Supervisor', N'Active', N'2019-10-15', N'sp011@example.com', N'000-555-0011'),
        (1, N'BR004', N'SP0002', N'SP0012', N'پویا سروش‌نیا', N'Sales Supervisor', N'Active', N'2020-10-02', N'sp012@example.com', N'000-555-0012'),
        (1, N'BR005', N'SP0002', N'SP0013', N'سامان نصیری', N'Sales Supervisor', N'Active', N'2020-12-11', N'sp013@example.com', N'000-555-0013'),
        (1, N'BR006', N'SP0002', N'SP0014', N'آیدا نیک‌پی', N'Sales Supervisor', N'Active', N'2018-10-01', N'sp014@example.com', N'000-555-0014'),
        (1, N'BR007', N'SP0003', N'SP0015', N'آریا رستگار', N'Sales Supervisor', N'Active', N'2019-02-09', N'sp015@example.com', N'000-555-0015'),
        (1, N'BR008', N'SP0003', N'SP0016', N'مریم نصیری', N'Sales Supervisor', N'Active', N'2020-04-08', N'sp016@example.com', N'000-555-0016'),
        (1, N'BR009', N'SP0003', N'SP0017', N'رها کیانی', N'Sales Supervisor', N'Active', N'2018-09-05', N'sp017@example.com', N'000-555-0017'),
        (1, N'BR010', N'SP0004', N'SP0018', N'رها ساعی', N'Sales Supervisor', N'Active', N'2019-01-30', N'sp018@example.com', N'000-555-0018'),
        (1, N'BR011', N'SP0004', N'SP0019', N'هومن رادمنش', N'Sales Supervisor', N'Active', N'2018-09-04', N'sp019@example.com', N'000-555-0019'),
        (1, N'BR012', N'SP0004', N'SP0020', N'یاسین مقدم', N'Sales Supervisor', N'Active', N'2018-12-16', N'sp020@example.com', N'000-555-0020'),
        (1, N'BR013', N'SP0005', N'SP0021', N'غزل کیانی', N'Sales Supervisor', N'Active', N'2019-11-26', N'sp021@example.com', N'000-555-0021'),
        (1, N'BR014', N'SP0005', N'SP0022', N'شایان یوسفی', N'Sales Supervisor', N'Active', N'2020-04-30', N'sp022@example.com', N'000-555-0022'),
        (1, N'BR015', N'SP0005', N'SP0023', N'بهاره رادمنش', N'Sales Supervisor', N'Active', N'2019-01-12', N'sp023@example.com', N'000-555-0023'),
        (1, N'BR016', N'SP0006', N'SP0024', N'یگانه نصیری', N'Sales Supervisor', N'Active', N'2018-07-25', N'sp024@example.com', N'000-555-0024'),
        (1, N'BR017', N'SP0006', N'SP0025', N'شایان نصیری', N'Sales Supervisor', N'Active', N'2018-05-16', N'sp025@example.com', N'000-555-0025'),
        (1, N'BR018', N'SP0006', N'SP0026', N'نیما فروتن', N'Sales Supervisor', N'Active', N'2018-09-14', N'sp026@example.com', N'000-555-0026'),
        (1, N'BR019', N'SP0007', N'SP0027', N'آرمان کیانی', N'Sales Supervisor', N'Active', N'2018-12-26', N'sp027@example.com', N'000-555-0027'),
        (1, N'BR020', N'SP0007', N'SP0028', N'سروش نیک‌روش', N'Sales Supervisor', N'Active', N'2018-03-20', N'sp028@example.com', N'000-555-0028'),
        (2, N'BR001', N'SP0009', N'SP0029', N'مریم مهرجو', N'Senior Sales Representative', N'Active', N'2021-11-01', N'sp029@example.com', N'000-555-0029'),
        (2, N'BR002', N'SP0010', N'SP0030', N'سروش جهانگیری', N'Senior Sales Representative', N'Active', N'2020-11-30', N'sp030@example.com', N'000-555-0030'),
        (2, N'BR003', N'SP0011', N'SP0031', N'پریناز جهانگیری', N'Senior Sales Representative', N'Active', N'2021-12-19', N'sp031@example.com', N'000-555-0031'),
        (2, N'BR004', N'SP0012', N'SP0032', N'مهراد رادمنش', N'Senior Sales Representative', N'Active', N'2022-08-23', N'sp032@example.com', N'000-555-0032'),
        (2, N'BR005', N'SP0013', N'SP0033', N'سینا کاشانی', N'Senior Sales Representative', N'Active', N'2021-07-28', N'sp033@example.com', N'000-555-0033'),
        (2, N'BR006', N'SP0014', N'SP0034', N'یاسین دادخواه', N'Senior Sales Representative', N'Active', N'2022-08-01', N'sp034@example.com', N'000-555-0034'),
        (2, N'BR007', N'SP0015', N'SP0035', N'ترانه رادمنش', N'Senior Sales Representative', N'Active', N'2020-01-21', N'sp035@example.com', N'000-555-0035'),
        (2, N'BR008', N'SP0016', N'SP0036', N'مهراد کیانی', N'Senior Sales Representative', N'Active', N'2023-04-16', N'sp036@example.com', N'000-555-0036'),
        (2, N'BR009', N'SP0017', N'SP0037', N'آتنا ساعی', N'Senior Sales Representative', N'Active', N'2020-09-21', N'sp037@example.com', N'000-555-0037'),
        (2, N'BR010', N'SP0018', N'SP0038', N'مهسا شریفی', N'Senior Sales Representative', N'Active', N'2019-01-31', N'sp038@example.com', N'000-555-0038'),
        (2, N'BR011', N'SP0019', N'SP0039', N'پریناز یوسفی', N'Senior Sales Representative', N'Active', N'2023-02-04', N'sp039@example.com', N'000-555-0039'),
        (2, N'BR012', N'SP0020', N'SP0040', N'امیرعلی سروش‌نیا', N'Senior Sales Representative', N'Active', N'2020-08-14', N'sp040@example.com', N'000-555-0040'),
        (2, N'BR013', N'SP0021', N'SP0041', N'سینا شایسته', N'Senior Sales Representative', N'Active', N'2023-03-17', N'sp041@example.com', N'000-555-0041'),
        (2, N'BR014', N'SP0022', N'SP0042', N'آیدا کیانی', N'Senior Sales Representative', N'Active', N'2021-04-08', N'sp042@example.com', N'000-555-0042'),
        (2, N'BR015', N'SP0023', N'SP0043', N'مانی سپهر', N'Senior Sales Representative', N'Active', N'2021-04-25', N'sp043@example.com', N'000-555-0043'),
        (2, N'BR016', N'SP0024', N'SP0044', N'غزل آذری', N'Senior Sales Representative', N'Active', N'2020-01-28', N'sp044@example.com', N'000-555-0044'),
        (2, N'BR017', N'SP0025', N'SP0045', N'مهراد نصیری', N'Senior Sales Representative', N'Active', N'2020-03-14', N'sp045@example.com', N'000-555-0045'),
        (2, N'BR018', N'SP0026', N'SP0046', N'اشکان مقدم', N'Senior Sales Representative', N'Active', N'2022-10-21', N'sp046@example.com', N'000-555-0046'),
        (2, N'BR019', N'SP0027', N'SP0047', N'رادین نیک‌پی', N'Senior Sales Representative', N'Active', N'2021-09-29', N'sp047@example.com', N'000-555-0047'),
        (2, N'BR020', N'SP0028', N'SP0048', N'شایان آذری', N'Senior Sales Representative', N'Active', N'2022-02-18', N'sp048@example.com', N'000-555-0048'),
        (2, N'BR001', N'SP0009', N'SP0049', N'مانی نیک‌پی', N'Senior Sales Representative', N'Active', N'2021-05-03', N'sp049@example.com', N'000-555-0049'),
        (2, N'BR002', N'SP0010', N'SP0050', N'هلیا نیک‌روش', N'Senior Sales Representative', N'Active', N'2021-03-16', N'sp050@example.com', N'000-555-0050'),
        (2, N'BR003', N'SP0011', N'SP0051', N'سامان آزاد', N'Senior Sales Representative', N'Active', N'2021-05-26', N'sp051@example.com', N'000-555-0051'),
        (2, N'BR004', N'SP0012', N'SP0052', N'ترانه کاشانی', N'Senior Sales Representative', N'Active', N'2021-03-29', N'sp052@example.com', N'000-555-0052'),
        (2, N'BR005', N'SP0013', N'SP0053', N'مانی دادگر', N'Senior Sales Representative', N'Active', N'2021-01-13', N'sp053@example.com', N'000-555-0053'),
        (2, N'BR006', N'SP0014', N'SP0054', N'آیدا نیک‌روش', N'Senior Sales Representative', N'Active', N'2022-04-30', N'sp054@example.com', N'000-555-0054'),
        (2, N'BR007', N'SP0015', N'SP0055', N'ستاره کاشانی', N'Senior Sales Representative', N'Inactive', N'2020-02-19', N'sp055@example.com', N'000-555-0055'),
        (2, N'BR008', N'SP0016', N'SP0056', N'آرمان دادخواه', N'Senior Sales Representative', N'Active', N'2020-10-13', N'sp056@example.com', N'000-555-0056'),
        (2, N'BR009', N'SP0017', N'SP0057', N'نازنین دادخواه', N'Senior Sales Representative', N'Active', N'2022-05-03', N'sp057@example.com', N'000-555-0057'),
        (2, N'BR010', N'SP0018', N'SP0058', N'ریحانه مقدم', N'Senior Sales Representative', N'Active', N'2023-04-22', N'sp058@example.com', N'000-555-0058'),
        (2, N'BR011', N'SP0019', N'SP0059', N'ترانه آذری', N'Senior Sales Representative', N'Active', N'2021-07-12', N'sp059@example.com', N'000-555-0059'),
        (2, N'BR012', N'SP0020', N'SP0060', N'پویا امینی', N'Senior Sales Representative', N'Active', N'2021-03-10', N'sp060@example.com', N'000-555-0060'),
        (2, N'BR001', N'SP0009', N'SP0061', N'رها نیکنام', N'Sales Representative', N'Active', N'2023-06-15', N'sp061@example.com', N'000-555-0061'),
        (2, N'BR002', N'SP0010', N'SP0062', N'نگار امینی', N'Sales Representative', N'Active', N'2021-02-01', N'sp062@example.com', N'000-555-0062'),
        (2, N'BR003', N'SP0011', N'SP0063', N'مانی آذری', N'Sales Representative', N'Active', N'2020-03-05', N'sp063@example.com', N'000-555-0063'),
        (2, N'BR004', N'SP0012', N'SP0064', N'الناز سروش‌نیا', N'Sales Representative', N'Active', N'2021-03-25', N'sp064@example.com', N'000-555-0064'),
        (2, N'BR005', N'SP0013', N'SP0065', N'پویا نیک‌پی', N'Sales Representative', N'Active', N'2022-12-18', N'sp065@example.com', N'000-555-0065'),
        (2, N'BR006', N'SP0014', N'SP0066', N'شایان مهرآیین', N'Sales Representative', N'Active', N'2021-03-30', N'sp066@example.com', N'000-555-0066'),
        (2, N'BR007', N'SP0015', N'SP0067', N'بهاره یوسفی', N'Sales Representative', N'On Leave', N'2020-02-12', N'sp067@example.com', N'000-555-0067'),
        (2, N'BR008', N'SP0016', N'SP0068', N'آرمان نیک‌روش', N'Sales Representative', N'Active', N'2022-06-28', N'sp068@example.com', N'000-555-0068'),
        (2, N'BR009', N'SP0017', N'SP0069', N'امیرعلی فرهی', N'Sales Representative', N'Active', N'2022-07-20', N'sp069@example.com', N'000-555-0069'),
        (2, N'BR010', N'SP0018', N'SP0070', N'سارا رستگار', N'Sales Representative', N'Active', N'2021-11-24', N'sp070@example.com', N'000-555-0070'),
        (2, N'BR011', N'SP0019', N'SP0071', N'نازنین شریفی', N'Sales Representative', N'Active', N'2024-03-09', N'sp071@example.com', N'000-555-0071'),
        (2, N'BR012', N'SP0020', N'SP0072', N'آوا رستگار', N'Sales Representative', N'Active', N'2024-04-03', N'sp072@example.com', N'000-555-0072'),
        (2, N'BR013', N'SP0021', N'SP0073', N'بردیا پویان', N'Sales Representative', N'Inactive', N'2020-10-28', N'sp073@example.com', N'000-555-0073'),
        (2, N'BR014', N'SP0022', N'SP0074', N'غزل جهانگیری', N'Sales Representative', N'Active', N'2024-09-08', N'sp074@example.com', N'000-555-0074'),
        (2, N'BR015', N'SP0023', N'SP0075', N'ریحانه نیک‌روش', N'Sales Representative', N'Active', N'2023-08-02', N'sp075@example.com', N'000-555-0075'),
        (2, N'BR016', N'SP0024', N'SP0076', N'پویا فرهی', N'Sales Representative', N'Active', N'2019-12-09', N'sp076@example.com', N'000-555-0076'),
        (2, N'BR017', N'SP0025', N'SP0077', N'نرگس نیکنام', N'Sales Representative', N'Active', N'2022-04-24', N'sp077@example.com', N'000-555-0077'),
        (2, N'BR018', N'SP0026', N'SP0078', N'نوید امینی', N'Sales Representative', N'Active', N'2019-02-02', N'sp078@example.com', N'000-555-0078'),
        (2, N'BR019', N'SP0027', N'SP0079', N'نوید یوسفی', N'Sales Representative', N'Active', N'2019-09-23', N'sp079@example.com', N'000-555-0079'),
        (2, N'BR020', N'SP0028', N'SP0080', N'سینا مهرجو', N'Sales Representative', N'Active', N'2021-08-10', N'sp080@example.com', N'000-555-0080'),
        (2, N'BR001', N'SP0009', N'SP0081', N'ریحانه نصیری', N'Sales Representative', N'Active', N'2022-06-11', N'sp081@example.com', N'000-555-0081'),
        (2, N'BR002', N'SP0010', N'SP0082', N'امیرعلی دادخواه', N'Sales Representative', N'Active', N'2021-04-01', N'sp082@example.com', N'000-555-0082'),
        (2, N'BR003', N'SP0011', N'SP0083', N'هومن ساعی', N'Sales Representative', N'Active', N'2020-08-06', N'sp083@example.com', N'000-555-0083'),
        (2, N'BR004', N'SP0012', N'SP0084', N'ستاره فرهی', N'Sales Representative', N'Active', N'2021-02-14', N'sp084@example.com', N'000-555-0084'),
        (2, N'BR005', N'SP0013', N'SP0085', N'نوید آرمان‌خواه', N'Sales Representative', N'Active', N'2024-07-10', N'sp085@example.com', N'000-555-0085'),
        (2, N'BR006', N'SP0014', N'SP0086', N'اشکان نیک‌روش', N'Sales Representative', N'Active', N'2023-07-05', N'sp086@example.com', N'000-555-0086'),
        (2, N'BR007', N'SP0015', N'SP0087', N'نرگس فروتن', N'Sales Representative', N'Active', N'2023-07-03', N'sp087@example.com', N'000-555-0087'),
        (2, N'BR008', N'SP0016', N'SP0088', N'یگانه جهانگیری', N'Sales Representative', N'Inactive', N'2020-08-30', N'sp088@example.com', N'000-555-0088'),
        (2, N'BR009', N'SP0017', N'SP0089', N'ترانه فرهی', N'Sales Representative', N'Active', N'2021-09-10', N'sp089@example.com', N'000-555-0089'),
        (2, N'BR010', N'SP0018', N'SP0090', N'شایان کیانی', N'Sales Representative', N'Active', N'2023-03-25', N'sp090@example.com', N'000-555-0090'),
        (2, N'BR011', N'SP0019', N'SP0091', N'آتنا بهرامی', N'Sales Representative', N'Active', N'2022-08-30', N'sp091@example.com', N'000-555-0091'),
        (2, N'BR012', N'SP0020', N'SP0092', N'هانیه یوسفی', N'Sales Representative', N'Active', N'2022-08-16', N'sp092@example.com', N'000-555-0092'),
        (2, N'BR013', N'SP0021', N'SP0093', N'رادین امینی', N'Sales Representative', N'Active', N'2020-06-12', N'sp093@example.com', N'000-555-0093'),
        (2, N'BR014', N'SP0022', N'SP0094', N'مریم آزاد', N'Sales Representative', N'Active', N'2022-07-01', N'sp094@example.com', N'000-555-0094'),
        (2, N'BR015', N'SP0023', N'SP0095', N'هلیا آذری', N'Sales Representative', N'Active', N'2019-12-11', N'sp095@example.com', N'000-555-0095'),
        (2, N'BR016', N'SP0024', N'SP0096', N'مانی یوسفی', N'Sales Representative', N'On Leave', N'2020-05-20', N'sp096@example.com', N'000-555-0096'),
        (2, N'BR017', N'SP0025', N'SP0097', N'آیدا شایسته', N'Sales Representative', N'Active', N'2021-08-24', N'sp097@example.com', N'000-555-0097'),
        (2, N'BR018', N'SP0026', N'SP0098', N'آرمان پارسا', N'Sales Representative', N'Active', N'2022-06-20', N'sp098@example.com', N'000-555-0098'),
        (2, N'BR019', N'SP0027', N'SP0099', N'پویا نیکنام', N'Sales Representative', N'Active', N'2021-01-05', N'sp099@example.com', N'000-555-0099'),
        (2, N'BR020', N'SP0028', N'SP0100', N'شایان فرهمند', N'Sales Representative', N'Active', N'2021-12-05', N'sp100@example.com', N'000-555-0100'),
        (2, N'BR001', N'SP0009', N'SP0101', N'مهراد پویان', N'Sales Representative', N'Active', N'2022-04-10', N'sp101@example.com', N'000-555-0101'),
        (2, N'BR002', N'SP0010', N'SP0102', N'مهسا پویان', N'Sales Representative', N'Active', N'2022-08-17', N'sp102@example.com', N'000-555-0102'),
        (2, N'BR003', N'SP0011', N'SP0103', N'سارا یوسفی', N'Sales Representative', N'Active', N'2020-11-10', N'sp103@example.com', N'000-555-0103'),
        (2, N'BR004', N'SP0012', N'SP0104', N'الناز پویان', N'Sales Representative', N'Inactive', N'2024-06-24', N'sp104@example.com', N'000-555-0104'),
        (2, N'BR005', N'SP0013', N'SP0105', N'هلیا رستگار', N'Sales Representative', N'Active', N'2021-04-26', N'sp105@example.com', N'000-555-0105'),
        (2, N'BR006', N'SP0014', N'SP0106', N'امیرعلی نیک‌پی', N'Sales Representative', N'Active', N'2022-12-04', N'sp106@example.com', N'000-555-0106'),
        (2, N'BR007', N'SP0015', N'SP0107', N'نیما نیک‌پی', N'Sales Representative', N'Active', N'2021-10-01', N'sp107@example.com', N'000-555-0107'),
        (2, N'BR008', N'SP0016', N'SP0108', N'رها فروتن', N'Sales Representative', N'Active', N'2022-01-02', N'sp108@example.com', N'000-555-0108'),
        (2, N'BR009', N'SP0017', N'SP0109', N'آیدا امینی', N'Sales Representative', N'Active', N'2022-03-06', N'sp109@example.com', N'000-555-0109'),
        (2, N'BR010', N'SP0018', N'SP0110', N'مانی فروتن', N'Sales Representative', N'Active', N'2020-11-15', N'sp110@example.com', N'000-555-0110'),
        (2, N'BR011', N'SP0019', N'SP0111', N'یاسین بهرامی', N'Sales Representative', N'Active', N'2020-08-24', N'sp111@example.com', N'000-555-0111'),
        (2, N'BR012', N'SP0020', N'SP0112', N'غزل نیک‌روش', N'Sales Representative', N'On Leave', N'2020-07-29', N'sp112@example.com', N'000-555-0112'),
        (2, N'BR013', N'SP0021', N'SP0113', N'یگانه نیک‌پی', N'Sales Representative', N'Active', N'2024-08-07', N'sp113@example.com', N'000-555-0113'),
        (2, N'BR014', N'SP0022', N'SP0114', N'رادین بهرامی', N'Sales Representative', N'Active', N'2020-11-22', N'sp114@example.com', N'000-555-0114'),
        (2, N'BR015', N'SP0023', N'SP0115', N'مانی فرهی', N'Sales Representative', N'Active', N'2020-06-10', N'sp115@example.com', N'000-555-0115'),
        (2, N'BR016', N'SP0024', N'SP0116', N'غزل دادگر', N'Sales Representative', N'Active', N'2024-01-20', N'sp116@example.com', N'000-555-0116'),
        (2, N'BR017', N'SP0025', N'SP0117', N'مانی رستگار', N'Sales Representative', N'Inactive', N'2022-04-26', N'sp117@example.com', N'000-555-0117'),
        (2, N'BR018', N'SP0026', N'SP0118', N'کیان سروش‌نیا', N'Sales Representative', N'Active', N'2023-02-11', N'sp118@example.com', N'000-555-0118'),
        (2, N'BR019', N'SP0027', N'SP0119', N'ماهان پارسا', N'Sales Representative', N'Active', N'2024-07-01', N'sp119@example.com', N'000-555-0119'),
        (2, N'BR020', N'SP0028', N'SP0120', N'ماهان کیانی', N'Sales Representative', N'Active', N'2019-09-25', N'sp120@example.com', N'000-555-0120')
    ) v (Depth, Branch_Code, Manager_Code, Salesperson_Code, Salesperson_Name, Role, Employment_Status, Hire_Date, Email, Phone_Number);


    /* hierarchy level 0 (no manager) */
    INSERT INTO core.Salesperson (Branch_ID, Manager_Salesperson_ID, Salesperson_Code, Salesperson_Name, Role, Employment_Status, Hire_Date, Email, Phone_Number)
    SELECT b.Branch_ID, NULL, s.Salesperson_Code, s.Salesperson_Name, s.Role, s.Employment_Status, s.Hire_Date, s.Email, s.Phone_Number
    FROM #SpStg s JOIN core.Branch b ON b.Branch_Code = s.Branch_Code
    WHERE s.Depth = 0 ORDER BY s.Salesperson_Code;


    /* hierarchy level 1 (manager already inserted) */
    INSERT INTO core.Salesperson (Branch_ID, Manager_Salesperson_ID, Salesperson_Code, Salesperson_Name, Role, Employment_Status, Hire_Date, Email, Phone_Number)
    SELECT b.Branch_ID, m.Salesperson_ID, s.Salesperson_Code, s.Salesperson_Name, s.Role, s.Employment_Status, s.Hire_Date, s.Email, s.Phone_Number
    FROM #SpStg s JOIN core.Branch b ON b.Branch_Code = s.Branch_Code
                  JOIN core.Salesperson m ON m.Salesperson_Code = s.Manager_Code
    WHERE s.Depth = 1 ORDER BY s.Salesperson_Code;


    /* hierarchy level 2 (manager already inserted) */
    INSERT INTO core.Salesperson (Branch_ID, Manager_Salesperson_ID, Salesperson_Code, Salesperson_Name, Role, Employment_Status, Hire_Date, Email, Phone_Number)
    SELECT b.Branch_ID, m.Salesperson_ID, s.Salesperson_Code, s.Salesperson_Name, s.Role, s.Employment_Status, s.Hire_Date, s.Email, s.Phone_Number
    FROM #SpStg s JOIN core.Branch b ON b.Branch_Code = s.Branch_Code
                  JOIN core.Salesperson m ON m.Salesperson_Code = s.Manager_Code
    WHERE s.Depth = 2 ORDER BY s.Salesperson_Code;


    /* Calendar validation before COMMIT. */
    IF (SELECT COUNT(*) FROM core.Calendar WHERE Calendar_Date BETWEEN @StartDate AND @EndDate) <> @ExpectedCalendarCount
        THROW 51104, 'Calendar target row count validation failed.', 1;

    IF (SELECT MIN(Calendar_Date) FROM core.Calendar) <> @StartDate
       OR (SELECT MAX(Calendar_Date) FROM core.Calendar) <> @EndDate
        THROW 51105, 'Calendar date boundaries validation failed.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM core.Calendar
        WHERE Day_Number <> DAY(Calendar_Date)
           OR Month_Number <> MONTH(Calendar_Date)
           OR Quarter_Number <> DATEPART(QUARTER,Calendar_Date)
           OR Year_Number <> YEAR(Calendar_Date)
           OR Week_Number <> DATEPART(ISO_WEEK,Calendar_Date)
    )
        THROW 51106, 'Calendar derived attributes do not match the Gregorian/ISO convention.', 1;

    IF EXISTS
    (
        SELECT 1 FROM #CalendarSource s
        LEFT JOIN core.Calendar c ON c.Calendar_Date=s.Calendar_Date
        WHERE c.Calendar_Date IS NULL
    )
        THROW 51107, 'One or more calendar dates are missing.', 1;

    /* Branch and salesperson validation. */
    IF (SELECT COUNT(*) FROM core.Branch) <> 20
       OR (SELECT COUNT(*) FROM core.Salesperson) <> 120
        THROW 51108, 'Branch/Salesperson row-count validation failed.', 1;

    IF EXISTS
    (
        SELECT 1 FROM core.Branch b
        LEFT JOIN ref.SalesRegion r ON r.Sales_Region_ID=b.Sales_Region_ID
        WHERE r.Sales_Region_ID IS NULL OR r.Region_Level <> N'Team'
    )
        THROW 51109, 'Every Branch must reference an existing Team-level SalesRegion.', 1;

    IF EXISTS
    (
        SELECT 1 FROM core.Salesperson s
        LEFT JOIN core.Branch b ON b.Branch_ID=s.Branch_ID
        WHERE s.Branch_ID IS NOT NULL AND b.Branch_ID IS NULL
    )
        THROW 51110, 'Salesperson references a missing Branch.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM core.Salesperson s
        LEFT JOIN core.Salesperson m ON m.Salesperson_ID=s.Manager_Salesperson_ID
        WHERE s.Manager_Salesperson_ID IS NOT NULL
          AND (m.Salesperson_ID IS NULL OR m.Hire_Date > s.Hire_Date
               OR m.Role NOT IN (N'Manager',N'Sales Supervisor')
               OR m.Employment_Status <> N'Active')
    )
        THROW 51111, 'Salesperson manager hierarchy or hire-date validation failed.', 1;

    IF EXISTS
    (
        SELECT Salesperson_Code FROM core.Salesperson
        GROUP BY Salesperson_Code HAVING COUNT(*)>1
    )
       OR EXISTS
    (
        SELECT Email FROM core.Salesperson WHERE Email IS NOT NULL
        GROUP BY Email HAVING COUNT(*)>1
    )
        THROW 51112, 'Duplicate salesperson code or email detected.', 1;


    COMMIT TRANSACTION;
    INSERT INTO #T1Log VALUES (N'8.1b', N'core.Calendar', (SELECT COUNT(*) FROM core.Calendar));
    INSERT INTO #T1Log VALUES (N'8.1b', N'core.Branch', (SELECT COUNT(*) FROM core.Branch));
    INSERT INTO #T1Log VALUES (N'8.1b', N'core.Salesperson', (SELECT COUNT(*) FROM core.Salesperson));
    PRINT CONCAT(N'8.1b Calendar=', (SELECT COUNT(*) FROM core.Calendar), N' Branch=', (SELECT COUNT(*) FROM core.Branch), N' Salesperson=', (SELECT COUNT(*) FROM core.Salesperson));
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    UPDATE #T1Cfg SET Abort = 1;
    PRINT CONCAT(N'ERROR ', ERROR_NUMBER(), N' | LINE ', ERROR_LINE(), N' | ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO

GO
/* ===================== SECTION 3 : 8.2 Customer, Lead ====================== */
SET NOCOUNT ON; SET XACT_ABORT ON;
IF EXISTS (SELECT 1 FROM #T1Cfg WHERE Abort = 1) BEGIN PRINT N'SKIPPED section 3 (earlier failure)'; RETURN; END;
DECLARE @DataVersion nvarchar(50), @Seed int, @Scale decimal(5,2), @FromDate date, @ToDate date, @AsOfDate date;
SELECT @DataVersion = DataVersion, @Seed = Seed, @Scale = Scale, @FromDate = FromDate, @ToDate = ToDate, @AsOfDate = AsOfDate FROM #T1Cfg;

/* پارامترهای اختصاصی این اسکریپت (فرض‌های ثبت‌شده در Plan / Issue Log) */
DECLARE @CustomerBase int          = 5000;         -- حجم پیشنهادی کامل Customer (D-06)
DECLARE @LeadBase     int          = 4000;         -- حجم پیشنهادی کامل Lead (D-06)
DECLARE @NoOrderPct   decimal(5,2) = 8.00;         -- ٪ مشتریان «بدون سفارش» (سناریوی مستند؛ ۵ تا ۱۰٪)
DECLARE @MinDaysAfterReg int       = 90;           -- آخرین Registration_Date = @ToDate - این تعداد روز
DECLARE @Seg8EndDate  date         = '2024-12-31'; -- SEG08 فقط برای ثبت‌نام تا این تاریخ (End_Date سگمنت)
DECLARE @InactiveSalespersonCutoff date = '2024-12-31'; -- فرض Plan: فروشنده Inactive تا این تاریخ فعال بوده

DECLARE @CustCount int = CONVERT(int, ROUND(@CustomerBase * @Scale, 0));
DECLARE @LeadCount int = CONVERT(int, ROUND(@LeadBase * @Scale, 0));
DECLARE @RegSpan   int = DATEDIFF(day, @FromDate, @ToDate) - @MinDaysAfterReg;
DECLARE @LeadSpan  int = DATEDIFF(day, @FromDate, @ToDate);
DECLARE @cCust int, @cLead int;

BEGIN TRY
    /* ---------- پیش‌نیاز و سیاست اجرای مجدد ---------- */
    IF OBJECT_ID(N'core.Customer', N'U') IS NULL OR OBJECT_ID(N'sales.Lead', N'U') IS NULL
        THROW 52000, N'core.Customer or sales.Lead does not exist.', 1;
    IF EXISTS (SELECT 1 FROM core.Customer) OR EXISTS (SELECT 1 FROM sales.Lead)
        THROW 52001, N'core.Customer or sales.Lead already contains rows. Stopped. Clean up only with 08-03-T1-00-Reset.sql (team lead).', 1;
    IF NOT EXISTS (SELECT 1 FROM ref.City) OR NOT EXISTS (SELECT 1 FROM ref.CustomerSegment)
       OR NOT EXISTS (SELECT 1 FROM ref.SalesChannel) OR NOT EXISTS (SELECT 1 FROM ref.SalesTerritory)
       OR NOT EXISTS (SELECT 1 FROM core.Branch) OR NOT EXISTS (SELECT 1 FROM core.Salesperson)
        THROW 52002, N'A prerequisite table (ref.City/CustomerSegment/SalesChannel/SalesTerritory, core.Branch/Salesperson) is empty.', 1;

    /* ---------- مقادیر مجاز موقت (D-07 باز است؛ بعد از تأیید سرگروه همین‌جا اصلاح شود) ----------
       (فایل سرگروه customer.pdf - هنوز نیازمند تطبیق نهایی با Data Dictionary)
       Customer_Type : Organization | Individual
       Business_Type : Grocery | Supermarket | Hypermarket | Wholesale | Distributor | Restaurant | Hotel | Catering | Institutional | Retail Online
       Industry      : Food Retail | Food Wholesale | HORECA | Food Distribution | Healthcare | Education | Other
       Customer_Size : Small | Medium | Large | Enterprise
       Credit_Status : Approved | Under Review | On Hold | Blocked | Cash Only
       سایر دامنه‌ها در جدول وزن‌دار زیر */
    CREATE TABLE #Dom (Domain nvarchar(40) NOT NULL, Value nvarchar(100) NOT NULL, W decimal(9,4) NOT NULL, Lo decimal(9,4) NULL);
    INSERT INTO #Dom (Domain, Value, W) VALUES
     (N'Customer_Status', N'Active', 85), (N'Customer_Status', N'Inactive', 10), (N'Customer_Status', N'Suspended', 5),
     (N'Reason_Inactive', N'No Recent Purchase', 1), (N'Reason_Inactive', N'Business Closed', 1), (N'Reason_Inactive', N'Customer Request', 1),
     (N'Reason_Suspended', N'Credit Hold', 1), (N'Reason_Suspended', N'Payment Overdue', 1), (N'Reason_Suspended', N'Compliance Review', 1),
     (N'Credit_Active', N'Approved', 78.5), (N'Credit_Active', N'Under Review', 12), (N'Credit_Active', N'On Hold', 4.5), (N'Credit_Active', N'Blocked', 0.5), (N'Credit_Active', N'Cash Only', 4.5),
     (N'Credit_Inactive', N'Approved', 30), (N'Credit_Inactive', N'Under Review', 10), (N'Credit_Inactive', N'On Hold', 20), (N'Credit_Inactive', N'Blocked', 15), (N'Credit_Inactive', N'Cash Only', 25),
     (N'Credit_Suspended', N'Approved', 0.001), (N'Credit_Suspended', N'Under Review', 20), (N'Credit_Suspended', N'On Hold', 55), (N'Credit_Suspended', N'Blocked', 25), (N'Credit_Suspended', N'Cash Only', 0.001),
     (N'Contact_Channel', N'Phone', 30), (N'Contact_Channel', N'SMS', 30), (N'Contact_Channel', N'Email', 15), (N'Contact_Channel', N'Visit', 25),
     (N'Lead_Source', N'Referral', 25), (N'Lead_Source', N'Field Visit', 22), (N'Lead_Source', N'Website', 15), (N'Lead_Source', N'Cold Call', 13),
     (N'Lead_Source', N'Social Media', 10), (N'Lead_Source', N'Exhibition', 8), (N'Lead_Source', N'Partner', 7),
     (N'Lead_Status_Open', N'New', 30), (N'Lead_Status_Open', N'Contacted', 35), (N'Lead_Status_Open', N'Qualified', 20), (N'Lead_Status_Open', N'Lost', 15);
    -- Status_Reason برای Active: Regular Business (90٪) | Reactivated (10٪) - در منطق Customer؛ Customer_Type: Organization (≈90٪) | Individual (≈10٪)
    -- Lead_Status مجاز (موقت): New | Contacted | Qualified | Converted | Lost  (Converted از شاخه‌ی نرخ تبدیل می‌آید)
    UPDATE d SET Lo = x.Lo
    FROM #Dom d JOIN (SELECT Domain, Value,
           (SUM(W) OVER (PARTITION BY Domain ORDER BY Value ROWS UNBOUNDED PRECEDING) - W) * 100.0 / SUM(W) OVER (PARTITION BY Domain) AS Lo
           FROM #Dom) x ON x.Domain = d.Domain AND x.Value = d.Value;

    CREATE TABLE #Season (m int NOT NULL, w decimal(5,2) NOT NULL);   -- فرضیه‌ی فصلی (ماه میلادی): نوروز/مارس، یلدا/دسامبر، بازگشایی مدارس/سپتامبر
    INSERT INTO #Season (m, w) VALUES (1,0.70),(2,0.80),(3,1.00),(4,0.70),(5,0.80),(6,0.80),(7,0.75),(8,0.80),(9,0.90),(10,0.85),(11,0.80),(12,1.00);

    CREATE TABLE #ProvGeo (Province_Code nvarchar(30) NOT NULL, Lat decimal(9,6) NOT NULL, Lon decimal(9,6) NOT NULL);  -- نقطه‌ی تقریبی مرکز استان (ref.City مختصات ندارد)
    INSERT INTO #ProvGeo VALUES
     (N'PR001',38.08,46.29),(N'PR002',37.55,45.07),(N'PR003',38.25,48.30),(N'PR004',32.65,51.67),(N'PR005',35.84,50.99),
     (N'PR006',33.64,46.42),(N'PR007',28.92,50.84),(N'PR008',35.69,51.39),(N'PR009',32.33,50.86),(N'PR010',32.87,59.22),
     (N'PR011',36.30,59.60),(N'PR012',37.47,57.33),(N'PR013',31.32,48.67),(N'PR014',36.68,48.48),(N'PR015',35.58,53.39),
     (N'PR016',29.50,60.86),(N'PR017',29.59,52.58),(N'PR018',36.27,50.00),(N'PR019',34.64,50.88),(N'PR020',35.31,47.00),
     (N'PR021',30.28,57.08),(N'PR022',34.31,47.07),(N'PR023',30.67,51.59),(N'PR024',36.84,54.43),(N'PR025',37.28,49.58),
     (N'PR026',33.49,48.35),(N'PR027',36.56,53.06),(N'PR028',34.09,49.69),(N'PR029',27.19,56.27),(N'PR030',34.80,48.51),
     (N'PR031',31.90,54.37);

    CREATE TABLE #ProvPhone (Province_Code nvarchar(30) NOT NULL, Area_Code nvarchar(4) NOT NULL);  -- کد شهری مرکز هر استان
    INSERT INTO #ProvPhone VALUES
     (N'PR001',N'041'),(N'PR002',N'044'),(N'PR003',N'045'),(N'PR004',N'031'),(N'PR005',N'026'),(N'PR006',N'084'),(N'PR007',N'077'),(N'PR008',N'021'),
     (N'PR009',N'038'),(N'PR010',N'056'),(N'PR011',N'051'),(N'PR012',N'058'),(N'PR013',N'061'),(N'PR014',N'024'),(N'PR015',N'023'),(N'PR016',N'054'),
     (N'PR017',N'071'),(N'PR018',N'028'),(N'PR019',N'025'),(N'PR020',N'087'),(N'PR021',N'034'),(N'PR022',N'083'),(N'PR023',N'074'),(N'PR024',N'017'),
     (N'PR025',N'013'),(N'PR026',N'066'),(N'PR027',N'011'),(N'PR028',N'086'),(N'PR029',N'076'),(N'PR030',N'081'),(N'PR031',N'035');

    CREATE TABLE #SegP (Segment_Code nvarchar(30) NOT NULL, SegW decimal(9,4) NOT NULL, Pct_Individual decimal(5,2) NOT NULL,
        Pct_Small decimal(5,2) NOT NULL, Pct_SM decimal(5,2) NOT NULL, Pct_SML decimal(5,2) NOT NULL);
    -- وزن سگمنت؛ ٪ Individual؛ آستانه‌های تجمعی اندازه (Small | Small+Medium | Small+Medium+Large؛ بقیه Enterprise)
    -- هدف کل: Organization≈90٪ ، Small≈55٪ Medium≈30٪ Large≈12٪ Enterprise≈3٪ (فرضیه‌ی فایل سرگروه)
    INSERT INTO #SegP VALUES
     (N'SEG01', 30, 20, 77,  96, 100),
     (N'SEG02', 22,  2, 40,  85,  98),
     (N'SEG03',  3,  0,  0,  10,  65),
     (N'SEG04', 10,  0, 45,  85,  97),
     (N'SEG05',  6,  0,  5,  40,  90),
     (N'SEG06', 12, 12, 70,  95, 100),
     (N'SEG07',  5,  0,  0,  30,  85),
     (N'SEG08', 12, 15, 82,  99, 100);

    CREATE TABLE #BizP (Business_Type nvarchar(50) NOT NULL, Industry nvarchar(100) NOT NULL, Name_Prefix nvarchar(60) NOT NULL);
    INSERT INTO #BizP VALUES
     (N'Grocery',       N'Food Retail',       N'خواربارفروشی نمونه'),
     (N'Supermarket',   N'Food Retail',       N'سوپرمارکت نمونه'),
     (N'Hypermarket',   N'Food Retail',       N'هایپرمارکت نمونه'),
     (N'Retail Online', N'Food Retail',       N'فروشگاه آنلاین نمونه'),
     (N'Wholesale',     N'Food Wholesale',    N'عمده‌فروشی نمونه'),
     (N'Distributor',   N'Food Distribution', N'شرکت پخش نمونه'),
     (N'Restaurant',    N'HORECA',            N'رستوران نمونه'),
     (N'Hotel',         N'HORECA',            N'هتل نمونه'),
     (N'Catering',      N'HORECA',            N'کترینگ نمونه'),
     (N'Institutional', N'Other',             N'مجموعه سازمانی نمونه');   -- Industry نهایی Institutional: Healthcare 35٪ | Education 40٪ | Other 25٪ (در منطق)

    CREATE TABLE #SegBizW (Segment_Code nvarchar(30) NOT NULL, Business_Type nvarchar(50) NOT NULL, W decimal(9,4) NOT NULL);
    INSERT INTO #SegBizW VALUES
     (N'SEG01',N'Grocery',85),(N'SEG01',N'Retail Online',15),
     (N'SEG02',N'Supermarket',100),
     (N'SEG03',N'Hypermarket',100),
     (N'SEG04',N'Restaurant',55),(N'SEG04',N'Hotel',25),(N'SEG04',N'Catering',20),
     (N'SEG05',N'Wholesale',60),(N'SEG05',N'Distributor',40),
     (N'SEG06',N'Grocery',70),(N'SEG06',N'Retail Online',30),
     (N'SEG07',N'Institutional',100),
     (N'SEG08',N'Grocery',70),(N'SEG08',N'Restaurant',30);

    CREATE TABLE #SegChanW (Segment_Code nvarchar(30) NOT NULL, Sales_Channel_Code nvarchar(30) NOT NULL, W decimal(9,4) NOT NULL);
    INSERT INTO #SegChanW VALUES
     (N'SEG01',N'CH01',45),(N'SEG01',N'CH02',20),(N'SEG01',N'CH03',15),(N'SEG01',N'CH05',15),(N'SEG01',N'CH06',5),
     (N'SEG02',N'CH01',50),(N'SEG02',N'CH02',15),(N'SEG02',N'CH03',10),(N'SEG02',N'CH05',15),(N'SEG02',N'CH06',10),
     (N'SEG03',N'CH05',40),(N'SEG03',N'CH04',30),(N'SEG03',N'CH03',10),(N'SEG03',N'CH01',20),
     (N'SEG04',N'CH01',35),(N'SEG04',N'CH02',25),(N'SEG04',N'CH05',25),(N'SEG04',N'CH03',15),
     (N'SEG05',N'CH04',70),(N'SEG05',N'CH06',20),(N'SEG05',N'CH05',10),
     (N'SEG06',N'CH01',30),(N'SEG06',N'CH03',30),(N'SEG06',N'CH02',20),(N'SEG06',N'CH05',20),
     (N'SEG07',N'CH05',50),(N'SEG07',N'CH04',25),(N'SEG07',N'CH02',25),
     (N'SEG08',N'CH02',40),(N'SEG08',N'CH03',30),(N'SEG08',N'CH01',30);

/* نگاشت شهر ← قلمرو و شهر ← شعبه از روی نام (فرض OI-20/OI-23؛ ساختار جدید ساخته نمی‌شود) */
CREATE TABLE #TerrCity (Eff_City_ID int NOT NULL, Sales_Territory_ID int NOT NULL);
INSERT INTO #TerrCity (Eff_City_ID, Sales_Territory_ID)
SELECT cn.City_ID, t.Sales_Territory_ID
FROM ref.SalesTerritory t
CROSS APPLY (SELECT p1 = CHARINDEX(N' ', t.Territory_Name) + 1, p2 = CHARINDEX(N' - ', t.Territory_Name)) p
JOIN (SELECT City_Name, MIN(City_ID) AS City_ID FROM ref.City WHERE City_Level = N'City' GROUP BY City_Name) cn
  ON cn.City_Name = LTRIM(RTRIM(SUBSTRING(t.Territory_Name, p.p1, p.p2 - p.p1)))
WHERE t.Territory_Status = N'Active' AND p.p2 > p.p1;

CREATE TABLE #BranchCity (Eff_City_ID int NOT NULL, Branch_ID int NOT NULL);
INSERT INTO #BranchCity (Eff_City_ID, Branch_ID)
SELECT cn.City_ID, b.Branch_ID
FROM core.Branch b
CROSS APPLY (SELECT p1 = CHARINDEX(N' ', b.Branch_Name) + 1, p2 = CHARINDEX(N' - ', b.Branch_Name)) p
JOIN (SELECT City_Name, MIN(City_ID) AS City_ID FROM ref.City WHERE City_Level = N'City' GROUP BY City_Name) cn
  ON cn.City_Name = LTRIM(RTRIM(SUBSTRING(b.Branch_Name, p.p1, p.p2 - p.p1)))
WHERE b.Branch_Status = N'Active' AND p.p2 > p.p1;

    IF (SELECT COUNT(DISTINCT Eff_City_ID) FROM #TerrCity) = 0 OR (SELECT COUNT(DISTINCT Eff_City_ID) FROM #BranchCity) = 0
        THROW 52003, N'City<->Territory/Branch name mapping produced no rows; check territory/branch naming (OI-20/OI-23).', 1;

    /* ---------- وزن شهرها (دُم بلند: Zipf روی رتبه؛ شهرهای دارای قلمرو/شعبه جلوتر) ---------- */
    SELECT c.City_ID, c.City_Name, pr.Province_Code, ISNULL(c.Parent_City_ID, c.City_ID) AS Eff_City_ID,
           CASE WHEN EXISTS (SELECT 1 FROM #TerrCity t WHERE t.Eff_City_ID = ISNULL(c.Parent_City_ID, c.City_ID)) THEN 1
                WHEN EXISTS (SELECT 1 FROM #BranchCity b WHERE b.Eff_City_ID = ISNULL(c.Parent_City_ID, c.City_ID)) THEN 2 ELSE 3 END AS Tier,
           COALESCE((SELECT MIN(t.Sales_Territory_ID) FROM #TerrCity t WHERE t.Eff_City_ID = ISNULL(c.Parent_City_ID, c.City_ID)),
                    (SELECT MIN(b.Branch_ID) FROM #BranchCity b WHERE b.Eff_City_ID = ISNULL(c.Parent_City_ID, c.City_ID)),
                    ISNULL(c.Parent_City_ID, c.City_ID)) AS Tier_Order,
           CASE WHEN c.Parent_City_ID IS NULL THEN 0 ELSE 1 END AS Lvl
    INTO #CityBase
    FROM ref.City c JOIN ref.Province pr ON pr.Province_ID = c.Province_ID;

    SELECT x.City_ID, x.City_Name, x.Province_Code, x.Eff_City_ID,
           (SUM(x.W) OVER (ORDER BY x.Rnk ROWS UNBOUNDED PRECEDING) - x.W) / SUM(x.W) OVER () AS CumLo
    INTO #CityW
    FROM (SELECT b.*, ROW_NUMBER() OVER (ORDER BY b.Tier, b.Tier_Order, b.Eff_City_ID, b.Lvl, b.City_ID) AS Rnk,
                 CONVERT(decimal(18,10), 1.0) / ROW_NUMBER() OVER (ORDER BY b.Tier, b.Tier_Order, b.Eff_City_ID, b.Lvl, b.City_ID) AS W
          FROM #CityBase b) x;

    SELECT s.Segment_Code, s.Customer_Segment_ID,
           (SUM(p.SegW) OVER (ORDER BY s.Segment_Code ROWS UNBOUNDED PRECEDING) - p.SegW) / SUM(p.SegW) OVER () AS Lo
    INTO #SegCum
    FROM ref.CustomerSegment s JOIN #SegP p ON p.Segment_Code = s.Segment_Code;

    SELECT w.Segment_Code, ch.Sales_Channel_ID,
           (SUM(w.W) OVER (PARTITION BY w.Segment_Code ORDER BY w.Sales_Channel_Code ROWS UNBOUNDED PRECEDING) - w.W)
             / SUM(w.W) OVER (PARTITION BY w.Segment_Code) AS Lo
    INTO #ChanCum
    FROM #SegChanW w JOIN ref.SalesChannel ch ON ch.Sales_Channel_Code = w.Sales_Channel_Code;

    SELECT w.Segment_Code, w.Business_Type,
           (SUM(w.W) OVER (PARTITION BY w.Segment_Code ORDER BY w.Business_Type ROWS UNBOUNDED PRECEDING) - w.W)
             / SUM(w.W) OVER (PARTITION BY w.Segment_Code) AS Lo
    INTO #BizCum FROM #SegBizW w;

    SELECT TOP (CASE WHEN @CustCount > @LeadCount THEN @CustCount ELSE @LeadCount END)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    INTO #N FROM sys.all_objects a CROSS JOIN sys.all_objects b;

    /* ======================= CUSTOMER ======================= */
    SELECT n.n,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|city')))) / 4294967296.0) AS u_city,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|seg')))) / 4294967296.0) AS u_seg,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|chan')))) / 4294967296.0) AS u_chan,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|biz')))) / 4294967296.0) AS u_biz,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|ind')))) / 4294967296.0) AS u_ind,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|type')))) / 4294967296.0) AS u_type,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|size')))) / 4294967296.0) AS u_size,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|emp')))) / 4294967296.0) AS u_emp,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|exc')))) / 4294967296.0) AS u_exc,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|rev')))) / 4294967296.0) AS u_rev,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|reg')))) / 4294967296.0) AS u_reg,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|status')))) / 4294967296.0) AS u_status,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|sdays')))) / 4294967296.0) AS u_sdays,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|reason')))) / 4294967296.0) AS u_reason,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|cred')))) / 4294967296.0) AS u_cred,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|credst')))) / 4294967296.0) AS u_credst,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|lim')))) / 4294967296.0) AS u_lim,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|crdays')))) / 4294967296.0) AS u_crdays,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|crnull')))) / 4294967296.0) AS u_crnull,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|upd')))) / 4294967296.0) AS u_upd,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|lat')))) / 4294967296.0) AS u_lat,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|lon')))) / 4294967296.0) AS u_lon,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|sp')))) / 4294967296.0) AS u_sp,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|terr')))) / 4294967296.0) AS u_terr,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|ph')))) / 4294967296.0) AS u_ph,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|mo')))) / 4294967296.0) AS u_mo,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|mp')))) / 4294967296.0) AS u_mp,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|em')))) / 4294967296.0) AS u_em,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|cc')))) / 4294967296.0) AS u_cc,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|a1')))) / 4294967296.0) AS u_a1,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|a2')))) / 4294967296.0) AS u_a2,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Customer|', n.n, N'|a3')))) / 4294967296.0) AS u_a3
    INTO #C0 FROM #N n WHERE n.n <= @CustCount;

    SELECT c0.*, cw.City_ID, cw.City_Name, cw.Province_Code, cw.Eff_City_ID,
           DATEADD(day, CONVERT(int, FLOOR(POWER(c0.u_reg, 0.5) * @RegSpan)), @FromDate) AS Registration_Date
    INTO #C1
    FROM #C0 c0
    CROSS APPLY (SELECT TOP (1) w.* FROM #CityW w WHERE w.CumLo <= c0.u_city ORDER BY w.CumLo DESC) cw;

    SELECT c1.*, sc.Segment_Code AS Seg0
    INTO #C2
    FROM #C1 c1
    CROSS APPLY (SELECT TOP (1) s.Segment_Code FROM #SegCum s WHERE s.Lo <= c1.u_seg ORDER BY s.Lo DESC) sc;

    SELECT c2.*,
           CASE WHEN c2.Seg0 = N'SEG08' AND c2.Registration_Date > @Seg8EndDate THEN N'SEG01' ELSE c2.Seg0 END AS Segment_Code
    INTO #C3 FROM #C2 c2;

    /* نوع مشتری و نوع کسب‌وکار (Individual ≈10٪؛ Business_Type سازمانی هرگز به Individual داده نمی‌شود) */
    SELECT c3.*, sg.Customer_Segment_ID, p.Pct_Small, p.Pct_SM, p.Pct_SML,
           CASE WHEN c3.u_type * 100 < p.Pct_Individual THEN N'Individual' ELSE N'Organization' END AS Customer_Type,
           bz.Business_Type AS Biz0
    INTO #Ca
    FROM #C3 c3
    JOIN #SegP p ON p.Segment_Code = c3.Segment_Code
    JOIN ref.CustomerSegment sg ON sg.Segment_Code = c3.Segment_Code
    CROSS APPLY (SELECT TOP (1) b.Business_Type FROM #BizCum b WHERE b.Segment_Code = c3.Segment_Code AND b.Lo <= c3.u_biz ORDER BY b.Lo DESC) bz;

    SELECT a.n, a.City_ID, a.City_Name, a.Province_Code, a.Eff_City_ID, a.Registration_Date, a.Segment_Code, a.Customer_Segment_ID,
           a.Customer_Type, a.Biz0,
           CASE WHEN a.Customer_Type = N'Individual' THEN N'مشتری حقیقی نمونه' ELSE bp.Name_Prefix END AS Name_Prefix,
           CASE WHEN a.Customer_Type = N'Individual' THEN NULL ELSE a.Biz0 END AS Business_Type,
           CASE WHEN a.Customer_Type = N'Individual' THEN N'Other'
                WHEN a.Biz0 = N'Institutional' THEN CASE WHEN a.u_ind < 0.35 THEN N'Healthcare' WHEN a.u_ind < 0.75 THEN N'Education' ELSE N'Other' END
                ELSE bp.Industry END AS Industry,
           CASE WHEN a.Customer_Type = N'Individual' THEN CASE WHEN a.u_size < 0.95 THEN N'Small' ELSE N'Medium' END
                WHEN a.u_size * 100 < a.Pct_Small THEN N'Small' WHEN a.u_size * 100 < a.Pct_SM THEN N'Medium'
                WHEN a.u_size * 100 < a.Pct_SML THEN N'Large' ELSE N'Enterprise' END AS Customer_Size,
           CASE WHEN a.Biz0 = N'Retail Online' AND a.Customer_Type = N'Organization'
                THEN (SELECT x.Sales_Channel_ID FROM ref.SalesChannel x WHERE x.Sales_Channel_Code = N'CH03')
                ELSE ch.Sales_Channel_ID END AS Sales_Channel_ID,
           (SELECT TOP (1) d.Value FROM #Dom d WHERE d.Domain = N'Customer_Status' AND d.Lo <= a.u_status * 100 ORDER BY d.Lo DESC) AS Customer_Status,
           (SELECT TOP (1) d.Value FROM #Dom d WHERE d.Domain = N'Contact_Channel' AND d.Lo <= a.u_cc * 100 ORDER BY d.Lo DESC) AS Preferred_Contact_Channel,
           a.u_emp, a.u_exc, a.u_rev, a.u_sdays, a.u_reason, a.u_cred, a.u_credst, a.u_lim, a.u_crdays, a.u_crnull, a.u_upd, a.u_lat, a.u_lon,
           a.u_sp, a.u_terr, a.u_ph, a.u_mo, a.u_mp, a.u_em, a.u_a1, a.u_a2, a.u_a3,
           CONVERT(int, NULL) AS Sales_Territory_ID, CONVERT(int, NULL) AS Salesperson_ID
    INTO #C
    FROM #Ca a
    LEFT JOIN #BizP bp ON bp.Business_Type = a.Biz0
    CROSS APPLY (SELECT TOP (1) cc.Sales_Channel_ID FROM #ChanCum cc WHERE cc.Segment_Code = a.Segment_Code AND cc.Lo <= a.u_chan ORDER BY cc.Lo DESC) ch;

    /* قلمرو: از قلمروهای همان شهر مؤثر (در صورت وجود) */
    ;WITH T AS (
        SELECT c.n, t.Sales_Territory_ID,
               ROW_NUMBER() OVER (PARTITION BY c.n ORDER BY t.Sales_Territory_ID) AS rn,
               COUNT(*) OVER (PARTITION BY c.n) AS cnt
        FROM #C c JOIN #TerrCity t ON t.Eff_City_ID = c.Eff_City_ID)
    UPDATE c SET Sales_Territory_ID = t.Sales_Territory_ID
    FROM #C c JOIN T t ON t.n = c.n AND t.rn = CONVERT(int, FLOOR(c.u_terr * t.cnt)) + 1;

    /* فروشنده: غیرمدیر، Active، شعبه‌ی فعال همان شهر، Hire_Date <= Registration_Date */
    ;WITH E AS (
        SELECT c.n, s.Salesperson_ID,
               ROW_NUMBER() OVER (PARTITION BY c.n ORDER BY s.Salesperson_ID) AS rn,
               COUNT(*) OVER (PARTITION BY c.n) AS cnt
        FROM #C c
        JOIN #BranchCity bc ON bc.Eff_City_ID = c.Eff_City_ID
        JOIN core.Salesperson s ON s.Branch_ID = bc.Branch_ID AND s.Role <> N'Manager'
             AND s.Employment_Status = N'Active' AND s.Hire_Date <= c.Registration_Date)
    UPDATE c SET Salesperson_ID = e.Salesperson_ID
    FROM #C c JOIN E e ON e.n = c.n AND e.rn = CONVERT(int, FLOOR(c.u_sp * e.cnt)) + 1;

    /* درآمد، کارکنان (استثنا: عمده‌فروش/پخش گاهی کارکنان کمتر نسبت به درآمد = یک پله پایین‌تر)، دلیل وضعیت */
    SELECT c.*,
      CONVERT(decimal(18,2), ROUND(
          CASE c.Customer_Size WHEN N'Small' THEN 5000000000.0 WHEN N'Medium' THEN 30000000000.0
                               WHEN N'Large' THEN 150000000000.0 ELSE 700000000000.0 END
          * POWER(CONVERT(decimal(18,6), CASE c.Customer_Size WHEN N'Small' THEN 6.0 WHEN N'Medium' THEN 5.0
                               WHEN N'Large' THEN 4.666667 ELSE 7.142857 END), c.u_rev), -6)) AS Annual_Revenue,
      CASE WHEN c.Customer_Type = N'Individual' THEN NULL
           WHEN es.EmpSize = N'Small'  THEN 1   + CONVERT(int, FLOOR(c.u_emp * 10))
           WHEN es.EmpSize = N'Medium' THEN 11  + CONVERT(int, FLOOR(c.u_emp * 40))
           WHEN es.EmpSize = N'Large'  THEN 51  + CONVERT(int, FLOOR(c.u_emp * 150))
           ELSE 201 + CONVERT(int, FLOOR(c.u_emp * c.u_emp * 800)) END AS Employee_Count,
      CASE c.Customer_Status
           WHEN N'Active' THEN CASE WHEN c.u_reason < 0.90 THEN N'Regular Business' ELSE N'Reactivated' END
           WHEN N'Inactive'  THEN (SELECT TOP (1) d.Value FROM #Dom d WHERE d.Domain = N'Reason_Inactive'  AND d.Lo <= c.u_reason * 100 ORDER BY d.Lo DESC)
           ELSE (SELECT TOP (1) d.Value FROM #Dom d WHERE d.Domain = N'Reason_Suspended' AND d.Lo <= c.u_reason * 100 ORDER BY d.Lo DESC) END AS Status_Reason
    INTO #C4
    FROM #C c
    CROSS APPLY (SELECT CASE WHEN c.Biz0 IN (N'Wholesale', N'Distributor') AND c.u_exc < 0.30
                             THEN CASE c.Customer_Size WHEN N'Enterprise' THEN N'Large' WHEN N'Large' THEN N'Medium' ELSE N'Small' END
                             ELSE c.Customer_Size END AS EmpSize) es;

    SELECT c.*,
      CASE WHEN c.Status_Reason = N'Regular Business' THEN c.Registration_Date
           ELSE DATEADD(day, 30 + CONVERT(int, FLOOR(c.u_sdays * (DATEDIFF(day, c.Registration_Date, @AsOfDate) - 30))), c.Registration_Date) END AS Status_Effective_Date,
      CASE c.Customer_Status WHEN N'Active'   THEN (SELECT TOP (1) d.Value FROM #Dom d WHERE d.Domain = N'Credit_Active'    AND d.Lo <= c.u_credst * 100 ORDER BY d.Lo DESC)
                             WHEN N'Inactive' THEN (SELECT TOP (1) d.Value FROM #Dom d WHERE d.Domain = N'Credit_Inactive'  AND d.Lo <= c.u_credst * 100 ORDER BY d.Lo DESC)
                             ELSE (SELECT TOP (1) d.Value FROM #Dom d WHERE d.Domain = N'Credit_Suspended' AND d.Lo <= c.u_credst * 100 ORDER BY d.Lo DESC) END AS Credit_Status
    INTO #C5 FROM #C4 c;

    /* سقف و تاریخ بررسی اعتبار: Approved>0 ؛ Under Review>0 (نیمه) ؛ On Hold صفر یا استفاده‌نشده ؛ Blocked/Cash Only صفر */
    SELECT c.*,
      CONVERT(decimal(18,2), CASE c.Credit_Status
           WHEN N'Approved'     THEN b.Base
           WHEN N'Under Review' THEN ROUND(b.Base * 0.5, -6)
           WHEN N'On Hold'      THEN CASE WHEN c.u_lim < 0.5 THEN 0 ELSE ROUND(b.Base * 0.3, -6) END
           ELSE 0 END) AS Credit_Limit,
      CASE WHEN c.Credit_Status = N'Cash Only' AND c.u_crnull < 0.60 THEN NULL
           WHEN c.Credit_Status IN (N'Approved', N'Cash Only')
                THEN CASE WHEN DATEADD(day, 90 + CONVERT(int, FLOOR(c.u_crdays * 540)), c.Registration_Date) > @AsOfDate THEN @AsOfDate
                          ELSE DATEADD(day, 90 + CONVERT(int, FLOOR(c.u_crdays * 540)), c.Registration_Date) END
           ELSE CASE WHEN DATEADD(day, -CONVERT(int, FLOOR(c.u_crdays * 180)), @AsOfDate) < c.Registration_Date THEN c.Registration_Date
                     ELSE DATEADD(day, -CONVERT(int, FLOOR(c.u_crdays * 180)), @AsOfDate) END END AS Credit_Review_Date
    INTO #C6
    FROM #C5 c
    CROSS APPLY (SELECT ROUND(c.Annual_Revenue * (0.01 + 0.04 * c.u_cred) * CASE WHEN c.Customer_Type = N'Individual' THEN 0.5 ELSE 1.0 END, -6) AS Base) b;

    SELECT c.*,
      CASE WHEN DATEADD(day, CONVERT(int, FLOOR(c.u_upd * 60)), m.MaxD) > @AsOfDate THEN @AsOfDate
           ELSE DATEADD(day, CONVERT(int, FLOOR(c.u_upd * 60)), m.MaxD) END AS Last_Update_Date
    INTO #C7
    FROM #C6 c
    CROSS APPLY (SELECT MAX(v.d) AS MaxD FROM (VALUES (c.Registration_Date), (c.Status_Effective_Date), (c.Credit_Review_Date)) v(d)) m;

    /* ======================= LEAD ======================= */
    SELECT n.n,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Lead|', n.n, N'|d1')))) / 4294967296.0) AS u_d1, CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Lead|', n.n, N'|d2')))) / 4294967296.0) AS u_d2, CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Lead|', n.n, N'|d3')))) / 4294967296.0) AS u_d3, CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Lead|', n.n, N'|d4')))) / 4294967296.0) AS u_d4,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Lead|', n.n, N'|a1')))) / 4294967296.0) AS u_a1, CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Lead|', n.n, N'|a2')))) / 4294967296.0) AS u_a2, CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Lead|', n.n, N'|a3')))) / 4294967296.0) AS u_a3,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Lead|', n.n, N'|src')))) / 4294967296.0) AS u_src, CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Lead|', n.n, N'|conv')))) / 4294967296.0) AS u_conv, CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Lead|', n.n, N'|status')))) / 4294967296.0) AS u_status,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Lead|', n.n, N'|cdays')))) / 4294967296.0) AS u_cdays, CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Lead|', n.n, N'|score')))) / 4294967296.0) AS u_score, CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Lead|', n.n, N'|val')))) / 4294967296.0) AS u_val,
      CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Lead|', n.n, N'|sp')))) / 4294967296.0) AS u_sp, CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256', CONCAT(@Seed, N'|Lead|', n.n, N'|spmiss')))) / 4294967296.0) AS u_spmiss
    INTO #L0 FROM #N n WHERE n.n <= @LeadCount;

    SELECT l.*, cr.Created_Date
    INTO #L1
    FROM #L0 l
    CROSS APPLY (SELECT DATEADD(day, CONVERT(int, FLOOR(POWER(l.u_d1, 0.6) * @LeadSpan)), @FromDate) AS d1,
                        DATEADD(day, CONVERT(int, FLOOR(POWER(l.u_d2, 0.6) * @LeadSpan)), @FromDate) AS d2,
                        DATEADD(day, CONVERT(int, FLOOR(POWER(l.u_d3, 0.6) * @LeadSpan)), @FromDate) AS d3,
                        DATEADD(day, CONVERT(int, FLOOR(POWER(l.u_d4, 0.6) * @LeadSpan)), @FromDate) AS d4) d
    CROSS APPLY (SELECT CASE WHEN l.u_a1 < (SELECT s.w FROM #Season s WHERE s.m = MONTH(d.d1)) THEN d.d1
                             WHEN l.u_a2 < (SELECT s.w FROM #Season s WHERE s.m = MONTH(d.d2)) THEN d.d2
                             WHEN l.u_a3 < (SELECT s.w FROM #Season s WHERE s.m = MONTH(d.d3)) THEN d.d3
                             ELSE d.d4 END AS Created_Date) cr;

    SELECT l.*,
           CASE WHEN l.u_conv < CASE WHEN MONTH(l.Created_Date) IN (3, 12) THEN 0.30 ELSE 0.22 END THEN N'Converted'
                ELSE (SELECT TOP (1) d.Value FROM #Dom d WHERE d.Domain = N'Lead_Status_Open' AND d.Lo <= l.u_status * 100 ORDER BY d.Lo DESC) END AS Status0,
           DATEADD(day, 7 + CONVERT(int, FLOOR(l.u_cdays * 120)), l.Created_Date) AS Conv_Cand,
           (SELECT TOP (1) d.Value FROM #Dom d WHERE d.Domain = N'Lead_Source' AND d.Lo <= l.u_src * 100 ORDER BY d.Lo DESC) AS Lead_Source,
           CONVERT(int, NULL) AS Salesperson_ID
    INTO #L2 FROM #L1 l;

    SELECT l.*,
           CASE WHEN l.Status0 = N'Converted' AND l.Conv_Cand > @AsOfDate THEN N'Qualified'
                WHEN l.Status0 IN (N'New', N'Contacted') AND l.Created_Date < DATEADD(day, -180, @AsOfDate) THEN N'Lost'
                ELSE l.Status0 END AS Lead_Status,
           CASE WHEN l.Status0 = N'Converted' AND l.Conv_Cand <= @AsOfDate THEN l.Conv_Cand END AS Conversion_Date
    INTO #L3 FROM #L2 l;

    ;WITH E AS (
        SELECT l.n, s.Salesperson_ID,
               ROW_NUMBER() OVER (PARTITION BY l.n ORDER BY s.Salesperson_ID) AS rn,
               COUNT(*) OVER (PARTITION BY l.n) AS cnt
        FROM #L3 l
        JOIN core.Salesperson s ON s.Role <> N'Manager' AND s.Hire_Date <= l.Created_Date
             AND (s.Employment_Status IN (N'Active', N'On Leave')
                  OR (s.Employment_Status = N'Inactive' AND l.Created_Date <= @InactiveSalespersonCutoff)))
    UPDATE l SET Salesperson_ID = e.Salesperson_ID
    FROM #L3 l JOIN E e ON e.n = l.n AND e.rn = CONVERT(int, FLOOR(l.u_sp * e.cnt)) + 1
    WHERE l.u_spmiss < 0.90;

    /* ======================= درج و کنترل پیش از COMMIT ======================= */
    BEGIN TRANSACTION;

    INSERT INTO core.Customer
        (City_ID, Customer_Segment_ID, Sales_Channel_ID, Sales_Territory_ID, Salesperson_ID, Customer_Code, Customer_Name,
         Customer_Type, Customer_Status, Status_Reason, Status_Effective_Date, Business_Type, Industry, Customer_Size,
         Employee_Count, Annual_Revenue, Contact_Person_Name, Phone, Mobile, Email, Preferred_Contact_Channel, Address,
         Postal_Code, Latitude, Longitude, Registration_Date, Credit_Limit, Credit_Status, Credit_Review_Date, Last_Update_Date)
    SELECT c.City_ID, c.Customer_Segment_ID, c.Sales_Channel_ID, c.Sales_Territory_ID, c.Salesperson_ID,
           CONCAT(N'CUS', RIGHT(CONCAT(N'000000', c.n), 6)),
           CONCAT(c.Name_Prefix, N' ', RIGHT(CONCAT(N'000000', c.n), 6)),
           c.Customer_Type, c.Customer_Status, c.Status_Reason, c.Status_Effective_Date, c.Business_Type, c.Industry, c.Customer_Size,
           c.Employee_Count, c.Annual_Revenue,
           CASE WHEN c.Customer_Type = N'Individual' THEN CONCAT(c.Name_Prefix, N' ', RIGHT(CONCAT(N'000000', c.n), 6)) ELSE CONCAT(N'شخص رابط نمونه ', RIGHT(CONCAT(N'000000', c.n), 6)) END,
           CASE WHEN c.u_ph < 0.70 OR c.Preferred_Contact_Channel = N'Phone' THEN CONCAT(N'000-', pp.Area_Code, N'-', RIGHT(CONCAT(N'000000', c.n % 1000000), 6)) END,
           CASE WHEN c.u_mo < 0.90 OR c.Preferred_Contact_Channel = N'SMS' THEN CONCAT(N'000-555-', RIGHT(CONCAT(N'0000000', c.n % 10000000), 7)) END,
           CASE WHEN c.u_em < 0.60 OR c.Preferred_Contact_Channel = N'Email' THEN CONCAT(N'customer', RIGHT(CONCAT(N'000000', c.n), 6), N'@example.com') END,
           c.Preferred_Contact_Channel,
           CONCAT(N'شهر ', c.City_Name, N'، محله ساختگی ', 1 + CONVERT(int, FLOOR(c.u_a1 * 60)),
                  N'، خیابان ساختگی ', 1 + CONVERT(int, FLOOR(c.u_a2 * 90)), N'، پلاک ', 1 + CONVERT(int, FLOOR(c.u_a3 * 300))),
           CONCAT(N'00', RIGHT(CONCAT(N'00000000', (c.n * 7919 + 13) % 100000000), 8)),
           CONVERT(decimal(9,6), pg.Lat + (c.u_lat - 0.5) * 0.2),
           CONVERT(decimal(9,6), pg.Lon + (c.u_lon - 0.5) * 0.2),
           c.Registration_Date, c.Credit_Limit, c.Credit_Status, c.Credit_Review_Date, c.Last_Update_Date
    FROM #C7 c JOIN #ProvGeo pg ON pg.Province_Code = c.Province_Code JOIN #ProvPhone pp ON pp.Province_Code = c.Province_Code
    ORDER BY c.n;
    SET @cCust = @@ROWCOUNT;

    INSERT INTO sales.Lead
        (Salesperson_ID, Lead_Code, Lead_Name, Lead_Source, Lead_Status, Lead_Score, Expected_Value, Created_Date, Conversion_Date)
    SELECT l.Salesperson_ID,
           CONCAT(N'LD', RIGHT(CONCAT(N'000000', l.n), 6)),
           CONCAT(N'سرنخ نمونه ', RIGHT(CONCAT(N'000000', l.n), 6)),
           l.Lead_Source, l.Lead_Status,
           CONVERT(decimal(5,2), ROUND(sc.lo + (sc.hi - sc.lo) * l.u_score, 2)),
           CONVERT(decimal(18,2), ROUND(500000000.0 * POWER(CONVERT(decimal(18,6), 40), l.u_val), -5)),
           l.Created_Date, l.Conversion_Date
    FROM #L3 l
    CROSS APPLY (SELECT CASE l.Lead_Status WHEN N'Converted' THEN 55.0 WHEN N'Qualified' THEN 50.0 WHEN N'Contacted' THEN 30.0 WHEN N'New' THEN 10.0 ELSE 5.0 END AS lo,
                        CASE l.Lead_Status WHEN N'Converted' THEN 95.0 WHEN N'Qualified' THEN 90.0 WHEN N'Contacted' THEN 75.0 WHEN N'New' THEN 60.0 ELSE 50.0 END AS hi) sc
    ORDER BY l.n;
    SET @cLead = @@ROWCOUNT;

    /* کنترل‌های اجباری پیش از COMMIT */
    IF @cCust <> @CustCount OR @cLead <> @LeadCount THROW 52010, N'Inserted row count differs from planned count.', 1;
    IF EXISTS (SELECT Customer_Code FROM core.Customer GROUP BY Customer_Code HAVING COUNT(*) > 1)
       OR EXISTS (SELECT Lead_Code FROM sales.Lead GROUP BY Lead_Code HAVING COUNT(*) > 1)
        THROW 52011, N'Duplicate Customer_Code or Lead_Code.', 1;
    IF EXISTS (SELECT 1 FROM core.Customer WHERE Registration_Date IS NULL OR Registration_Date < @FromDate OR Registration_Date > @ToDate
                  OR Status_Effective_Date < Registration_Date OR Last_Update_Date < Registration_Date OR Last_Update_Date > @AsOfDate
                  OR Credit_Review_Date < Registration_Date OR Credit_Limit < 0 OR Annual_Revenue < 0 OR Employee_Count < 0)
        THROW 52012, N'Customer date/range validation failed.', 1;
    IF EXISTS (SELECT 1 FROM core.Customer WHERE (Credit_Status IN (N'Approved', N'Under Review') AND Credit_Limit <= 0)
                  OR (Credit_Status IN (N'Blocked', N'Cash Only') AND Credit_Limit <> 0)
                  OR (Customer_Type = N'Individual' AND (Business_Type IS NOT NULL OR Employee_Count IS NOT NULL))
                  OR (Customer_Type = N'Organization' AND (Business_Type IS NULL OR Employee_Count IS NULL OR Employee_Count <= 0)))
        THROW 52014, N'Customer business-rule validation failed (credit limit/status or type rules).', 1;
    IF EXISTS (SELECT 1 FROM sales.Lead WHERE Created_Date < @FromDate OR Created_Date > @ToDate OR Expected_Value < 0
                  OR (Conversion_Date IS NOT NULL AND (Conversion_Date < Created_Date OR Conversion_Date > @AsOfDate OR Lead_Status <> N'Converted'))
                  OR (Lead_Status = N'Converted' AND Conversion_Date IS NULL) OR Lead_Score NOT BETWEEN 0 AND 100)
        THROW 52013, N'Lead date/range validation failed.', 1;

    COMMIT TRANSACTION;

    /* ---------- لاگ بارگذاری (Q18) ---------- */
    PRINT CONCAT(N'DataVersion=', @DataVersion, N'; Seed=', @Seed, N'; Scale=', @Scale, N'; AsOf=', CONVERT(nvarchar(10), @AsOfDate, 23));
    PRINT CONCAT(N'core.Customer: input=', @CustCount, N'; inserted=', @cCust, N'; rejected=0; updated=0');
    PRINT CONCAT(N'sales.Lead   : input=', @LeadCount, N'; inserted=', @cLead, N'; rejected=0; updated=0');
    PRINT CONCAT(N'Customers without territory (city has no territory): ', (SELECT COUNT(*) FROM core.Customer WHERE Sales_Territory_ID IS NULL));
    PRINT CONCAT(N'Customers without salesperson: ', (SELECT COUNT(*) FROM core.Customer WHERE Salesperson_ID IS NULL));
    PRINT CONCAT(N'Converted leads: ', (SELECT COUNT(*) FROM sales.Lead WHERE Lead_Status = N'Converted'), N' of ', @cLead);

    /* ---------- hand-over to 8.4: "no order" customers (documented scenario, same hash flag) ---------- */
    INSERT INTO #T1NoOrder (Customer_ID)
    SELECT c.Customer_ID
    FROM core.Customer c
    WHERE CONVERT(decimal(18,10), CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256',
              CONCAT(@Seed, N'|Customer|', CONVERT(int, SUBSTRING(c.Customer_Code, 4, 6)), N'|noorder')))) / 4294967296.0) * 100 < @NoOrderPct;
    INSERT INTO #T1Log VALUES (N'8.2', N'core.Customer', @cCust);
    INSERT INTO #T1Log VALUES (N'8.2', N'sales.Lead', @cLead);
    PRINT CONCAT(N'Customers flagged "no order" (excluded from 8.4): ', (SELECT COUNT(*) FROM #T1NoOrder));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    UPDATE #T1Cfg SET Abort = 1;
    PRINT CONCAT(N'ERROR ', ERROR_NUMBER(), N' (line ', ERROR_LINE(), N'): ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO
/*
Project : Food Distribution (Etemad Iranian Food Distribution)
Stage   : 8 - Mock Data
Team    : Team 1 - Sales & Customer
Group   : Funnel
File    : Funnel.sql (Revised per Team 1 Stage 8.3 correction)
Database: FoodDistributionDB (SQL Server 2022)
Version : MockData_v1.0_Seed20261031
Run order: 4 (after Stage 8.1 Reference/Organization and Stage 8.2 Customer/Lead parent data)
Prerequisites:
  - 8.1: core.Salesperson (120 rows), ref.SalesTerritory (50 rows), core.Calendar (2,922 dates)
  - Customer/Lead parent rows loaded in core.Customer and sales.Lead
  - PreValidation must pass first.
Identity policy: SQL Server generates target identity keys; no IDENTITY_INSERT.
Parent key policy: parent IDs are selected from the actual database rows; no IDs are hard-coded.
*/
GO
/* ===================== SECTION 4 : 8.3 Funnel (CustomerInteraction, SalesOpportunity, Contract) ===== */
SET NOCOUNT ON; SET XACT_ABORT ON;
IF EXISTS (SELECT 1 FROM #T1Cfg WHERE Abort = 1) BEGIN PRINT N'SKIPPED section 4 (earlier failure)'; RETURN; END;
DECLARE @DataVersion nvarchar(50), @Seed int, @Scale decimal(5,2), @FromDate date, @ToDate date, @AsOfDate date;
SELECT @DataVersion = DataVersion, @Seed = Seed, @Scale = Scale, @FromDate = FromDate, @ToDate = ToDate, @AsOfDate = AsOfDate FROM #T1Cfg;

/* ---------------- Funnel plan volumes ---------------- */
DECLARE @FullInteractions int=30000;
DECLARE @FullOpportunities int=6000;
DECLARE @FullContracts int=500;
DECLARE @InteractionCount int=CONVERT(int,CEILING(@FullInteractions*@Scale));
DECLARE @OpportunityCount int=CONVERT(int,CEILING(@FullOpportunities*@Scale));
DECLARE @ContractCount int=CONVERT(int,CEILING(@FullContracts*@Scale));
DECLARE @MaxRows int=CASE WHEN @InteractionCount>@OpportunityCount THEN @InteractionCount ELSE @OpportunityCount END;
DECLARE @LatestOpportunityDate date=DATEADD(DAY,-90,@ToDate);   -- FIX: was -720 (customers registered later than that got no valid window)
DECLARE @LatestInteractionDate date=DATEADD(DAY,-21,@ToDate);
DECLARE @EligibleStartDate date;
DECLARE @CustomerWeightTotal int;
DECLARE @LargeCustomerWeightTotal int;
DECLARE @DateWeightTotal int;
DECLARE @LeadCount int;
DECLARE @ActiveSalespersonCount int;
DECLARE @ActiveProductCount int=0;

/* ---------------- Controlled-vocabulary note ----------------
   Interaction_Type values Call/Meeting/Visit/Activity are taken from the final LDM.
   Channel/status/stage/type/source/proposal/contract codes are PROVISIONAL because
   approved D-07 lists were not supplied. They must not be treated as final business vocabulary.
   Lead-only opportunities are kept Open at Prospecting/Qualification; no Won/Lost outcome
   is generated for an unconverted Lead until a PM-approved conversion rule exists.
   Contract_Amount remains a synthetic placeholder because no approved reconciliation formula
   to Expected_Value/Proposed_Price exists. Large/Wholesale/Enterprise-only Contract sourcing
   is retained as a provisional generation assumption pending Plan/PM confirmation.
   Territory inheritance uses the customer's assignment only when the territory is Active;
   otherwise the optional interaction territory remains NULL. This assumption is reported in QC.
   CHECKSUM over SHA2_256 bytes is masked to a non-negative 31-bit integer before modulo;
   this avoids ABS(bigint-min) overflow. It is deterministic, but is a selector, not a proof of
   collision-free randomness. Repeatability is evaluated separately by Q18 business-data hashes.
*/

BEGIN TRY
IF @Scale<=0 OR @Scale>1
    THROW 52100,'@Scale must be greater than 0 and less than or equal to 1.',1;

IF OBJECT_ID(N'sales.CustomerInteraction',N'U') IS NULL
 OR OBJECT_ID(N'sales.SalesOpportunity',N'U') IS NULL
 OR OBJECT_ID(N'sales.Contract',N'U') IS NULL
 OR OBJECT_ID(N'core.Customer',N'U') IS NULL
 OR OBJECT_ID(N'sales.Lead',N'U') IS NULL
 OR OBJECT_ID(N'core.Salesperson',N'U') IS NULL
 OR OBJECT_ID(N'ref.SalesTerritory',N'U') IS NULL
 OR OBJECT_ID(N'core.Calendar',N'U') IS NULL
 OR OBJECT_ID(N'core.Product',N'U') IS NULL
    THROW 52101,'One or more required tables are missing. Run Stage 7 deployment and parent loads first.',1;

IF EXISTS(SELECT 1 FROM sales.CustomerInteraction)
 OR EXISTS(SELECT 1 FROM sales.SalesOpportunity)
 OR EXISTS(SELECT 1 FROM sales.Contract)
    THROW 52102,'A Funnel target table already contains rows. Use only the approved team-lead reset script; no data was deleted.',1;

IF NOT EXISTS(SELECT 1 FROM core.Customer)
    THROW 52103,'core.Customer is empty. Load the Stage 8.2 Customer parent data first.',1;
IF NOT EXISTS(SELECT 1 FROM sales.Lead WHERE Conversion_Date IS NULL AND Created_Date<=@LatestOpportunityDate)
    THROW 52104,'No eligible unconverted Lead exists for the Lead-only opportunity scenario.',1;
IF NOT EXISTS(SELECT 1 FROM core.Salesperson WHERE Employment_Status=N'Active' AND Hire_Date IS NOT NULL)
    THROW 52105,'No Active salesperson with Hire_Date is available.',1;
IF NOT EXISTS(SELECT 1 FROM ref.SalesTerritory WHERE Territory_Status=N'Active')
    PRINT N'WARNING: no Active territory; interaction territory will remain NULL when customer assignment is unavailable.';

SELECT @EligibleStartDate=CASE WHEN MIN(Hire_Date)<@FromDate THEN @FromDate ELSE MIN(Hire_Date) END
FROM core.Salesperson
WHERE Employment_Status=N'Active' AND Hire_Date IS NOT NULL;

IF @EligibleStartDate>@LatestOpportunityDate
    THROW 52106,'No date window remains for opportunities after the earliest active salesperson hire date.',1;

IF EXISTS(SELECT 1 FROM core.Customer c
          LEFT JOIN ref.SalesTerritory t ON t.Sales_Territory_ID=c.Sales_Territory_ID
          WHERE c.Sales_Territory_ID IS NOT NULL AND t.Sales_Territory_ID IS NULL)
    THROW 52107,'Customer contains an orphan Sales_Territory_ID. Fix Stage 8.2 parent data; do not invent parent IDs.',1;

IF EXISTS(SELECT 1 FROM core.Customer c
          LEFT JOIN core.Salesperson s ON s.Salesperson_ID=c.Salesperson_ID
          WHERE c.Salesperson_ID IS NOT NULL AND s.Salesperson_ID IS NULL)
    THROW 52108,'Customer contains an orphan Salesperson_ID. Fix Stage 8.2 parent data.',1;

IF EXISTS(SELECT 1 FROM sales.Lead l
          LEFT JOIN core.Salesperson s ON s.Salesperson_ID=l.Salesperson_ID
          WHERE l.Salesperson_ID IS NOT NULL AND s.Salesperson_ID IS NULL)
    THROW 52109,'Lead contains an orphan Salesperson_ID. Fix parent data.',1;


 BEGIN TRANSACTION;

 DROP TABLE IF EXISTS #N,#CustomerWeighted,#LargeCustomerWeighted,#LeadPool,#ActiveSalespeople,#ActiveTerritories,#ActiveProducts,#DatePool;

 /* Active seller pool from the actual Stage 8.1 output. */
 SELECT Salesperson_ID,Hire_Date,Salesperson_Code,
        ROW_NUMBER() OVER(ORDER BY Salesperson_Code,Salesperson_ID) AS rn
 INTO #ActiveSalespeople
 FROM core.Salesperson
 WHERE Employment_Status=N'Active' AND Hire_Date IS NOT NULL;
 CREATE UNIQUE CLUSTERED INDEX IX_ActiveSalespeople_rn ON #ActiveSalespeople(rn);
 SELECT @ActiveSalespersonCount=COUNT(*) FROM #ActiveSalespeople;

 /* Active territory and product pools are also read from loaded parent tables. */
 SELECT Sales_Territory_ID,Territory_Code
 INTO #ActiveTerritories
 FROM ref.SalesTerritory WHERE Territory_Status=N'Active';
 CREATE UNIQUE CLUSTERED INDEX IX_ActiveTerritories_ID ON #ActiveTerritories(Sales_Territory_ID);

 SELECT Product_ID,Product_Code,
        ROW_NUMBER() OVER(ORDER BY Product_Code,Product_ID) AS rn
 INTO #ActiveProducts
 FROM core.Product WHERE Product_Status=N'Active';
 CREATE UNIQUE CLUSTERED INDEX IX_ActiveProducts_rn ON #ActiveProducts(rn);
 SELECT @ActiveProductCount=COUNT(*) FROM #ActiveProducts;

 /* Customer assignment is preserved: interactions inherit the customer's assigned seller/territory.
    Weighted pool gives large/wholesale customers more interactions, without inventing assignments. */
 SELECT c.Customer_ID,c.Customer_Code,c.Customer_Size,c.Salesperson_ID,c.Sales_Territory_ID,
        c.Registration_Date,c.Customer_Status,
        CASE WHEN c.Customer_Status=N'Active' THEN @LatestInteractionDate
             WHEN c.Status_Effective_Date<@LatestInteractionDate THEN c.Status_Effective_Date
             ELSE @LatestInteractionDate END AS EndDate,
        CASE WHEN LOWER(COALESCE(c.Customer_Size,N'')) LIKE N'%large%'
               OR LOWER(COALESCE(c.Customer_Size,N'')) LIKE N'%wholesale%'
               OR LOWER(COALESCE(c.Customer_Size,N'')) LIKE N'%enterprise%'
               OR c.Customer_Size LIKE N'%بزرگ%' OR c.Customer_Size LIKE N'%عمده%' THEN 4
             WHEN LOWER(COALESCE(c.Customer_Size,N'')) LIKE N'%medium%'
               OR c.Customer_Size LIKE N'%متوسط%' THEN 2 ELSE 1 END AS Weight,
        SUM(CASE WHEN LOWER(COALESCE(c.Customer_Size,N'')) LIKE N'%large%'
                   OR LOWER(COALESCE(c.Customer_Size,N'')) LIKE N'%wholesale%'
                   OR LOWER(COALESCE(c.Customer_Size,N'')) LIKE N'%enterprise%'
                   OR c.Customer_Size LIKE N'%بزرگ%' OR c.Customer_Size LIKE N'%عمده%' THEN 4
                 WHEN LOWER(COALESCE(c.Customer_Size,N'')) LIKE N'%medium%'
                   OR c.Customer_Size LIKE N'%متوسط%' THEN 2 ELSE 1 END)
          OVER(ORDER BY c.Customer_Code,c.Customer_ID ROWS UNBOUNDED PRECEDING) AS CumWeight
 INTO #CustomerWeighted
 FROM core.Customer c;
 CREATE UNIQUE CLUSTERED INDEX IX_CustomerWeighted_CumWeight ON #CustomerWeighted(CumWeight);
 SELECT @CustomerWeightTotal=MAX(CumWeight) FROM #CustomerWeighted;

 SELECT c.Customer_ID,c.Customer_Code,c.Customer_Size,c.Salesperson_ID,c.Registration_Date,
        4 AS Weight,
        SUM(4) OVER(ORDER BY c.Customer_Code,c.Customer_ID ROWS UNBOUNDED PRECEDING) AS CumWeight
 INTO #LargeCustomerWeighted
 FROM core.Customer c
 WHERE c.Customer_Status=N'Active'
   AND (LOWER(COALESCE(c.Customer_Size,N'')) LIKE N'%large%'
    OR LOWER(COALESCE(c.Customer_Size,N'')) LIKE N'%wholesale%'
    OR LOWER(COALESCE(c.Customer_Size,N'')) LIKE N'%enterprise%'
    OR c.Customer_Size LIKE N'%بزرگ%' OR c.Customer_Size LIKE N'%عمده%');
 CREATE UNIQUE CLUSTERED INDEX IX_LargeCustomerWeighted_CumWeight ON #LargeCustomerWeighted(CumWeight);
 SELECT @LargeCustomerWeightTotal=MAX(CumWeight) FROM #LargeCustomerWeighted;

 IF ISNULL(@LargeCustomerWeightTotal,0)=0
    THROW 52110,'No customer is classified as Large/Wholesale/Enterprise. Review Customer_Size values and the mapping in the gap register.',1;

 /* Unconverted Leads only: the deployed Lead table has no Customer_ID conversion bridge.
    Therefore the generator never fabricates a Lead -> Customer pairing. */
 SELECT Lead_ID,Lead_Code,Created_Date,Salesperson_ID,
        ROW_NUMBER() OVER(ORDER BY COALESCE(Lead_Code,N''),Lead_ID) AS rn
 INTO #LeadPool
 FROM sales.Lead
 WHERE Conversion_Date IS NULL AND Created_Date<=@LatestOpportunityDate;
 CREATE UNIQUE CLUSTERED INDEX IX_LeadPool_rn ON #LeadPool(rn);
 SELECT @LeadCount=COUNT(*) FROM #LeadPool;
 IF @LeadCount=0 THROW 52111,'No eligible unconverted Leads after filtering.',1;

 /* Weighted calendar: pre-Nowruz Gregorian March dates receive weight 2.
    Ramadan weighting is not inferred because Stage 8.1 Calendar has no Hijri/Ramadan attribute. */
 SELECT Calendar_Date,
        CASE WHEN MONTH(Calendar_Date)=3 AND DAY(Calendar_Date)<=20 THEN 2 ELSE 1 END AS Weight,
        SUM(CASE WHEN MONTH(Calendar_Date)=3 AND DAY(Calendar_Date)<=20 THEN 2 ELSE 1 END)
          OVER(ORDER BY Calendar_Date ROWS UNBOUNDED PRECEDING) AS CumWeight
 INTO #DatePool
 FROM core.Calendar
 WHERE Calendar_Date BETWEEN @FromDate AND @LatestInteractionDate;
 CREATE UNIQUE CLUSTERED INDEX IX_DatePool_CumWeight ON #DatePool(CumWeight);
 SELECT @DateWeightTotal=MAX(CumWeight) FROM #DatePool;
 IF ISNULL(@DateWeightTotal,0)=0 THROW 52112,'Calendar date pool is empty.',1;

 /* Deterministic set-based number source. */
 ;WITH N AS
 (
   SELECT TOP(@MaxRows) ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS n
   FROM sys.all_objects a CROSS JOIN sys.all_objects b
 )
 SELECT n INTO #N FROM N;
 CREATE UNIQUE CLUSTERED INDEX IX_N ON #N(n);

 /* ---------------------------------------------------------------------
    1) CustomerInteraction
    - Customer_ID from actual Customer parent.
    - Salesperson_ID and Sales_Territory_ID inherit customer assignments.
    - If an assigned salesperson is not Active/on-hire at event date, the optional FK is NULL.
    - Interaction natural key is Customer_ID + Interaction_DateTime + Interaction_Type.
 --------------------------------------------------------------------- */
 ;WITH S AS
 (
   SELECT n,
          CONVERT(int,(CONVERT(bigint,(CHECKSUM(HASHBYTES('SHA2_256',CONCAT(@Seed,N'|CI|',n,N'|customer'))) & 2147483647)))%@CustomerWeightTotal)+1 AS CustomerPick,
          CONVERT(int,(CONVERT(bigint,(CHECKSUM(HASHBYTES('SHA2_256',CONCAT(@Seed,N'|CI|',n,N'|date'))) & 2147483647)))%@DateWeightTotal)+1 AS DatePick,
          CONVERT(int,(CONVERT(bigint,(CHECKSUM(HASHBYTES('SHA2_256',CONCAT(@Seed,N'|CI|',n,N'|type'))) & 2147483647)))%4)+1 AS TypePick,
          CONVERT(int,(CONVERT(bigint,(CHECKSUM(HASHBYTES('SHA2_256',CONCAT(@Seed,N'|CI|',n,N'|channel'))) & 2147483647)))%4)+1 AS ChannelPick,
          CONVERT(int,(CONVERT(bigint,(CHECKSUM(HASHBYTES('SHA2_256',CONCAT(@Seed,N'|CI|',n,N'|status'))) & 2147483647)))%10) AS StatusPick,
          CONVERT(int,(CONVERT(bigint,(CHECKSUM(HASHBYTES('SHA2_256',CONCAT(@Seed,N'|CI|',n,N'|duration'))) & 2147483647)))%91) AS DurationPick,
          CONVERT(int,(CONVERT(bigint,(CHECKSUM(HASHBYTES('SHA2_256',CONCAT(@Seed,N'|CI|',n,N'|participants'))) & 2147483647)))%8)+1 AS Participants
   FROM #N WHERE n<=@InteractionCount
 )
 INSERT INTO sales.CustomerInteraction
 (
   Customer_ID,Salesperson_ID,Sales_Territory_ID,Interaction_Type,
   Interaction_DateTime,Interaction_Channel,Interaction_Subject,
   Interaction_Purpose,Interaction_Status,Interaction_Result,
   Interaction_Duration_Minutes,Participants_Count,Follow_Up_Required,
   Follow_Up_Date,Interaction_Notes
 )
 SELECT c.Customer_ID,
        CASE WHEN s.Hire_Date<=ed.EffDate THEN s.Salesperson_ID ELSE NULL END,
        t.Sales_Territory_ID,
        CASE x.TypePick WHEN 1 THEN N'Call' WHEN 2 THEN N'Meeting' WHEN 3 THEN N'Visit' ELSE N'Activity' END,
        DATEADD(SECOND,x.n,DATEADD(HOUR,9,CONVERT(datetime2(0),ed.EffDate))),
        CASE x.ChannelPick WHEN 1 THEN N'Phone' WHEN 2 THEN N'In-Person' WHEN 3 THEN N'Email' ELSE N'Online Meeting' END,
        CASE x.TypePick WHEN 1 THEN N'پیگیری تلفنی مشتری'
                        WHEN 2 THEN N'جلسه بررسی نیاز مشتری'
                        WHEN 3 THEN N'بازدید از محل مشتری'
                        ELSE N'فعالیت پیگیری فروش' END,
        CASE x.TypePick WHEN 1 THEN N'پیگیری وضعیت خرید و نیازهای مشتری'
                        WHEN 2 THEN N'بررسی نیازها و شرایط همکاری'
                        WHEN 3 THEN N'ارزیابی شرایط و ظرفیت مشتری'
                        ELSE N'هماهنگی اقدامات بعدی فروش' END,
        CASE WHEN x.StatusPick<9 THEN N'Completed' ELSE N'Cancelled' END,
        CASE WHEN x.StatusPick>=9 THEN N'لغو شد'
             ELSE CASE x.n%4 WHEN 0 THEN N'نیاز مشتری شناسایی و ثبت شد'
                             WHEN 1 THEN N'اطلاعات تکمیلی ارسال شد'
                             WHEN 2 THEN N'پیگیری بعدی توافق شد'
                             ELSE N'مذاکره در جریان است' END END,
        CASE WHEN x.TypePick=1 THEN x.DurationPick ELSE NULL END,
        CASE WHEN x.TypePick IN(2,3) THEN x.Participants ELSE NULL END,
        CASE WHEN x.n%5=0 THEN 1 ELSE 0 END,
        CASE WHEN x.n%5=0 THEN DATEADD(DAY,1+(x.n%21),ed.EffDate) ELSE NULL END,
        CONCAT(N'Mock | ',@DataVersion,N' | Interaction-',x.n)
 FROM S x
 JOIN #CustomerWeighted c ON c.CumWeight>=x.CustomerPick AND c.CumWeight-c.Weight<x.CustomerPick
 JOIN #DatePool d ON d.CumWeight>=x.DatePick AND d.CumWeight-d.Weight<x.DatePick
 CROSS APPLY (SELECT CASE WHEN d.Calendar_Date>=c.Registration_Date AND d.Calendar_Date<=c.EndDate THEN d.Calendar_Date
                          ELSE DATEADD(DAY,x.DatePick%(DATEDIFF(DAY,c.Registration_Date,c.EndDate)+1),c.Registration_Date) END AS EffDate) ed
 LEFT JOIN core.Salesperson s
   ON s.Salesperson_ID=c.Salesperson_ID
  AND s.Employment_Status=N'Active'
 LEFT JOIN ref.SalesTerritory t
   ON t.Sales_Territory_ID=c.Sales_Territory_ID
  AND t.Territory_Status=N'Active';

 /* ---------------------------------------------------------------------
    2) SalesOpportunity
    - 20% Lead-only (OI-07); rows are unconverted Lead + NULL Customer and remain Open.
    - Customer-origin Won opportunities are assigned to Large/Wholesale customers
      so the planned Contract volume can be sourced from genuine Won opportunities.
    - Seller prefers the assigned customer/lead salesperson if Active and hired by date;
      otherwise another actual Active salesperson is selected.
 --------------------------------------------------------------------- */
 ;WITH S AS
 (
   SELECT n,
          CASE WHEN n%5=0 THEN 1 ELSE 0 END AS IsLeadOnly,
          CASE WHEN n%5=0 THEN 0
               WHEN n%20<5 THEN 1
               WHEN n%20<7 THEN 2
               ELSE 0 END AS OutcomeCode,
          CONVERT(int,(CONVERT(bigint,(CHECKSUM(HASHBYTES('SHA2_256',CONCAT(@Seed,N'|OPP|',n,N'|lead'))) & 2147483647)))%@LeadCount)+1 AS LeadPick,
          CONVERT(int,(CONVERT(bigint,(CHECKSUM(HASHBYTES('SHA2_256',CONCAT(@Seed,N'|OPP|',n,N'|customer'))) & 2147483647)))%@CustomerWeightTotal)+1 AS CustomerPick,
          CONVERT(int,(CONVERT(bigint,(CHECKSUM(HASHBYTES('SHA2_256',CONCAT(@Seed,N'|OPP|',n,N'|largecustomer'))) & 2147483647)))%@LargeCustomerWeightTotal)+1 AS LargeCustomerPick
   FROM #N WHERE n<=@OpportunityCount
 ),
 P AS
 (
   SELECT s.*,
          l.Lead_ID,l.Created_Date AS LeadCreatedDate,l.Salesperson_ID AS LeadSalespersonID,
          CASE WHEN s.IsLeadOnly=1 THEN NULL
               WHEN s.OutcomeCode=1 THEN lc.Customer_ID
               ELSE c.Customer_ID END AS Customer_ID,
          CASE WHEN s.IsLeadOnly=1 THEN NULL
               WHEN s.OutcomeCode=1 THEN lc.Salesperson_ID
               ELSE c.Salesperson_ID END AS CustomerSalespersonID,
          CASE WHEN s.IsLeadOnly=1 THEN NULL
               WHEN s.OutcomeCode=1 THEN lc.Registration_Date
               ELSE c.Registration_Date END AS CustomerRegDate
   FROM S s
   LEFT JOIN #LeadPool l ON s.IsLeadOnly=1 AND l.rn=s.LeadPick
   LEFT JOIN #CustomerWeighted c ON s.IsLeadOnly=0 AND s.OutcomeCode<>1 AND c.CumWeight>=s.CustomerPick AND c.CumWeight-c.Weight<s.CustomerPick
   LEFT JOIN #LargeCustomerWeighted lc ON s.IsLeadOnly=0 AND s.OutcomeCode=1 AND lc.CumWeight>=s.LargeCustomerPick AND lc.CumWeight-lc.Weight<s.LargeCustomerPick
 ),
 D AS
 (
   SELECT p.*,
          CASE WHEN p.IsLeadOnly=1 THEN (CASE WHEN p.LeadCreatedDate>@EligibleStartDate THEN p.LeadCreatedDate ELSE @EligibleStartDate END)
             WHEN p.CustomerRegDate>@EligibleStartDate THEN p.CustomerRegDate
             ELSE @EligibleStartDate END AS MinOppDate
   FROM P p
 )
 INSERT INTO sales.SalesOpportunity
 (
   Customer_ID,Lead_ID,Salesperson_ID,Opportunity_Code,Opportunity_Name,
   Opportunity_Stage,Opportunity_Status,Opportunity_Type,Opportunity_Date,
   Expected_Close_Date,Probability,Expected_Value,Opportunity_Source,Description,
   Proposal_Number,Proposal_Date,Proposal_Status,Proposal_Valid_From,Proposal_Valid_To,
   Proposed_Price,Proposal_Discount_Amount,Proposal_Payment_Terms,Proposal_Delivery_Terms
 )
 SELECT
   d.Customer_ID,
   CASE WHEN d.IsLeadOnly=1 THEN d.Lead_ID ELSE NULL END,
   seller.Salesperson_ID,
   CONCAT(N'OPP-',RIGHT(CONCAT(N'000000',d.n),6)),
   CONCAT(N'فرصت فروش آزمایشی ',d.n),
   CASE WHEN d.IsLeadOnly=1
        THEN CASE WHEN d.n%2=0 THEN N'Prospecting' ELSE N'Qualification' END
        ELSE CASE d.OutcomeCode WHEN 1 THEN N'Closed Won' WHEN 2 THEN N'Closed Lost'
             ELSE CASE d.n%4 WHEN 0 THEN N'Prospecting' WHEN 1 THEN N'Qualification'
                             WHEN 2 THEN N'Proposal' ELSE N'Negotiation' END END END,
   CASE d.OutcomeCode WHEN 1 THEN N'Won' WHEN 2 THEN N'Lost' ELSE N'Open' END,
   CASE WHEN d.IsLeadOnly=1 THEN N'New Business' ELSE N'Existing Customer' END,
   od.OpportunityDate,
   CASE WHEN d.OutcomeCode IN(1,2) AND DATEADD(DAY,30+(d.n%150),od.OpportunityDate)>@AsOfDate THEN @AsOfDate
        ELSE DATEADD(DAY,30+(d.n%150),od.OpportunityDate) END,
   CASE WHEN d.IsLeadOnly=1 THEN CONVERT(decimal(5,2),5+(d.n%36))
        WHEN d.OutcomeCode=1 THEN CONVERT(decimal(5,2),85+(d.n%16))
        WHEN d.OutcomeCode=2 THEN CONVERT(decimal(5,2),0)
        ELSE CONVERT(decimal(5,2),5+(d.n%70)) END,
   CONVERT(decimal(18,2),5000000+(d.n%200)*250000),
   CASE WHEN d.IsLeadOnly=1 THEN N'Lead' ELSE N'Existing Customer' END,
   CONCAT(N'Synthetic opportunity | ',@DataVersion),
   CASE WHEN d.IsLeadOnly=0 AND (d.OutcomeCode IN(1,2) OR d.n%4 IN(2,3))
        THEN CONCAT(N'PROP-',RIGHT(CONCAT(N'000000',d.n),6)) ELSE NULL END,
   CASE WHEN d.IsLeadOnly=0 AND (d.OutcomeCode IN(1,2) OR d.n%4 IN(2,3))
        THEN DATEADD(DAY,1+(d.n%10),od.OpportunityDate) ELSE NULL END,
   CASE WHEN d.IsLeadOnly=1 THEN NULL
        WHEN d.OutcomeCode=1 THEN N'Accepted'
        WHEN d.OutcomeCode=2 THEN N'Rejected'
        WHEN d.n%4 IN(2,3) THEN N'Sent' ELSE NULL END,
   CASE WHEN d.IsLeadOnly=0 AND (d.OutcomeCode IN(1,2) OR d.n%4 IN(2,3))
        THEN DATEADD(DAY,1+(d.n%10),od.OpportunityDate) ELSE NULL END,
   CASE WHEN d.IsLeadOnly=0 AND (d.OutcomeCode IN(1,2) OR d.n%4 IN(2,3))
        THEN DATEADD(DAY,31+(d.n%60),DATEADD(DAY,1+(d.n%10),od.OpportunityDate)) ELSE NULL END,
   CASE WHEN d.IsLeadOnly=0 AND (d.OutcomeCode IN(1,2) OR d.n%4 IN(2,3))
        THEN CONVERT(decimal(18,2),(5000000+(d.n%200)*250000)*1.05) ELSE NULL END,
   CASE WHEN d.IsLeadOnly=0 AND (d.OutcomeCode IN(1,2) OR d.n%4 IN(2,3))
        THEN CONVERT(decimal(18,2),(5000000+(d.n%200)*250000)*1.05*0.05) ELSE NULL END,
   CASE WHEN d.IsLeadOnly=0 AND (d.OutcomeCode IN(1,2) OR d.n%4 IN(2,3)) THEN N'پرداخت توافقی' ELSE NULL END,
   CASE WHEN d.IsLeadOnly=0 AND (d.OutcomeCode IN(1,2) OR d.n%4 IN(2,3)) THEN N'تحویل طبق توافق طرفین' ELSE NULL END
 FROM D d
 CROSS APPLY
 (
   SELECT DATEADD(DAY,
       CONVERT(int,(CONVERT(bigint,(CHECKSUM(HASHBYTES('SHA2_256',CONCAT(@Seed,N'|OPP|',d.n,N'|date'))) & 2147483647)))
         % (DATEDIFF(DAY,d.MinOppDate,@LatestOpportunityDate)+1)),
       d.MinOppDate) AS OpportunityDate
 ) od
 CROSS APPLY
 (
   SELECT TOP(1) a.Salesperson_ID
   FROM #ActiveSalespeople a
   WHERE a.Hire_Date<=od.OpportunityDate
   ORDER BY CASE WHEN a.Salesperson_ID=COALESCE(d.CustomerSalespersonID,d.LeadSalespersonID) THEN 0 ELSE 1 END,
            (CONVERT(bigint,(CHECKSUM(HASHBYTES('SHA2_256',CONCAT(@Seed,N'|OPP|',d.n,N'|seller|',a.Salesperson_ID))) & 2147483647)))
 ) seller
 WHERE (d.IsLeadOnly=0 AND d.Customer_ID IS NOT NULL)
    OR (d.IsLeadOnly=1 AND d.Lead_ID IS NOT NULL);

 /* ---------------------------------------------------------------------
    3) Contract
    - Source is only Won customer-linked opportunities for Large/Wholesale customers (provisional segment assumption).
    - Customer_ID is copied from the Won opportunity; no independent random customer assignment.
    - Product_ID is optionally selected only from actual Active products.
    - Item columns remain NULL because the final LDM does not define the amount reconciliation formula.
 --------------------------------------------------------------------- */
 ;WITH EligibleWon AS
 (
   SELECT o.Sales_Opportunity_ID,o.Opportunity_Code,o.Customer_ID,o.Opportunity_Date,
          ROW_NUMBER() OVER(ORDER BY o.Opportunity_Code,o.Sales_Opportunity_ID) AS rn
   FROM sales.SalesOpportunity o
   JOIN core.Customer c ON c.Customer_ID=o.Customer_ID
   WHERE o.Opportunity_Status=N'Won'
     AND o.Customer_ID IS NOT NULL
     AND c.Customer_Status=N'Active'
     AND (LOWER(COALESCE(c.Customer_Size,N'')) LIKE N'%large%'
       OR LOWER(COALESCE(c.Customer_Size,N'')) LIKE N'%wholesale%'
       OR LOWER(COALESCE(c.Customer_Size,N'')) LIKE N'%enterprise%'
       OR c.Customer_Size LIKE N'%بزرگ%' OR c.Customer_Size LIKE N'%عمده%')
 ),
 Pick AS (SELECT TOP(@ContractCount) * FROM EligibleWon ORDER BY rn),
 K AS
 (
   /* FIX: End_Date is derived from Start_Date (12-24 months, capped at @ToDate); status follows the dates.
      Old logic used @AsOfDate-based dates and could give End_Date < Start_Date (CHECK violation). */
   SELECT p.*,
          CASE WHEN DATEADD(DAY,365+(p.rn%365),p.Opportunity_Date)>@ToDate THEN @ToDate
               ELSE DATEADD(DAY,365+(p.rn%365),p.Opportunity_Date) END AS EndDt
   FROM Pick p
 )
 INSERT INTO sales.Contract
 (
   Customer_ID,Sales_Opportunity_ID,Product_ID,Contract_Number,Contract_Type,
   Contract_Status,Start_Date,End_Date,Closed_Date,Contract_Amount,Currency_Code,
   Payment_Terms,Delivery_Terms,Contract_Conditions,
   Item_Quantity,Item_Unit_Price,Item_Unit_of_Measure
 )
 SELECT k.Customer_ID,k.Sales_Opportunity_ID,
        prod.Product_ID,
        CONCAT(N'CTR-',RIGHT(CONCAT(N'000000',k.rn),6)),
        N'Sales',
        CASE WHEN k.EndDt>=@AsOfDate THEN N'Active'
             WHEN k.rn%8=0 THEN N'Terminated' WHEN k.rn%8=1 THEN N'Cancelled' ELSE N'Completed' END,
        k.Opportunity_Date,
        k.EndDt,
        CASE WHEN k.EndDt>=@AsOfDate THEN NULL
             WHEN k.rn%8 IN(0,1) THEN (CASE WHEN DATEADD(DAY,30+(k.rn%180),k.Opportunity_Date)>k.EndDt THEN k.EndDt
                                            ELSE DATEADD(DAY,30+(k.rn%180),k.Opportunity_Date) END)
             ELSE k.EndDt END,
        CONVERT(decimal(18,2),10000000+(k.rn%100)*500000),
        'IRR',
        N'پرداخت توافقی',
        N'تحویل طبق برنامه توافق‌شده',
        CONCAT(N'Synthetic contract | ',@DataVersion),
        NULL,NULL,NULL
 FROM K k
 OUTER APPLY
 (
   SELECT TOP(1) a.Product_ID
   FROM #ActiveProducts a JOIN core.Product cp ON cp.Product_ID=a.Product_ID
   WHERE k.rn%10<7 AND cp.Launch_Date<=k.Opportunity_Date      -- only products already launched at contract start
   ORDER BY (a.rn*7919+k.rn*104729)%100003,a.rn
 ) prod
 WHERE k.rn<=@ContractCount;

 /* Transaction-level assertions. Any failure rolls back all three inserts. */
 IF (SELECT COUNT(*) FROM sales.CustomerInteraction)<>@InteractionCount
    THROW 52120,'CustomerInteraction count mismatch.',1;
 IF (SELECT COUNT(*) FROM sales.SalesOpportunity)<>@OpportunityCount
    THROW 52121,'SalesOpportunity count mismatch. Check eligible Lead/Customer parent data.',1;
 IF (SELECT COUNT(*) FROM sales.Contract)<>@ContractCount
    THROW 52122,'Insufficient Won opportunities for Large/Wholesale customers to meet Contract target.',1;

 COMMIT TRANSACTION;

 PRINT CONCAT(N'DataVersion=',@DataVersion,N'; Seed=',@Seed,N'; Scale=',@Scale);
 PRINT CONCAT(N'CustomerInteraction inserted: ',(SELECT COUNT(*) FROM sales.CustomerInteraction));
 PRINT CONCAT(N'SalesOpportunity inserted: ',(SELECT COUNT(*) FROM sales.SalesOpportunity));
 PRINT CONCAT(N'Contract inserted: ',(SELECT COUNT(*) FROM sales.Contract));
 PRINT CONCAT(N'Active product pool: ',@ActiveProductCount);
 INSERT INTO #T1Log VALUES(N'8.3',N'sales.CustomerInteraction',@InteractionCount),(N'8.3',N'sales.SalesOpportunity',@OpportunityCount),(N'8.3',N'sales.Contract',@ContractCount);
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 UPDATE #T1Cfg SET Abort=1;
 PRINT CONCAT(N'ERROR ',ERROR_NUMBER(),N' at line ',ERROR_LINE(),N': ',ERROR_MESSAGE());
 PRINT N'Transaction rolled back; no Funnel rows were committed.';
 THROW;
END CATCH;
GO

GO
/* ===================== SECTION 5 : 8.4 SalesOrder, SalesOrderItem ============
 REWRITTEN (the supplied 8.4 produced data that 8.5-8.7 cannot use):
  - fixed 6,000/21,000 rows ignoring @Scale  -> OrderBase 60,000 x @Scale, 2-6 lines per order
  - Salesperson_ID / Sales_Region_ID were NULL -> 8.7 (targets/commission) stopped with "no attributable sales":
    now = customer's salesperson (or a salesperson hired and active at order date) and the branch's Team region
  - prices were invented (not ProductPrice) -> Unit_Price = Standard price of the base SKU valid at order date (Team 2 rule T2-S8-01)
  - products chosen without Launch_Date check and could repeat inside an order (8.5 stops on that) -> launch-date check + distinct products
  - order dates ignored status/registration of the customer and the "no order" scenario -> window = [Registration_Date, status end]
  - Promotion / Contract / Interaction links were NULL -> filled only when dates and customer match
  - CHECKSUM selector replaced by the guide's HASHBYTES formula (Q17)
  - Payment_Terms aligned with the Due_Date rule of 8.5 (same hash)
  Status values Completed / Cancelled / Processing are PROVISIONAL (D-07 open).
=============================================================================*/
SET NOCOUNT ON; SET XACT_ABORT ON;
IF EXISTS (SELECT 1 FROM #T1Cfg WHERE Abort = 1) BEGIN PRINT N'SKIPPED section 5 (earlier failure)'; RETURN; END;
DECLARE @DataVersion nvarchar(50), @Seed int, @Scale decimal(5,2), @FromDate date, @ToDate date, @AsOfDate date;
SELECT @DataVersion = DataVersion, @Seed = Seed, @Scale = Scale, @FromDate = FromDate, @ToDate = ToDate, @AsOfDate = AsOfDate FROM #T1Cfg;

DECLARE @OrderBase int = 60000;                       -- full volume (guide: 20,000-100,000 orders)
DECLARE @OrderCount int = CONVERT(int, ROUND(@OrderBase * @Scale, 0));
DECLARE @InactiveSpCutoff date = '2024-12-31';        -- same assumption as 8.2 (inactive salesperson worked until this date)
DECLARE @LastOrderDate date = DATEADD(DAY, -10, @ToDate);   -- delivery (<= +7 days) stays inside the Calendar
DECLARE @PromoShare int = 2500, @ContractShare int = 4000, @InteractionShare int = 3000;  -- per 10,000
DECLARE @CancelShare int = 500;                       -- 5% cancelled (per 10,000)
DECLARE @StCompleted nvarchar(30) = N'Completed', @StCancelled nvarchar(30) = N'Cancelled', @StProcessing nvarchar(30) = N'Processing';
DECLARE @MinSalesDate date, @CustTotal int, @InsOrders int, @InsItems int;

BEGIN TRY
    IF OBJECT_ID(N'sales.SalesOrder',N'U') IS NULL OR OBJECT_ID(N'sales.SalesOrderItem',N'U') IS NULL OR OBJECT_ID(N'core.Customer',N'U') IS NULL
       OR OBJECT_ID(N'core.Calendar',N'U') IS NULL OR OBJECT_ID(N'core.Product',N'U') IS NULL OR OBJECT_ID(N'core.SKU',N'U') IS NULL
       OR OBJECT_ID(N'marketing.ProductPrice',N'U') IS NULL OR OBJECT_ID(N'marketing.Promotion',N'U') IS NULL
        THROW 52401, 'A required table is missing.', 1;
    IF EXISTS (SELECT 1 FROM sales.SalesOrder) OR EXISTS (SELECT 1 FROM sales.SalesOrderItem)
        THROW 52403, 'Target tables must be empty. Existing data was not deleted.', 1;
    IF NOT EXISTS (SELECT 1 FROM core.Customer) THROW 52404, 'Customer pool is empty (run 8.2 first).', 1;

    DROP TABLE IF EXISTS #ProdPrice, #DP0, #DP, #CW0, #CW, #Promo, #Ctr, #Int, #Ord, #OrdMap, #Cand0, #Cand, #Line, #Tot;
    BEGIN TRANSACTION;

    /* ---- price book: Standard price of the base SKU (lowest SKU_Code) per Active product (Team 2 rule T2-S8-01) ---- */
    SELECT p.Product_ID, p.Launch_Date, ISNULL(p.Unit_Of_Measure, N'Unit') AS Unit_of_Measure,
           pp.Unit_Price, pp.Effective_From, ISNULL(pp.Effective_To, CONVERT(date,'9999-12-31')) AS Effective_To
    INTO #ProdPrice
    FROM core.Product p
    CROSS APPLY (SELECT TOP (1) s.SKU_ID FROM core.SKU s WHERE s.Product_ID = p.Product_ID ORDER BY s.SKU_Code) bs
    JOIN marketing.ProductPrice pp ON pp.SKU_ID = bs.SKU_ID AND pp.Price_Type = N'Standard'
    WHERE p.Product_Status = N'Active' AND pp.Unit_Price > 0;
    CREATE CLUSTERED INDEX IX_ProdPrice ON #ProdPrice (Effective_From, Effective_To);

    /* first date on which at least 3 products are sellable (launched + valid price) */
    SELECT @MinSalesDate = MIN(c.Calendar_Date)
    FROM core.Calendar c
    CROSS APPLY (SELECT COUNT(DISTINCT x.Product_ID) AS cnt FROM #ProdPrice x
                 WHERE x.Launch_Date <= c.Calendar_Date AND x.Effective_From <= c.Calendar_Date AND x.Effective_To >= c.Calendar_Date) e
    WHERE c.Calendar_Date BETWEEN @FromDate AND @LastOrderDate AND e.cnt >= 3;
    IF @MinSalesDate IS NULL THROW 52407, 'No date with at least 3 sellable products (check Team 2 Launch_Date / ProductPrice).', 1;

    /* ---- weighted date pool: season (Nowruz, Yalda, school opening), growth/inflation, Friday weekend ---- */
    SELECT c.Calendar_ID, c.Calendar_Date,
           CONVERT(int, ROUND(100.0 * m.f * (1.0 + 0.18 * (c.Year_Number - 2019))
                       * CASE WHEN DATEDIFF(DAY, '20190104', c.Calendar_Date) % 7 = 0 THEN 0.25 ELSE 1.0 END, 0)) AS W
    INTO #DP0
    FROM core.Calendar c
    CROSS APPLY (SELECT CASE c.Month_Number WHEN 1 THEN 0.85 WHEN 2 THEN 1.05 WHEN 3 THEN 1.40 WHEN 4 THEN 0.90 WHEN 5 THEN 0.95
                                            WHEN 6 THEN 1.00 WHEN 7 THEN 0.90 WHEN 8 THEN 0.95 WHEN 9 THEN 1.05 WHEN 10 THEN 1.00
                                            WHEN 11 THEN 0.95 ELSE 1.20 END AS f) m
    WHERE c.Calendar_Date BETWEEN @MinSalesDate AND @LastOrderDate;
    SELECT Calendar_ID, Calendar_Date, W, SUM(W) OVER (ORDER BY Calendar_Date ROWS UNBOUNDED PRECEDING) AS CumW INTO #DP FROM #DP0;
    CREATE UNIQUE CLUSTERED INDEX IX_DP_CumW ON #DP (CumW);
    CREATE UNIQUE INDEX IX_DP_Date ON #DP (Calendar_Date) INCLUDE (CumW, Calendar_ID);

    /* ---- customer pool: not "no order", window [Registration_Date, end of activity], size-weighted (long tail) ---- */
    SELECT c.Customer_ID, c.Customer_Code, c.Registration_Date, c.Sales_Channel_ID, c.Salesperson_ID, c.Customer_Size,
           CASE WHEN c.Customer_Status = N'Active' THEN @LastOrderDate
                WHEN c.Status_Effective_Date < @LastOrderDate THEN c.Status_Effective_Date ELSE @LastOrderDate END AS EndDt,
           CASE c.Customer_Size WHEN N'Small' THEN 1 WHEN N'Medium' THEN 3 WHEN N'Large' THEN 8 WHEN N'Enterprise' THEN 20 ELSE 1 END AS Wt
    INTO #CW0
    FROM core.Customer c
    WHERE NOT EXISTS (SELECT 1 FROM #T1NoOrder z WHERE z.Customer_ID = c.Customer_ID);

    SELECT w.*, l.lo, h.hi,
           SUM(w.Wt) OVER (ORDER BY w.Customer_Code ROWS UNBOUNDED PRECEDING) AS CumWt
    INTO #CW
    FROM #CW0 w
    CROSS APPLY (SELECT ISNULL(MAX(d.CumW),0) AS lo FROM #DP d WHERE d.Calendar_Date < w.Registration_Date) l
    CROSS APPLY (SELECT ISNULL(MAX(d.CumW),0) AS hi FROM #DP d WHERE d.Calendar_Date <= w.EndDt) h
    WHERE h.hi > l.lo;
    CREATE UNIQUE CLUSTERED INDEX IX_CW ON #CW (CumWt);
    SELECT @CustTotal = MAX(CumWt) FROM #CW;
    IF ISNULL(@CustTotal,0) = 0 THROW 52405, 'No customer is eligible for orders.', 1;

    /* ---- promotions usable by orders (never Planned), contracts and interactions of the same customer ---- */
    SELECT Promotion_ID, Start_Date, End_Date, Discount_Type, Discount_Value
    INTO #Promo FROM marketing.Promotion
    WHERE Promotion_Status IN (N'Active', N'Expired') AND Discount_Value > 0;
    SELECT Contract_ID, Customer_ID, Start_Date, COALESCE(Closed_Date, End_Date) AS Eff_End
    INTO #Ctr FROM sales.Contract WHERE Contract_Status IN (N'Active', N'Completed', N'Terminated', N'Cancelled');
    CREATE CLUSTERED INDEX IX_Ctr ON #Ctr (Customer_ID, Start_Date);
    SELECT Customer_Interaction_ID, Customer_ID, CONVERT(date, Interaction_DateTime) AS IDate
    INTO #Int FROM sales.CustomerInteraction WHERE Interaction_Status = N'Completed';
    CREATE CLUSTERED INDEX IX_Int ON #Int (Customer_ID, IDate);

    /* ---- order headers (staging) ---- */
    ;WITH N AS (SELECT TOP (@OrderCount) CONVERT(int, ROW_NUMBER() OVER (ORDER BY (SELECT NULL))) AS n FROM sys.all_objects a CROSS JOIN sys.all_objects b),
    R AS
    (
        SELECT n.n,
               CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|SO|',n.n,N'|cust')))) AS h_cust, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|SO|',n.n,N'|date')))) AS h_date, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|SO|',n.n,N'|stat')))) AS h_stat, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|SO|',n.n,N'|del')))) AS h_del, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|SO|',n.n,N'|promo')))) AS h_promo,
               CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|SO|',n.n,N'|ctr')))) AS h_ctr, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|SO|',n.n,N'|int')))) AS h_int, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|SO|',n.n,N'|lines')))) AS h_lines,
               CONVERT(decimal(18,10), CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',
                   CONCAT(@Seed,N'|Invoice|',CONCAT(N'SO-',@Seed,N'-',RIGHT(CONCAT(N'000000',n.n),6)),N'|terms')))) / 4294967296.0) AS u_term   -- same draw as 8.5 Due_Date
        FROM N n
    )
    SELECT r.n, c.Customer_ID, c.Customer_Size, c.Sales_Channel_ID, c.Salesperson_ID AS Cust_Salesperson_ID,
           dd.Calendar_ID, dd.Calendar_Date AS Order_Date,
           CONCAT(N'SO-',@Seed,N'-',RIGHT(CONCAT(N'000000',r.n),6)) AS Sales_Order_Number,
           CASE WHEN r.h_stat % 10000 < @CancelShare THEN @StCancelled
                WHEN dd.Calendar_Date > DATEADD(DAY,-30,@AsOfDate) AND r.h_stat % 10000 < 4500 THEN @StProcessing
                ELSE @StCompleted END AS Order_Status,
           r.h_del, r.h_promo, r.h_ctr, r.h_int, r.h_lines, r.u_term
    INTO #Ord
    FROM R r
    JOIN #CW c ON c.CumWt >= (r.h_cust % @CustTotal) + 1 AND c.CumWt - c.Wt < (r.h_cust % @CustTotal) + 1
    CROSS APPLY (SELECT TOP (1) d.Calendar_ID, d.Calendar_Date FROM #DP d
                 WHERE d.CumW >= c.lo + 1 + (r.h_date % (c.hi - c.lo)) ORDER BY d.CumW) dd;
    IF (SELECT COUNT(*) FROM #Ord) <> @OrderCount THROW 52408, 'Order staging count differs from the planned count.', 1;

    ALTER TABLE #Ord ADD Salesperson_ID int NULL, Sales_Region_ID int NULL, Promotion_ID int NULL, Promo_Type nvarchar(30) NULL,
                         Promo_Value decimal(18,2) NULL, Contract_ID int NULL, Customer_Interaction_ID int NULL,
                         Delivery_Date date NULL, Payment_Terms nvarchar(250) NULL;
    CREATE UNIQUE CLUSTERED INDEX IX_Ord ON #Ord (n);

    /* salesperson: customer's own; fallback = non-manager hired at order date, active (or inactive but before the cutoff) */
    UPDATE o SET Salesperson_ID = COALESCE(own.Salesperson_ID, alt.Salesperson_ID)
    FROM #Ord o
    OUTER APPLY (SELECT s.Salesperson_ID FROM core.Salesperson s WHERE s.Salesperson_ID = o.Cust_Salesperson_ID AND s.Hire_Date <= o.Order_Date) own
    OUTER APPLY (SELECT TOP (1) s.Salesperson_ID FROM core.Salesperson s
                 WHERE own.Salesperson_ID IS NULL AND s.Role <> N'Manager' AND s.Hire_Date <= o.Order_Date
                   AND (s.Employment_Status = N'Active' OR o.Order_Date <= @InactiveSpCutoff)
                 ORDER BY CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|SO|',o.n,N'|sp', N'|', s.Salesperson_ID))))) alt;
    UPDATE o SET Sales_Region_ID = b.Sales_Region_ID
    FROM #Ord o JOIN core.Salesperson s ON s.Salesperson_ID = o.Salesperson_ID JOIN core.Branch b ON b.Branch_ID = s.Branch_ID;

    /* promotion only inside its own validity period */
    UPDATE o SET Promotion_ID = pr.Promotion_ID, Promo_Type = pr.Discount_Type, Promo_Value = pr.Discount_Value
    FROM #Ord o
    CROSS APPLY (SELECT TOP (1) p.Promotion_ID, p.Discount_Type, p.Discount_Value FROM #Promo p
                 WHERE o.h_promo % 10000 < @PromoShare AND p.Start_Date <= o.Order_Date AND p.End_Date >= o.Order_Date
                 ORDER BY CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|SO|',o.n,N'|promoPick', N'|', p.Promotion_ID))))) pr;

    /* contract of the same customer valid on the order date; interaction of the same customer in the last 30 days */
    UPDATE o SET Contract_ID = k.Contract_ID
    FROM #Ord o
    CROSS APPLY (SELECT TOP (1) c.Contract_ID FROM #Ctr c
                 WHERE o.h_ctr % 10000 < @ContractShare AND c.Customer_ID = o.Customer_ID
                   AND o.Order_Date BETWEEN c.Start_Date AND c.Eff_End ORDER BY c.Start_Date, c.Contract_ID) k;
    UPDATE o SET Customer_Interaction_ID = i.Customer_Interaction_ID
    FROM #Ord o
    CROSS APPLY (SELECT TOP (1) x.Customer_Interaction_ID FROM #Int x
                 WHERE o.h_int % 10000 < @InteractionShare AND x.Customer_ID = o.Customer_ID
                   AND x.IDate BETWEEN DATEADD(DAY,-30,o.Order_Date) AND o.Order_Date ORDER BY x.IDate DESC, x.Customer_Interaction_ID) i;

    UPDATE #Ord SET Delivery_Date = CASE WHEN Order_Status = @StCompleted THEN DATEADD(DAY, 1 + (h_del % 7), Order_Date) END,
                    Payment_Terms = CONCAT(N'پرداخت ', CASE WHEN u_term < 0.20 THEN 15 WHEN u_term < 0.65 THEN 30 WHEN u_term < 0.90 THEN 45 ELSE 60 END, N' روزه');
    IF EXISTS (SELECT 1 FROM #Ord WHERE Salesperson_ID IS NULL OR Sales_Region_ID IS NULL)
        THROW 52409, 'An order has no attributable salesperson/region (check 8.1 salesperson and branch data).', 1;

    /* ---- lines: distinct products sellable on the order date; price = Standard price valid on that date ---- */
    SELECT o.n, pp.Product_ID, pp.Unit_Price, pp.Unit_of_Measure,
           ROW_NUMBER() OVER (PARTITION BY o.n, pp.Product_ID ORDER BY pp.Effective_From DESC) AS dup
    INTO #Cand0
    FROM #Ord o
    JOIN #ProdPrice pp ON pp.Launch_Date <= o.Order_Date AND pp.Effective_From <= o.Order_Date AND pp.Effective_To >= o.Order_Date;

    SELECT c.n, c.Product_ID, c.Unit_Price, c.Unit_of_Measure,
           ROW_NUMBER() OVER (PARTITION BY c.n ORDER BY
               CONVERT(decimal(18,10), CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|SO|',c.n,N'|prod', N'|', c.Product_ID))))) / 4294967296.0 / (1 + (c.Product_ID % 5)), c.Product_ID) AS rk
    INTO #Cand
    FROM #Cand0 c WHERE c.dup = 1;

    SELECT o.n, c.rk AS Line_Number, c.Product_ID, c.Unit_of_Measure, c.Unit_Price,
           CONVERT(decimal(18,3), 1 + (CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|SO|',o.n,N'|qty', N'|', c.rk))))) % (CASE o.Customer_Size WHEN N'Small' THEN 20 WHEN N'Medium' THEN 50 WHEN N'Large' THEN 120 WHEN N'Enterprise' THEN 200 ELSE 20 END)) AS Quantity,
           o.Promo_Type, o.Promo_Value, o.Order_Status
    INTO #Line
    FROM #Cand c JOIN #Ord o ON o.n = c.n
    WHERE c.rk <= 2 + (o.h_lines % 5);

    ALTER TABLE #Line ADD Gross decimal(18,2) NULL, Disc decimal(18,2) NULL, Net decimal(18,2) NULL, Disc_Pct decimal(5,2) NULL;
    UPDATE #Line SET Gross = CONVERT(decimal(18,2), ROUND(Quantity * Unit_Price, 0));
    UPDATE #Line SET Disc = CONVERT(decimal(18,2),
           CASE WHEN Promo_Type = N'Percentage' THEN ROUND(Gross * Promo_Value / 100.0, 0)
                WHEN Promo_Type = N'Fixed Amount' AND Line_Number = 1 THEN CASE WHEN Promo_Value < Gross THEN ROUND(Promo_Value, 0) ELSE Gross END
                ELSE 0 END);
    UPDATE #Line SET Net = Gross - Disc,
                     Disc_Pct = CONVERT(decimal(5,2), CASE WHEN Gross > 0 THEN 100.0 * Disc / Gross ELSE 0 END);
    IF EXISTS (SELECT 1 FROM #Ord o WHERE NOT EXISTS (SELECT 1 FROM #Line l WHERE l.n = o.n))
        THROW 52413, 'An order has no item (no sellable product on its date).', 1;

    SELECT n, SUM(Net) AS Total_Amount, SUM(Disc) AS Discount_Amount INTO #Tot FROM #Line GROUP BY n;

    /* ---- insert (identity by SQL Server; mapping through Sales_Order_Number) ---- */
    CREATE TABLE #OrdMap (Sales_Order_ID int NOT NULL PRIMARY KEY, Sales_Order_Number nvarchar(30) NOT NULL UNIQUE);
    INSERT INTO sales.SalesOrder
        (Customer_ID, Salesperson_ID, Sales_Channel_ID, Sales_Region_ID, Promotion_ID, Contract_ID, Customer_Interaction_ID,
         Calendar_ID, Sales_Order_Number, Order_Status, Total_Amount, Discount_Amount, Payment_Terms, Delivery_Date)
    OUTPUT inserted.Sales_Order_ID, inserted.Sales_Order_Number INTO #OrdMap
    SELECT o.Customer_ID, o.Salesperson_ID, o.Sales_Channel_ID, o.Sales_Region_ID, o.Promotion_ID, o.Contract_ID, o.Customer_Interaction_ID,
           o.Calendar_ID, o.Sales_Order_Number, o.Order_Status, t.Total_Amount, t.Discount_Amount, o.Payment_Terms, o.Delivery_Date
    FROM #Ord o JOIN #Tot t ON t.n = o.n
    ORDER BY o.n;

    INSERT INTO sales.SalesOrderItem
        (Sales_Order_ID, Product_ID, Line_Number, Quantity, Unit_of_Measure, Unit_Price, Discount_Amount, Discount_Percentage, Net_Amount, Item_Status)
    SELECT m.Sales_Order_ID, l.Product_ID, l.Line_Number, l.Quantity, l.Unit_of_Measure, l.Unit_Price, l.Disc, l.Disc_Pct, l.Net,
           CASE WHEN l.Order_Status = @StCancelled THEN N'Cancelled' ELSE N'Active' END
    FROM #Line l JOIN #Ord o ON o.n = l.n JOIN #OrdMap m ON m.Sales_Order_Number = o.Sales_Order_Number
    ORDER BY m.Sales_Order_ID, l.Line_Number;

    SELECT @InsOrders = COUNT(*) FROM sales.SalesOrder;
    SELECT @InsItems  = COUNT(*) FROM sales.SalesOrderItem;

    /* ---- in-transaction validation ---- */
    IF @InsOrders <> @OrderCount THROW 52410, 'SalesOrder count validation failed.', 1;
    IF @InsItems <> (SELECT COUNT(*) FROM #Line) THROW 52411, 'SalesOrderItem count validation failed.', 1;
    IF EXISTS (SELECT 1 FROM sales.SalesOrderItem WHERE Quantity <= 0 OR Unit_Price <= 0 OR Discount_Amount < 0 OR Discount_Percentage NOT BETWEEN 0 AND 100 OR Net_Amount < 0)
        THROW 52412, 'Invalid numeric values in order items.', 1;
    IF EXISTS (SELECT 1 FROM sales.SalesOrder so JOIN (SELECT Sales_Order_ID, SUM(Net_Amount) t, SUM(Discount_Amount) d FROM sales.SalesOrderItem GROUP BY Sales_Order_ID) x
                 ON x.Sales_Order_ID = so.Sales_Order_ID WHERE so.Total_Amount <> x.t OR so.Discount_Amount <> x.d)
        THROW 52414, 'Order header/item reconciliation failed.', 1;
    IF EXISTS (SELECT 1 FROM sales.SalesOrder so JOIN core.Calendar cal ON cal.Calendar_ID = so.Calendar_ID JOIN core.Customer c ON c.Customer_ID = so.Customer_ID
               WHERE cal.Calendar_Date < c.Registration_Date)
        THROW 52415, 'An order is dated before the customer registration.', 1;
    IF EXISTS (SELECT 1 FROM sales.SalesOrderItem i JOIN sales.SalesOrder so ON so.Sales_Order_ID = i.Sales_Order_ID JOIN core.Calendar cal ON cal.Calendar_ID = so.Calendar_ID
               JOIN core.Product p ON p.Product_ID = i.Product_ID WHERE cal.Calendar_Date < p.Launch_Date)
        THROW 52416, 'An order item is dated before the product launch.', 1;
    IF EXISTS (SELECT 1 FROM sales.SalesOrder so JOIN core.Calendar cal ON cal.Calendar_ID = so.Calendar_ID JOIN core.Salesperson s ON s.Salesperson_ID = so.Salesperson_ID
               WHERE cal.Calendar_Date < s.Hire_Date)
        THROW 52417, 'An order is dated before the salesperson hire date.', 1;

    COMMIT TRANSACTION;
    INSERT INTO #T1Log VALUES (N'8.4', N'sales.SalesOrder', @InsOrders), (N'8.4', N'sales.SalesOrderItem', @InsItems);
    PRINT CONCAT(N'8.4 SalesOrder inserted: ', @InsOrders, N' | SalesOrderItem inserted: ', @InsItems, N' | first sellable date: ', CONVERT(nvarchar(10), @MinSalesDate, 23));
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    UPDATE #T1Cfg SET Abort = 1;
    PRINT CONCAT(N'ERROR ', ERROR_NUMBER(), N' | LINE ', ERROR_LINE(), N' | ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO
/*=============================================================================
 Project   : Food Distribution (FoodDistributionDB)
 Stage     : 8 - Mock Data Design
 Team      : Team 1 - Sales & Customer      Owner: Issue #201 / Task 8.5
 Database  : FoodDistributionDB (SQL Server 2022)
 File      : 08-03-T1-06-Invoices.sql
 Version   : MockData_v1.0_Seed20261031 (DRAFT - not yet executed)
 Purpose   : Generate sales.Invoice and sales.InvoiceItem from existing
             sales.SalesOrder / sales.SalesOrderItem (8.4).
 Run order : 6 (after 8.4 Orders; before 8.6 Payments and 8.7 Commissions)
 Prereq    : core.Customer, core.Calendar, core.Product (Team 2, Tax_Rate),
             sales.SalesOrder, sales.SalesOrderItem. Both target tables empty.
 Volume    : follows the order pool. Because 8.4 is scaled by @Scale, invoice
             volume scales with it (pilot = ~10%). @Scale is printed only.
 Tables    : sales.Invoice, sales.InvoiceItem

 Approved-formula assumptions (D-04 / OI-09 still open - see Issue Log):
   Item  : Net_Amount  = order item Net_Amount (already net of item discount)
           Tax_Amount  = ROUND(Net_Amount * Tax_Rate / 100, 0)   (whole rial)
           Final       = Net_Amount + Tax_Amount                 (DB CHECK)
   Header: Subtotal    = SUM(Net_Amount + Discount_Amount)       (gross)
           Discount    = SUM(item Discount_Amount)
           Tax         = SUM(item Tax_Amount)
           Total       = Subtotal - Discount + Tax = SUM(Final)  (DB CHECK)
   All arithmetic is decimal -> no rounding tolerance needed.
 Natural key of InvoiceItem: (Invoice_ID, Product_ID).
 One invoice per invoiceable order (no split invoices in this version).

 Determinism: no NEWID/RAND/GETDATE; random numbers only via HASHBYTES SHA2_256
 formula from the stage guide. Identity values are left to SQL Server.
=============================================================================*/
GO
/* ===================== SECTION 6 : 8.5 Invoice, InvoiceItem ================ */
SET NOCOUNT ON; SET XACT_ABORT ON;
IF EXISTS (SELECT 1 FROM #T1Cfg WHERE Abort = 1) BEGIN PRINT N'SKIPPED section 6 (earlier failure)'; RETURN; END;
DECLARE @DataVersion nvarchar(50), @Seed int, @Scale decimal(5,2), @FromDate date, @ToDate date, @AsOfDate date;
SELECT @DataVersion = DataVersion, @Seed = Seed, @Scale = Scale, @FromDate = FromDate, @ToDate = ToDate, @AsOfDate = AsOfDate FROM #T1Cfg;

/* ---------------- Script parameters --------------------------------------
   !! Replace the status/type literals with the D-07 approved list before the
   !! real run. They are placeholders, not approved values.                  */
DECLARE @InvoiceType    nvarchar(30) = N'Standard';
DECLARE @StatusPaid     nvarchar(30) = N'Paid';
DECLARE @StatusPartial  nvarchar(30) = N'Partially Paid';
DECLARE @StatusIssued   nvarchar(30) = N'Issued';    -- unpaid, not yet due
DECLARE @StatusOverdue  nvarchar(30) = N'Overdue';   -- unpaid/partial, Due_Date < @AsOfDate
DECLARE @InvoiceRate    decimal(5,4) = 0.9200;       -- share of invoiceable orders invoiced (85-100%)
DECLARE @PaidRate       decimal(5,4) = 0.7000;       -- scenario: fully paid (consumed by 8.6)
DECLARE @PartialRate    decimal(5,4) = 0.0800;       -- scenario: partially paid
DECLARE @InvoiceNoPrefix nvarchar(10) = N'INV';

DECLARE @InsInvoices int, @InsItems int, @CappedDue int, @CappedInv int;

BEGIN TRY
IF DB_NAME() <> N'FoodDistributionDB'
        THROW 53000, 'Wrong database context.', 1;
    
    IF OBJECT_ID(N'sales.Invoice',N'U') IS NULL OR OBJECT_ID(N'sales.InvoiceItem',N'U') IS NULL
     OR OBJECT_ID(N'sales.SalesOrder',N'U') IS NULL OR OBJECT_ID(N'sales.SalesOrderItem',N'U') IS NULL
     OR OBJECT_ID(N'core.Calendar',N'U') IS NULL OR OBJECT_ID(N'core.Product',N'U') IS NULL
        THROW 53001, 'A required table is missing.', 1;
    
    IF NOT EXISTS (SELECT 1 FROM sales.SalesOrder) OR NOT EXISTS (SELECT 1 FROM sales.SalesOrderItem)
        THROW 53002, 'Parent tables (8.4) are empty. Run section 5 (8.4 Orders) first.', 1;
    
    IF EXISTS (SELECT 1 FROM sales.Invoice) OR EXISTS (SELECT 1 FROM sales.InvoiceItem)
        THROW 53003, 'Target tables are not empty. Nothing was deleted; use the lead''s Reset script.', 1;
    
    
    BEGIN TRANSACTION;

    DROP TABLE IF EXISTS #InvoiceableStatus, #OrderPool, #InvPlan, #ItemPlan, #HdrPlan, #InvMap;

    /* Order statuses allowed to receive an invoice (D-07: confirm list) */
    CREATE TABLE #InvoiceableStatus (Order_Status nvarchar(30) NOT NULL PRIMARY KEY);
    INSERT INTO #InvoiceableStatus VALUES (N'Completed');

    /* 1) Candidate orders + deterministic uniform numbers (0..1) */
    SELECT
        so.Sales_Order_ID, so.Customer_ID, so.Sales_Order_Number, so.Delivery_Date,
        cal.Calendar_Date AS Order_Date,
        h.u_sel, h.u_off, h.u_term, h.u_stat
    INTO #OrderPool
    FROM sales.SalesOrder so
    JOIN core.Calendar cal          ON cal.Calendar_ID = so.Calendar_ID
    JOIN #InvoiceableStatus s       ON s.Order_Status  = so.Order_Status
    CROSS APPLY (SELECT
        u_sel  = CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256',
                   CONCAT(@Seed, N'|Invoice|', so.Sales_Order_Number, N'|select')))) / 4294967296.0,
        u_off  = CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256',
                   CONCAT(@Seed, N'|Invoice|', so.Sales_Order_Number, N'|offset')))) / 4294967296.0,
        u_term = CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256',
                   CONCAT(@Seed, N'|Invoice|', so.Sales_Order_Number, N'|terms')))) / 4294967296.0,
        u_stat = CONVERT(bigint, CONVERT(binary(4), HASHBYTES('SHA2_256',
                   CONCAT(@Seed, N'|Invoice|', so.Sales_Order_Number, N'|status')))) / 4294967296.0
    ) h
    WHERE cal.Calendar_Date BETWEEN @FromDate AND @ToDate
      AND h.u_sel < @InvoiceRate
      AND EXISTS (SELECT 1 FROM sales.SalesOrderItem i WHERE i.Sales_Order_ID = so.Sales_Order_ID);

    IF NOT EXISTS (SELECT 1 FROM #OrderPool)
        THROW 53004, 'No invoiceable orders found (check Order_Status list).', 1;

    /* Guard: natural key (Order, Product) must be unique in the order items.
       Never merge silently - refer to the 8.4 owner. */
    IF EXISTS (SELECT 1 FROM sales.SalesOrderItem i
               JOIN #OrderPool p ON p.Sales_Order_ID = i.Sales_Order_ID
               GROUP BY i.Sales_Order_ID, i.Product_ID HAVING COUNT(*) > 1)
        THROW 53005, 'Duplicate Product_ID inside an order (8.4). Refer to the 8.4 owner; natural key (Invoice_ID, Product_ID) would break.', 1;

    /* 2) Header plan: dates, number, status */
    SELECT
        p.Sales_Order_ID, p.Customer_ID, p.Order_Date,
        CONCAT(@InvoiceNoPrefix, N'-', @Seed, N'-',
               RIGHT(CONCAT(N'000000', ROW_NUMBER() OVER (ORDER BY p.Sales_Order_Number)), 6)) AS Invoice_Number,
        d.Invoice_Date_Raw, d.Invoice_Date,
        t.Due_Date_Raw,
        CASE WHEN t.Due_Date_Raw > @ToDate THEN @ToDate ELSE t.Due_Date_Raw END AS Due_Date,
        CASE
            WHEN p.u_stat < @PaidRate                 THEN @StatusPaid
            WHEN p.u_stat < @PaidRate + @PartialRate  THEN
                 CASE WHEN (CASE WHEN t.Due_Date_Raw > @ToDate THEN @ToDate ELSE t.Due_Date_Raw END) < @AsOfDate
                      THEN @StatusOverdue ELSE @StatusPartial END
            ELSE CASE WHEN (CASE WHEN t.Due_Date_Raw > @ToDate THEN @ToDate ELSE t.Due_Date_Raw END) < @AsOfDate
                      THEN @StatusOverdue ELSE @StatusIssued END
        END AS Invoice_Status
    INTO #InvPlan
    FROM #OrderPool p
    CROSS APPLY (SELECT
        span = CASE WHEN p.Delivery_Date IS NULL OR p.Delivery_Date < p.Order_Date
                    THEN 3 ELSE DATEDIFF(DAY, p.Order_Date, p.Delivery_Date) + 1 END) sp
    CROSS APPLY (SELECT
        Invoice_Date_Raw = DATEADD(DAY, CONVERT(int, FLOOR(p.u_off * sp.span)), p.Order_Date)) r
    CROSS APPLY (SELECT
        Invoice_Date_Raw = r.Invoice_Date_Raw,
        Invoice_Date     = CASE WHEN r.Invoice_Date_Raw > @ToDate THEN @ToDate ELSE r.Invoice_Date_Raw END) d
    CROSS APPLY (SELECT
        Due_Date_Raw = DATEADD(DAY,
            CASE WHEN p.u_term < 0.20 THEN 15
                 WHEN p.u_term < 0.65 THEN 30
                 WHEN p.u_term < 0.90 THEN 45
                 ELSE 60 END,
            d.Invoice_Date)) t;

    SELECT @CappedInv = COUNT(*) FROM #InvPlan WHERE Invoice_Date_Raw <> Invoice_Date;
    SELECT @CappedDue = COUNT(*) FROM #InvPlan WHERE Due_Date_Raw     <> Due_Date;

    /* 3) Item plan (inherits quantities/prices from the order items) */
    SELECT
        ip.Sales_Order_ID, soi.Product_ID, soi.Quantity, soi.Unit_of_Measure, soi.Unit_Price,
        ISNULL(soi.Discount_Amount, 0) AS Discount_Amount,
        soi.Net_Amount,
        CONVERT(decimal(18,2), ROUND(soi.Net_Amount * ISNULL(pr.Tax_Rate, 0) / 100.0, 0)) AS Tax_Amount
    INTO #ItemPlan
    FROM #InvPlan ip
    JOIN sales.SalesOrderItem soi ON soi.Sales_Order_ID = ip.Sales_Order_ID
    JOIN core.Product pr          ON pr.Product_ID      = soi.Product_ID;

    /* 4) Header totals = sums of item columns */
    SELECT
        Sales_Order_ID,
        SUM(Net_Amount + Discount_Amount)  AS Subtotal,
        SUM(Discount_Amount)               AS Discount_Amount,
        SUM(Tax_Amount)                    AS Tax_Amount,
        SUM(Net_Amount + Tax_Amount)       AS Total_Amount
    INTO #HdrPlan
    FROM #ItemPlan
    GROUP BY Sales_Order_ID;

    /* 5) Insert invoices (identity by SQL Server; mapping via OUTPUT) */
    CREATE TABLE #InvMap (Invoice_ID int NOT NULL PRIMARY KEY, Sales_Order_ID int NOT NULL UNIQUE);

    INSERT INTO sales.Invoice
        (Customer_ID, Sales_Order_ID, Invoice_Number, Invoice_Date, Invoice_Type,
         Due_Date, Invoice_Status, Subtotal, Discount_Amount, Tax_Amount, Total_Amount)
    OUTPUT inserted.Invoice_ID, inserted.Sales_Order_ID INTO #InvMap
    SELECT
        ip.Customer_ID, ip.Sales_Order_ID, ip.Invoice_Number, ip.Invoice_Date, @InvoiceType,
        ip.Due_Date, ip.Invoice_Status, h.Subtotal, h.Discount_Amount, h.Tax_Amount, h.Total_Amount
    FROM #InvPlan ip
    JOIN #HdrPlan h ON h.Sales_Order_ID = ip.Sales_Order_ID
    ORDER BY ip.Invoice_Number;

    /* 6) Insert invoice items */
    INSERT INTO sales.InvoiceItem
        (Invoice_ID, Product_ID, Quantity, Unit_of_Measure, Unit_Price,
         Discount_Amount, Tax_Amount, Net_Amount, Final_Amount)
    SELECT
        m.Invoice_ID, i.Product_ID, i.Quantity, i.Unit_of_Measure, i.Unit_Price,
        i.Discount_Amount, i.Tax_Amount, i.Net_Amount, i.Net_Amount + i.Tax_Amount
    FROM #ItemPlan i
    JOIN #InvMap m ON m.Sales_Order_ID = i.Sales_Order_ID
    ORDER BY m.Invoice_ID, i.Product_ID;

    IF EXISTS (SELECT 1 FROM #ItemPlan i JOIN core.Product p ON p.Product_ID = i.Product_ID WHERE p.Tax_Rate IS NULL)
        THROW 53013, 'core.Product.Tax_Rate is NULL for an invoiced product (Team 2 parent guarantee).', 1;
    SELECT @InsInvoices = COUNT(*) FROM sales.Invoice;
    SELECT @InsItems    = COUNT(*) FROM sales.InvoiceItem;

    /* 7) In-script validation (full checks live in 08-05-T1-06-Invoices-Checks.sql) */
    IF @InsInvoices <> (SELECT COUNT(*) FROM #InvPlan)
        THROW 53010, 'Invoice count validation failed.', 1;
    IF @InsItems <> (SELECT COUNT(*) FROM #ItemPlan)
        THROW 53011, 'InvoiceItem count validation failed.', 1;
    IF EXISTS (SELECT 1 FROM sales.Invoice i
               JOIN (SELECT Invoice_ID, SUM(Net_Amount) n, SUM(Discount_Amount) d,
                            SUM(Tax_Amount) t, SUM(Final_Amount) f
                     FROM sales.InvoiceItem GROUP BY Invoice_ID) x ON x.Invoice_ID = i.Invoice_ID
               WHERE i.Subtotal - i.Discount_Amount <> x.n
                  OR i.Discount_Amount <> x.d OR i.Tax_Amount <> x.t OR i.Total_Amount <> x.f)
        THROW 53012, 'Header/item reconciliation failed.', 1;

    COMMIT TRANSACTION;

    /* Load log (Q18) */
    PRINT CONCAT(N'DataVersion=', @DataVersion, N' Seed=', @Seed, N' Scale=', @Scale);
    PRINT CONCAT(N'sales.Invoice     inserted: ', @InsInvoices);
    PRINT CONCAT(N'sales.InvoiceItem inserted: ', @InsItems);
    PRINT CONCAT(N'Invoice_Date capped at @ToDate: ', @CappedInv, N' | Due_Date capped at @ToDate: ', @CappedDue);

    INSERT INTO #T1Log VALUES (N'8.5', N'sales.Invoice', @InsInvoices), (N'8.5', N'sales.InvoiceItem', @InsItems);
    SELECT @InsInvoices AS Invoices_Inserted, @InsItems AS InvoiceItems_Inserted,
           @CappedInv AS Invoice_Date_Capped, @CappedDue AS Due_Date_Capped, N'Committed' AS Execution_Status;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    UPDATE #T1Cfg SET Abort = 1;
    PRINT CONCAT(N'ERROR ', ERROR_NUMBER(), N' | LINE ', ERROR_LINE(), N' | ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO

GO
/* ===================== SECTION 7 : 8.6 Payment, ReturnRequest, CustomerFeedback ==========
 REWRITTEN. Problems of the supplied 8.6 script:
  - only Paid invoices, always one "Gateway/Successful" payment on the invoice date; no partial / overdue / failed / split scenarios
  - ReturnRequest.Calendar_ID = TOP 1 without ORDER BY (one random date for ALL returns, may precede the delivery);
    Refund_Amount = full line Net_Amount although Approved_Quantity = 1 (wrong when Quantity > 1); every return "Approved/Damaged"
  - CustomerFeedback for ALL orders (also Cancelled / not delivered): Delivery_Date NULL -> insert error (Feedback_Date NOT NULL);
    Rating always 5, no product/interaction link
  - @Scale / @AsOfDate / @DataVersion unused; CATCH printed the error but did not re-throw (pipeline would not see the failure)
  - CHECKSUM selector instead of the guide's HASHBYTES formula; not repeatable-safe (no empty-table guard)
  Statuses / methods / reasons are PROVISIONAL (D-07 open).
===========================================================================================*/
SET NOCOUNT ON; SET XACT_ABORT ON;
IF EXISTS (SELECT 1 FROM #T1Cfg WHERE Abort = 1) BEGIN PRINT N'SKIPPED section 7 (earlier failure)'; RETURN; END;
DECLARE @DataVersion nvarchar(50), @Seed int, @Scale decimal(5,2), @FromDate date, @ToDate date, @AsOfDate date;
SELECT @DataVersion = DataVersion, @Seed = Seed, @Scale = Scale, @FromDate = FromDate, @ToDate = ToDate, @AsOfDate = AsOfDate FROM #T1Cfg;

/* invoice statuses written by section 6 (must stay identical) */
DECLARE @StPaid nvarchar(30) = N'Paid', @StPartial nvarchar(30) = N'Partially Paid', @StOverdue nvarchar(30) = N'Overdue';
DECLARE @OrderCompleted nvarchar(30) = N'Completed';
DECLARE @SplitPayShare int = 2000,        -- 20% of Paid invoices are paid in two instalments (per 10,000)
        @FailedAttemptShare int = 400,    -- 4% of Paid invoices had a failed attempt first
        @OverduePartialShare int = 4000,  -- 40% of Overdue invoices already have a partial payment
        @FeedbackShare int = 500,         -- 5% of delivered orders give general feedback
        @ComplaintShare int = 4000;       -- 40% of orders with a return also file a complaint
DECLARE @InsPay int, @InsRet int, @InsFb int;

BEGIN TRY
    IF OBJECT_ID(N'sales.Payment',N'U') IS NULL OR OBJECT_ID(N'sales.ReturnRequest',N'U') IS NULL OR OBJECT_ID(N'sales.CustomerFeedback',N'U') IS NULL
       OR OBJECT_ID(N'sales.Invoice',N'U') IS NULL
        THROW 53600, 'A required table is missing.', 1;
    IF EXISTS (SELECT 1 FROM sales.Payment) OR EXISTS (SELECT 1 FROM sales.ReturnRequest) OR EXISTS (SELECT 1 FROM sales.CustomerFeedback)
        THROW 53601, 'Target tables are not empty. Nothing was deleted; use the lead''s Reset script.', 1;
    IF NOT EXISTS (SELECT 1 FROM sales.Invoice) THROW 53602, 'Invoices are empty (run section 6 first).', 1;

    DROP TABLE IF EXISTS #Inv, #Pay, #Ret, #Fb;
    BEGIN TRANSACTION;

    /* ============ 1) Payment ============================================================== */
    SELECT i.Invoice_ID, i.Customer_ID, i.Sales_Order_ID, i.Invoice_Number, i.Invoice_Date, i.Due_Date, i.Invoice_Status, i.Total_Amount,
           DATEDIFF(DAY, i.Invoice_Date, i.Due_Date) AS Term_Days,
           CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|PAY|',i.Invoice_Number,N'|off')))) AS h_off, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|PAY|',i.Invoice_Number,N'|split')))) AS h_split, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|PAY|',i.Invoice_Number,N'|pct')))) AS h_pct, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|PAY|',i.Invoice_Number,N'|fail')))) AS h_fail, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|PAY|',i.Invoice_Number,N'|meth')))) AS h_meth,
           CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|PAY|',i.Invoice_Number,N'|ovp')))) AS h_ovp, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|PAY|',i.Invoice_Number,N'|gap')))) AS h_gap
    INTO #Inv FROM sales.Invoice i;

    CREATE TABLE #Pay (Invoice_ID int NOT NULL, Seq int NOT NULL, Customer_ID int NOT NULL, Sales_Order_ID int NOT NULL, Invoice_Number nvarchar(50) NOT NULL,
                       Payment_Date date NOT NULL, Amount decimal(18,2) NOT NULL, Payment_Method nvarchar(30) NOT NULL, Payment_Status nvarchar(30) NOT NULL);

    /* helper: payment method (provisional list) */
    /* 1a) Paid invoices - first (or only) successful payment: between invoice date and due date + 10 days */
    INSERT INTO #Pay
    SELECT v.Invoice_ID, 1, v.Customer_ID, v.Sales_Order_ID, v.Invoice_Number,
           CASE WHEN DATEADD(DAY, v.h_off % (v.Term_Days + 11), v.Invoice_Date) > @AsOfDate THEN @AsOfDate ELSE DATEADD(DAY, v.h_off % (v.Term_Days + 11), v.Invoice_Date) END,
           CASE WHEN v.h_split % 10000 < @SplitPayShare THEN CONVERT(decimal(18,2), ROUND(v.Total_Amount * (40 + v.h_pct % 21) / 100.0, 0)) ELSE v.Total_Amount END,
           CASE WHEN v.h_meth % 100 < 40 THEN N'Bank Transfer' WHEN v.h_meth % 100 < 65 THEN N'Gateway' WHEN v.h_meth % 100 < 85 THEN N'Cheque' ELSE N'Cash' END,
           N'Successful'
    FROM #Inv v WHERE v.Invoice_Status = @StPaid AND v.Total_Amount > 0;

    /* 1b) second instalment of split Paid invoices: remainder, 1-20 days later */
    INSERT INTO #Pay
    SELECT p.Invoice_ID, 2, p.Customer_ID, p.Sales_Order_ID, p.Invoice_Number,
           CASE WHEN DATEADD(DAY, 1 + v.h_gap % 20, p.Payment_Date) > @AsOfDate THEN @AsOfDate ELSE DATEADD(DAY, 1 + v.h_gap % 20, p.Payment_Date) END,
           v.Total_Amount - p.Amount, p.Payment_Method, N'Successful'
    FROM #Pay p JOIN #Inv v ON v.Invoice_ID = p.Invoice_ID
    WHERE p.Seq = 1 AND p.Amount < v.Total_Amount;

    /* 1c) failed attempt (Gateway) on some Paid invoices, on or before the successful payment */
    INSERT INTO #Pay
    SELECT p.Invoice_ID, 3, p.Customer_ID, p.Sales_Order_ID, p.Invoice_Number, v.Invoice_Date, v.Total_Amount, N'Gateway', N'Failed'
    FROM #Pay p JOIN #Inv v ON v.Invoice_ID = p.Invoice_ID
    WHERE p.Seq = 1 AND v.h_fail % 10000 < @FailedAttemptShare AND v.Invoice_Date <= p.Payment_Date;

    /* 1d) Partially Paid: one payment of 20-80% */
    INSERT INTO #Pay
    SELECT v.Invoice_ID, 1, v.Customer_ID, v.Sales_Order_ID, v.Invoice_Number,
           CASE WHEN DATEADD(DAY, v.h_off % (v.Term_Days + 11), v.Invoice_Date) > @AsOfDate THEN @AsOfDate ELSE DATEADD(DAY, v.h_off % (v.Term_Days + 11), v.Invoice_Date) END,
           CONVERT(decimal(18,2), ROUND(v.Total_Amount * (20 + v.h_pct % 61) / 100.0, 0)),
           CASE WHEN v.h_meth % 100 < 40 THEN N'Bank Transfer' WHEN v.h_meth % 100 < 65 THEN N'Gateway' WHEN v.h_meth % 100 < 85 THEN N'Cheque' ELSE N'Cash' END,
           N'Successful'
    FROM #Inv v WHERE v.Invoice_Status = @StPartial AND v.Total_Amount > 1;

    /* 1e) Overdue: some already received a partial payment (20-60%), the rest nothing */
    INSERT INTO #Pay
    SELECT v.Invoice_ID, 1, v.Customer_ID, v.Sales_Order_ID, v.Invoice_Number,
           CASE WHEN DATEADD(DAY, v.h_off % (v.Term_Days + 1), v.Invoice_Date) > @AsOfDate THEN @AsOfDate ELSE DATEADD(DAY, v.h_off % (v.Term_Days + 1), v.Invoice_Date) END,
           CONVERT(decimal(18,2), ROUND(v.Total_Amount * (20 + v.h_pct % 41) / 100.0, 0)),
           CASE WHEN v.h_meth % 100 < 50 THEN N'Bank Transfer' WHEN v.h_meth % 100 < 80 THEN N'Cheque' ELSE N'Cash' END,
           N'Successful'
    FROM #Inv v WHERE v.Invoice_Status = @StOverdue AND v.h_ovp % 10000 < @OverduePartialShare AND v.Total_Amount > 1;

    /* guards: no successful over-payment, no zero amounts, no payment before the invoice */
    IF EXISTS (SELECT 1 FROM #Pay WHERE Amount <= 0 OR Payment_Date < (SELECT Invoice_Date FROM #Inv WHERE #Inv.Invoice_ID = #Pay.Invoice_ID))
        THROW 53603, 'Payment plan contains a non-positive amount or a payment dated before its invoice.', 1;
    IF EXISTS (SELECT 1 FROM #Pay p JOIN #Inv v ON v.Invoice_ID = p.Invoice_ID WHERE p.Payment_Status = N'Successful'
               GROUP BY p.Invoice_ID, v.Total_Amount HAVING SUM(p.Amount) > v.Total_Amount)
        THROW 53604, 'Successful payments exceed an invoice total.', 1;

    INSERT INTO sales.Payment (Customer_ID, Invoice_ID, Sales_Order_ID, Payment_Date, Amount, Payment_Method, Payment_Status, Transaction_Reference, Received_By)
    SELECT p.Customer_ID, p.Invoice_ID, p.Sales_Order_ID, p.Payment_Date, p.Amount, p.Payment_Method, p.Payment_Status,
           CONCAT(N'REF-', @Seed, N'-', p.Invoice_Number, N'-', p.Seq), NULL
    FROM #Pay p ORDER BY p.Invoice_ID, p.Seq;
    SET @InsPay = @@ROWCOUNT;

    /* ============ 2) ReturnRequest ======================================================== */
    SELECT soi.Sales_Order_Item_ID, soi.Sales_Order_ID, soi.Quantity, soi.Net_Amount, soi.Product_ID, so.Customer_ID, so.Delivery_Date,
           CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|RET|',soi.Sales_Order_Item_ID,N'|ret')))) AS h_sel, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|RET|',soi.Sales_Order_Item_ID,N'|day')))) AS h_day, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|RET|',soi.Sales_Order_Item_ID,N'|qty')))) AS h_qty, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|RET|',soi.Sales_Order_Item_ID,N'|status')))) AS h_st, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|RET|',soi.Sales_Order_Item_ID,N'|rev')))) AS h_rev, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|RET|',soi.Sales_Order_Item_ID,N'|reason')))) AS h_rsn, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|RET|',soi.Sales_Order_Item_ID,N'|method')))) AS h_mth
    INTO #Ret
    FROM sales.SalesOrderItem soi
    JOIN sales.SalesOrder so ON so.Sales_Order_ID = soi.Sales_Order_ID
    WHERE so.Order_Status = @OrderCompleted AND so.Delivery_Date IS NOT NULL AND soi.Item_Status = N'Active';

    /* return rate differs between products (about 2.6% overall; guide 1-5%) */
    DELETE r FROM #Ret r
    WHERE r.h_sel % 10000 >= CASE WHEN r.Product_ID % 7 = 0 THEN 600 WHEN r.Product_ID % 7 IN (1,2) THEN 100 ELSE 250 END;

    ALTER TABLE #Ret ADD Return_Date date NULL, Req_Qty decimal(18,3) NULL, Return_Status nvarchar(30) NULL, Appr_Qty decimal(18,3) NULL,
                         Review_Date date NULL, Refund_Amount decimal(18,2) NULL, Refund_Date date NULL, Refund_Status nvarchar(30) NULL, Refund_Method nvarchar(30) NULL,
                         Reason nvarchar(250) NULL, Calendar_ID int NULL;
    UPDATE #Ret SET
        Return_Date = CASE WHEN DATEADD(DAY, 1 + h_day % 20, Delivery_Date) > @AsOfDate THEN @AsOfDate ELSE DATEADD(DAY, 1 + h_day % 20, Delivery_Date) END,
        Req_Qty = CONVERT(decimal(18,3), CASE WHEN Quantity <= 1 THEN Quantity
                       WHEN CEILING(Quantity * (10 + h_qty % 41) / 100.0) > Quantity THEN Quantity
                       ELSE CEILING(Quantity * (10 + h_qty % 41) / 100.0) END),
        Reason = CASE h_rsn % 5 WHEN 0 THEN N'Damaged' WHEN 1 THEN N'Expired' WHEN 2 THEN N'Wrong Item' WHEN 3 THEN N'Quality Issue' ELSE N'Short Delivery' END;
    UPDATE #Ret SET Return_Status = CASE WHEN h_st % 100 < 70 THEN N'Approved'
                                         WHEN h_st % 100 < 80 AND Req_Qty >= 2 THEN N'Partially Approved'
                                         WHEN h_st % 100 < 80 THEN N'Approved'
                                         WHEN h_st % 100 < 92 THEN N'Rejected' ELSE N'Pending' END;
    UPDATE #Ret SET Appr_Qty = CASE Return_Status WHEN N'Approved' THEN Req_Qty WHEN N'Partially Approved' THEN FLOOR(Req_Qty / 2.0) WHEN N'Rejected' THEN 0 ELSE NULL END,
                    Review_Date = CASE WHEN Return_Status = N'Pending' THEN NULL
                                       WHEN DATEADD(DAY, 1 + h_rev % 7, Return_Date) > @AsOfDate THEN @AsOfDate ELSE DATEADD(DAY, 1 + h_rev % 7, Return_Date) END;
    UPDATE #Ret SET Refund_Amount = CASE WHEN Return_Status IN (N'Approved', N'Partially Approved') THEN CONVERT(decimal(18,2), ROUND(Net_Amount * Appr_Qty / Quantity, 0))   -- proportional to the approved quantity
                                         WHEN Return_Status = N'Rejected' THEN 0 ELSE NULL END;
    UPDATE #Ret SET Refund_Date   = CASE WHEN Refund_Amount > 0 THEN (CASE WHEN DATEADD(DAY, 1 + h_rev % 5, Review_Date) > @AsOfDate THEN @AsOfDate ELSE DATEADD(DAY, 1 + h_rev % 5, Review_Date) END) END,
                    Refund_Status = CASE WHEN Refund_Amount > 0 THEN N'Refunded' END,
                    Refund_Method = CASE WHEN Refund_Amount > 0 THEN (CASE WHEN h_mth % 2 = 0 THEN N'Bank Transfer' ELSE N'Credit Note' END) END;
    UPDATE r SET Calendar_ID = c.Calendar_ID FROM #Ret r JOIN core.Calendar c ON c.Calendar_Date = r.Return_Date;
    IF EXISTS (SELECT 1 FROM #Ret WHERE Calendar_ID IS NULL OR Req_Qty <= 0 OR Req_Qty > Quantity OR Appr_Qty > Req_Qty OR Appr_Qty < 0)
        THROW 53605, 'Return plan violates quantity or calendar rules.', 1;

    INSERT INTO sales.ReturnRequest
        (Sales_Order_Item_ID, Payment_ID, Calendar_ID, Return_Reason, Return_Description, Return_Status, Requested_Quantity, Approved_Quantity,
         Review_Date, Reviewer_Comment, Return_Shipping_Cost, Refund_Amount, Refund_Date, Refund_Status, Refund_Method, Refund_Tracking_Code, Refund_Failure_Reason)
    SELECT r.Sales_Order_Item_ID, pay.Payment_ID, r.Calendar_ID, r.Reason, NULL, r.Return_Status, r.Req_Qty, r.Appr_Qty,
           r.Review_Date, NULL, CASE WHEN r.Return_Status IN (N'Approved', N'Partially Approved') THEN 0 END, r.Refund_Amount, r.Refund_Date, r.Refund_Status, r.Refund_Method, NULL, NULL
    FROM #Ret r
    OUTER APPLY (SELECT TOP (1) p.Payment_ID FROM sales.Payment p JOIN sales.Invoice i ON i.Invoice_ID = p.Invoice_ID
                 WHERE i.Sales_Order_ID = r.Sales_Order_ID AND p.Payment_Status = N'Successful' AND r.Refund_Amount > 0
                   AND p.Payment_Date <= r.Refund_Date ORDER BY p.Payment_Date, p.Payment_ID) pay
    ORDER BY r.Sales_Order_Item_ID;
    SET @InsRet = @@ROWCOUNT;

    /* ============ 3) CustomerFeedback ===================================================== */
    SELECT so.Sales_Order_ID, so.Customer_ID, so.Customer_Interaction_ID, so.Delivery_Date,
           CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|FB|',so.Sales_Order_Number,N'|sel')))) AS h_sel, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|FB|',so.Sales_Order_Number,N'|day')))) AS h_day, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|FB|',so.Sales_Order_Number,N'|type')))) AS h_typ, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|FB|',so.Sales_Order_Number,N'|rating')))) AS h_rat, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|FB|',so.Sales_Order_Number,N'|status')))) AS h_sta, CONVERT(bigint,CONVERT(binary(4),HASHBYTES('SHA2_256',CONCAT(@Seed,N'|FB|',so.Sales_Order_Number,N'|channel')))) AS h_ch,
           (SELECT TOP (1) i.Product_ID FROM sales.SalesOrderItem i WHERE i.Sales_Order_ID = so.Sales_Order_ID ORDER BY i.Line_Number) AS First_Product_ID
    INTO #Fb
    FROM sales.SalesOrder so
    WHERE so.Order_Status = @OrderCompleted AND so.Delivery_Date IS NOT NULL AND so.Delivery_Date < @AsOfDate;

    /* 3a) general feedback of 5% of delivered orders */
    INSERT INTO sales.CustomerFeedback
        (Customer_ID, Customer_Interaction_ID, Sales_Order_ID, Product_ID, Feedback_Type, Feedback_Date, Feedback_Channel, Feedback_Category,
         Feedback_Text, Rating, Priority, Feedback_Status, Resolution_Date, SLA_Status, Feedback_Result, Moderation_Comment)
    SELECT f.Customer_ID, f.Customer_Interaction_ID, f.Sales_Order_ID,
           CASE WHEN f.h_typ % 10 BETWEEN 7 AND 8 THEN f.First_Product_ID END,
           CASE WHEN f.h_typ % 10 < 7 THEN N'Order Feedback' WHEN f.h_typ % 10 < 9 THEN N'Product Feedback' ELSE N'Suggestion' END,
           d.Fdate,
           CASE f.h_ch % 4 WHEN 0 THEN N'Phone' WHEN 1 THEN N'Email' WHEN 2 THEN N'Website' ELSE N'Visit' END,
           CASE f.h_typ % 10 WHEN 9 THEN N'Suggestion' WHEN 7 THEN N'Product' WHEN 8 THEN N'Product' ELSE N'Delivery & Service' END,
           N'بازخورد نمونه مشتری برای سفارش',
           CONVERT(decimal(4,2), CASE WHEN f.h_rat % 100 < 7 THEN 1 WHEN f.h_rat % 100 < 15 THEN 2 WHEN f.h_rat % 100 < 30 THEN 3 WHEN f.h_rat % 100 < 65 THEN 4 ELSE 5 END),
           N'Low',
           CASE WHEN f.h_sta % 100 < 85 THEN N'Closed' ELSE N'Open' END,
           CASE WHEN f.h_sta % 100 < 85 THEN (CASE WHEN DATEADD(DAY, f.h_sta % 8, d.Fdate) > @AsOfDate THEN @AsOfDate ELSE DATEADD(DAY, f.h_sta % 8, d.Fdate) END) END,
           CASE WHEN f.h_sta % 100 < 85 THEN N'Met' END, NULL, NULL
    FROM #Fb f
    CROSS APPLY (SELECT CASE WHEN DATEADD(DAY, 1 + f.h_day % 10, f.Delivery_Date) > @AsOfDate THEN @AsOfDate ELSE DATEADD(DAY, 1 + f.h_day % 10, f.Delivery_Date) END AS Fdate) d
    WHERE f.h_sel % 10000 < @FeedbackShare
    ORDER BY f.Sales_Order_ID;

    /* 3b) complaints for 40% of orders that have a return (one per order) */
    INSERT INTO sales.CustomerFeedback
        (Customer_ID, Customer_Interaction_ID, Sales_Order_ID, Product_ID, Feedback_Type, Feedback_Date, Feedback_Channel, Feedback_Category,
         Feedback_Text, Rating, Priority, Feedback_Status, Resolution_Date, SLA_Status, Feedback_Result, Moderation_Comment)
    SELECT f.Customer_ID, f.Customer_Interaction_ID, f.Sales_Order_ID, g.Product_ID, N'Complaint', d.Fdate,
           CASE f.h_ch % 4 WHEN 0 THEN N'Phone' WHEN 1 THEN N'Email' WHEN 2 THEN N'Website' ELSE N'Visit' END,
           N'Return', N'شکایت نمونه مشتری در پی مرجوعی کالا',
           CONVERT(decimal(4,2), CASE WHEN f.h_rat % 2 = 0 THEN 1 ELSE 2 END),
           CASE WHEN f.h_typ % 3 = 0 THEN N'High' ELSE N'Medium' END,
           CASE WHEN f.h_sta % 100 < 75 THEN N'Closed' ELSE N'Open' END,
           CASE WHEN f.h_sta % 100 < 75 THEN d.Rdate END,
           CASE WHEN f.h_sta % 100 < 75 THEN (CASE WHEN d.Rdate <= DATEADD(DAY, 7, d.Fdate) THEN N'Met' ELSE N'Breached' END) END, NULL, NULL
    FROM #Fb f
    CROSS APPLY (SELECT TOP (1) r.Product_ID, r.Return_Date FROM #Ret r WHERE r.Sales_Order_ID = f.Sales_Order_ID ORDER BY r.Sales_Order_Item_ID) g
    CROSS APPLY (SELECT g.Return_Date AS Fdate,
                        CASE WHEN DATEADD(DAY, 1 + f.h_day % 14, g.Return_Date) > @AsOfDate THEN @AsOfDate ELSE DATEADD(DAY, 1 + f.h_day % 14, g.Return_Date) END AS Rdate) d
    WHERE f.h_sel % 10000 < @ComplaintShare
    ORDER BY f.Sales_Order_ID;

    SELECT @InsFb = COUNT(*) FROM sales.CustomerFeedback;
    SELECT @InsPay = COUNT(*) FROM sales.Payment;
    SELECT @InsRet = COUNT(*) FROM sales.ReturnRequest;

    /* ============ in-transaction validation (full QC in the QC file) ======================= */
    IF EXISTS (SELECT 1 FROM sales.Payment p JOIN sales.Invoice i ON i.Invoice_ID = p.Invoice_ID
               WHERE p.Customer_ID <> i.Customer_ID OR p.Sales_Order_ID <> i.Sales_Order_ID OR p.Payment_Date < i.Invoice_Date)
        THROW 53610, 'Payment is linked to an unrelated customer/order or dated before its invoice.', 1;
    IF EXISTS (SELECT 1 FROM sales.Invoice i JOIN (SELECT Invoice_ID, SUM(Amount) a FROM sales.Payment WHERE Payment_Status = N'Successful' GROUP BY Invoice_ID) x ON x.Invoice_ID = i.Invoice_ID
               WHERE x.a > i.Total_Amount OR (i.Invoice_Status = @StPaid AND x.a <> i.Total_Amount))
        THROW 53611, 'Payment reconciliation failed (over-payment or Paid invoice not fully paid).', 1;
    IF EXISTS (SELECT 1 FROM sales.Invoice i WHERE i.Invoice_Status = @StPaid AND NOT EXISTS (SELECT 1 FROM sales.Payment p WHERE p.Invoice_ID = i.Invoice_ID AND p.Payment_Status = N'Successful'))
        THROW 53612, 'A Paid invoice has no successful payment.', 1;
    IF EXISTS (SELECT 1 FROM sales.ReturnRequest WHERE Approved_Quantity > Requested_Quantity OR Approved_Quantity < 0 OR Refund_Amount < 0)
        THROW 53613, 'Return quantity/refund validation failed.', 1;
    IF EXISTS (SELECT 1 FROM sales.ReturnRequest rr JOIN sales.SalesOrderItem soi ON soi.Sales_Order_Item_ID = rr.Sales_Order_Item_ID
               JOIN sales.SalesOrder so ON so.Sales_Order_ID = soi.Sales_Order_ID JOIN core.Calendar c ON c.Calendar_ID = rr.Calendar_ID
               WHERE rr.Requested_Quantity > soi.Quantity OR c.Calendar_Date < so.Delivery_Date OR rr.Refund_Amount > soi.Net_Amount)
        THROW 53614, 'Return is larger than the sold item or dated before delivery.', 1;
    IF EXISTS (SELECT 1 FROM sales.CustomerFeedback fb JOIN sales.SalesOrder so ON so.Sales_Order_ID = fb.Sales_Order_ID
               WHERE fb.Feedback_Date < so.Delivery_Date OR fb.Rating NOT BETWEEN 1 AND 5 OR fb.Resolution_Date < fb.Feedback_Date)
        THROW 53615, 'Feedback date/rating validation failed.', 1;

    COMMIT TRANSACTION;
    INSERT INTO #T1Log VALUES (N'8.6', N'sales.Payment', @InsPay), (N'8.6', N'sales.ReturnRequest', @InsRet), (N'8.6', N'sales.CustomerFeedback', @InsFb);
    PRINT CONCAT(N'8.6 Payment inserted: ', @InsPay, N' | ReturnRequest: ', @InsRet, N' | CustomerFeedback: ', @InsFb);
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    UPDATE #T1Cfg SET Abort = 1;
    PRINT CONCAT(N'ERROR ', ERROR_NUMBER(), N' | LINE ', ERROR_LINE(), N' | ', ERROR_MESSAGE());
    THROW;
END CATCH;
GO
/*=============================================================================
 Project   : Food Distribution (FoodDistributionDB)
 Stage     : 8 - Mock Data Design
 Team      : Team 1 - Sales & Customer
 Issue     : #203 / Task 8.7
 Database  : FoodDistributionDB (SQL Server 2022)
 File      : 08-03-T1-08-Planning-Commission.sql
 Version   : MockData_v1.0_Seed20261031
 Purpose   : Generate sales.SalesTarget, sales.SalesForecast and sales.Commission.
 Run Order : 8 (after 8.1, 8.4, 8.5 and 8.6 have populated their dependencies)
 Prerequisites:
   core.Calendar, core.Salesperson, core.Branch, ref.SalesRegion,
   ref.SalesChannel, sales.SalesOrder, sales.SalesOrderItem, sales.Invoice,
   sales.InvoiceItem, sales.Payment, sales.ReturnRequest.
 Tables    : sales.SalesTarget, sales.SalesForecast, sales.Commission

 PROPOSED GRAIN (D-01 - pending Lead approval):
   SalesTarget  : Annual = one row per Gregorian year;
                  Region/Team/Salesperson/Channel = one row per month and dimension.
   SalesForecast: one row per month and forecast version (3 versions; 96 months).
   Commission   : one row per active salesperson and month (zero-base rows included).
   Monthly period key = last calendar date available in each month.
   First partial month (2019-03-21..2019-03-31) is excluded from monthly grain;
   the final partial month is represented by 2027-03-20.

 PROVISIONAL BUSINESS ASSUMPTIONS (must be approved before execution):
   D-02: Fiscal_Year = Gregorian core.Calendar.Year_Number.
   D-07: Target_Status = N'Planned'.
   OI-17: Commission amount rounded to whole IRR using ROUND(...,0).
   Commission basis = successful payments less approved refunds, attributed to
   the original salesperson and the calendar month recorded on each transaction.
   Commission rates by Role: Manager 2%; Supervisor 3%; all other roles 4%.
   Zero-sales active salesperson-months are inserted with Base_Amount = 0.
   Product-level targets are intentionally omitted until Team 2 confirms active
   Product rows and the business owner confirms whether this target level is needed.

 IMPORTANT:
   Set @AllowProvisionalAssumptions = 1 ONLY after the Lead/business owner approves
   the assumptions above or replaces them with approved values.
   This script does not change schema, disable constraints, use IDENTITY_INSERT,
   NEWID, RAND, CHECKSUM(NEWID), GETDATE, or row-by-row loops.
   @Scale is informational here: the supplied 8.4 transaction set is already the
   pilot dataset. Do not scale Commission rows a second time.
=============================================================================*/
GO
/* ===================== SECTION 8 : 8.7 SalesTarget, SalesForecast, Commission ============ */
SET NOCOUNT ON; SET XACT_ABORT ON;
IF EXISTS (SELECT 1 FROM #T1Cfg WHERE Abort = 1) BEGIN PRINT N'SKIPPED section 8 (earlier failure)'; RETURN; END;
DECLARE @DataVersion nvarchar(50), @Seed int, @Scale decimal(5,2), @FromDate date, @ToDate date, @AsOfDate date, @AllowProvisionalAssumptions bit;
SELECT @DataVersion = DataVersion, @Seed = Seed, @Scale = Scale, @FromDate = FromDate, @ToDate = ToDate, @AsOfDate = AsOfDate,
       @AllowProvisionalAssumptions = AllowProvisionalAssumptions FROM #T1Cfg;   -- approval gate lives in section 0

/* ---------------- Approval gate / editable assumptions ------------------ */
DECLARE @TargetStatus nvarchar(30) = N'Planned'; -- D-07 pending confirmation
DECLARE @CurrencyCode char(3) = 'IRR';
DECLARE @TargetVersion int = 1;
DECLARE @ForecastVersionCount int = 3;
DECLARE @TargetFactor decimal(9,4) = 1.0800;
DECLARE @CommissionRateManager decimal(5,2) = 2.00;
DECLARE @CommissionRateSupervisor decimal(5,2) = 3.00;
DECLARE @CommissionRateOther decimal(5,2) = 4.00;

DECLARE @InsertedTargets int = 0, @InsertedForecasts int = 0, @InsertedCommissions int = 0;

BEGIN TRY
IF DB_NAME() <> N'FoodDistributionDB'
        THROW 53800, 'Wrong database context. Use FoodDistributionDB.', 1;
    
    IF @AllowProvisionalAssumptions <> 1
        THROW 53801, 'Approval gate: review D-01, D-02, D-07, OI-15, OI-17 and commission-basis assumptions; then set @AllowProvisionalAssumptions = 1.', 1;
    
    IF @FromDate >= @ToDate OR @AsOfDate < @FromDate OR @AsOfDate > @ToDate
        THROW 53802, 'Invalid date configuration.', 1;
    
    IF @TargetVersion < 1 OR @ForecastVersionCount < 1
        THROW 53803, 'Target/Forecast version must be >= 1.', 1;
    
    IF OBJECT_ID(N'core.Calendar',N'U') IS NULL
     OR OBJECT_ID(N'core.Salesperson',N'U') IS NULL
     OR OBJECT_ID(N'core.Branch',N'U') IS NULL
     OR OBJECT_ID(N'ref.SalesRegion',N'U') IS NULL
     OR OBJECT_ID(N'ref.SalesChannel',N'U') IS NULL
     OR OBJECT_ID(N'sales.SalesOrder',N'U') IS NULL
     OR OBJECT_ID(N'sales.SalesOrderItem',N'U') IS NULL
     OR OBJECT_ID(N'sales.Invoice',N'U') IS NULL
     OR OBJECT_ID(N'sales.InvoiceItem',N'U') IS NULL
     OR OBJECT_ID(N'sales.Payment',N'U') IS NULL
     OR OBJECT_ID(N'sales.ReturnRequest',N'U') IS NULL
     OR OBJECT_ID(N'sales.SalesTarget',N'U') IS NULL
     OR OBJECT_ID(N'sales.SalesForecast',N'U') IS NULL
     OR OBJECT_ID(N'sales.Commission',N'U') IS NULL
        THROW 53804, 'One or more required source/target tables are missing.', 1;
    
    IF NOT EXISTS (SELECT 1 FROM core.Calendar)
     OR NOT EXISTS (SELECT 1 FROM core.Salesperson)
     OR NOT EXISTS (SELECT 1 FROM core.Branch)
     OR NOT EXISTS (SELECT 1 FROM ref.SalesRegion)
     OR NOT EXISTS (SELECT 1 FROM ref.SalesChannel)
     OR NOT EXISTS (SELECT 1 FROM sales.SalesOrder)
     OR NOT EXISTS (SELECT 1 FROM sales.Invoice)
     OR NOT EXISTS (SELECT 1 FROM sales.Payment)
     OR NOT EXISTS (SELECT 1 FROM sales.ReturnRequest)
        THROW 53805, 'A required parent/transaction table is empty. Complete 8.1 and 8.4-8.6 first.', 1;
    
    IF EXISTS (SELECT 1 FROM sales.SalesTarget)
     OR EXISTS (SELECT 1 FROM sales.SalesForecast)
     OR EXISTS (SELECT 1 FROM sales.Commission)
        THROW 53806, 'At least one target table is not empty. No rows were deleted; request the approved Reset procedure.', 1;
    
    
    BEGIN TRANSACTION;

    DROP TABLE IF EXISTS #MonthPeriods, #AnnualPeriods, #EligibleActual,
                         #TargetPlan, #ActualMonthly, #ForecastPlan,
                         #SellerPeriods, #PaymentByMonth, #RefundByMonth,
                         #CommissionPlan;

    /* 1. Period map: 96 complete/available monthly period-end dates.
       Start at 2019-04 to avoid the partial first month. The final period is
       2027-03-20 because that is the end of the supplied Calendar range. */
    SELECT c.Calendar_ID, c.Calendar_Date, c.Year_Number, c.Month_Number
    INTO #MonthPeriods
    FROM core.Calendar c
    WHERE c.Calendar_Date BETWEEN @FromDate AND @ToDate
      AND c.Calendar_Date >= DATEADD(MONTH, 1, DATEFROMPARTS(YEAR(@FromDate), MONTH(@FromDate), 1))
      AND (c.Calendar_Date = EOMONTH(c.Calendar_Date) OR c.Calendar_Date = @ToDate);

    IF (SELECT COUNT(*) FROM #MonthPeriods) <> 96
        THROW 53807, 'Expected 96 monthly periods (2019-04 through 2027-03); check Calendar coverage.', 1;

    /* Annual periods use Gregorian year-end dates; the final partial 2027 year
       uses @ToDate. Fiscal_Year remains provisional under D-02. */
    SELECT c.Calendar_ID, c.Calendar_Date, c.Year_Number
    INTO #AnnualPeriods
    FROM core.Calendar c
    WHERE c.Calendar_Date BETWEEN @FromDate AND @ToDate
      AND (c.Calendar_Date = DATEFROMPARTS(c.Year_Number,12,31) OR c.Calendar_Date = @ToDate);

    /* 2. Eligible invoiced sales for hierarchical targets.
       Sales are attributable only when salesperson -> branch -> Team -> Area
       -> root Region is resolvable. This makes Annual/Region/Team/Salesperson
       target totals reconcile to the same covered population. */
    SELECT
        i.Invoice_ID,
        i.Invoice_Date,
        YEAR(i.Invoice_Date) AS Fiscal_Year,
        MONTH(i.Invoice_Date) AS Month_Number,
        i.Total_Amount,
        so.Salesperson_ID,
        so.Sales_Channel_ID,
        team.Sales_Region_ID AS Team_Sales_Region_ID,
        rootRegion.Sales_Region_ID AS Root_Sales_Region_ID
    INTO #EligibleActual
    FROM sales.Invoice i
    JOIN sales.SalesOrder so
      ON so.Sales_Order_ID = i.Sales_Order_ID
    JOIN core.Salesperson sp
      ON sp.Salesperson_ID = so.Salesperson_ID
    JOIN core.Branch br
      ON br.Branch_ID = sp.Branch_ID
    JOIN ref.SalesRegion team
      ON team.Sales_Region_ID = br.Sales_Region_ID
     AND team.Region_Level = N'Team'
    JOIN ref.SalesRegion area
      ON area.Sales_Region_ID = team.Parent_Sales_Region_ID
    JOIN ref.SalesRegion rootRegion
      ON rootRegion.Sales_Region_ID = area.Parent_Sales_Region_ID
     AND rootRegion.Region_Level = N'Region'
    WHERE i.Invoice_Date BETWEEN @FromDate AND @ToDate
      AND so.Salesperson_ID IS NOT NULL
      AND so.Sales_Channel_ID IS NOT NULL
      AND i.Invoice_Date >= DATEADD(MONTH, 1, DATEFROMPARTS(YEAR(@FromDate), MONTH(@FromDate), 1));

    IF NOT EXISTS (SELECT 1 FROM #EligibleActual)
        THROW 53808, 'No eligible invoiced sales could be attributed to salesperson/team/region.', 1;

    /* 3. Build target rows.
       Annual = one row per year; other produced levels = month x dimension.
       Product level is not generated in this version (Team 2 dependency and
       business need remain unconfirmed). */
    CREATE TABLE #TargetPlan
    (
        Calendar_ID int NOT NULL,
        Sales_Region_ID int NULL,
        Salesperson_ID int NULL,
        Sales_Channel_ID int NULL,
        Product_ID int NULL,
        Target_Level nvarchar(30) NOT NULL,
        Plan_Title nvarchar(200) NULL,
        Fiscal_Year int NULL,
        Target_Value decimal(18,2) NULL,
        Target_Quantity decimal(18,3) NULL,
        Currency_Code char(3) NULL,
        Target_Version int NOT NULL,
        Target_Status nvarchar(30) NOT NULL
    );

    /* Annual */
    INSERT #TargetPlan
    (Calendar_ID,Sales_Region_ID,Salesperson_ID,Sales_Channel_ID,Product_ID,
     Target_Level,Plan_Title,Fiscal_Year,Target_Value,Target_Quantity,
     Currency_Code,Target_Version,Target_Status)
    SELECT
        ap.Calendar_ID, NULL,NULL,NULL,NULL,N'Annual',
        CONCAT(N'Annual Sales Target - ',ap.Year_Number),
        ap.Year_Number,
        CONVERT(decimal(18,2),ROUND(ISNULL(SUM(e.Total_Amount),0)*@TargetFactor,0)),
        NULL,@CurrencyCode,@TargetVersion,@TargetStatus
    FROM #AnnualPeriods ap
    LEFT JOIN #EligibleActual e ON e.Fiscal_Year = ap.Year_Number
    GROUP BY ap.Calendar_ID,ap.Year_Number;

    /* Region */
    INSERT #TargetPlan
    SELECT
        p.Calendar_ID,r.Sales_Region_ID,NULL,NULL,NULL,N'Region',
        CONCAT(N'Monthly Region Target - ',r.Sales_Region_ID,N' - ',p.Year_Number,N'-',RIGHT(CONCAT('0',p.Month_Number),2)),
        p.Year_Number,
        CONVERT(decimal(18,2),ROUND(ISNULL(SUM(e.Total_Amount),0)*@TargetFactor,0)),
        NULL,@CurrencyCode,@TargetVersion,@TargetStatus
    FROM #MonthPeriods p
    CROSS JOIN ref.SalesRegion r
    LEFT JOIN #EligibleActual e
      ON e.Fiscal_Year=p.Year_Number AND e.Month_Number=p.Month_Number
     AND e.Root_Sales_Region_ID=r.Sales_Region_ID
    WHERE r.Region_Level=N'Region'
    GROUP BY p.Calendar_ID,p.Year_Number,p.Month_Number,r.Sales_Region_ID;

    /* Team */
    INSERT #TargetPlan
    SELECT
        p.Calendar_ID,r.Sales_Region_ID,NULL,NULL,NULL,N'Team',
        CONCAT(N'Monthly Team Target - ',r.Sales_Region_ID,N' - ',p.Year_Number,N'-',RIGHT(CONCAT('0',p.Month_Number),2)),
        p.Year_Number,
        CONVERT(decimal(18,2),ROUND(ISNULL(SUM(e.Total_Amount),0)*@TargetFactor,0)),
        NULL,@CurrencyCode,@TargetVersion,@TargetStatus
    FROM #MonthPeriods p
    CROSS JOIN ref.SalesRegion r
    LEFT JOIN #EligibleActual e
      ON e.Fiscal_Year=p.Year_Number AND e.Month_Number=p.Month_Number
     AND e.Team_Sales_Region_ID=r.Sales_Region_ID
    WHERE r.Region_Level=N'Team'
    GROUP BY p.Calendar_ID,p.Year_Number,p.Month_Number,r.Sales_Region_ID;

    /* Salesperson */
    INSERT #TargetPlan
    SELECT
        p.Calendar_ID,NULL,sp.Salesperson_ID,NULL,NULL,N'Salesperson',
        CONCAT(N'Monthly Salesperson Target - ',sp.Salesperson_ID,N' - ',p.Year_Number,N'-',RIGHT(CONCAT('0',p.Month_Number),2)),
        p.Year_Number,
        CONVERT(decimal(18,2),ROUND(ISNULL(SUM(e.Total_Amount),0)*@TargetFactor,0)),
        NULL,@CurrencyCode,@TargetVersion,@TargetStatus
    FROM #MonthPeriods p
    JOIN core.Salesperson sp
      ON sp.Hire_Date IS NOT NULL
     AND sp.Hire_Date<=p.Calendar_Date
    LEFT JOIN #EligibleActual e
      ON e.Fiscal_Year=p.Year_Number AND e.Month_Number=p.Month_Number
     AND e.Salesperson_ID=sp.Salesperson_ID
    WHERE sp.Employment_Status=N'Active' OR e.Invoice_ID IS NOT NULL   -- FIX: leavers keep their target rows for the months they sold
    GROUP BY p.Calendar_ID,p.Year_Number,p.Month_Number,sp.Salesperson_ID;

    /* Channel */
    INSERT #TargetPlan
    SELECT
        p.Calendar_ID,NULL,NULL,ch.Sales_Channel_ID,NULL,N'Channel',
        CONCAT(N'Monthly Channel Target - ',ch.Sales_Channel_ID,N' - ',p.Year_Number,N'-',RIGHT(CONCAT('0',p.Month_Number),2)),
        p.Year_Number,
        CONVERT(decimal(18,2),ROUND(ISNULL(SUM(e.Total_Amount),0)*@TargetFactor,0)),
        NULL,@CurrencyCode,@TargetVersion,@TargetStatus
    FROM #MonthPeriods p
    CROSS JOIN ref.SalesChannel ch
    LEFT JOIN #EligibleActual e
      ON e.Fiscal_Year=p.Year_Number AND e.Month_Number=p.Month_Number
     AND e.Sales_Channel_ID=ch.Sales_Channel_ID
    GROUP BY p.Calendar_ID,p.Year_Number,p.Month_Number,ch.Sales_Channel_ID;

    IF NOT EXISTS (SELECT 1 FROM #TargetPlan)
        THROW 53809, 'Target plan is empty.', 1;

    /* 4. Forecasts: three deterministic versions for each monthly period.
       Amounts are anchored to monthly invoiced sales to preserve observed
       seasonality; accuracy is computed only for periods <= @AsOfDate. */
    SELECT
        p.Calendar_ID,p.Calendar_Date,p.Year_Number,p.Month_Number,
        CONVERT(decimal(18,2),ISNULL(SUM(i.Total_Amount),0)) AS Actual_Amount
    INTO #ActualMonthly
    FROM #MonthPeriods p
    LEFT JOIN sales.Invoice i
      ON YEAR(i.Invoice_Date)=p.Year_Number
     AND MONTH(i.Invoice_Date)=p.Month_Number
     AND i.Invoice_Date BETWEEN @FromDate AND @ToDate
    GROUP BY p.Calendar_ID,p.Calendar_Date,p.Year_Number,p.Month_Number;

    CREATE TABLE #ForecastPlan
    (
        Calendar_ID int NOT NULL,
        Forecast_Amount decimal(18,2) NOT NULL,
        Forecast_Version int NOT NULL,
        Forecast_Accuracy_Percent decimal(5,2) NULL
    );

    INSERT #ForecastPlan (Calendar_ID,Forecast_Amount,Forecast_Version,Forecast_Accuracy_Percent)
    SELECT
        a.Calendar_ID,
        CONVERT(decimal(18,2),ROUND(a.Actual_Amount*f.Factor,0)),
        f.Forecast_Version,
        CASE WHEN a.Calendar_Date <= @AsOfDate AND a.Actual_Amount > 0
             THEN CONVERT(decimal(5,2),
                  CASE WHEN 100.0-ABS(ROUND(a.Actual_Amount*f.Factor,0)-a.Actual_Amount)*100.0/a.Actual_Amount < 0
                       THEN 0
                       ELSE 100.0-ABS(ROUND(a.Actual_Amount*f.Factor,0)-a.Actual_Amount)*100.0/a.Actual_Amount END)
             WHEN a.Calendar_Date <= @AsOfDate AND a.Actual_Amount=0 THEN CONVERT(decimal(5,2),100.00)
             ELSE NULL END
    FROM #ActualMonthly a
    CROSS APPLY
    (
        SELECT v.Forecast_Version,
               Factor = CONVERT(decimal(9,4),
                 CASE v.Forecast_Version
                   WHEN 1 THEN 0.9400 + (a.Month_Number % 4)*0.0100
                   WHEN 2 THEN 0.9800 + (a.Month_Number % 3)*0.0050
                   ELSE 1.0200 + (a.Month_Number % 4)*0.0100
                 END)
        FROM (VALUES (1),(2),(3)) v(Forecast_Version)
    ) f;

    /* 5. Commission base = successful payments minus approved refunds.
       Payment and refund periods use their own recorded transaction dates.
       Return value is attributed to the original order salesperson. */
    SELECT
        so.Salesperson_ID,
        YEAR(pay.Payment_Date) AS Year_Number,
        MONTH(pay.Payment_Date) AS Month_Number,
        SUM(pay.Amount) AS Paid_Amount
    INTO #PaymentByMonth
    FROM sales.Payment pay
    JOIN sales.SalesOrder so ON so.Sales_Order_ID=pay.Sales_Order_ID
    WHERE pay.Payment_Status=N'Successful'
      AND pay.Payment_Date BETWEEN @FromDate AND @ToDate
      AND so.Salesperson_ID IS NOT NULL
    GROUP BY so.Salesperson_ID,YEAR(pay.Payment_Date),MONTH(pay.Payment_Date);

    SELECT
        so.Salesperson_ID,
        cal.Year_Number,
        cal.Month_Number,
        SUM(ISNULL(rr.Refund_Amount,0)) AS Approved_Refund_Amount
    INTO #RefundByMonth
    FROM sales.ReturnRequest rr
    JOIN core.Calendar cal ON cal.Calendar_ID=rr.Calendar_ID
    JOIN sales.SalesOrderItem soi ON soi.Sales_Order_Item_ID=rr.Sales_Order_Item_ID
    JOIN sales.SalesOrder so ON so.Sales_Order_ID=soi.Sales_Order_ID
    WHERE rr.Return_Status IN (N'Approved',N'Partially Approved')   -- FIX: partially approved refunds reduce the commission base too
      AND rr.Refund_Amount IS NOT NULL
      AND cal.Calendar_Date BETWEEN @FromDate AND @ToDate
      AND so.Salesperson_ID IS NOT NULL
    GROUP BY so.Salesperson_ID,cal.Year_Number,cal.Month_Number;

    SELECT
        sp.Salesperson_ID,
        p.Calendar_ID,
        p.Calendar_Date,
        sp.Role,
        CONVERT(decimal(18,2),
          CASE WHEN ISNULL(pb.Paid_Amount,0)-ISNULL(rb.Approved_Refund_Amount,0) < 0
               THEN 0
               ELSE ISNULL(pb.Paid_Amount,0)-ISNULL(rb.Approved_Refund_Amount,0) END) AS Commission_Base_Amount,
        CONVERT(decimal(5,2),
          CASE WHEN sp.Role LIKE N'%Manager%' THEN @CommissionRateManager
               WHEN sp.Role LIKE N'%Supervisor%' THEN @CommissionRateSupervisor
               ELSE @CommissionRateOther END) AS Commission_Rate
    INTO #CommissionPlan
    FROM core.Salesperson sp
    CROSS JOIN #MonthPeriods p
    LEFT JOIN #PaymentByMonth pb
      ON pb.Salesperson_ID=sp.Salesperson_ID
     AND pb.Year_Number=p.Year_Number AND pb.Month_Number=p.Month_Number
    LEFT JOIN #RefundByMonth rb
      ON rb.Salesperson_ID=sp.Salesperson_ID
     AND rb.Year_Number=p.Year_Number AND rb.Month_Number=p.Month_Number
    WHERE sp.Hire_Date IS NOT NULL
      AND sp.Hire_Date <= p.Calendar_Date
      AND (sp.Employment_Status=N'Active' OR ISNULL(pb.Paid_Amount,0)<>0 OR ISNULL(rb.Approved_Refund_Amount,0)<>0);   -- FIX: commission of leavers

    /* 6. Insert in dependency order: targets, forecasts, commissions. */
    INSERT INTO sales.SalesTarget
    (Calendar_ID,Sales_Region_ID,Salesperson_ID,Sales_Channel_ID,Product_ID,
     Target_Level,Plan_Title,Fiscal_Year,Target_Value,Target_Quantity,
     Currency_Code,Target_Version,Target_Status)
    SELECT
        Calendar_ID,Sales_Region_ID,Salesperson_ID,Sales_Channel_ID,Product_ID,
        Target_Level,Plan_Title,Fiscal_Year,Target_Value,Target_Quantity,
        Currency_Code,Target_Version,Target_Status
    FROM #TargetPlan;

    SET @InsertedTargets=@@ROWCOUNT;

    INSERT INTO sales.SalesForecast
    (Calendar_ID,Forecast_Amount,Forecast_Version,Forecast_Accuracy_Percent)
    SELECT Calendar_ID,Forecast_Amount,Forecast_Version,Forecast_Accuracy_Percent
    FROM #ForecastPlan;

    SET @InsertedForecasts=@@ROWCOUNT;

    INSERT INTO sales.Commission
    (Salesperson_ID,Calendar_ID,Commission_Base_Amount,Commission_Rate,Commission_Amount)
    SELECT
        Salesperson_ID,Calendar_ID,Commission_Base_Amount,Commission_Rate,
        CONVERT(decimal(18,2),ROUND(Commission_Base_Amount*Commission_Rate/100.0,0))
    FROM #CommissionPlan;

    SET @InsertedCommissions=@@ROWCOUNT;

    /* 7. In-transaction integrity checks; full independent QC is separate. */
    IF EXISTS
    (
        SELECT 1 FROM sales.SalesTarget
        WHERE Target_Level=N'Annual'
          AND (Sales_Region_ID IS NOT NULL OR Salesperson_ID IS NOT NULL
               OR Sales_Channel_ID IS NOT NULL OR Product_ID IS NOT NULL)
    )
        THROW 53810, 'Annual target dimension matrix failed.', 1;

    IF EXISTS
    (
        SELECT 1 FROM sales.SalesTarget
        WHERE (Target_Level IN (N'Region',N'Team') AND
               (Sales_Region_ID IS NULL OR Salesperson_ID IS NOT NULL OR Sales_Channel_ID IS NOT NULL OR Product_ID IS NOT NULL))
           OR (Target_Level=N'Salesperson' AND
               (Sales_Region_ID IS NOT NULL OR Salesperson_ID IS NULL OR Sales_Channel_ID IS NOT NULL OR Product_ID IS NOT NULL))
           OR (Target_Level=N'Channel' AND
               (Sales_Region_ID IS NOT NULL OR Salesperson_ID IS NOT NULL OR Sales_Channel_ID IS NULL OR Product_ID IS NOT NULL))
    )
        THROW 53811, 'SalesTarget dimension matrix failed.', 1;

    IF EXISTS
    (
        SELECT 1 FROM sales.SalesTarget t
        JOIN ref.SalesRegion r ON r.Sales_Region_ID=t.Sales_Region_ID
        WHERE t.Target_Level=N'Team' AND r.Region_Level<>N'Team'
    )
        THROW 53812, 'Team target must reference a Team-level SalesRegion.', 1;

    IF EXISTS
    (
        SELECT 1 FROM sales.Commission
        WHERE Commission_Base_Amount<0 OR Commission_Rate NOT BETWEEN 0 AND 100
           OR Commission_Amount<>ROUND(Commission_Base_Amount*Commission_Rate/100.0,0)
    )
        THROW 53813, 'Commission formula/value validation failed.', 1;

    IF @InsertedTargets=0 OR @InsertedForecasts<>96*@ForecastVersionCount OR @InsertedCommissions=0
        THROW 53814, 'Unexpected inserted row counts.', 1;

    COMMIT TRANSACTION;
    INSERT INTO #T1Log VALUES (N'8.7', N'sales.SalesTarget', @InsertedTargets), (N'8.7', N'sales.SalesForecast', @InsertedForecasts), (N'8.7', N'sales.Commission', @InsertedCommissions);

    PRINT CONCAT(N'DataVersion=',@DataVersion,N' | Seed=',@Seed,N' | Scale=',@Scale);
    PRINT CONCAT(N'sales.SalesTarget inserted: ',@InsertedTargets);
    PRINT CONCAT(N'sales.SalesForecast inserted: ',@InsertedForecasts);
    PRINT CONCAT(N'sales.Commission inserted: ',@InsertedCommissions);
    PRINT N'Assumptions used are provisional; see the 8.7 Plan and Issue Log.';
    SELECT @InsertedTargets AS SalesTarget_Inserted,
           @InsertedForecasts AS SalesForecast_Inserted,
           @InsertedCommissions AS Commission_Inserted,
           N'Committed - provisional assumptions' AS Execution_Status;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    UPDATE #T1Cfg SET Abort=1;
    PRINT CONCAT(N'ERROR ',ERROR_NUMBER(),N' | LINE ',ERROR_LINE(),N' | ',ERROR_MESSAGE());
    THROW;
END CATCH;
GO

/* ===================== FINAL LOAD LOG (Q18) ===================== */
IF EXISTS (SELECT 1 FROM #T1Cfg WHERE Abort = 1)
    PRINT N'RUN FAILED - see the first ERROR line above. Failed section rolled back; later sections skipped.';
ELSE
    PRINT N'RUN COMPLETED - all Team 1 Stage 8 sections committed.';
SELECT Step, Table_Name, Rows_Inserted FROM #T1Log ORDER BY Step, Table_Name;
GO

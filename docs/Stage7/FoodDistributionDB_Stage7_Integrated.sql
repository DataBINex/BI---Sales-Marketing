/*=============================================================================
  Food Distribution - Stage 7 Integrated SQL Server Deployment Script
  Database: FoodDistributionDB
  Target: SQL Server 2022

  STAGE 1: Create database
  STAGE 2: Create schemas (ref, core, sales, marketing)
  STAGE 3: Create tables, constraints/rules/triggers, and indexes for BOTH teams

  Deployment order within Stage 3:
    3.1 Team 1 + Team 2 tables
    3.2 Team 1 + Team 2 constraints, foreign keys, and integrity triggers
    3.3 Team 1 + Team 2 indexes

  Excluded intentionally: test/validation scripts and index-evaluation scripts.
  Run in SQL Server Management Studio (SSMS) with permission to create databases.
  IMPORTANT: This script does not drop/recreate the database. Existing objects are
  handled according to the idempotency logic in each team's source scripts.
=============================================================================*/

SET NOCOUNT ON;
GO

/*=============================================================================
  STAGE 1 - CREATE DATABASE
=============================================================================*/
IF DB_ID(N'FoodDistributionDB') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE [FoodDistributionDB]');
    PRINT N'Database FoodDistributionDB created.';
END
ELSE
BEGIN
    PRINT N'Database FoodDistributionDB already exists; it will not be recreated.';
END;
GO

/*=============================================================================
  STAGE 2 - CREATE SCHEMAS
=============================================================================*/
USE [FoodDistributionDB];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO
IF SCHEMA_ID(N'ref') IS NULL EXEC(N'CREATE SCHEMA [ref]');
IF SCHEMA_ID(N'core') IS NULL EXEC(N'CREATE SCHEMA [core]');
IF SCHEMA_ID(N'sales') IS NULL EXEC(N'CREATE SCHEMA [sales]');
IF SCHEMA_ID(N'marketing') IS NULL EXEC(N'CREATE SCHEMA [marketing]');
GO
PRINT N'Stage 2 complete: schemas ref, core, sales, marketing are available.';
GO

/*=============================================================================
  STAGE 3.1 - CREATE TABLES (TEAM 1 + TEAM 2)
  Both teams' tables are created before any cross-team foreign keys are added.
=============================================================================*/


/*---------------- SOURCE FILE: 07-Team1-01-Create-Tables.sql ----------------*/
/*
    Project : Food Distribution (Etemad Iranian Food Distribution)
    Stage   : 7 - Physical Data Model
    Team    : Team 1 - Sales & Customer
    Database: FoodDistributionDB
    SQL Server: 2022
    File    : 07-Team1-01-Create-Tables.sql
    Purpose : Create the 24 Team 1 tables (columns, data types, NULL/NOT NULL, IDENTITY, PRIMARY KEY).
    Run order: 1 (after 07-01-Create-Database.sql and 07-02-Create-Schemas.sql)
    Prerequisites: Database FoodDistributionDB and schemas ref, core and sales exist.
    Source  : 06-Team1-Sales-Customer-Logical-Data-Model.xlsx (Stage 6)
    Schemas : Team 1 proposal for the Entity-to-Schema matrix (ref / core / sales); not yet approved
    Re-run  : Safe. Every object is created only if it does not already exist.
*/

USE [FoodDistributionDB];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

/* ---- Prerequisite check: stop the whole script if a prerequisite is missing ---- */
IF SCHEMA_ID(N'ref') IS NULL OR SCHEMA_ID(N'core') IS NULL OR SCHEMA_ID(N'sales') IS NULL
BEGIN
    RAISERROR(N'Schemas ref, core and sales are required. Run 07-02-Create-Schemas.sql first.', 16, 1);
    SET NOEXEC ON;
END;
GO

/* ========================================================================
   Schema [ref] - Reference tables (depend only on ref)
   ======================================================================== */

-- ref.Province  <-  Stage 6 entity "Province"
IF OBJECT_ID(N'ref.Province', N'U') IS NULL
BEGIN
    CREATE TABLE ref.Province
    (
        Province_ID      int IDENTITY(1,1)  NOT NULL,
        Province_Code    nvarchar(30)       NOT NULL,
        Province_Name    nvarchar(150)      NOT NULL,
        Province_Status  nvarchar(30)       NOT NULL,
        CONSTRAINT PK_Province PRIMARY KEY CLUSTERED (Province_ID)
    );
    PRINT N'Created table ref.Province.';
END
ELSE
    PRINT N'Table ref.Province already exists - skipped.';
GO

-- ref.City  <-  Stage 6 entity "City"
IF OBJECT_ID(N'ref.City', N'U') IS NULL
BEGIN
    CREATE TABLE ref.City
    (
        City_ID         int IDENTITY(1,1)  NOT NULL,
        Province_ID     int                NOT NULL,
        Parent_City_ID  int                NULL,
        City_Code       nvarchar(30)       NOT NULL,
        City_Name       nvarchar(150)      NOT NULL,
        City_Level      nvarchar(30)       NOT NULL,
        City_Status     nvarchar(30)       NULL,
        CONSTRAINT PK_City PRIMARY KEY CLUSTERED (City_ID)
    );
    PRINT N'Created table ref.City.';
END
ELSE
    PRINT N'Table ref.City already exists - skipped.';
GO

-- ref.CustomerSegment  <-  Stage 6 entity "Customer Segment"
IF OBJECT_ID(N'ref.CustomerSegment', N'U') IS NULL
BEGIN
    CREATE TABLE ref.CustomerSegment
    (
        Customer_Segment_ID  int IDENTITY(1,1)  NOT NULL,
        Segment_Code         nvarchar(30)       NOT NULL,
        Segment_Name         nvarchar(150)      NOT NULL,
        Segment_Type         nvarchar(30)       NULL,
        Segment_Level        nvarchar(30)       NULL,
        Segment_Criteria     nvarchar(1000)     NULL,
        Segment_Description  nvarchar(1000)     NULL,
        Priority             int                NULL,
        Segment_Status       nvarchar(30)       NULL,
        Created_Date         date               NULL,
        End_Date             date               NULL,
        CONSTRAINT PK_CustomerSegment PRIMARY KEY CLUSTERED (Customer_Segment_ID)
    );
    PRINT N'Created table ref.CustomerSegment.';
END
ELSE
    PRINT N'Table ref.CustomerSegment already exists - skipped.';
GO

-- ref.SalesChannel  <-  Stage 6 entity "Sales Channel"
IF OBJECT_ID(N'ref.SalesChannel', N'U') IS NULL
BEGIN
    CREATE TABLE ref.SalesChannel
    (
        Sales_Channel_ID    int IDENTITY(1,1)  NOT NULL,
        Sales_Channel_Code  nvarchar(30)       NOT NULL,
        Sales_Channel_Name  nvarchar(150)      NOT NULL,
        Sales_Channel_Type  nvarchar(30)       NOT NULL,
        Channel_Status      nvarchar(30)       NOT NULL,
        Campaign_Name       nvarchar(150)      NULL,
        CONSTRAINT PK_SalesChannel PRIMARY KEY CLUSTERED (Sales_Channel_ID)
    );
    PRINT N'Created table ref.SalesChannel.';
END
ELSE
    PRINT N'Table ref.SalesChannel already exists - skipped.';
GO

-- ref.SalesRegion  <-  Stage 6 entity "Sales Region"
IF OBJECT_ID(N'ref.SalesRegion', N'U') IS NULL
BEGIN
    CREATE TABLE ref.SalesRegion
    (
        Sales_Region_ID         int IDENTITY(1,1)  NOT NULL,
        Parent_Sales_Region_ID  int                NULL,
        Sales_Region_Code       nvarchar(30)       NOT NULL,
        Sales_Region_Name       nvarchar(150)      NOT NULL,
        Region_Level            nvarchar(30)       NULL,
        Region_Status           nvarchar(30)       NOT NULL,
        CONSTRAINT PK_SalesRegion PRIMARY KEY CLUSTERED (Sales_Region_ID)
    );
    PRINT N'Created table ref.SalesRegion.';
END
ELSE
    PRINT N'Table ref.SalesRegion already exists - skipped.';
GO

-- ref.SalesTerritory  <-  Stage 6 entity "Sales Territory"
IF OBJECT_ID(N'ref.SalesTerritory', N'U') IS NULL
BEGIN
    CREATE TABLE ref.SalesTerritory
    (
        Sales_Territory_ID      int IDENTITY(1,1)  NOT NULL,
        Territory_Code          nvarchar(30)       NOT NULL,
        Territory_Name          nvarchar(150)      NOT NULL,
        Territory_Type          nvarchar(30)       NULL,
        Territory_Manager_Name  nvarchar(150)      NULL,
        Route_Code              nvarchar(30)       NULL,
        Route_Name              nvarchar(150)      NULL,
        Visit_Frequency         int                NULL,
        Territory_Status        nvarchar(30)       NOT NULL,
        CONSTRAINT PK_SalesTerritory PRIMARY KEY CLUSTERED (Sales_Territory_ID)
    );
    PRINT N'Created table ref.SalesTerritory.';
END
ELSE
    PRINT N'Table ref.SalesTerritory already exists - skipped.';
GO

/* ========================================================================
   Schema [core] - Core master tables (depend on core and ref)
   ======================================================================== */

-- core.Calendar  <-  Stage 6 entity "Calendar"
IF OBJECT_ID(N'core.Calendar', N'U') IS NULL
BEGIN
    CREATE TABLE core.Calendar
    (
        Calendar_ID     int IDENTITY(1,1)  NOT NULL,
        Calendar_Date   date               NOT NULL,
        Day_Number      int                NOT NULL,
        Month_Number    int                NOT NULL,
        Quarter_Number  int                NOT NULL,
        Week_Number     int                NOT NULL,
        Year_Number     int                NOT NULL,
        CONSTRAINT PK_Calendar PRIMARY KEY CLUSTERED (Calendar_ID)
    );
    PRINT N'Created table core.Calendar.';
END
ELSE
    PRINT N'Table core.Calendar already exists - skipped.';
GO

-- core.Branch  <-  Stage 6 entity "Branch"
IF OBJECT_ID(N'core.Branch', N'U') IS NULL
BEGIN
    CREATE TABLE core.Branch
    (
        Branch_ID        int IDENTITY(1,1)  NOT NULL,
        Sales_Region_ID  int                NOT NULL,
        Branch_Code      nvarchar(30)       NOT NULL,
        Branch_Name      nvarchar(150)      NOT NULL,
        Branch_Status    nvarchar(30)       NULL,
        CONSTRAINT PK_Branch PRIMARY KEY CLUSTERED (Branch_ID)
    );
    PRINT N'Created table core.Branch.';
END
ELSE
    PRINT N'Table core.Branch already exists - skipped.';
GO

-- core.Salesperson  <-  Stage 6 entity "Salesperson"
IF OBJECT_ID(N'core.Salesperson', N'U') IS NULL
BEGIN
    CREATE TABLE core.Salesperson
    (
        Salesperson_ID          int IDENTITY(1,1)  NOT NULL,
        Branch_ID               int                NULL,
        Manager_Salesperson_ID  int                NULL,
        Salesperson_Code        nvarchar(30)       NOT NULL,
        Salesperson_Name        nvarchar(150)      NOT NULL,
        Role                    nvarchar(100)      NOT NULL,
        Employment_Status       nvarchar(30)       NOT NULL,
        Hire_Date               date               NULL,
        Email                   nvarchar(254)      NULL,
        Phone_Number            nvarchar(20)       NULL,
        CONSTRAINT PK_Salesperson PRIMARY KEY CLUSTERED (Salesperson_ID)
    );
    PRINT N'Created table core.Salesperson.';
END
ELSE
    PRINT N'Table core.Salesperson already exists - skipped.';
GO

-- core.Customer  <-  Stage 6 entity "Customer"
IF OBJECT_ID(N'core.Customer', N'U') IS NULL
BEGIN
    CREATE TABLE core.Customer
    (
        Customer_ID                int IDENTITY(1,1)  NOT NULL,
        City_ID                    int                NULL,
        Customer_Segment_ID        int                NULL,
        Sales_Channel_ID           int                NULL,
        Sales_Territory_ID         int                NULL,
        Salesperson_ID             int                NULL,
        Customer_Code              nvarchar(30)       NOT NULL,
        Customer_Name              nvarchar(150)      NOT NULL,
        Customer_Type              nvarchar(30)       NOT NULL,
        Customer_Status            nvarchar(30)       NOT NULL,
        Status_Reason              nvarchar(250)      NULL,
        Status_Effective_Date      date               NULL,
        Business_Type              nvarchar(50)       NULL,
        Industry                   nvarchar(100)      NULL,
        Customer_Size              nvarchar(30)       NULL,
        Employee_Count             int                NULL,
        Annual_Revenue             decimal(18,2)      NULL,
        Contact_Person_Name        nvarchar(150)      NULL,
        Phone                      nvarchar(20)       NULL,
        Mobile                     nvarchar(20)       NULL,
        Email                      nvarchar(254)      NULL,
        Preferred_Contact_Channel  nvarchar(30)       NULL,
        Address                    nvarchar(500)      NULL,
        Postal_Code                nvarchar(20)       NULL,
        Latitude                   decimal(9,6)       NULL,
        Longitude                  decimal(9,6)       NULL,
        Registration_Date          date               NULL,
        Credit_Limit               decimal(18,2)      NULL,
        Credit_Status              nvarchar(30)       NULL,
        Credit_Review_Date         date               NULL,
        Last_Update_Date           date               NULL,
        CONSTRAINT PK_Customer PRIMARY KEY CLUSTERED (Customer_ID)
    );
    PRINT N'Created table core.Customer.';
END
ELSE
    PRINT N'Table core.Customer already exists - skipped.';
GO

/* ========================================================================
   Schema [sales] - Sales transactions and planning (depend on core, ref and Team 2 keys)
   ======================================================================== */

-- sales.Lead  <-  Stage 6 entity "Lead"
IF OBJECT_ID(N'sales.Lead', N'U') IS NULL
BEGIN
    CREATE TABLE sales.Lead
    (
        Lead_ID          int IDENTITY(1,1)  NOT NULL,
        Salesperson_ID   int                NULL,
        Lead_Code        nvarchar(30)       NULL,
        Lead_Name        nvarchar(150)      NOT NULL,
        Lead_Source      nvarchar(100)      NOT NULL,
        Lead_Status      nvarchar(30)       NOT NULL,
        Lead_Score       decimal(5,2)       NULL,
        Expected_Value   decimal(18,2)      NULL,
        Created_Date     date               NOT NULL,
        Conversion_Date  date               NULL,
        CONSTRAINT PK_Lead PRIMARY KEY CLUSTERED (Lead_ID)
    );
    PRINT N'Created table sales.Lead.';
END
ELSE
    PRINT N'Table sales.Lead already exists - skipped.';
GO

-- sales.CustomerInteraction  <-  Stage 6 entity "Customer Interaction"
IF OBJECT_ID(N'sales.CustomerInteraction', N'U') IS NULL
BEGIN
    CREATE TABLE sales.CustomerInteraction
    (
        Customer_Interaction_ID       int IDENTITY(1,1)  NOT NULL,
        Customer_ID                   int                NOT NULL,
        Salesperson_ID                int                NULL,
        Sales_Territory_ID            int                NULL,
        Interaction_Type              nvarchar(30)       NOT NULL,
        Interaction_DateTime          datetime2(0)       NOT NULL,
        Interaction_Channel           nvarchar(30)       NULL,
        Interaction_Subject           nvarchar(200)      NULL,
        Interaction_Purpose           nvarchar(250)      NULL,
        Interaction_Status            nvarchar(30)       NULL,
        Interaction_Result            nvarchar(250)      NULL,
        Interaction_Duration_Minutes  int                NULL,
        Participants_Count            int                NULL,
        Follow_Up_Required            bit                NULL,
        Follow_Up_Date                date               NULL,
        Interaction_Notes             nvarchar(2000)     NULL,
        CONSTRAINT PK_CustomerInteraction PRIMARY KEY CLUSTERED (Customer_Interaction_ID)
    );
    PRINT N'Created table sales.CustomerInteraction.';
END
ELSE
    PRINT N'Table sales.CustomerInteraction already exists - skipped.';
GO

-- sales.SalesOpportunity  <-  Stage 6 entity "Sales Opportunity"
IF OBJECT_ID(N'sales.SalesOpportunity', N'U') IS NULL
BEGIN
    CREATE TABLE sales.SalesOpportunity
    (
        Sales_Opportunity_ID      int IDENTITY(1,1)  NOT NULL,
        Customer_ID               int                NULL,
        Lead_ID                   int                NULL,
        Salesperson_ID            int                NOT NULL,
        Opportunity_Code          nvarchar(30)       NOT NULL,
        Opportunity_Name          nvarchar(150)      NOT NULL,
        Opportunity_Stage         nvarchar(30)       NOT NULL,
        Opportunity_Status        nvarchar(30)       NOT NULL,
        Opportunity_Type          nvarchar(30)       NULL,
        Opportunity_Date          date               NOT NULL,
        Expected_Close_Date       date               NULL,
        Probability               decimal(5,2)       NULL,
        Expected_Value            decimal(18,2)      NULL,
        Opportunity_Source        nvarchar(100)      NULL,
        Description               nvarchar(1000)     NULL,
        Proposal_Number           nvarchar(30)       NULL,
        Proposal_Date             date               NULL,
        Proposal_Status           nvarchar(30)       NULL,
        Proposal_Valid_From       date               NULL,
        Proposal_Valid_To         date               NULL,
        Proposed_Price            decimal(18,2)      NULL,
        Proposal_Discount_Amount  decimal(18,2)      NULL,
        Proposal_Payment_Terms    nvarchar(250)      NULL,
        Proposal_Delivery_Terms   nvarchar(250)      NULL,
        CONSTRAINT PK_SalesOpportunity PRIMARY KEY CLUSTERED (Sales_Opportunity_ID)
    );
    PRINT N'Created table sales.SalesOpportunity.';
END
ELSE
    PRINT N'Table sales.SalesOpportunity already exists - skipped.';
GO

-- sales.Contract  <-  Stage 6 entity "Contract"
IF OBJECT_ID(N'sales.Contract', N'U') IS NULL
BEGIN
    CREATE TABLE sales.Contract
    (
        Contract_ID           int IDENTITY(1,1)  NOT NULL,
        Customer_ID           int                NOT NULL,
        Sales_Opportunity_ID  int                NULL,
        Product_ID            int                NULL,
        Contract_Number       nvarchar(30)       NOT NULL,
        Contract_Type         nvarchar(30)       NOT NULL,
        Contract_Status       nvarchar(30)       NOT NULL,
        Start_Date            date               NOT NULL,
        End_Date              date               NOT NULL,
        Closed_Date           date               NULL,
        Contract_Amount       decimal(18,2)      NOT NULL,
        Currency_Code         char(3)            NULL,
        Payment_Terms         nvarchar(250)      NOT NULL,
        Delivery_Terms        nvarchar(250)      NULL,
        Contract_Conditions   nvarchar(2000)     NULL,
        Item_Quantity         decimal(18,3)      NULL,
        Item_Unit_Price       decimal(18,2)      NULL,
        Item_Unit_of_Measure  nvarchar(20)       NULL,
        CONSTRAINT PK_Contract PRIMARY KEY CLUSTERED (Contract_ID)
    );
    PRINT N'Created table sales.Contract.';
END
ELSE
    PRINT N'Table sales.Contract already exists - skipped.';
GO

-- sales.SalesOrder  <-  Stage 6 entity "Sales Order"
IF OBJECT_ID(N'sales.SalesOrder', N'U') IS NULL
BEGIN
    CREATE TABLE sales.SalesOrder
    (
        Sales_Order_ID           int IDENTITY(1,1)  NOT NULL,
        Customer_ID              int                NOT NULL,
        Salesperson_ID           int                NULL,
        Sales_Channel_ID         int                NOT NULL,
        Sales_Region_ID          int                NULL,
        Promotion_ID             int                NULL,
        Contract_ID              int                NULL,
        Customer_Interaction_ID  int                NULL,
        Calendar_ID              int                NOT NULL,
        Sales_Order_Number       nvarchar(30)       NOT NULL,
        Order_Status             nvarchar(30)       NOT NULL,
        Total_Amount             decimal(18,2)      NOT NULL,
        Discount_Amount          decimal(18,2)      NULL,
        Payment_Terms            nvarchar(250)      NULL,
        Delivery_Date            date               NULL,
        CONSTRAINT PK_SalesOrder PRIMARY KEY CLUSTERED (Sales_Order_ID)
    );
    PRINT N'Created table sales.SalesOrder.';
END
ELSE
    PRINT N'Table sales.SalesOrder already exists - skipped.';
GO

-- sales.SalesOrderItem  <-  Stage 6 entity "Sales Order Item"
IF OBJECT_ID(N'sales.SalesOrderItem', N'U') IS NULL
BEGIN
    CREATE TABLE sales.SalesOrderItem
    (
        Sales_Order_Item_ID  int IDENTITY(1,1)  NOT NULL,
        Sales_Order_ID       int                NOT NULL,
        Product_ID           int                NOT NULL,
        Line_Number          int                NOT NULL,
        Quantity             decimal(18,3)      NOT NULL,
        Unit_of_Measure      nvarchar(20)       NOT NULL,
        Unit_Price           decimal(18,2)      NOT NULL,
        Discount_Amount      decimal(18,2)      NULL,
        Discount_Percentage  decimal(5,2)       NULL,
        Net_Amount           decimal(18,2)      NOT NULL,
        Item_Status          nvarchar(30)       NOT NULL,
        CONSTRAINT PK_SalesOrderItem PRIMARY KEY CLUSTERED (Sales_Order_Item_ID)
    );
    PRINT N'Created table sales.SalesOrderItem.';
END
ELSE
    PRINT N'Table sales.SalesOrderItem already exists - skipped.';
GO

-- sales.Invoice  <-  Stage 6 entity "Invoice"
IF OBJECT_ID(N'sales.Invoice', N'U') IS NULL
BEGIN
    CREATE TABLE sales.Invoice
    (
        Invoice_ID       int IDENTITY(1,1)  NOT NULL,
        Customer_ID      int                NOT NULL,
        Sales_Order_ID   int                NOT NULL,
        Invoice_Number   nvarchar(30)       NOT NULL,
        Invoice_Date     date               NOT NULL,
        Invoice_Type     nvarchar(30)       NULL,
        Due_Date         date               NULL,
        Invoice_Status   nvarchar(30)       NOT NULL,
        Subtotal         decimal(18,2)      NOT NULL,
        Discount_Amount  decimal(18,2)      NULL,
        Tax_Amount       decimal(18,2)      NULL,
        Total_Amount     decimal(18,2)      NOT NULL,
        CONSTRAINT PK_Invoice PRIMARY KEY CLUSTERED (Invoice_ID)
    );
    PRINT N'Created table sales.Invoice.';
END
ELSE
    PRINT N'Table sales.Invoice already exists - skipped.';
GO

-- sales.InvoiceItem  <-  Stage 6 entity "Invoice Item"
IF OBJECT_ID(N'sales.InvoiceItem', N'U') IS NULL
BEGIN
    CREATE TABLE sales.InvoiceItem
    (
        Invoice_Item_ID  int IDENTITY(1,1)  NOT NULL,
        Invoice_ID       int                NOT NULL,
        Product_ID       int                NOT NULL,
        Quantity         decimal(18,3)      NOT NULL,
        Unit_of_Measure  nvarchar(20)       NULL,
        Unit_Price       decimal(18,2)      NOT NULL,
        Discount_Amount  decimal(18,2)      NULL,
        Tax_Amount       decimal(18,2)      NULL,
        Net_Amount       decimal(18,2)      NOT NULL,
        Final_Amount     decimal(18,2)      NOT NULL,
        CONSTRAINT PK_InvoiceItem PRIMARY KEY CLUSTERED (Invoice_Item_ID)
    );
    PRINT N'Created table sales.InvoiceItem.';
END
ELSE
    PRINT N'Table sales.InvoiceItem already exists - skipped.';
GO

-- sales.Payment  <-  Stage 6 entity "Payment"
IF OBJECT_ID(N'sales.Payment', N'U') IS NULL
BEGIN
    CREATE TABLE sales.Payment
    (
        Payment_ID             int IDENTITY(1,1)  NOT NULL,
        Customer_ID            int                NOT NULL,
        Invoice_ID             int                NULL,
        Sales_Order_ID         int                NULL,
        Payment_Date           date               NOT NULL,
        Amount                 decimal(18,2)      NOT NULL,
        Payment_Method         nvarchar(30)       NOT NULL,
        Payment_Status         nvarchar(30)       NOT NULL,
        Transaction_Reference  nvarchar(100)      NULL,
        Received_By            nvarchar(150)      NULL,
        CONSTRAINT PK_Payment PRIMARY KEY CLUSTERED (Payment_ID)
    );
    PRINT N'Created table sales.Payment.';
END
ELSE
    PRINT N'Table sales.Payment already exists - skipped.';
GO

-- sales.ReturnRequest  <-  Stage 6 entity "Return Request"
IF OBJECT_ID(N'sales.ReturnRequest', N'U') IS NULL
BEGIN
    CREATE TABLE sales.ReturnRequest
    (
        Return_Request_ID      int IDENTITY(1,1)  NOT NULL,
        Sales_Order_Item_ID    int                NOT NULL,
        Payment_ID             int                NULL,
        Calendar_ID            int                NOT NULL,
        Return_Reason          nvarchar(250)      NOT NULL,
        Return_Description     nvarchar(1000)     NULL,
        Return_Status          nvarchar(30)       NOT NULL,
        Requested_Quantity     decimal(18,3)      NOT NULL,
        Approved_Quantity      decimal(18,3)      NULL,
        Review_Date            date               NULL,
        Reviewer_Comment       nvarchar(1000)     NULL,
        Return_Shipping_Cost   decimal(18,2)      NULL,
        Refund_Amount          decimal(18,2)      NULL,
        Refund_Date            date               NULL,
        Refund_Status          nvarchar(30)       NULL,
        Refund_Method          nvarchar(30)       NULL,
        Refund_Tracking_Code   nvarchar(100)      NULL,
        Refund_Failure_Reason  nvarchar(250)      NULL,
        CONSTRAINT PK_ReturnRequest PRIMARY KEY CLUSTERED (Return_Request_ID)
    );
    PRINT N'Created table sales.ReturnRequest.';
END
ELSE
    PRINT N'Table sales.ReturnRequest already exists - skipped.';
GO

-- sales.CustomerFeedback  <-  Stage 6 entity "Customer Feedback"
IF OBJECT_ID(N'sales.CustomerFeedback', N'U') IS NULL
BEGIN
    CREATE TABLE sales.CustomerFeedback
    (
        Customer_Feedback_ID     int IDENTITY(1,1)  NOT NULL,
        Customer_ID              int                NOT NULL,
        Customer_Interaction_ID  int                NULL,
        Sales_Order_ID           int                NULL,
        Product_ID               int                NULL,
        Feedback_Type            nvarchar(30)       NOT NULL,
        Feedback_Date            date               NOT NULL,
        Feedback_Channel         nvarchar(30)       NULL,
        Feedback_Category        nvarchar(100)      NULL,
        Feedback_Text            nvarchar(2000)     NULL,
        Rating                   decimal(4,2)       NULL,
        Priority                 nvarchar(30)       NULL,
        Feedback_Status          nvarchar(30)       NULL,
        Resolution_Date          date               NULL,
        SLA_Status               nvarchar(30)       NULL,
        Feedback_Result          nvarchar(250)      NULL,
        Moderation_Comment       nvarchar(1000)     NULL,
        CONSTRAINT PK_CustomerFeedback PRIMARY KEY CLUSTERED (Customer_Feedback_ID)
    );
    PRINT N'Created table sales.CustomerFeedback.';
END
ELSE
    PRINT N'Table sales.CustomerFeedback already exists - skipped.';
GO

-- sales.Commission  <-  Stage 6 entity "Commission"
IF OBJECT_ID(N'sales.Commission', N'U') IS NULL
BEGIN
    CREATE TABLE sales.Commission
    (
        Commission_ID           int IDENTITY(1,1)  NOT NULL,
        Salesperson_ID          int                NOT NULL,
        Calendar_ID             int                NOT NULL,
        Commission_Base_Amount  decimal(18,2)      NOT NULL,
        Commission_Rate         decimal(5,2)       NOT NULL,
        Commission_Amount       decimal(18,2)      NOT NULL,
        CONSTRAINT PK_Commission PRIMARY KEY CLUSTERED (Commission_ID)
    );
    PRINT N'Created table sales.Commission.';
END
ELSE
    PRINT N'Table sales.Commission already exists - skipped.';
GO

-- sales.SalesTarget  <-  Stage 6 entity "Sales Target"
IF OBJECT_ID(N'sales.SalesTarget', N'U') IS NULL
BEGIN
    CREATE TABLE sales.SalesTarget
    (
        Sales_Target_ID   int IDENTITY(1,1)  NOT NULL,
        Calendar_ID       int                NOT NULL,
        Sales_Region_ID   int                NULL,
        Salesperson_ID    int                NULL,
        Sales_Channel_ID  int                NULL,
        Product_ID        int                NULL,
        Target_Level      nvarchar(30)       NOT NULL,
        Plan_Title        nvarchar(200)      NULL,
        Fiscal_Year       int                NULL,
        Target_Value      decimal(18,2)      NULL,
        Target_Quantity   decimal(18,3)      NULL,
        Currency_Code     char(3)            NULL,
        Target_Version    int                NOT NULL,
        Target_Status     nvarchar(30)       NOT NULL,
        CONSTRAINT PK_SalesTarget PRIMARY KEY CLUSTERED (Sales_Target_ID)
    );
    PRINT N'Created table sales.SalesTarget.';
END
ELSE
    PRINT N'Table sales.SalesTarget already exists - skipped.';
GO

-- sales.SalesForecast  <-  Stage 6 entity "Sales Forecast"
IF OBJECT_ID(N'sales.SalesForecast', N'U') IS NULL
BEGIN
    CREATE TABLE sales.SalesForecast
    (
        Sales_Forecast_ID          int IDENTITY(1,1)  NOT NULL,
        Calendar_ID                int                NOT NULL,
        Forecast_Amount            decimal(18,2)      NOT NULL,
        Forecast_Version           int                NOT NULL,
        Forecast_Accuracy_Percent  decimal(5,2)       NULL,
        CONSTRAINT PK_SalesForecast PRIMARY KEY CLUSTERED (Sales_Forecast_ID)
    );
    PRINT N'Created table sales.SalesForecast.';
END
ELSE
    PRINT N'Table sales.SalesForecast already exists - skipped.';
GO

/* ---- Summary of Team 1 objects ---- */
DECLARE @t TABLE (object_id int PRIMARY KEY);
INSERT @t (object_id)
SELECT OBJECT_ID(n) FROM (VALUES (N'ref.Province'), (N'ref.City'), (N'ref.CustomerSegment'), (N'ref.SalesChannel'), (N'ref.SalesRegion'), (N'ref.SalesTerritory'), (N'core.Calendar'), (N'core.Branch'), (N'core.Salesperson'), (N'core.Customer'), (N'sales.Lead'), (N'sales.CustomerInteraction'), (N'sales.SalesOpportunity'), (N'sales.Contract'), (N'sales.SalesOrder'), (N'sales.SalesOrderItem'), (N'sales.Invoice'), (N'sales.InvoiceItem'), (N'sales.Payment'), (N'sales.ReturnRequest'), (N'sales.CustomerFeedback'), (N'sales.Commission'), (N'sales.SalesTarget'), (N'sales.SalesForecast')) v(n) WHERE OBJECT_ID(n) IS NOT NULL;
DECLARE @msg nvarchar(600) = CONCAT(
    N'Team 1 objects now in FoodDistributionDB: tables ', (SELECT COUNT(*) FROM @t),
    N', columns ', (SELECT COUNT(*) FROM sys.columns c JOIN @t t ON t.object_id = c.object_id),
    N', PK ', (SELECT COUNT(*) FROM sys.key_constraints k JOIN @t t ON t.object_id = k.parent_object_id WHERE k.type = 'PK'),
    N', UNIQUE ', (SELECT COUNT(*) FROM sys.key_constraints k JOIN @t t ON t.object_id = k.parent_object_id WHERE k.type = 'UQ')
                + (SELECT COUNT(*) FROM sys.indexes i JOIN @t t ON t.object_id = i.object_id WHERE i.is_unique = 1 AND i.has_filter = 1),
    N', CHECK ', (SELECT COUNT(*) FROM sys.check_constraints k JOIN @t t ON t.object_id = k.parent_object_id),
    N', DEFAULT ', (SELECT COUNT(*) FROM sys.default_constraints k JOIN @t t ON t.object_id = k.parent_object_id),
    N', FK ', (SELECT COUNT(*) FROM sys.foreign_keys k JOIN @t t ON t.object_id = k.parent_object_id),
    N', indexes ', (SELECT COUNT(*) FROM sys.indexes i JOIN @t t ON t.object_id = i.object_id WHERE i.type = 2 AND i.is_unique = 0),
    N'.');
PRINT @msg;
GO

SET NOEXEC OFF;
GO
PRINT N'07-Team1-01-Create-Tables.sql finished.';
GO


/*---------------- SOURCE FILE: 07-Team2-03-Create-Tables.sql ----------------*/
/*
    Project : Food Distribution (Etemad Iranian Food Distribution)
    Stage   : 7 - Physical Data Model
    Team    : Team 2 - Product & Marketing
    Database: FoodDistributionDB
    SQL Server: 2022
    Version : 1.1 (2026-10-28)
    File    : 07-Team2-03-Create-Tables.sql
    Purpose : Create the 24 Team 2 tables (columns, data types, NULL/NOT NULL, IDENTITY, PRIMARY KEY).
    Run order: 3 (after 07-01-Create-Database.sql and 07-02-Create-Schemas.sql)
    Prerequisites: Database FoodDistributionDB and schemas ref, core, marketing exist.
    Source  : 06-Team2-Product-Marketing-Logical-Data-Model.xlsx (Stage 6, #175)
    Schemas : Team 2 proposal for #183 (ref / core / marketing); not yet approved
    Re-run  : Safe. A table is created only if it does not exist. An existing table is NOT altered: if its columns or
              primary key differ from the expected definition, the script reports the difference as an error.
              The verification at the end compares the whole structure with the expected definition.
*/

USE [FoodDistributionDB];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

/* ---- Prerequisite check: stop the whole script if a prerequisite is missing ---- */
IF SCHEMA_ID(N'ref') IS NULL OR SCHEMA_ID(N'core') IS NULL OR SCHEMA_ID(N'marketing') IS NULL
BEGIN
    RAISERROR(N'Schemas ref, core and marketing are required. Run 07-02-Create-Schemas.sql first.', 16, 1);
    SET NOEXEC ON;
END;
GO

/* ========================================================================
   Schema [ref] - Reference tables (no dependencies)
   ======================================================================== */

-- ref.ProductCategory  <-  Stage 6 entity "Product Category"
IF OBJECT_ID(N'ref.ProductCategory', N'U') IS NULL
BEGIN
    CREATE TABLE ref.ProductCategory
    (
        Product_Category_ID  int IDENTITY(1,1)  NOT NULL,
        Parent_Category_ID   int                NULL,
        Category_Code        nvarchar(30)       NOT NULL,
        Category_Name        nvarchar(150)      NOT NULL,
        Category_Level       int                NOT NULL,
        Category_Status      nvarchar(30)       NOT NULL,
        CONSTRAINT PK_ProductCategory PRIMARY KEY CLUSTERED (Product_Category_ID)
    );
    PRINT N'Created table ref.ProductCategory.';
END
ELSE
    PRINT N'Table ref.ProductCategory already exists - not altered; its structure is checked in the verification below.';
GO

-- ref.Package  <-  Stage 6 entity "Package"
IF OBJECT_ID(N'ref.Package', N'U') IS NULL
BEGIN
    CREATE TABLE ref.Package
    (
        Package_ID           int IDENTITY(1,1)  NOT NULL,
        Package_Code         nvarchar(30)       NOT NULL,
        Package_Name         nvarchar(150)      NOT NULL,
        Package_Description  nvarchar(1000)     NULL,
        CONSTRAINT PK_Package PRIMARY KEY CLUSTERED (Package_ID)
    );
    PRINT N'Created table ref.Package.';
END
ELSE
    PRINT N'Table ref.Package already exists - not altered; its structure is checked in the verification below.';
GO

/* ========================================================================
   Schema [core] - Core shared master tables
   ======================================================================== */

-- core.Brand  <-  Stage 6 entity "Brand"
IF OBJECT_ID(N'core.Brand', N'U') IS NULL
BEGIN
    CREATE TABLE core.Brand
    (
        Brand_ID           int IDENTITY(1,1)  NOT NULL,
        Brand_Name         nvarchar(150)      NOT NULL,
        Brand_Code         nvarchar(30)       NOT NULL,
        Brand_Type         nvarchar(30)       NOT NULL,
        Brand_Status       nvarchar(30)       NOT NULL,
        Brand_Start_Date   date               NULL,
        Brand_End_Date     date               NULL,
        Brand_Owner        nvarchar(150)      NULL,
        Brand_Positioning  nvarchar(500)      NULL,
        Target_Market      nvarchar(100)      NULL,
        Target_Segment     nvarchar(100)      NULL,
        Brand_Tagline      nvarchar(250)      NULL,
        Brand_Logo_URL     nvarchar(500)      NULL,
        Brand_Website      nvarchar(500)      NULL,
        Brand_Country      char(2)            NULL,
        CONSTRAINT PK_Brand PRIMARY KEY CLUSTERED (Brand_ID)
    );
    PRINT N'Created table core.Brand.';
END
ELSE
    PRINT N'Table core.Brand already exists - not altered; its structure is checked in the verification below.';
GO

-- core.Product  <-  Stage 6 entity "Product"
IF OBJECT_ID(N'core.Product', N'U') IS NULL
BEGIN
    CREATE TABLE core.Product
    (
        Product_ID            int IDENTITY(1,1)  NOT NULL,
        Product_Code          nvarchar(30)       NOT NULL,
        Product_Name          nvarchar(150)      NOT NULL,
        Product_Description   nvarchar(1000)     NULL,
        Product_Category_ID   int                NOT NULL,
        Brand_ID              int                NOT NULL,
        Product_Type          nvarchar(30)       NOT NULL,
        Unit_Of_Measure       nvarchar(20)       NOT NULL,
        Product_Status        nvarchar(30)       NOT NULL,
        Launch_Date           date               NULL,
        Weight                decimal(10,3)      NULL,
        Tax_Rate              decimal(5,2)       NULL,
        Product_Created_Date  datetime2(0)       NOT NULL,
        Product_Updated_Date  datetime2(0)       NULL,
        CONSTRAINT PK_Product PRIMARY KEY CLUSTERED (Product_ID)
    );
    PRINT N'Created table core.Product.';
END
ELSE
    PRINT N'Table core.Product already exists - not altered; its structure is checked in the verification below.';
GO

-- core.SKU  <-  Stage 6 entity "SKU"
IF OBJECT_ID(N'core.SKU', N'U') IS NULL
BEGIN
    CREATE TABLE core.SKU
    (
        SKU_ID         int IDENTITY(1,1)  NOT NULL,
        Product_ID     int                NOT NULL,
        Package_ID     int                NOT NULL,
        SKU_Code       nvarchar(30)       NOT NULL,
        SKU_Name       nvarchar(150)      NOT NULL,
        Barcode        nvarchar(20)       NULL,
        Weight         decimal(10,3)      NULL,
        Standard_Cost  decimal(18,2)      NULL,
        Currency       char(3)            NULL,
        SKU_Status     nvarchar(30)       NOT NULL,
        CONSTRAINT PK_SKU PRIMARY KEY CLUSTERED (SKU_ID)
    );
    PRINT N'Created table core.SKU.';
END
ELSE
    PRINT N'Table core.SKU already exists - not altered; its structure is checked in the verification below.';
GO

/* ========================================================================
   Schema [marketing] - Marketing tables
   ======================================================================== */

-- marketing.ProductPrice  <-  Stage 6 entity "Product Price"
IF OBJECT_ID(N'marketing.ProductPrice', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.ProductPrice
    (
        Product_Price_ID  int IDENTITY(1,1)  NOT NULL,
        SKU_ID            int                NOT NULL,
        Price_Type        nvarchar(30)       NOT NULL,
        Unit_Price        decimal(18,2)      NOT NULL,
        Currency          char(3)            NOT NULL,
        Effective_From    date               NOT NULL,
        Effective_To      date               NULL,
        Price_Status      nvarchar(30)       NOT NULL,
        CONSTRAINT PK_ProductPrice PRIMARY KEY CLUSTERED (Product_Price_ID)
    );
    PRINT N'Created table marketing.ProductPrice.';
END
ELSE
    PRINT N'Table marketing.ProductPrice already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.CampaignChannel  <-  Stage 6 entity "Campaign Channel"
IF OBJECT_ID(N'marketing.CampaignChannel', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.CampaignChannel
    (
        Campaign_Channel_ID  int IDENTITY(1,1)  NOT NULL,
        Channel_Name         nvarchar(150)      NOT NULL,
        Channel_Type         nvarchar(30)       NOT NULL,
        Channel_Description  nvarchar(1000)     NULL,
        Channel_Status       nvarchar(30)       NOT NULL,
        CONSTRAINT PK_CampaignChannel PRIMARY KEY CLUSTERED (Campaign_Channel_ID)
    );
    PRINT N'Created table marketing.CampaignChannel.';
END
ELSE
    PRINT N'Table marketing.CampaignChannel already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.CampaignAudience  <-  Stage 6 entity "Campaign Audience"
IF OBJECT_ID(N'marketing.CampaignAudience', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.CampaignAudience
    (
        Campaign_Audience_ID  int IDENTITY(1,1)  NOT NULL,
        Audience_Name         nvarchar(150)      NOT NULL,
        Audience_Type         nvarchar(30)       NOT NULL,
        Audience_Description  nvarchar(1000)     NULL,
        Audience_Status       nvarchar(30)       NOT NULL,
        Age_Range             nvarchar(20)       NULL,
        Gender                nvarchar(20)       NULL,
        Geographic_Location   nvarchar(150)      NULL,
        CONSTRAINT PK_CampaignAudience PRIMARY KEY CLUSTERED (Campaign_Audience_ID)
    );
    PRINT N'Created table marketing.CampaignAudience.';
END
ELSE
    PRINT N'Table marketing.CampaignAudience already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.MarketingCampaign  <-  Stage 6 entity "Marketing Campaign"
IF OBJECT_ID(N'marketing.MarketingCampaign', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.MarketingCampaign
    (
        Marketing_Campaign_ID  int IDENTITY(1,1)  NOT NULL,
        Brand_ID               int                NULL,
        Campaign_Name          nvarchar(150)      NOT NULL,
        Campaign_Type          nvarchar(30)       NOT NULL,
        Campaign_Purpose       nvarchar(30)       NOT NULL,
        Campaign_Objective     nvarchar(500)      NULL,
        Start_Date             date               NOT NULL,
        End_Date               date               NULL,
        Campaign_Status        nvarchar(30)       NOT NULL,
        CONSTRAINT PK_MarketingCampaign PRIMARY KEY CLUSTERED (Marketing_Campaign_ID)
    );
    PRINT N'Created table marketing.MarketingCampaign.';
END
ELSE
    PRINT N'Table marketing.MarketingCampaign already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.MarketingCampaignChannel  <-  Stage 6 entity "Marketing Campaign Channel"
IF OBJECT_ID(N'marketing.MarketingCampaignChannel', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.MarketingCampaignChannel
    (
        Marketing_Campaign_ID  int  NOT NULL,
        Campaign_Channel_ID    int  NOT NULL,
        CONSTRAINT PK_MarketingCampaignChannel PRIMARY KEY CLUSTERED (Marketing_Campaign_ID, Campaign_Channel_ID)
    );
    PRINT N'Created table marketing.MarketingCampaignChannel.';
END
ELSE
    PRINT N'Table marketing.MarketingCampaignChannel already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.MarketingCampaignAudience  <-  Stage 6 entity "Marketing Campaign Audience"
IF OBJECT_ID(N'marketing.MarketingCampaignAudience', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.MarketingCampaignAudience
    (
        Marketing_Campaign_ID  int  NOT NULL,
        Campaign_Audience_ID   int  NOT NULL,
        CONSTRAINT PK_MarketingCampaignAudience PRIMARY KEY CLUSTERED (Marketing_Campaign_ID, Campaign_Audience_ID)
    );
    PRINT N'Created table marketing.MarketingCampaignAudience.';
END
ELSE
    PRINT N'Table marketing.MarketingCampaignAudience already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.CampaignBudget  <-  Stage 6 entity "Campaign Budget"
IF OBJECT_ID(N'marketing.CampaignBudget', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.CampaignBudget
    (
        Campaign_Budget_ID      int IDENTITY(1,1)  NOT NULL,
        Marketing_Campaign_ID   int                NOT NULL,
        Campaign_Channel_ID     int                NULL,
        Total_Allocated_Amount  decimal(18,2)      NOT NULL,
        Currency                char(3)            NOT NULL,
        Approval_Date           date               NULL,
        CONSTRAINT PK_CampaignBudget PRIMARY KEY CLUSTERED (Campaign_Budget_ID)
    );
    PRINT N'Created table marketing.CampaignBudget.';
END
ELSE
    PRINT N'Table marketing.CampaignBudget already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.CampaignCost  <-  Stage 6 entity "Campaign Cost"
IF OBJECT_ID(N'marketing.CampaignCost', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.CampaignCost
    (
        Campaign_Cost_ID       int IDENTITY(1,1)  NOT NULL,
        Marketing_Campaign_ID  int                NOT NULL,
        Campaign_Channel_ID    int                NULL,
        Actual_Spent           decimal(18,2)      NOT NULL,
        Currency               char(3)            NOT NULL,
        Cost_Date              date               NOT NULL,
        CONSTRAINT PK_CampaignCost PRIMARY KEY CLUSTERED (Campaign_Cost_ID)
    );
    PRINT N'Created table marketing.CampaignCost.';
END
ELSE
    PRINT N'Table marketing.CampaignCost already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.CampaignResult  <-  Stage 6 entity "Campaign Result"
IF OBJECT_ID(N'marketing.CampaignResult', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.CampaignResult
    (
        Campaign_Result_ID     int IDENTITY(1,1)  NOT NULL,
        Marketing_Campaign_ID  int                NOT NULL,
        Metric_Name            nvarchar(100)      NOT NULL,
        Metric_Value           decimal(18,4)      NOT NULL,
        Measurement_Date       date               NOT NULL,
        CONSTRAINT PK_CampaignResult PRIMARY KEY CLUSTERED (Campaign_Result_ID)
    );
    PRINT N'Created table marketing.CampaignResult.';
END
ELSE
    PRINT N'Table marketing.CampaignResult already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.Promotion  <-  Stage 6 entity "Promotion"
IF OBJECT_ID(N'marketing.Promotion', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.Promotion
    (
        Promotion_ID           int IDENTITY(1,1)  NOT NULL,
        Marketing_Campaign_ID  int                NULL,
        Promotion_Code         nvarchar(30)       NOT NULL,
        Promotion_Name         nvarchar(150)      NOT NULL,
        Promotion_Type         nvarchar(30)       NOT NULL,
        Discount_Type          nvarchar(30)       NOT NULL,
        Discount_Value         decimal(18,2)      NOT NULL,
        Currency               char(3)            NULL,
        Start_Date             date               NOT NULL,
        End_Date               date               NOT NULL,
        Promotion_Status       nvarchar(30)       NOT NULL,
        CONSTRAINT PK_Promotion PRIMARY KEY CLUSTERED (Promotion_ID)
    );
    PRINT N'Created table marketing.Promotion.';
END
ELSE
    PRINT N'Table marketing.Promotion already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.BrandActivity  <-  Stage 6 entity "Brand Activity"
IF OBJECT_ID(N'marketing.BrandActivity', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.BrandActivity
    (
        Brand_Activity_ID     int IDENTITY(1,1)  NOT NULL,
        Brand_ID              int                NOT NULL,
        Activity_Type         nvarchar(30)       NULL,
        Activity_Title        nvarchar(200)      NULL,
        Activity_Description  nvarchar(1000)     NULL,
        Activity_Start_Date   date               NULL,
        Activity_End_Date     date               NULL,
        Activity_Channel      nvarchar(100)      NULL,
        Activity_Status       nvarchar(30)       NULL,
        Activity_Owner        nvarchar(150)      NULL,
        Activity_Cost         decimal(18,2)      NULL,
        Currency              char(3)            NULL,
        Activity_Result       nvarchar(1000)     NULL,
        CONSTRAINT PK_BrandActivity PRIMARY KEY CLUSTERED (Brand_Activity_ID)
    );
    PRINT N'Created table marketing.BrandActivity.';
END
ELSE
    PRINT N'Table marketing.BrandActivity already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.Market  <-  Stage 6 entity "Market"
IF OBJECT_ID(N'marketing.Market', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.Market
    (
        Market_ID           int IDENTITY(1,1)  NOT NULL,
        Market_Code         nvarchar(30)       NOT NULL,
        Market_Name         nvarchar(150)      NOT NULL,
        Market_Type         nvarchar(30)       NULL,
        Market_Description  nvarchar(1000)     NULL,
        Market_Status       nvarchar(30)       NOT NULL,
        CONSTRAINT PK_Market PRIMARY KEY CLUSTERED (Market_ID)
    );
    PRINT N'Created table marketing.Market.';
END
ELSE
    PRINT N'Table marketing.Market already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.MarketSegment  <-  Stage 6 entity "Market Segment"
IF OBJECT_ID(N'marketing.MarketSegment', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.MarketSegment
    (
        Market_Segment_ID    int IDENTITY(1,1)  NOT NULL,
        Market_ID            int                NOT NULL,
        Segment_Code         nvarchar(30)       NOT NULL,
        Segment_Name         nvarchar(150)      NOT NULL,
        Segmentation_Basis   nvarchar(30)       NOT NULL,
        Segment_Description  nvarchar(1000)     NULL,
        Segment_Status       nvarchar(30)       NOT NULL,
        CONSTRAINT PK_MarketSegment PRIMARY KEY CLUSTERED (Market_Segment_ID)
    );
    PRINT N'Created table marketing.MarketSegment.';
END
ELSE
    PRINT N'Table marketing.MarketSegment already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.MarketResearch  <-  Stage 6 entity "Market Research"
IF OBJECT_ID(N'marketing.MarketResearch', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.MarketResearch
    (
        Market_Research_ID  int IDENTITY(1,1)  NOT NULL,
        Market_ID           int                NOT NULL,
        Research_Title      nvarchar(200)      NOT NULL,
        Research_Type       nvarchar(30)       NOT NULL,
        Start_Date          date               NOT NULL,
        End_Date            date               NULL,
        Research_Status     nvarchar(30)       NOT NULL,
        Responsible_Person  nvarchar(150)      NOT NULL,
        Research_Cost       decimal(18,2)      NULL,
        Currency            char(3)            NULL,
        CONSTRAINT PK_MarketResearch PRIMARY KEY CLUSTERED (Market_Research_ID)
    );
    PRINT N'Created table marketing.MarketResearch.';
END
ELSE
    PRINT N'Table marketing.MarketResearch already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.MarketSurvey  <-  Stage 6 entity "Market Survey"
IF OBJECT_ID(N'marketing.MarketSurvey', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.MarketSurvey
    (
        Market_Survey_ID    int IDENTITY(1,1)  NOT NULL,
        Market_Research_ID  int                NOT NULL,
        Market_Segment_ID   int                NULL,
        Survey_Title        nvarchar(200)      NOT NULL,
        Survey_Date         date               NOT NULL,
        Survey_Method       nvarchar(30)       NOT NULL,
        Sample_Size         int                NOT NULL,
        Survey_Status       nvarchar(30)       NOT NULL,
        CONSTRAINT PK_MarketSurvey PRIMARY KEY CLUSTERED (Market_Survey_ID)
    );
    PRINT N'Created table marketing.MarketSurvey.';
END
ELSE
    PRINT N'Table marketing.MarketSurvey already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.ResearchResult  <-  Stage 6 entity "Research Result"
IF OBJECT_ID(N'marketing.ResearchResult', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.ResearchResult
    (
        Research_Result_ID      int IDENTITY(1,1)  NOT NULL,
        Market_Research_ID      int                NOT NULL,
        Result_Title            nvarchar(200)      NOT NULL,
        Result_Summary          nvarchar(2000)     NOT NULL,
        Result_Date             date               NOT NULL,
        Recommendation          nvarchar(2000)     NULL,
        Opportunity_Identified  nvarchar(500)      NULL,
        CONSTRAINT PK_ResearchResult PRIMARY KEY CLUSTERED (Research_Result_ID)
    );
    PRINT N'Created table marketing.ResearchResult.';
END
ELSE
    PRINT N'Table marketing.ResearchResult already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.Competitor  <-  Stage 6 entity "Competitor"
IF OBJECT_ID(N'marketing.Competitor', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.Competitor
    (
        Competitor_ID      int IDENTITY(1,1)  NOT NULL,
        Competitor_Name    nvarchar(150)      NOT NULL,
        Competitor_Type    nvarchar(30)       NOT NULL,
        Market_ID          int                NULL,
        Competitor_Status  nvarchar(30)       NOT NULL,
        CONSTRAINT PK_Competitor PRIMARY KEY CLUSTERED (Competitor_ID)
    );
    PRINT N'Created table marketing.Competitor.';
END
ELSE
    PRINT N'Table marketing.Competitor already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.CompetitorProduct  <-  Stage 6 entity "Competitor Product"
IF OBJECT_ID(N'marketing.CompetitorProduct', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.CompetitorProduct
    (
        Competitor_Product_ID    int IDENTITY(1,1)  NOT NULL,
        Competitor_ID            int                NOT NULL,
        Competitor_Product_Name  nvarchar(150)      NOT NULL,
        Category                 nvarchar(100)      NULL,
        CONSTRAINT PK_CompetitorProduct PRIMARY KEY CLUSTERED (Competitor_Product_ID)
    );
    PRINT N'Created table marketing.CompetitorProduct.';
END
ELSE
    PRINT N'Table marketing.CompetitorProduct already exists - not altered; its structure is checked in the verification below.';
GO

-- marketing.MarketPrice  <-  Stage 6 entity "Market Price"
IF OBJECT_ID(N'marketing.MarketPrice', N'U') IS NULL
BEGIN
    CREATE TABLE marketing.MarketPrice
    (
        Market_Price_ID        int IDENTITY(1,1)  NOT NULL,
        Product_ID             int                NULL,
        Competitor_Product_ID  int                NULL,
        Market_ID              int                NOT NULL,
        Price_Date             datetime2(0)       NOT NULL,
        Price_Value            decimal(18,2)      NOT NULL,
        Currency               char(3)            NOT NULL,
        Price_Source           nvarchar(100)      NOT NULL,
        CONSTRAINT PK_MarketPrice PRIMARY KEY CLUSTERED (Market_Price_ID)
    );
    PRINT N'Created table marketing.MarketPrice.';
END
ELSE
    PRINT N'Table marketing.MarketPrice already exists - not altered; its structure is checked in the verification below.';
GO

/* ---- Verification: existing structure is compared with the expected definition (not assumed to be correct) ---- */
DECLARE @E TABLE (kind nvarchar(10), obj sysname, parent nvarchar(300), sig nvarchar(max));
INSERT @E VALUES
    (N'TABLE', N'ref.ProductCategory', N'ref.ProductCategory', N'Product_Category_ID int NOT NULL IDENTITY; Parent_Category_ID int NULL; Category_Code nvarchar(30) NOT NULL; Category_Name nvarchar(150) NOT NULL; Category_Level int NOT NULL; Category_Status nvarchar(30) NOT NULL'),
    (N'PK', N'PK_ProductCategory', N'ref.ProductCategory', N'CLUSTERED:Product_Category_ID'),
    (N'TABLE', N'ref.Package', N'ref.Package', N'Package_ID int NOT NULL IDENTITY; Package_Code nvarchar(30) NOT NULL; Package_Name nvarchar(150) NOT NULL; Package_Description nvarchar(1000) NULL'),
    (N'PK', N'PK_Package', N'ref.Package', N'CLUSTERED:Package_ID'),
    (N'TABLE', N'core.Brand', N'core.Brand', N'Brand_ID int NOT NULL IDENTITY; Brand_Name nvarchar(150) NOT NULL; Brand_Code nvarchar(30) NOT NULL; Brand_Type nvarchar(30) NOT NULL; Brand_Status nvarchar(30) NOT NULL; Brand_Start_Date date NULL; Brand_End_Date date NULL; Brand_Owner nvarchar(150) NULL; Brand_Positioning nvarchar(500) NULL; Target_Market nvarchar(100) NULL; Target_Segment nvarchar(100) NULL; Brand_Tagline nvarchar(250) NULL; Brand_Logo_URL nvarchar(500) NULL; Brand_Website nvarchar(500) NULL; Brand_Country char(2) NULL'),
    (N'PK', N'PK_Brand', N'core.Brand', N'CLUSTERED:Brand_ID'),
    (N'TABLE', N'core.Product', N'core.Product', N'Product_ID int NOT NULL IDENTITY; Product_Code nvarchar(30) NOT NULL; Product_Name nvarchar(150) NOT NULL; Product_Description nvarchar(1000) NULL; Product_Category_ID int NOT NULL; Brand_ID int NOT NULL; Product_Type nvarchar(30) NOT NULL; Unit_Of_Measure nvarchar(20) NOT NULL; Product_Status nvarchar(30) NOT NULL; Launch_Date date NULL; Weight decimal(10,3) NULL; Tax_Rate decimal(5,2) NULL; Product_Created_Date datetime2(0) NOT NULL; Product_Updated_Date datetime2(0) NULL'),
    (N'PK', N'PK_Product', N'core.Product', N'CLUSTERED:Product_ID'),
    (N'TABLE', N'core.SKU', N'core.SKU', N'SKU_ID int NOT NULL IDENTITY; Product_ID int NOT NULL; Package_ID int NOT NULL; SKU_Code nvarchar(30) NOT NULL; SKU_Name nvarchar(150) NOT NULL; Barcode nvarchar(20) NULL; Weight decimal(10,3) NULL; Standard_Cost decimal(18,2) NULL; Currency char(3) NULL; SKU_Status nvarchar(30) NOT NULL'),
    (N'PK', N'PK_SKU', N'core.SKU', N'CLUSTERED:SKU_ID'),
    (N'TABLE', N'marketing.ProductPrice', N'marketing.ProductPrice', N'Product_Price_ID int NOT NULL IDENTITY; SKU_ID int NOT NULL; Price_Type nvarchar(30) NOT NULL; Unit_Price decimal(18,2) NOT NULL; Currency char(3) NOT NULL; Effective_From date NOT NULL; Effective_To date NULL; Price_Status nvarchar(30) NOT NULL'),
    (N'PK', N'PK_ProductPrice', N'marketing.ProductPrice', N'CLUSTERED:Product_Price_ID'),
    (N'TABLE', N'marketing.CampaignChannel', N'marketing.CampaignChannel', N'Campaign_Channel_ID int NOT NULL IDENTITY; Channel_Name nvarchar(150) NOT NULL; Channel_Type nvarchar(30) NOT NULL; Channel_Description nvarchar(1000) NULL; Channel_Status nvarchar(30) NOT NULL'),
    (N'PK', N'PK_CampaignChannel', N'marketing.CampaignChannel', N'CLUSTERED:Campaign_Channel_ID'),
    (N'TABLE', N'marketing.CampaignAudience', N'marketing.CampaignAudience', N'Campaign_Audience_ID int NOT NULL IDENTITY; Audience_Name nvarchar(150) NOT NULL; Audience_Type nvarchar(30) NOT NULL; Audience_Description nvarchar(1000) NULL; Audience_Status nvarchar(30) NOT NULL; Age_Range nvarchar(20) NULL; Gender nvarchar(20) NULL; Geographic_Location nvarchar(150) NULL'),
    (N'PK', N'PK_CampaignAudience', N'marketing.CampaignAudience', N'CLUSTERED:Campaign_Audience_ID'),
    (N'TABLE', N'marketing.MarketingCampaign', N'marketing.MarketingCampaign', N'Marketing_Campaign_ID int NOT NULL IDENTITY; Brand_ID int NULL; Campaign_Name nvarchar(150) NOT NULL; Campaign_Type nvarchar(30) NOT NULL; Campaign_Purpose nvarchar(30) NOT NULL; Campaign_Objective nvarchar(500) NULL; Start_Date date NOT NULL; End_Date date NULL; Campaign_Status nvarchar(30) NOT NULL'),
    (N'PK', N'PK_MarketingCampaign', N'marketing.MarketingCampaign', N'CLUSTERED:Marketing_Campaign_ID'),
    (N'TABLE', N'marketing.MarketingCampaignChannel', N'marketing.MarketingCampaignChannel', N'Marketing_Campaign_ID int NOT NULL; Campaign_Channel_ID int NOT NULL'),
    (N'PK', N'PK_MarketingCampaignChannel', N'marketing.MarketingCampaignChannel', N'CLUSTERED:Marketing_Campaign_ID,Campaign_Channel_ID'),
    (N'TABLE', N'marketing.MarketingCampaignAudience', N'marketing.MarketingCampaignAudience', N'Marketing_Campaign_ID int NOT NULL; Campaign_Audience_ID int NOT NULL'),
    (N'PK', N'PK_MarketingCampaignAudience', N'marketing.MarketingCampaignAudience', N'CLUSTERED:Marketing_Campaign_ID,Campaign_Audience_ID'),
    (N'TABLE', N'marketing.CampaignBudget', N'marketing.CampaignBudget', N'Campaign_Budget_ID int NOT NULL IDENTITY; Marketing_Campaign_ID int NOT NULL; Campaign_Channel_ID int NULL; Total_Allocated_Amount decimal(18,2) NOT NULL; Currency char(3) NOT NULL; Approval_Date date NULL'),
    (N'PK', N'PK_CampaignBudget', N'marketing.CampaignBudget', N'CLUSTERED:Campaign_Budget_ID'),
    (N'TABLE', N'marketing.CampaignCost', N'marketing.CampaignCost', N'Campaign_Cost_ID int NOT NULL IDENTITY; Marketing_Campaign_ID int NOT NULL; Campaign_Channel_ID int NULL; Actual_Spent decimal(18,2) NOT NULL; Currency char(3) NOT NULL; Cost_Date date NOT NULL'),
    (N'PK', N'PK_CampaignCost', N'marketing.CampaignCost', N'CLUSTERED:Campaign_Cost_ID'),
    (N'TABLE', N'marketing.CampaignResult', N'marketing.CampaignResult', N'Campaign_Result_ID int NOT NULL IDENTITY; Marketing_Campaign_ID int NOT NULL; Metric_Name nvarchar(100) NOT NULL; Metric_Value decimal(18,4) NOT NULL; Measurement_Date date NOT NULL'),
    (N'PK', N'PK_CampaignResult', N'marketing.CampaignResult', N'CLUSTERED:Campaign_Result_ID'),
    (N'TABLE', N'marketing.Promotion', N'marketing.Promotion', N'Promotion_ID int NOT NULL IDENTITY; Marketing_Campaign_ID int NULL; Promotion_Code nvarchar(30) NOT NULL; Promotion_Name nvarchar(150) NOT NULL; Promotion_Type nvarchar(30) NOT NULL; Discount_Type nvarchar(30) NOT NULL; Discount_Value decimal(18,2) NOT NULL; Currency char(3) NULL; Start_Date date NOT NULL; End_Date date NOT NULL; Promotion_Status nvarchar(30) NOT NULL'),
    (N'PK', N'PK_Promotion', N'marketing.Promotion', N'CLUSTERED:Promotion_ID'),
    (N'TABLE', N'marketing.BrandActivity', N'marketing.BrandActivity', N'Brand_Activity_ID int NOT NULL IDENTITY; Brand_ID int NOT NULL; Activity_Type nvarchar(30) NULL; Activity_Title nvarchar(200) NULL; Activity_Description nvarchar(1000) NULL; Activity_Start_Date date NULL; Activity_End_Date date NULL; Activity_Channel nvarchar(100) NULL; Activity_Status nvarchar(30) NULL; Activity_Owner nvarchar(150) NULL; Activity_Cost decimal(18,2) NULL; Currency char(3) NULL; Activity_Result nvarchar(1000) NULL'),
    (N'PK', N'PK_BrandActivity', N'marketing.BrandActivity', N'CLUSTERED:Brand_Activity_ID'),
    (N'TABLE', N'marketing.Market', N'marketing.Market', N'Market_ID int NOT NULL IDENTITY; Market_Code nvarchar(30) NOT NULL; Market_Name nvarchar(150) NOT NULL; Market_Type nvarchar(30) NULL; Market_Description nvarchar(1000) NULL; Market_Status nvarchar(30) NOT NULL'),
    (N'PK', N'PK_Market', N'marketing.Market', N'CLUSTERED:Market_ID'),
    (N'TABLE', N'marketing.MarketSegment', N'marketing.MarketSegment', N'Market_Segment_ID int NOT NULL IDENTITY; Market_ID int NOT NULL; Segment_Code nvarchar(30) NOT NULL; Segment_Name nvarchar(150) NOT NULL; Segmentation_Basis nvarchar(30) NOT NULL; Segment_Description nvarchar(1000) NULL; Segment_Status nvarchar(30) NOT NULL'),
    (N'PK', N'PK_MarketSegment', N'marketing.MarketSegment', N'CLUSTERED:Market_Segment_ID'),
    (N'TABLE', N'marketing.MarketResearch', N'marketing.MarketResearch', N'Market_Research_ID int NOT NULL IDENTITY; Market_ID int NOT NULL; Research_Title nvarchar(200) NOT NULL; Research_Type nvarchar(30) NOT NULL; Start_Date date NOT NULL; End_Date date NULL; Research_Status nvarchar(30) NOT NULL; Responsible_Person nvarchar(150) NOT NULL; Research_Cost decimal(18,2) NULL; Currency char(3) NULL'),
    (N'PK', N'PK_MarketResearch', N'marketing.MarketResearch', N'CLUSTERED:Market_Research_ID'),
    (N'TABLE', N'marketing.MarketSurvey', N'marketing.MarketSurvey', N'Market_Survey_ID int NOT NULL IDENTITY; Market_Research_ID int NOT NULL; Market_Segment_ID int NULL; Survey_Title nvarchar(200) NOT NULL; Survey_Date date NOT NULL; Survey_Method nvarchar(30) NOT NULL; Sample_Size int NOT NULL; Survey_Status nvarchar(30) NOT NULL'),
    (N'PK', N'PK_MarketSurvey', N'marketing.MarketSurvey', N'CLUSTERED:Market_Survey_ID'),
    (N'TABLE', N'marketing.ResearchResult', N'marketing.ResearchResult', N'Research_Result_ID int NOT NULL IDENTITY; Market_Research_ID int NOT NULL; Result_Title nvarchar(200) NOT NULL; Result_Summary nvarchar(2000) NOT NULL; Result_Date date NOT NULL; Recommendation nvarchar(2000) NULL; Opportunity_Identified nvarchar(500) NULL'),
    (N'PK', N'PK_ResearchResult', N'marketing.ResearchResult', N'CLUSTERED:Research_Result_ID'),
    (N'TABLE', N'marketing.Competitor', N'marketing.Competitor', N'Competitor_ID int NOT NULL IDENTITY; Competitor_Name nvarchar(150) NOT NULL; Competitor_Type nvarchar(30) NOT NULL; Market_ID int NULL; Competitor_Status nvarchar(30) NOT NULL'),
    (N'PK', N'PK_Competitor', N'marketing.Competitor', N'CLUSTERED:Competitor_ID'),
    (N'TABLE', N'marketing.CompetitorProduct', N'marketing.CompetitorProduct', N'Competitor_Product_ID int NOT NULL IDENTITY; Competitor_ID int NOT NULL; Competitor_Product_Name nvarchar(150) NOT NULL; Category nvarchar(100) NULL'),
    (N'PK', N'PK_CompetitorProduct', N'marketing.CompetitorProduct', N'CLUSTERED:Competitor_Product_ID'),
    (N'TABLE', N'marketing.MarketPrice', N'marketing.MarketPrice', N'Market_Price_ID int NOT NULL IDENTITY; Product_ID int NULL; Competitor_Product_ID int NULL; Market_ID int NOT NULL; Price_Date datetime2(0) NOT NULL; Price_Value decimal(18,2) NOT NULL; Currency char(3) NOT NULL; Price_Source nvarchar(100) NOT NULL'),
    (N'PK', N'PK_MarketPrice', N'marketing.MarketPrice', N'CLUSTERED:Market_Price_ID');
DECLARE @D TABLE (kind nvarchar(10), obj sysname, problem nvarchar(max));
WITH tbl AS (SELECT OBJECT_ID(n) AS object_id, n AS full_name FROM (VALUES (N'ref.ProductCategory'), (N'ref.Package'), (N'core.Brand'), (N'core.Product'), (N'core.SKU'), (N'marketing.ProductPrice'), (N'marketing.CampaignChannel'), (N'marketing.CampaignAudience'), (N'marketing.MarketingCampaign'), (N'marketing.MarketingCampaignChannel'), (N'marketing.MarketingCampaignAudience'), (N'marketing.CampaignBudget'), (N'marketing.CampaignCost'), (N'marketing.CampaignResult'), (N'marketing.Promotion'), (N'marketing.BrandActivity'), (N'marketing.Market'), (N'marketing.MarketSegment'), (N'marketing.MarketResearch'), (N'marketing.MarketSurvey'), (N'marketing.ResearchResult'), (N'marketing.Competitor'), (N'marketing.CompetitorProduct'), (N'marketing.MarketPrice')) v(n) WHERE OBJECT_ID(n) IS NOT NULL),
icols AS (
    SELECT i.object_id, i.index_id, i.name, i.type_desc, i.is_unique, i.is_primary_key, i.is_unique_constraint, i.filter_definition,
           STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',')
               WITHIN GROUP (ORDER BY ic.key_ordinal, col.name) AS keys,
           STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',')
               WITHIN GROUP (ORDER BY ic.key_ordinal, col.name) AS incs
    FROM sys.indexes i
    JOIN tbl t ON t.object_id = i.object_id
    JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
    GROUP BY i.object_id, i.index_id, i.name, i.type_desc, i.is_unique, i.is_primary_key, i.is_unique_constraint, i.filter_definition),
act AS (
    SELECT N'TABLE' AS kind, t.full_name AS obj, t.full_name AS parent,
           (SELECT STRING_AGG(CONCAT(CAST(c.name AS nvarchar(max)), N' ', CASE WHEN ty.name IN (N'nvarchar', N'nchar') THEN ty.name + N'(' + CASE WHEN c.max_length = -1 THEN N'max' ELSE CAST(c.max_length / 2 AS nvarchar(10)) END + N')' WHEN ty.name IN (N'varchar', N'char') THEN ty.name + N'(' + CASE WHEN c.max_length = -1 THEN N'max' ELSE CAST(c.max_length AS nvarchar(10)) END + N')' WHEN ty.name IN (N'decimal', N'numeric') THEN ty.name + N'(' + CAST(c.precision AS nvarchar(10)) + N',' + CAST(c.scale AS nvarchar(10)) + N')' WHEN ty.name = N'datetime2' THEN N'datetime2(' + CAST(c.scale AS nvarchar(10)) + N')' ELSE ty.name END, IIF(c.is_nullable = 1, N' NULL', N' NOT NULL'), IIF(c.is_identity = 1, N' IDENTITY', N'')), N'; ')
                   WITHIN GROUP (ORDER BY c.column_id)
            FROM sys.columns c JOIN sys.types ty ON ty.user_type_id = c.user_type_id WHERE c.object_id = t.object_id) AS sig
    FROM tbl t
    UNION ALL
    SELECT CASE WHEN x.is_primary_key = 1 THEN N'PK' WHEN x.is_unique_constraint = 1 THEN N'UQ' WHEN x.is_unique = 1 THEN N'UX' ELSE N'IX' END,
           x.name, t.full_name,
           CASE WHEN x.is_primary_key = 1 THEN CONCAT(x.type_desc, N':', x.keys)
                ELSE CONCAT(x.type_desc, N'|', IIF(x.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|', x.keys, N'|', x.incs, N'|', x.filter_definition) END
    FROM icols x JOIN tbl t ON t.object_id = x.object_id
    UNION ALL
    SELECT N'CK', k.name, t.full_name, k.definition FROM sys.check_constraints k JOIN tbl t ON t.object_id = k.parent_object_id
    UNION ALL
    SELECT N'DF', d.name, t.full_name, CONCAT(col.name, N'=', d.definition)
    FROM sys.default_constraints d JOIN tbl t ON t.object_id = d.parent_object_id
    JOIN sys.columns col ON col.object_id = d.parent_object_id AND col.column_id = d.parent_column_id
    UNION ALL
    SELECT N'FK', f.name, t.full_name,
           CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
                  OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
                  STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
                  f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
    FROM sys.foreign_keys f JOIN tbl t ON t.object_id = f.parent_object_id
    JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
    JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
    JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
    GROUP BY f.name, t.full_name, f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc
    UNION ALL
    SELECT N'TR', tr.name, t.full_name,
           CONCAT(t.full_name, N'|', IIF(tr.is_instead_of_trigger = 1, N'INSTEAD OF', N'AFTER'), N'|',
                  (SELECT STRING_AGG(CAST(te.type_desc AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY te.type_desc) FROM sys.trigger_events te WHERE te.object_id = tr.object_id),
                  N'|', IIF(tr.is_disabled = 1, N'DISABLED', N'ENABLED'))
    FROM sys.triggers tr JOIN tbl t ON t.object_id = tr.parent_id)
INSERT @D
SELECT COALESCE(e.kind, a.kind), COALESCE(e.obj, a.obj),
       CASE WHEN a.obj IS NULL THEN N'missing'
            WHEN e.obj IS NULL THEN N'unexpected object: ' + a.sig
            ELSE N'expected [' + e.sig + N'] actual [' + a.sig + N']' END
FROM @E e
FULL JOIN (SELECT * FROM act WHERE kind IN (N'TABLE', N'PK')) a
  ON a.kind = e.kind AND a.obj COLLATE Latin1_General_BIN2 = e.obj COLLATE Latin1_General_BIN2 AND a.parent COLLATE Latin1_General_BIN2 = e.parent COLLATE Latin1_General_BIN2
WHERE a.obj IS NULL OR e.obj IS NULL OR a.sig COLLATE Latin1_General_BIN2 <> e.sig COLLATE Latin1_General_BIN2;
DECLARE @nE int = (SELECT COUNT(*) FROM @E), @nD int = (SELECT COUNT(*) FROM @D), @line nvarchar(max);
IF @nD = 0
    PRINT CONCAT(N'Verification passed: all ', @nE, N' tables and primary keys (columns, data types, lengths, NULL/NOT NULL, IDENTITY, PK columns) match the expected definition.');
ELSE
BEGIN
    DECLARE d CURSOR LOCAL FAST_FORWARD FOR SELECT CONCAT(N'  DIFFERENCE ', kind, N' ', obj, N': ', problem) FROM @D;
    OPEN d; FETCH NEXT FROM d INTO @line;
    WHILE @@FETCH_STATUS = 0 BEGIN PRINT @line; FETCH NEXT FROM d INTO @line; END;
    CLOSE d; DEALLOCATE d;
    RAISERROR(N'Verification FAILED: %d object(s) differ from the expected definition (see the lines above).', 16, 1, @nD);
END;
GO

SET NOEXEC OFF;
GO
PRINT N'07-Team2-03-Create-Tables.sql finished.';
GO


/*=============================================================================
  STAGE 3.2 - CREATE CONSTRAINTS, FOREIGN KEYS, AND INTEGRITY TRIGGERS
  Tables for both teams now exist, allowing cross-team relationships to be added.
=============================================================================*/


/*---------------- SOURCE FILE: 07-Team1-02-Create-Constraints.sql ----------------*/
/*
    Project : Food Distribution (Etemad Iranian Food Distribution)
    Stage   : 7 - Physical Data Model
    Team    : Team 1 - Sales & Customer
    Database: FoodDistributionDB
    SQL Server: 2022
    File    : 07-Team1-02-Create-Constraints.sql
    Purpose : UNIQUE, CHECK and DEFAULT constraints, then FOREIGN KEYs (PKs are already in 01).
    Run order: 2 (after 07-Team1-01-Create-Tables.sql)
    Prerequisites: All 24 Team 1 tables exist. The 6 FKs to Team 2 tables (core.Product, marketing.Promotion) are created only if those tables exist.
    Source  : 06-Team1-Sales-Customer-Logical-Data-Model.xlsx (Stage 6)
    Schemas : Team 1 proposal for the Entity-to-Schema matrix (ref / core / sales); not yet approved
    Re-run  : Safe. Every object is created only if it does not already exist.
*/

USE [FoodDistributionDB];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

/* ---- Prerequisite check: stop the whole script if a prerequisite is missing ---- */
IF OBJECT_ID(N'ref.Province', N'U') IS NULL
   OR OBJECT_ID(N'ref.City', N'U') IS NULL
   OR OBJECT_ID(N'ref.CustomerSegment', N'U') IS NULL
   OR OBJECT_ID(N'ref.SalesChannel', N'U') IS NULL
   OR OBJECT_ID(N'ref.SalesRegion', N'U') IS NULL
   OR OBJECT_ID(N'ref.SalesTerritory', N'U') IS NULL
   OR OBJECT_ID(N'core.Calendar', N'U') IS NULL
   OR OBJECT_ID(N'core.Branch', N'U') IS NULL
   OR OBJECT_ID(N'core.Salesperson', N'U') IS NULL
   OR OBJECT_ID(N'core.Customer', N'U') IS NULL
   OR OBJECT_ID(N'sales.Lead', N'U') IS NULL
   OR OBJECT_ID(N'sales.CustomerInteraction', N'U') IS NULL
   OR OBJECT_ID(N'sales.SalesOpportunity', N'U') IS NULL
   OR OBJECT_ID(N'sales.Contract', N'U') IS NULL
   OR OBJECT_ID(N'sales.SalesOrder', N'U') IS NULL
   OR OBJECT_ID(N'sales.SalesOrderItem', N'U') IS NULL
   OR OBJECT_ID(N'sales.Invoice', N'U') IS NULL
   OR OBJECT_ID(N'sales.InvoiceItem', N'U') IS NULL
   OR OBJECT_ID(N'sales.Payment', N'U') IS NULL
   OR OBJECT_ID(N'sales.ReturnRequest', N'U') IS NULL
   OR OBJECT_ID(N'sales.CustomerFeedback', N'U') IS NULL
   OR OBJECT_ID(N'sales.Commission', N'U') IS NULL
   OR OBJECT_ID(N'sales.SalesTarget', N'U') IS NULL
   OR OBJECT_ID(N'sales.SalesForecast', N'U') IS NULL
BEGIN
    RAISERROR(N'Team 1 tables are missing. Run 07-Team1-01-Create-Tables.sql first.', 16, 1);
    SET NOEXEC ON;
END;
GO

/* ========================================================================
   1. UNIQUE constraints (business keys)
   ======================================================================== */

IF OBJECT_ID(N'ref.UQ_Province_Province_Code') IS NULL
    ALTER TABLE ref.Province ADD CONSTRAINT UQ_Province_Province_Code UNIQUE (Province_Code);
GO

IF OBJECT_ID(N'ref.UQ_Province_Province_Name') IS NULL
    ALTER TABLE ref.Province ADD CONSTRAINT UQ_Province_Province_Name UNIQUE (Province_Name);
GO

IF OBJECT_ID(N'ref.UQ_City_City_Code') IS NULL
    ALTER TABLE ref.City ADD CONSTRAINT UQ_City_City_Code UNIQUE (City_Code);
GO

IF OBJECT_ID(N'ref.UQ_CustomerSegment_Segment_Code') IS NULL
    ALTER TABLE ref.CustomerSegment ADD CONSTRAINT UQ_CustomerSegment_Segment_Code UNIQUE (Segment_Code);
GO

IF OBJECT_ID(N'ref.UQ_SalesChannel_Sales_Channel_Code') IS NULL
    ALTER TABLE ref.SalesChannel ADD CONSTRAINT UQ_SalesChannel_Sales_Channel_Code UNIQUE (Sales_Channel_Code);
GO

IF OBJECT_ID(N'ref.UQ_SalesRegion_Sales_Region_Code') IS NULL
    ALTER TABLE ref.SalesRegion ADD CONSTRAINT UQ_SalesRegion_Sales_Region_Code UNIQUE (Sales_Region_Code);
GO

IF OBJECT_ID(N'ref.UQ_SalesTerritory_Territory_Code') IS NULL
    ALTER TABLE ref.SalesTerritory ADD CONSTRAINT UQ_SalesTerritory_Territory_Code UNIQUE (Territory_Code);
GO

IF OBJECT_ID(N'core.UQ_Calendar_Calendar_Date') IS NULL
    ALTER TABLE core.Calendar ADD CONSTRAINT UQ_Calendar_Calendar_Date UNIQUE (Calendar_Date);
GO

IF OBJECT_ID(N'core.UQ_Branch_Branch_Code') IS NULL
    ALTER TABLE core.Branch ADD CONSTRAINT UQ_Branch_Branch_Code UNIQUE (Branch_Code);
GO

IF OBJECT_ID(N'core.UQ_Salesperson_Salesperson_Code') IS NULL
    ALTER TABLE core.Salesperson ADD CONSTRAINT UQ_Salesperson_Salesperson_Code UNIQUE (Salesperson_Code);
GO

IF OBJECT_ID(N'core.UQ_Customer_Customer_Code') IS NULL
    ALTER TABLE core.Customer ADD CONSTRAINT UQ_Customer_Customer_Code UNIQUE (Customer_Code);
GO

IF OBJECT_ID(N'sales.UQ_SalesOpportunity_Opportunity_Code') IS NULL
    ALTER TABLE sales.SalesOpportunity ADD CONSTRAINT UQ_SalesOpportunity_Opportunity_Code UNIQUE (Opportunity_Code);
GO

IF OBJECT_ID(N'sales.UQ_Contract_Contract_Number') IS NULL
    ALTER TABLE sales.Contract ADD CONSTRAINT UQ_Contract_Contract_Number UNIQUE (Contract_Number);
GO

IF OBJECT_ID(N'sales.UQ_SalesOrder_Sales_Order_Number') IS NULL
    ALTER TABLE sales.SalesOrder ADD CONSTRAINT UQ_SalesOrder_Sales_Order_Number UNIQUE (Sales_Order_Number);
GO

IF OBJECT_ID(N'sales.UQ_SalesOrderItem_Sales_Order_ID_Line_Number') IS NULL
    ALTER TABLE sales.SalesOrderItem ADD CONSTRAINT UQ_SalesOrderItem_Sales_Order_ID_Line_Number UNIQUE (Sales_Order_ID, Line_Number);
GO

IF OBJECT_ID(N'sales.UQ_Invoice_Invoice_Number') IS NULL
    ALTER TABLE sales.Invoice ADD CONSTRAINT UQ_Invoice_Invoice_Number UNIQUE (Invoice_Number);
GO

IF OBJECT_ID(N'sales.UQ_Commission_Salesperson_ID_Calendar_ID') IS NULL
    ALTER TABLE sales.Commission ADD CONSTRAINT UQ_Commission_Salesperson_ID_Calendar_ID UNIQUE (Salesperson_ID, Calendar_ID);
GO

IF OBJECT_ID(N'sales.UQ_SalesForecast_Calendar_ID_Forecast_Version') IS NULL
    ALTER TABLE sales.SalesForecast ADD CONSTRAINT UQ_SalesForecast_Calendar_ID_Forecast_Version UNIQUE (Calendar_ID, Forecast_Version);
GO

-- یکتایی (Target_Level، Calendar_ID، Target_Version، FK بُعدیِ همان سطح)؛ چون فقط یک FK بُعدی پر است و بقیه NULL، یک UNIQUE روی همه‌ی ستون‌ها یکتایی هر سطح را می‌دهد
IF OBJECT_ID(N'sales.UQ_SalesTarget_Target_Level_Calendar_ID_Target_Version_Dimensions') IS NULL
    ALTER TABLE sales.SalesTarget ADD CONSTRAINT UQ_SalesTarget_Target_Level_Calendar_ID_Target_Version_Dimensions UNIQUE
        (
            Target_Level,
            Calendar_ID,
            Target_Version,
            Sales_Region_ID,
            Salesperson_ID,
            Sales_Channel_ID,
            Product_ID
        );
GO

/* Helper keys: (PK + Customer_ID) is unique by construction; it exists only as the target of the composite FKs in section 5 (rules CE-01..CE-03; the pair (Invoice_ID, Sales_Order_ID) serves review correction 1). */

IF OBJECT_ID(N'sales.UQ_SalesOrder_Sales_Order_ID_Customer_ID') IS NULL
    ALTER TABLE sales.SalesOrder ADD CONSTRAINT UQ_SalesOrder_Sales_Order_ID_Customer_ID UNIQUE (Sales_Order_ID, Customer_ID);
GO

IF OBJECT_ID(N'sales.UQ_Invoice_Invoice_ID_Customer_ID') IS NULL
    ALTER TABLE sales.Invoice ADD CONSTRAINT UQ_Invoice_Invoice_ID_Customer_ID UNIQUE (Invoice_ID, Customer_ID);
GO

-- Review correction 1: (Invoice_ID, Sales_Order_ID) is the target of FK_Payment_Invoice_Invoice_ID_Sales_Order_ID (invoice and order of one payment must belong together)
IF OBJECT_ID(N'sales.UQ_Invoice_Invoice_ID_Sales_Order_ID') IS NULL
    ALTER TABLE sales.Invoice ADD CONSTRAINT UQ_Invoice_Invoice_ID_Sales_Order_ID UNIQUE (Invoice_ID, Sales_Order_ID);
GO

IF OBJECT_ID(N'sales.UQ_CustomerInteraction_Customer_Interaction_ID_Customer_ID') IS NULL
    ALTER TABLE sales.CustomerInteraction ADD CONSTRAINT UQ_CustomerInteraction_Customer_Interaction_ID_Customer_ID UNIQUE (Customer_Interaction_ID, Customer_ID);
GO

/* Optional columns that must be unique when filled: filtered unique index (a UNIQUE constraint would allow only one NULL). */

-- Lead_Code در صورت وجود یکتا است
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Lead_Lead_Code' AND object_id = OBJECT_ID(N'sales.Lead'))
    CREATE UNIQUE NONCLUSTERED INDEX UQ_Lead_Lead_Code ON sales.Lead (Lead_Code) WHERE Lead_Code IS NOT NULL;
GO

-- Transaction_Reference در صورت وجود یکتا است
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Payment_Transaction_Reference' AND object_id = OBJECT_ID(N'sales.Payment'))
    CREATE UNIQUE NONCLUSTERED INDEX UQ_Payment_Transaction_Reference ON sales.Payment (Transaction_Reference) WHERE Transaction_Reference IS NOT NULL;
GO

-- رابطه 1:1 با Interaction: در صورت وجود یکتا است
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_CustomerFeedback_Customer_Interaction_ID' AND object_id = OBJECT_ID(N'sales.CustomerFeedback'))
    CREATE UNIQUE NONCLUSTERED INDEX UQ_CustomerFeedback_Customer_Interaction_ID ON sales.CustomerFeedback (Customer_Interaction_ID) WHERE Customer_Interaction_ID IS NOT NULL;
GO

/* ========================================================================
   2. CHECK constraints (business rules of the Stage 6 logical model)
   ======================================================================== */

IF OBJECT_ID(N'ref.CK_City_City_Level') IS NULL
    ALTER TABLE ref.City ADD CONSTRAINT CK_City_City_Level CHECK (City_Level IN (N'City', N'District'));
GO

IF OBJECT_ID(N'ref.CK_City_Parent_City_ID') IS NULL
    ALTER TABLE ref.City ADD CONSTRAINT CK_City_Parent_City_ID CHECK (Parent_City_ID IS NULL OR (City_Level = N'District' AND Parent_City_ID <> City_ID));
GO

IF OBJECT_ID(N'ref.CK_CustomerSegment_Priority') IS NULL
    ALTER TABLE ref.CustomerSegment ADD CONSTRAINT CK_CustomerSegment_Priority CHECK (Priority >= 0);
GO

IF OBJECT_ID(N'ref.CK_CustomerSegment_End_Date') IS NULL
    ALTER TABLE ref.CustomerSegment ADD CONSTRAINT CK_CustomerSegment_End_Date CHECK (End_Date >= Created_Date);
GO

IF OBJECT_ID(N'ref.CK_SalesRegion_Parent_Sales_Region_ID') IS NULL
    ALTER TABLE ref.SalesRegion ADD CONSTRAINT CK_SalesRegion_Parent_Sales_Region_ID CHECK (Parent_Sales_Region_ID <> Sales_Region_ID);
GO

IF OBJECT_ID(N'ref.CK_SalesTerritory_Visit_Frequency') IS NULL
    ALTER TABLE ref.SalesTerritory ADD CONSTRAINT CK_SalesTerritory_Visit_Frequency CHECK (Visit_Frequency > 0);
GO

IF OBJECT_ID(N'core.CK_Calendar_Week_Number') IS NULL
    ALTER TABLE core.Calendar ADD CONSTRAINT CK_Calendar_Week_Number CHECK (Week_Number BETWEEN 1 AND 53);
GO

IF OBJECT_ID(N'core.CK_Calendar_Calendar_Date') IS NULL
    ALTER TABLE core.Calendar ADD CONSTRAINT CK_Calendar_Calendar_Date CHECK (Day_Number = DAY(Calendar_Date) AND Month_Number = MONTH(Calendar_Date) AND Quarter_Number = DATEPART(QUARTER, Calendar_Date) AND Year_Number = YEAR(Calendar_Date));
GO

IF OBJECT_ID(N'core.CK_Salesperson_Manager_Salesperson_ID') IS NULL
    ALTER TABLE core.Salesperson ADD CONSTRAINT CK_Salesperson_Manager_Salesperson_ID CHECK (Manager_Salesperson_ID <> Salesperson_ID);
GO

IF OBJECT_ID(N'core.CK_Salesperson_Email') IS NULL
    ALTER TABLE core.Salesperson ADD CONSTRAINT CK_Salesperson_Email CHECK (Email LIKE '_%@_%._%' AND Email NOT LIKE '% %');
GO

IF OBJECT_ID(N'core.CK_Customer_Employee_Count') IS NULL
    ALTER TABLE core.Customer ADD CONSTRAINT CK_Customer_Employee_Count CHECK (Employee_Count >= 0);
GO

IF OBJECT_ID(N'core.CK_Customer_Annual_Revenue') IS NULL
    ALTER TABLE core.Customer ADD CONSTRAINT CK_Customer_Annual_Revenue CHECK (Annual_Revenue >= 0);
GO

IF OBJECT_ID(N'core.CK_Customer_Email') IS NULL
    ALTER TABLE core.Customer ADD CONSTRAINT CK_Customer_Email CHECK (Email LIKE '_%@_%._%' AND Email NOT LIKE '% %');
GO

IF OBJECT_ID(N'core.CK_Customer_Latitude') IS NULL
    ALTER TABLE core.Customer ADD CONSTRAINT CK_Customer_Latitude CHECK (Latitude BETWEEN -90 AND 90);
GO

IF OBJECT_ID(N'core.CK_Customer_Longitude') IS NULL
    ALTER TABLE core.Customer ADD CONSTRAINT CK_Customer_Longitude CHECK (Longitude BETWEEN -180 AND 180);
GO

IF OBJECT_ID(N'core.CK_Customer_Credit_Limit') IS NULL
    ALTER TABLE core.Customer ADD CONSTRAINT CK_Customer_Credit_Limit CHECK (Credit_Limit >= 0);
GO

IF OBJECT_ID(N'sales.CK_Lead_Expected_Value') IS NULL
    ALTER TABLE sales.Lead ADD CONSTRAINT CK_Lead_Expected_Value CHECK (Expected_Value >= 0);
GO

IF OBJECT_ID(N'sales.CK_Lead_Conversion_Date') IS NULL
    ALTER TABLE sales.Lead ADD CONSTRAINT CK_Lead_Conversion_Date CHECK (Conversion_Date >= Created_Date);
GO

IF OBJECT_ID(N'sales.CK_CustomerInteraction_Interaction_Duration_Minutes') IS NULL
    ALTER TABLE sales.CustomerInteraction ADD CONSTRAINT CK_CustomerInteraction_Interaction_Duration_Minutes CHECK (Interaction_Duration_Minutes >= 0);
GO

IF OBJECT_ID(N'sales.CK_CustomerInteraction_Participants_Count') IS NULL
    ALTER TABLE sales.CustomerInteraction ADD CONSTRAINT CK_CustomerInteraction_Participants_Count CHECK (Participants_Count >= 0);
GO

IF OBJECT_ID(N'sales.CK_CustomerInteraction_Follow_Up_Date') IS NULL
    ALTER TABLE sales.CustomerInteraction ADD CONSTRAINT CK_CustomerInteraction_Follow_Up_Date CHECK (Follow_Up_Date IS NULL OR Follow_Up_Required = 1);
GO

IF OBJECT_ID(N'sales.CK_SalesOpportunity_Customer_ID_Lead_ID') IS NULL
    ALTER TABLE sales.SalesOpportunity ADD CONSTRAINT CK_SalesOpportunity_Customer_ID_Lead_ID CHECK (Customer_ID IS NOT NULL OR Lead_ID IS NOT NULL);
GO

IF OBJECT_ID(N'sales.CK_SalesOpportunity_Probability') IS NULL
    ALTER TABLE sales.SalesOpportunity ADD CONSTRAINT CK_SalesOpportunity_Probability CHECK (Probability BETWEEN 0 AND 100);
GO

IF OBJECT_ID(N'sales.CK_SalesOpportunity_Expected_Value') IS NULL
    ALTER TABLE sales.SalesOpportunity ADD CONSTRAINT CK_SalesOpportunity_Expected_Value CHECK (Expected_Value >= 0);
GO

IF OBJECT_ID(N'sales.CK_SalesOpportunity_Proposal_Valid_To') IS NULL
    ALTER TABLE sales.SalesOpportunity ADD CONSTRAINT CK_SalesOpportunity_Proposal_Valid_To CHECK (Proposal_Valid_To >= Proposal_Valid_From);
GO

IF OBJECT_ID(N'sales.CK_SalesOpportunity_Proposed_Price') IS NULL
    ALTER TABLE sales.SalesOpportunity ADD CONSTRAINT CK_SalesOpportunity_Proposed_Price CHECK (Proposed_Price >= 0);
GO

IF OBJECT_ID(N'sales.CK_SalesOpportunity_Proposal_Discount_Amount') IS NULL
    ALTER TABLE sales.SalesOpportunity ADD CONSTRAINT CK_SalesOpportunity_Proposal_Discount_Amount CHECK (Proposal_Discount_Amount >= 0);
GO

IF OBJECT_ID(N'sales.CK_Contract_End_Date') IS NULL
    ALTER TABLE sales.Contract ADD CONSTRAINT CK_Contract_End_Date CHECK (End_Date >= Start_Date);
GO

IF OBJECT_ID(N'sales.CK_Contract_Contract_Amount') IS NULL
    ALTER TABLE sales.Contract ADD CONSTRAINT CK_Contract_Contract_Amount CHECK (Contract_Amount >= 0);
GO

IF OBJECT_ID(N'sales.CK_Contract_Currency_Code') IS NULL
    ALTER TABLE sales.Contract ADD CONSTRAINT CK_Contract_Currency_Code CHECK (Currency_Code COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z][A-Z]');
GO

IF OBJECT_ID(N'sales.CK_SalesOrder_Total_Amount') IS NULL
    ALTER TABLE sales.SalesOrder ADD CONSTRAINT CK_SalesOrder_Total_Amount CHECK (Total_Amount >= 0);
GO

IF OBJECT_ID(N'sales.CK_SalesOrder_Discount_Amount') IS NULL
    ALTER TABLE sales.SalesOrder ADD CONSTRAINT CK_SalesOrder_Discount_Amount CHECK (Discount_Amount >= 0);
GO

IF OBJECT_ID(N'sales.CK_SalesOrderItem_Quantity') IS NULL
    ALTER TABLE sales.SalesOrderItem ADD CONSTRAINT CK_SalesOrderItem_Quantity CHECK (Quantity > 0);
GO

IF OBJECT_ID(N'sales.CK_SalesOrderItem_Unit_Price') IS NULL
    ALTER TABLE sales.SalesOrderItem ADD CONSTRAINT CK_SalesOrderItem_Unit_Price CHECK (Unit_Price >= 0);
GO

IF OBJECT_ID(N'sales.CK_SalesOrderItem_Discount_Amount') IS NULL
    ALTER TABLE sales.SalesOrderItem ADD CONSTRAINT CK_SalesOrderItem_Discount_Amount CHECK (Discount_Amount >= 0);
GO

IF OBJECT_ID(N'sales.CK_SalesOrderItem_Discount_Percentage') IS NULL
    ALTER TABLE sales.SalesOrderItem ADD CONSTRAINT CK_SalesOrderItem_Discount_Percentage CHECK (Discount_Percentage BETWEEN 0 AND 100);
GO

IF OBJECT_ID(N'sales.CK_Invoice_Due_Date') IS NULL
    ALTER TABLE sales.Invoice ADD CONSTRAINT CK_Invoice_Due_Date CHECK (Due_Date >= Invoice_Date);
GO

IF OBJECT_ID(N'sales.CK_Invoice_Subtotal') IS NULL
    ALTER TABLE sales.Invoice ADD CONSTRAINT CK_Invoice_Subtotal CHECK (Subtotal >= 0);
GO

IF OBJECT_ID(N'sales.CK_Invoice_Discount_Amount') IS NULL
    ALTER TABLE sales.Invoice ADD CONSTRAINT CK_Invoice_Discount_Amount CHECK (Discount_Amount >= 0);
GO

IF OBJECT_ID(N'sales.CK_Invoice_Tax_Amount') IS NULL
    ALTER TABLE sales.Invoice ADD CONSTRAINT CK_Invoice_Tax_Amount CHECK (Tax_Amount >= 0);
GO

IF OBJECT_ID(N'sales.CK_Invoice_Total_Amount') IS NULL
    ALTER TABLE sales.Invoice ADD CONSTRAINT CK_Invoice_Total_Amount CHECK (Total_Amount = Subtotal - ISNULL(Discount_Amount, 0) + ISNULL(Tax_Amount, 0));
GO

IF OBJECT_ID(N'sales.CK_InvoiceItem_Quantity') IS NULL
    ALTER TABLE sales.InvoiceItem ADD CONSTRAINT CK_InvoiceItem_Quantity CHECK (Quantity > 0);
GO

IF OBJECT_ID(N'sales.CK_InvoiceItem_Unit_Price') IS NULL
    ALTER TABLE sales.InvoiceItem ADD CONSTRAINT CK_InvoiceItem_Unit_Price CHECK (Unit_Price >= 0);
GO

IF OBJECT_ID(N'sales.CK_InvoiceItem_Discount_Amount') IS NULL
    ALTER TABLE sales.InvoiceItem ADD CONSTRAINT CK_InvoiceItem_Discount_Amount CHECK (Discount_Amount >= 0);
GO

IF OBJECT_ID(N'sales.CK_InvoiceItem_Tax_Amount') IS NULL
    ALTER TABLE sales.InvoiceItem ADD CONSTRAINT CK_InvoiceItem_Tax_Amount CHECK (Tax_Amount >= 0);
GO

IF OBJECT_ID(N'sales.CK_InvoiceItem_Final_Amount') IS NULL
    ALTER TABLE sales.InvoiceItem ADD CONSTRAINT CK_InvoiceItem_Final_Amount CHECK (Final_Amount = Net_Amount + ISNULL(Tax_Amount, 0));
GO

IF OBJECT_ID(N'sales.CK_Payment_Invoice_ID_Sales_Order_ID') IS NULL
    ALTER TABLE sales.Payment ADD CONSTRAINT CK_Payment_Invoice_ID_Sales_Order_ID CHECK (Invoice_ID IS NOT NULL OR Sales_Order_ID IS NOT NULL);
GO

IF OBJECT_ID(N'sales.CK_Payment_Amount') IS NULL
    ALTER TABLE sales.Payment ADD CONSTRAINT CK_Payment_Amount CHECK (Amount > 0);
GO

IF OBJECT_ID(N'sales.CK_ReturnRequest_Requested_Quantity') IS NULL
    ALTER TABLE sales.ReturnRequest ADD CONSTRAINT CK_ReturnRequest_Requested_Quantity CHECK (Requested_Quantity > 0);
GO

-- Review correction 2: Approved_Quantity is NULL (request still pending) or between 0 and Requested_Quantity.
-- An older version of this CHECK (only Approved_Quantity <= Requested_Quantity, no lower bound) is dropped and re-created, so a re-run also fixes databases created earlier.
IF OBJECT_ID(N'sales.CK_ReturnRequest_Approved_Quantity') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.check_constraints
                   WHERE object_id = OBJECT_ID(N'sales.CK_ReturnRequest_Approved_Quantity') AND definition LIKE N'%>=%')
    ALTER TABLE sales.ReturnRequest DROP CONSTRAINT CK_ReturnRequest_Approved_Quantity;
GO

IF OBJECT_ID(N'sales.CK_ReturnRequest_Approved_Quantity') IS NULL
    ALTER TABLE sales.ReturnRequest ADD CONSTRAINT CK_ReturnRequest_Approved_Quantity
        CHECK (Approved_Quantity IS NULL OR (Approved_Quantity >= 0 AND Approved_Quantity <= Requested_Quantity));
GO

IF OBJECT_ID(N'sales.CK_ReturnRequest_Return_Shipping_Cost') IS NULL
    ALTER TABLE sales.ReturnRequest ADD CONSTRAINT CK_ReturnRequest_Return_Shipping_Cost CHECK (Return_Shipping_Cost >= 0);
GO

IF OBJECT_ID(N'sales.CK_ReturnRequest_Refund_Amount') IS NULL
    ALTER TABLE sales.ReturnRequest ADD CONSTRAINT CK_ReturnRequest_Refund_Amount CHECK (Refund_Amount >= 0);
GO

IF OBJECT_ID(N'sales.CK_CustomerFeedback_Resolution_Date') IS NULL
    ALTER TABLE sales.CustomerFeedback ADD CONSTRAINT CK_CustomerFeedback_Resolution_Date CHECK (Resolution_Date >= Feedback_Date);
GO

IF OBJECT_ID(N'sales.CK_Commission_Commission_Base_Amount') IS NULL
    ALTER TABLE sales.Commission ADD CONSTRAINT CK_Commission_Commission_Base_Amount CHECK (Commission_Base_Amount >= 0);
GO

IF OBJECT_ID(N'sales.CK_Commission_Commission_Rate') IS NULL
    ALTER TABLE sales.Commission ADD CONSTRAINT CK_Commission_Commission_Rate CHECK (Commission_Rate BETWEEN 0 AND 100);
GO

IF OBJECT_ID(N'sales.CK_SalesTarget_Target_Level') IS NULL
    ALTER TABLE sales.SalesTarget ADD CONSTRAINT CK_SalesTarget_Target_Level CHECK (Target_Level IN (N'Annual', N'Region', N'Team', N'Salesperson', N'Channel', N'Product'));
GO

-- ماتریس الزام FK بُعدی بر اساس Target_Level (OI-15): در هر سطح (جز Annual) دقیقاً یک FK بُعدی پر است
IF OBJECT_ID(N'sales.CK_SalesTarget_Target_Level_Dimensions') IS NULL
    ALTER TABLE sales.SalesTarget ADD CONSTRAINT CK_SalesTarget_Target_Level_Dimensions CHECK
    (
        (Target_Level = N'Annual' AND Sales_Region_ID IS NULL AND Salesperson_ID IS NULL AND Sales_Channel_ID IS NULL AND Product_ID IS NULL)
        OR (Target_Level IN (N'Region', N'Team') AND Sales_Region_ID IS NOT NULL AND Salesperson_ID IS NULL AND Sales_Channel_ID IS NULL AND Product_ID IS NULL)
        OR (Target_Level = N'Salesperson' AND Sales_Region_ID IS NULL AND Salesperson_ID IS NOT NULL AND Sales_Channel_ID IS NULL AND Product_ID IS NULL)
        OR (Target_Level = N'Channel' AND Sales_Region_ID IS NULL AND Salesperson_ID IS NULL AND Sales_Channel_ID IS NOT NULL AND Product_ID IS NULL)
        OR (Target_Level = N'Product' AND Sales_Region_ID IS NULL AND Salesperson_ID IS NULL AND Sales_Channel_ID IS NULL AND Product_ID IS NOT NULL)
    );
GO

IF OBJECT_ID(N'sales.CK_SalesTarget_Target_Value_Target_Quantity') IS NULL
    ALTER TABLE sales.SalesTarget ADD CONSTRAINT CK_SalesTarget_Target_Value_Target_Quantity CHECK (Target_Value IS NOT NULL OR Target_Quantity IS NOT NULL);
GO

IF OBJECT_ID(N'sales.CK_SalesTarget_Target_Value') IS NULL
    ALTER TABLE sales.SalesTarget ADD CONSTRAINT CK_SalesTarget_Target_Value CHECK (Target_Value >= 0);
GO

IF OBJECT_ID(N'sales.CK_SalesTarget_Target_Quantity') IS NULL
    ALTER TABLE sales.SalesTarget ADD CONSTRAINT CK_SalesTarget_Target_Quantity CHECK (Target_Quantity >= 0);
GO

IF OBJECT_ID(N'sales.CK_SalesTarget_Target_Version') IS NULL
    ALTER TABLE sales.SalesTarget ADD CONSTRAINT CK_SalesTarget_Target_Version CHECK (Target_Version >= 1);
GO

IF OBJECT_ID(N'sales.CK_SalesTarget_Currency_Code') IS NULL
    ALTER TABLE sales.SalesTarget ADD CONSTRAINT CK_SalesTarget_Currency_Code CHECK (Currency_Code COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z][A-Z]');
GO

IF OBJECT_ID(N'sales.CK_SalesForecast_Forecast_Amount') IS NULL
    ALTER TABLE sales.SalesForecast ADD CONSTRAINT CK_SalesForecast_Forecast_Amount CHECK (Forecast_Amount >= 0);
GO

IF OBJECT_ID(N'sales.CK_SalesForecast_Forecast_Version') IS NULL
    ALTER TABLE sales.SalesForecast ADD CONSTRAINT CK_SalesForecast_Forecast_Version CHECK (Forecast_Version >= 1);
GO

IF OBJECT_ID(N'sales.CK_SalesForecast_Forecast_Accuracy_Percent') IS NULL
    ALTER TABLE sales.SalesForecast ADD CONSTRAINT CK_SalesForecast_Forecast_Accuracy_Percent CHECK (Forecast_Accuracy_Percent BETWEEN 0 AND 100);
GO

/* ========================================================================
   3. DEFAULT constraints
   ======================================================================== */

-- نسخه اولیه هدف = ۱ (مدل منطقی: عدد صحیح ≥ ۱)
IF OBJECT_ID(N'sales.DF_SalesTarget_Target_Version') IS NULL
    ALTER TABLE sales.SalesTarget ADD CONSTRAINT DF_SalesTarget_Target_Version DEFAULT (1) FOR Target_Version;
GO

-- ۱ = پیش‌بینی اولیه (مدل منطقی)
IF OBJECT_ID(N'sales.DF_SalesForecast_Forecast_Version') IS NULL
    ALTER TABLE sales.SalesForecast ADD CONSTRAINT DF_SalesForecast_Forecast_Version DEFAULT (1) FOR Forecast_Version;
GO

/* ========================================================================
   4. FOREIGN KEY constraints between Team 1 tables
      (ON DELETE / ON UPDATE NO ACTION: no cascading deletes of business history)
   ======================================================================== */

-- Province -> City  (Province_ID)
IF OBJECT_ID(N'ref.FK_City_Province_Province_ID') IS NULL
    ALTER TABLE ref.City ADD CONSTRAINT FK_City_Province_Province_ID
        FOREIGN KEY (Province_ID) REFERENCES ref.Province (Province_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- City -> City  (Parent_City_ID, optional)
IF OBJECT_ID(N'ref.FK_City_City_Parent_City_ID') IS NULL
    ALTER TABLE ref.City ADD CONSTRAINT FK_City_City_Parent_City_ID
        FOREIGN KEY (Parent_City_ID) REFERENCES ref.City (City_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Sales Region -> Sales Region  (Parent_Sales_Region_ID, optional)
IF OBJECT_ID(N'ref.FK_SalesRegion_SalesRegion_Parent_Sales_Region_ID') IS NULL
    ALTER TABLE ref.SalesRegion ADD CONSTRAINT FK_SalesRegion_SalesRegion_Parent_Sales_Region_ID
        FOREIGN KEY (Parent_Sales_Region_ID) REFERENCES ref.SalesRegion (Sales_Region_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Sales Region -> Branch  (Sales_Region_ID)
IF OBJECT_ID(N'core.FK_Branch_SalesRegion_Sales_Region_ID') IS NULL
    ALTER TABLE core.Branch ADD CONSTRAINT FK_Branch_SalesRegion_Sales_Region_ID
        FOREIGN KEY (Sales_Region_ID) REFERENCES ref.SalesRegion (Sales_Region_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Branch -> Salesperson  (Branch_ID, optional)
IF OBJECT_ID(N'core.FK_Salesperson_Branch_Branch_ID') IS NULL
    ALTER TABLE core.Salesperson ADD CONSTRAINT FK_Salesperson_Branch_Branch_ID
        FOREIGN KEY (Branch_ID) REFERENCES core.Branch (Branch_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Salesperson -> Salesperson  (Manager_Salesperson_ID, optional)
IF OBJECT_ID(N'core.FK_Salesperson_Salesperson_Manager_Salesperson_ID') IS NULL
    ALTER TABLE core.Salesperson ADD CONSTRAINT FK_Salesperson_Salesperson_Manager_Salesperson_ID
        FOREIGN KEY (Manager_Salesperson_ID) REFERENCES core.Salesperson (Salesperson_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- City -> Customer  (City_ID, optional)
IF OBJECT_ID(N'core.FK_Customer_City_City_ID') IS NULL
    ALTER TABLE core.Customer ADD CONSTRAINT FK_Customer_City_City_ID
        FOREIGN KEY (City_ID) REFERENCES ref.City (City_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Customer Segment -> Customer  (Customer_Segment_ID, optional)
IF OBJECT_ID(N'core.FK_Customer_CustomerSegment_Customer_Segment_ID') IS NULL
    ALTER TABLE core.Customer ADD CONSTRAINT FK_Customer_CustomerSegment_Customer_Segment_ID
        FOREIGN KEY (Customer_Segment_ID) REFERENCES ref.CustomerSegment (Customer_Segment_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Sales Channel -> Customer  (Sales_Channel_ID, optional)
IF OBJECT_ID(N'core.FK_Customer_SalesChannel_Sales_Channel_ID') IS NULL
    ALTER TABLE core.Customer ADD CONSTRAINT FK_Customer_SalesChannel_Sales_Channel_ID
        FOREIGN KEY (Sales_Channel_ID) REFERENCES ref.SalesChannel (Sales_Channel_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Sales Territory -> Customer  (Sales_Territory_ID, optional)
IF OBJECT_ID(N'core.FK_Customer_SalesTerritory_Sales_Territory_ID') IS NULL
    ALTER TABLE core.Customer ADD CONSTRAINT FK_Customer_SalesTerritory_Sales_Territory_ID
        FOREIGN KEY (Sales_Territory_ID) REFERENCES ref.SalesTerritory (Sales_Territory_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Salesperson -> Customer  (Salesperson_ID, optional)
IF OBJECT_ID(N'core.FK_Customer_Salesperson_Salesperson_ID') IS NULL
    ALTER TABLE core.Customer ADD CONSTRAINT FK_Customer_Salesperson_Salesperson_ID
        FOREIGN KEY (Salesperson_ID) REFERENCES core.Salesperson (Salesperson_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Salesperson -> Lead  (Salesperson_ID, optional)
IF OBJECT_ID(N'sales.FK_Lead_Salesperson_Salesperson_ID') IS NULL
    ALTER TABLE sales.Lead ADD CONSTRAINT FK_Lead_Salesperson_Salesperson_ID
        FOREIGN KEY (Salesperson_ID) REFERENCES core.Salesperson (Salesperson_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Customer -> Customer Interaction  (Customer_ID)
IF OBJECT_ID(N'sales.FK_CustomerInteraction_Customer_Customer_ID') IS NULL
    ALTER TABLE sales.CustomerInteraction ADD CONSTRAINT FK_CustomerInteraction_Customer_Customer_ID
        FOREIGN KEY (Customer_ID) REFERENCES core.Customer (Customer_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Salesperson -> Customer Interaction  (Salesperson_ID, optional)
IF OBJECT_ID(N'sales.FK_CustomerInteraction_Salesperson_Salesperson_ID') IS NULL
    ALTER TABLE sales.CustomerInteraction ADD CONSTRAINT FK_CustomerInteraction_Salesperson_Salesperson_ID
        FOREIGN KEY (Salesperson_ID) REFERENCES core.Salesperson (Salesperson_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Sales Territory -> Customer Interaction  (Sales_Territory_ID, optional)
IF OBJECT_ID(N'sales.FK_CustomerInteraction_SalesTerritory_Sales_Territory_ID') IS NULL
    ALTER TABLE sales.CustomerInteraction ADD CONSTRAINT FK_CustomerInteraction_SalesTerritory_Sales_Territory_ID
        FOREIGN KEY (Sales_Territory_ID) REFERENCES ref.SalesTerritory (Sales_Territory_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Customer -> Sales Opportunity  (Customer_ID, optional)
IF OBJECT_ID(N'sales.FK_SalesOpportunity_Customer_Customer_ID') IS NULL
    ALTER TABLE sales.SalesOpportunity ADD CONSTRAINT FK_SalesOpportunity_Customer_Customer_ID
        FOREIGN KEY (Customer_ID) REFERENCES core.Customer (Customer_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Lead -> Sales Opportunity  (Lead_ID, optional)
IF OBJECT_ID(N'sales.FK_SalesOpportunity_Lead_Lead_ID') IS NULL
    ALTER TABLE sales.SalesOpportunity ADD CONSTRAINT FK_SalesOpportunity_Lead_Lead_ID
        FOREIGN KEY (Lead_ID) REFERENCES sales.Lead (Lead_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Salesperson -> Sales Opportunity  (Salesperson_ID)
IF OBJECT_ID(N'sales.FK_SalesOpportunity_Salesperson_Salesperson_ID') IS NULL
    ALTER TABLE sales.SalesOpportunity ADD CONSTRAINT FK_SalesOpportunity_Salesperson_Salesperson_ID
        FOREIGN KEY (Salesperson_ID) REFERENCES core.Salesperson (Salesperson_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Customer -> Contract  (Customer_ID)
IF OBJECT_ID(N'sales.FK_Contract_Customer_Customer_ID') IS NULL
    ALTER TABLE sales.Contract ADD CONSTRAINT FK_Contract_Customer_Customer_ID
        FOREIGN KEY (Customer_ID) REFERENCES core.Customer (Customer_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Sales Opportunity -> Contract  (Sales_Opportunity_ID, optional)
IF OBJECT_ID(N'sales.FK_Contract_SalesOpportunity_Sales_Opportunity_ID') IS NULL
    ALTER TABLE sales.Contract ADD CONSTRAINT FK_Contract_SalesOpportunity_Sales_Opportunity_ID
        FOREIGN KEY (Sales_Opportunity_ID) REFERENCES sales.SalesOpportunity (Sales_Opportunity_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Customer -> Sales Order  (Customer_ID)
IF OBJECT_ID(N'sales.FK_SalesOrder_Customer_Customer_ID') IS NULL
    ALTER TABLE sales.SalesOrder ADD CONSTRAINT FK_SalesOrder_Customer_Customer_ID
        FOREIGN KEY (Customer_ID) REFERENCES core.Customer (Customer_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Salesperson -> Sales Order  (Salesperson_ID, optional)
IF OBJECT_ID(N'sales.FK_SalesOrder_Salesperson_Salesperson_ID') IS NULL
    ALTER TABLE sales.SalesOrder ADD CONSTRAINT FK_SalesOrder_Salesperson_Salesperson_ID
        FOREIGN KEY (Salesperson_ID) REFERENCES core.Salesperson (Salesperson_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Sales Channel -> Sales Order  (Sales_Channel_ID)
IF OBJECT_ID(N'sales.FK_SalesOrder_SalesChannel_Sales_Channel_ID') IS NULL
    ALTER TABLE sales.SalesOrder ADD CONSTRAINT FK_SalesOrder_SalesChannel_Sales_Channel_ID
        FOREIGN KEY (Sales_Channel_ID) REFERENCES ref.SalesChannel (Sales_Channel_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Sales Region -> Sales Order  (Sales_Region_ID, optional)
IF OBJECT_ID(N'sales.FK_SalesOrder_SalesRegion_Sales_Region_ID') IS NULL
    ALTER TABLE sales.SalesOrder ADD CONSTRAINT FK_SalesOrder_SalesRegion_Sales_Region_ID
        FOREIGN KEY (Sales_Region_ID) REFERENCES ref.SalesRegion (Sales_Region_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Contract -> Sales Order  (Contract_ID, optional)
IF OBJECT_ID(N'sales.FK_SalesOrder_Contract_Contract_ID') IS NULL
    ALTER TABLE sales.SalesOrder ADD CONSTRAINT FK_SalesOrder_Contract_Contract_ID
        FOREIGN KEY (Contract_ID) REFERENCES sales.Contract (Contract_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Customer Interaction -> Sales Order  (Customer_Interaction_ID, optional)
IF OBJECT_ID(N'sales.FK_SalesOrder_CustomerInteraction_Customer_Interaction_ID') IS NULL
    ALTER TABLE sales.SalesOrder ADD CONSTRAINT FK_SalesOrder_CustomerInteraction_Customer_Interaction_ID
        FOREIGN KEY (Customer_Interaction_ID) REFERENCES sales.CustomerInteraction (Customer_Interaction_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Calendar -> Sales Order  (Calendar_ID)
IF OBJECT_ID(N'sales.FK_SalesOrder_Calendar_Calendar_ID') IS NULL
    ALTER TABLE sales.SalesOrder ADD CONSTRAINT FK_SalesOrder_Calendar_Calendar_ID
        FOREIGN KEY (Calendar_ID) REFERENCES core.Calendar (Calendar_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Sales Order -> Sales Order Item  (Sales_Order_ID)
IF OBJECT_ID(N'sales.FK_SalesOrderItem_SalesOrder_Sales_Order_ID') IS NULL
    ALTER TABLE sales.SalesOrderItem ADD CONSTRAINT FK_SalesOrderItem_SalesOrder_Sales_Order_ID
        FOREIGN KEY (Sales_Order_ID) REFERENCES sales.SalesOrder (Sales_Order_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Customer -> Invoice  (Customer_ID)
IF OBJECT_ID(N'sales.FK_Invoice_Customer_Customer_ID') IS NULL
    ALTER TABLE sales.Invoice ADD CONSTRAINT FK_Invoice_Customer_Customer_ID
        FOREIGN KEY (Customer_ID) REFERENCES core.Customer (Customer_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Sales Order -> Invoice  (Sales_Order_ID)
IF OBJECT_ID(N'sales.FK_Invoice_SalesOrder_Sales_Order_ID') IS NULL
    ALTER TABLE sales.Invoice ADD CONSTRAINT FK_Invoice_SalesOrder_Sales_Order_ID
        FOREIGN KEY (Sales_Order_ID) REFERENCES sales.SalesOrder (Sales_Order_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Invoice -> Invoice Item  (Invoice_ID)
IF OBJECT_ID(N'sales.FK_InvoiceItem_Invoice_Invoice_ID') IS NULL
    ALTER TABLE sales.InvoiceItem ADD CONSTRAINT FK_InvoiceItem_Invoice_Invoice_ID
        FOREIGN KEY (Invoice_ID) REFERENCES sales.Invoice (Invoice_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Customer -> Payment  (Customer_ID)
IF OBJECT_ID(N'sales.FK_Payment_Customer_Customer_ID') IS NULL
    ALTER TABLE sales.Payment ADD CONSTRAINT FK_Payment_Customer_Customer_ID
        FOREIGN KEY (Customer_ID) REFERENCES core.Customer (Customer_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Invoice -> Payment  (Invoice_ID, optional)
IF OBJECT_ID(N'sales.FK_Payment_Invoice_Invoice_ID') IS NULL
    ALTER TABLE sales.Payment ADD CONSTRAINT FK_Payment_Invoice_Invoice_ID
        FOREIGN KEY (Invoice_ID) REFERENCES sales.Invoice (Invoice_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Sales Order -> Payment  (Sales_Order_ID, optional)
IF OBJECT_ID(N'sales.FK_Payment_SalesOrder_Sales_Order_ID') IS NULL
    ALTER TABLE sales.Payment ADD CONSTRAINT FK_Payment_SalesOrder_Sales_Order_ID
        FOREIGN KEY (Sales_Order_ID) REFERENCES sales.SalesOrder (Sales_Order_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Sales Order Item -> Return Request  (Sales_Order_Item_ID)
IF OBJECT_ID(N'sales.FK_ReturnRequest_SalesOrderItem_Sales_Order_Item_ID') IS NULL
    ALTER TABLE sales.ReturnRequest ADD CONSTRAINT FK_ReturnRequest_SalesOrderItem_Sales_Order_Item_ID
        FOREIGN KEY (Sales_Order_Item_ID) REFERENCES sales.SalesOrderItem (Sales_Order_Item_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Payment -> Return Request  (Payment_ID, optional)
IF OBJECT_ID(N'sales.FK_ReturnRequest_Payment_Payment_ID') IS NULL
    ALTER TABLE sales.ReturnRequest ADD CONSTRAINT FK_ReturnRequest_Payment_Payment_ID
        FOREIGN KEY (Payment_ID) REFERENCES sales.Payment (Payment_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Calendar -> Return Request  (Calendar_ID)
IF OBJECT_ID(N'sales.FK_ReturnRequest_Calendar_Calendar_ID') IS NULL
    ALTER TABLE sales.ReturnRequest ADD CONSTRAINT FK_ReturnRequest_Calendar_Calendar_ID
        FOREIGN KEY (Calendar_ID) REFERENCES core.Calendar (Calendar_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Customer -> Customer Feedback  (Customer_ID)
IF OBJECT_ID(N'sales.FK_CustomerFeedback_Customer_Customer_ID') IS NULL
    ALTER TABLE sales.CustomerFeedback ADD CONSTRAINT FK_CustomerFeedback_Customer_Customer_ID
        FOREIGN KEY (Customer_ID) REFERENCES core.Customer (Customer_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Customer Interaction -> Customer Feedback  (Customer_Interaction_ID, optional)
IF OBJECT_ID(N'sales.FK_CustomerFeedback_CustomerInteraction_Customer_Interaction_ID') IS NULL
    ALTER TABLE sales.CustomerFeedback ADD CONSTRAINT FK_CustomerFeedback_CustomerInteraction_Customer_Interaction_ID
        FOREIGN KEY (Customer_Interaction_ID) REFERENCES sales.CustomerInteraction (Customer_Interaction_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Sales Order -> Customer Feedback  (Sales_Order_ID, optional)
IF OBJECT_ID(N'sales.FK_CustomerFeedback_SalesOrder_Sales_Order_ID') IS NULL
    ALTER TABLE sales.CustomerFeedback ADD CONSTRAINT FK_CustomerFeedback_SalesOrder_Sales_Order_ID
        FOREIGN KEY (Sales_Order_ID) REFERENCES sales.SalesOrder (Sales_Order_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Salesperson -> Commission  (Salesperson_ID)
IF OBJECT_ID(N'sales.FK_Commission_Salesperson_Salesperson_ID') IS NULL
    ALTER TABLE sales.Commission ADD CONSTRAINT FK_Commission_Salesperson_Salesperson_ID
        FOREIGN KEY (Salesperson_ID) REFERENCES core.Salesperson (Salesperson_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Calendar -> Commission  (Calendar_ID)
IF OBJECT_ID(N'sales.FK_Commission_Calendar_Calendar_ID') IS NULL
    ALTER TABLE sales.Commission ADD CONSTRAINT FK_Commission_Calendar_Calendar_ID
        FOREIGN KEY (Calendar_ID) REFERENCES core.Calendar (Calendar_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Calendar -> Sales Target  (Calendar_ID)
IF OBJECT_ID(N'sales.FK_SalesTarget_Calendar_Calendar_ID') IS NULL
    ALTER TABLE sales.SalesTarget ADD CONSTRAINT FK_SalesTarget_Calendar_Calendar_ID
        FOREIGN KEY (Calendar_ID) REFERENCES core.Calendar (Calendar_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Sales Region -> Sales Target  (Sales_Region_ID, optional)
IF OBJECT_ID(N'sales.FK_SalesTarget_SalesRegion_Sales_Region_ID') IS NULL
    ALTER TABLE sales.SalesTarget ADD CONSTRAINT FK_SalesTarget_SalesRegion_Sales_Region_ID
        FOREIGN KEY (Sales_Region_ID) REFERENCES ref.SalesRegion (Sales_Region_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Salesperson -> Sales Target  (Salesperson_ID, optional)
IF OBJECT_ID(N'sales.FK_SalesTarget_Salesperson_Salesperson_ID') IS NULL
    ALTER TABLE sales.SalesTarget ADD CONSTRAINT FK_SalesTarget_Salesperson_Salesperson_ID
        FOREIGN KEY (Salesperson_ID) REFERENCES core.Salesperson (Salesperson_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Sales Channel -> Sales Target  (Sales_Channel_ID, optional)
IF OBJECT_ID(N'sales.FK_SalesTarget_SalesChannel_Sales_Channel_ID') IS NULL
    ALTER TABLE sales.SalesTarget ADD CONSTRAINT FK_SalesTarget_SalesChannel_Sales_Channel_ID
        FOREIGN KEY (Sales_Channel_ID) REFERENCES ref.SalesChannel (Sales_Channel_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Calendar -> Sales Forecast  (Calendar_ID)
IF OBJECT_ID(N'sales.FK_SalesForecast_Calendar_Calendar_ID') IS NULL
    ALTER TABLE sales.SalesForecast ADD CONSTRAINT FK_SalesForecast_Calendar_Calendar_ID
        FOREIGN KEY (Calendar_ID) REFERENCES core.Calendar (Calendar_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

/* ========================================================================
   5. Composite FOREIGN KEYs for the consistency rules CE-01..CE-03 of Stage 6
      (same Customer_ID on the child row and on the related order / invoice / interaction)
      and review correction 1 (the invoice of a payment belongs to the order of the same payment).
      If the optional column of the pair is NULL, SQL Server skips the check - exactly the wanted behaviour.
   ======================================================================== */

-- CE-01: مشتری فاکتور = مشتری سفارش مبنا
IF OBJECT_ID(N'sales.FK_Invoice_SalesOrder_Sales_Order_ID_Customer_ID') IS NULL
    ALTER TABLE sales.Invoice ADD CONSTRAINT FK_Invoice_SalesOrder_Sales_Order_ID_Customer_ID
        FOREIGN KEY (Sales_Order_ID, Customer_ID) REFERENCES sales.SalesOrder (Sales_Order_ID, Customer_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- CE-02: مشتری پرداخت = مشتری فاکتور (وقتی Invoice_ID پر است)
IF OBJECT_ID(N'sales.FK_Payment_Invoice_Invoice_ID_Customer_ID') IS NULL
    ALTER TABLE sales.Payment ADD CONSTRAINT FK_Payment_Invoice_Invoice_ID_Customer_ID
        FOREIGN KEY (Invoice_ID, Customer_ID) REFERENCES sales.Invoice (Invoice_ID, Customer_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- CE-02: مشتری پرداخت = مشتری سفارش (وقتی Sales_Order_ID پر است)
IF OBJECT_ID(N'sales.FK_Payment_SalesOrder_Sales_Order_ID_Customer_ID') IS NULL
    ALTER TABLE sales.Payment ADD CONSTRAINT FK_Payment_SalesOrder_Sales_Order_ID_Customer_ID
        FOREIGN KEY (Sales_Order_ID, Customer_ID) REFERENCES sales.SalesOrder (Sales_Order_ID, Customer_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- Review correction 1: فاکتور و سفارش یک پرداخت باید به هم تعلق داشته باشند (وقتی هر دو Invoice_ID و Sales_Order_ID پر هستند؛ اگر یکی NULL باشد کنترل نمی‌شود)
IF OBJECT_ID(N'sales.FK_Payment_Invoice_Invoice_ID_Sales_Order_ID') IS NULL
    ALTER TABLE sales.Payment ADD CONSTRAINT FK_Payment_Invoice_Invoice_ID_Sales_Order_ID
        FOREIGN KEY (Invoice_ID, Sales_Order_ID) REFERENCES sales.Invoice (Invoice_ID, Sales_Order_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- CE-03: مشتری بازخورد = مشتری سفارش مرتبط
IF OBJECT_ID(N'sales.FK_CustomerFeedback_SalesOrder_Sales_Order_ID_Customer_ID') IS NULL
    ALTER TABLE sales.CustomerFeedback ADD CONSTRAINT FK_CustomerFeedback_SalesOrder_Sales_Order_ID_Customer_ID
        FOREIGN KEY (Sales_Order_ID, Customer_ID) REFERENCES sales.SalesOrder (Sales_Order_ID, Customer_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

-- CE-03: مشتری بازخورد = مشتری تعامل مرتبط
IF OBJECT_ID(N'sales.FK_CustomerFeedback_CustomerInteraction_Customer_Interaction_ID_Customer_ID') IS NULL
    ALTER TABLE sales.CustomerFeedback ADD CONSTRAINT FK_CustomerFeedback_CustomerInteraction_Customer_Interaction_ID_Customer_ID
        FOREIGN KEY (Customer_Interaction_ID, Customer_ID) REFERENCES sales.CustomerInteraction (Customer_Interaction_ID, Customer_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
GO

/* ========================================================================
   6. FOREIGN KEYs to Team 2 tables (core.Product, marketing.Promotion)
      Created only when the Team 2 table exists. Otherwise a WARNING is printed and nothing is created:
      run 07-Team2-03-Create-Tables.sql and then run this file again.
   ======================================================================== */

-- Product (Team 2) -> Contract  (Product_ID, optional)
IF OBJECT_ID(N'sales.FK_Contract_Product_Product_ID') IS NULL
BEGIN
    IF OBJECT_ID(N'core.Product', N'U') IS NULL
        PRINT N'WARNING: core.Product does not exist yet - FK_Contract_Product_Product_ID was NOT created. Run 07-Team2-03-Create-Tables.sql, then run this file again.';
    ELSE
    BEGIN
        EXEC (N'ALTER TABLE sales.Contract ADD CONSTRAINT FK_Contract_Product_Product_ID FOREIGN KEY (Product_ID) REFERENCES core.Product (Product_ID) ON DELETE NO ACTION ON UPDATE NO ACTION;');
        PRINT N'Created FK_Contract_Product_Product_ID.';
    END
END
GO

-- Promotion (Team 2) -> Sales Order  (Promotion_ID, optional)
IF OBJECT_ID(N'sales.FK_SalesOrder_Promotion_Promotion_ID') IS NULL
BEGIN
    IF OBJECT_ID(N'marketing.Promotion', N'U') IS NULL
        PRINT N'WARNING: marketing.Promotion does not exist yet - FK_SalesOrder_Promotion_Promotion_ID was NOT created. Run 07-Team2-03-Create-Tables.sql, then run this file again.';
    ELSE
    BEGIN
        EXEC (N'ALTER TABLE sales.SalesOrder ADD CONSTRAINT FK_SalesOrder_Promotion_Promotion_ID FOREIGN KEY (Promotion_ID) REFERENCES marketing.Promotion (Promotion_ID) ON DELETE NO ACTION ON UPDATE NO ACTION;');
        PRINT N'Created FK_SalesOrder_Promotion_Promotion_ID.';
    END
END
GO

-- Product (Team 2) -> Sales Order Item  (Product_ID)
IF OBJECT_ID(N'sales.FK_SalesOrderItem_Product_Product_ID') IS NULL
BEGIN
    IF OBJECT_ID(N'core.Product', N'U') IS NULL
        PRINT N'WARNING: core.Product does not exist yet - FK_SalesOrderItem_Product_Product_ID was NOT created. Run 07-Team2-03-Create-Tables.sql, then run this file again.';
    ELSE
    BEGIN
        EXEC (N'ALTER TABLE sales.SalesOrderItem ADD CONSTRAINT FK_SalesOrderItem_Product_Product_ID FOREIGN KEY (Product_ID) REFERENCES core.Product (Product_ID) ON DELETE NO ACTION ON UPDATE NO ACTION;');
        PRINT N'Created FK_SalesOrderItem_Product_Product_ID.';
    END
END
GO

-- Product (Team 2) -> Invoice Item  (Product_ID)
IF OBJECT_ID(N'sales.FK_InvoiceItem_Product_Product_ID') IS NULL
BEGIN
    IF OBJECT_ID(N'core.Product', N'U') IS NULL
        PRINT N'WARNING: core.Product does not exist yet - FK_InvoiceItem_Product_Product_ID was NOT created. Run 07-Team2-03-Create-Tables.sql, then run this file again.';
    ELSE
    BEGIN
        EXEC (N'ALTER TABLE sales.InvoiceItem ADD CONSTRAINT FK_InvoiceItem_Product_Product_ID FOREIGN KEY (Product_ID) REFERENCES core.Product (Product_ID) ON DELETE NO ACTION ON UPDATE NO ACTION;');
        PRINT N'Created FK_InvoiceItem_Product_Product_ID.';
    END
END
GO

-- Product (Team 2) -> Customer Feedback  (Product_ID, optional)
IF OBJECT_ID(N'sales.FK_CustomerFeedback_Product_Product_ID') IS NULL
BEGIN
    IF OBJECT_ID(N'core.Product', N'U') IS NULL
        PRINT N'WARNING: core.Product does not exist yet - FK_CustomerFeedback_Product_Product_ID was NOT created. Run 07-Team2-03-Create-Tables.sql, then run this file again.';
    ELSE
    BEGIN
        EXEC (N'ALTER TABLE sales.CustomerFeedback ADD CONSTRAINT FK_CustomerFeedback_Product_Product_ID FOREIGN KEY (Product_ID) REFERENCES core.Product (Product_ID) ON DELETE NO ACTION ON UPDATE NO ACTION;');
        PRINT N'Created FK_CustomerFeedback_Product_Product_ID.';
    END
END
GO

-- Product (Team 2) -> Sales Target  (Product_ID, optional)
IF OBJECT_ID(N'sales.FK_SalesTarget_Product_Product_ID') IS NULL
BEGIN
    IF OBJECT_ID(N'core.Product', N'U') IS NULL
        PRINT N'WARNING: core.Product does not exist yet - FK_SalesTarget_Product_Product_ID was NOT created. Run 07-Team2-03-Create-Tables.sql, then run this file again.';
    ELSE
    BEGIN
        EXEC (N'ALTER TABLE sales.SalesTarget ADD CONSTRAINT FK_SalesTarget_Product_Product_ID FOREIGN KEY (Product_ID) REFERENCES core.Product (Product_ID) ON DELETE NO ACTION ON UPDATE NO ACTION;');
        PRINT N'Created FK_SalesTarget_Product_Product_ID.';
    END
END
GO

/* ---- Summary of Team 1 objects ---- */
DECLARE @t TABLE (object_id int PRIMARY KEY);
INSERT @t (object_id)
SELECT OBJECT_ID(n) FROM (VALUES (N'ref.Province'), (N'ref.City'), (N'ref.CustomerSegment'), (N'ref.SalesChannel'), (N'ref.SalesRegion'), (N'ref.SalesTerritory'), (N'core.Calendar'), (N'core.Branch'), (N'core.Salesperson'), (N'core.Customer'), (N'sales.Lead'), (N'sales.CustomerInteraction'), (N'sales.SalesOpportunity'), (N'sales.Contract'), (N'sales.SalesOrder'), (N'sales.SalesOrderItem'), (N'sales.Invoice'), (N'sales.InvoiceItem'), (N'sales.Payment'), (N'sales.ReturnRequest'), (N'sales.CustomerFeedback'), (N'sales.Commission'), (N'sales.SalesTarget'), (N'sales.SalesForecast')) v(n) WHERE OBJECT_ID(n) IS NOT NULL;
DECLARE @msg nvarchar(600) = CONCAT(
    N'Team 1 objects now in FoodDistributionDB: tables ', (SELECT COUNT(*) FROM @t),
    N', columns ', (SELECT COUNT(*) FROM sys.columns c JOIN @t t ON t.object_id = c.object_id),
    N', PK ', (SELECT COUNT(*) FROM sys.key_constraints k JOIN @t t ON t.object_id = k.parent_object_id WHERE k.type = 'PK'),
    N', UNIQUE ', (SELECT COUNT(*) FROM sys.key_constraints k JOIN @t t ON t.object_id = k.parent_object_id WHERE k.type = 'UQ')
                + (SELECT COUNT(*) FROM sys.indexes i JOIN @t t ON t.object_id = i.object_id WHERE i.is_unique = 1 AND i.has_filter = 1),
    N', CHECK ', (SELECT COUNT(*) FROM sys.check_constraints k JOIN @t t ON t.object_id = k.parent_object_id),
    N', DEFAULT ', (SELECT COUNT(*) FROM sys.default_constraints k JOIN @t t ON t.object_id = k.parent_object_id),
    N', FK ', (SELECT COUNT(*) FROM sys.foreign_keys k JOIN @t t ON t.object_id = k.parent_object_id),
    N', indexes ', (SELECT COUNT(*) FROM sys.indexes i JOIN @t t ON t.object_id = i.object_id WHERE i.type = 2 AND i.is_unique = 0),
    N'.');
PRINT @msg;
GO

SET NOEXEC OFF;
GO
PRINT N'07-Team1-02-Create-Constraints.sql finished.';
GO


/*---------------- SOURCE FILE: 07-Team2-04-Create-Constraints.sql ----------------*/
/*
    Project : Food Distribution (Etemad Iranian Food Distribution)
    Stage   : 7 - Physical Data Model
    Team    : Team 2 - Product & Marketing
    Database: FoodDistributionDB
    SQL Server: 2022
    Version : 1.1 (2026-10-28)
    File    : 07-Team2-04-Create-Constraints.sql
    Purpose : UNIQUE, CHECK and DEFAULT constraints, FOREIGN KEYs and the two integrity triggers for multi-row rules.
    Run order: 4 (after 07-Team2-03-Create-Tables.sql)
    Prerequisites: All 24 Team 2 tables exist (07-Team2-03-Create-Tables.sql).
    Source  : 06-Team2-Product-Marketing-Logical-Data-Model.xlsx (Stage 6, #175)
    Schemas : Team 2 proposal for #183 (ref / core / marketing); not yet approved
    Re-run  : Safe. A constraint is created if missing. If one exists with the same name but a different definition
              (columns, expression, referenced table), it is dropped and recreated. Disabled or untrusted constraints
              are re-enabled WITH CHECK. Triggers use CREATE OR ALTER.
              The verification at the end compares the whole structure with the expected definition.
*/

USE [FoodDistributionDB];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

/* ---- Prerequisite check: stop the whole script if a prerequisite is missing ---- */
IF OBJECT_ID(N'ref.ProductCategory', N'U') IS NULL
   OR OBJECT_ID(N'ref.Package', N'U') IS NULL
   OR OBJECT_ID(N'core.Brand', N'U') IS NULL
   OR OBJECT_ID(N'core.Product', N'U') IS NULL
   OR OBJECT_ID(N'core.SKU', N'U') IS NULL
   OR OBJECT_ID(N'marketing.ProductPrice', N'U') IS NULL
   OR OBJECT_ID(N'marketing.CampaignChannel', N'U') IS NULL
   OR OBJECT_ID(N'marketing.CampaignAudience', N'U') IS NULL
   OR OBJECT_ID(N'marketing.MarketingCampaign', N'U') IS NULL
   OR OBJECT_ID(N'marketing.MarketingCampaignChannel', N'U') IS NULL
   OR OBJECT_ID(N'marketing.MarketingCampaignAudience', N'U') IS NULL
   OR OBJECT_ID(N'marketing.CampaignBudget', N'U') IS NULL
   OR OBJECT_ID(N'marketing.CampaignCost', N'U') IS NULL
   OR OBJECT_ID(N'marketing.CampaignResult', N'U') IS NULL
   OR OBJECT_ID(N'marketing.Promotion', N'U') IS NULL
   OR OBJECT_ID(N'marketing.BrandActivity', N'U') IS NULL
   OR OBJECT_ID(N'marketing.Market', N'U') IS NULL
   OR OBJECT_ID(N'marketing.MarketSegment', N'U') IS NULL
   OR OBJECT_ID(N'marketing.MarketResearch', N'U') IS NULL
   OR OBJECT_ID(N'marketing.MarketSurvey', N'U') IS NULL
   OR OBJECT_ID(N'marketing.ResearchResult', N'U') IS NULL
   OR OBJECT_ID(N'marketing.Competitor', N'U') IS NULL
   OR OBJECT_ID(N'marketing.CompetitorProduct', N'U') IS NULL
   OR OBJECT_ID(N'marketing.MarketPrice', N'U') IS NULL
BEGIN
    RAISERROR(N'Team 2 tables are missing. Run 07-Team2-03-Create-Tables.sql first.', 16, 1);
    SET NOEXEC ON;
END;
GO

/* ========================================================================
   1. UNIQUE constraints (business keys)
   ======================================================================== */

DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'ref.ProductCategory') AND i.name = N'UQ_ProductCategory_Category_Code'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|UNIQUE|Category_Code||' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE ref.ProductCategory DROP CONSTRAINT UQ_ProductCategory_Category_Code;
    PRINT N'UQ_ProductCategory_Category_Code: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE ref.ProductCategory ADD CONSTRAINT UQ_ProductCategory_Category_Code UNIQUE (Category_Code);
    PRINT N'Created UQ_ProductCategory_Category_Code.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'ref.Package') AND i.name = N'UQ_Package_Package_Code'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|UNIQUE|Package_Code||' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE ref.Package DROP CONSTRAINT UQ_Package_Package_Code;
    PRINT N'UQ_Package_Package_Code: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE ref.Package ADD CONSTRAINT UQ_Package_Package_Code UNIQUE (Package_Code);
    PRINT N'Created UQ_Package_Package_Code.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'core.Brand') AND i.name = N'UQ_Brand_Brand_Code'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|UNIQUE|Brand_Code||' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE core.Brand DROP CONSTRAINT UQ_Brand_Brand_Code;
    PRINT N'UQ_Brand_Brand_Code: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE core.Brand ADD CONSTRAINT UQ_Brand_Brand_Code UNIQUE (Brand_Code);
    PRINT N'Created UQ_Brand_Brand_Code.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'core.Product') AND i.name = N'UQ_Product_Product_Code'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|UNIQUE|Product_Code||' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE core.Product DROP CONSTRAINT UQ_Product_Product_Code;
    PRINT N'UQ_Product_Product_Code: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE core.Product ADD CONSTRAINT UQ_Product_Product_Code UNIQUE (Product_Code);
    PRINT N'Created UQ_Product_Product_Code.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'core.SKU') AND i.name = N'UQ_SKU_SKU_Code'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|UNIQUE|SKU_Code||' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE core.SKU DROP CONSTRAINT UQ_SKU_SKU_Code;
    PRINT N'UQ_SKU_SKU_Code: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE core.SKU ADD CONSTRAINT UQ_SKU_SKU_Code UNIQUE (SKU_Code);
    PRINT N'Created UQ_SKU_SKU_Code.';
END;
GO

-- Barcode is optional but must be unique when filled: filtered unique index (a UNIQUE constraint would allow only one NULL).
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'core.SKU') AND i.name = N'UQ_SKU_Barcode'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|UNIQUE|Barcode||([Barcode] IS NOT NULL)' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX UQ_SKU_Barcode ON core.SKU;
    PRINT N'UQ_SKU_Barcode: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_SKU_Barcode ON core.SKU (Barcode) WHERE Barcode IS NOT NULL;
    PRINT N'Created UQ_SKU_Barcode.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.Promotion') AND i.name = N'UQ_Promotion_Promotion_Code'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|UNIQUE|Promotion_Code||' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.Promotion DROP CONSTRAINT UQ_Promotion_Promotion_Code;
    PRINT N'UQ_Promotion_Promotion_Code: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.Promotion ADD CONSTRAINT UQ_Promotion_Promotion_Code UNIQUE (Promotion_Code);
    PRINT N'Created UQ_Promotion_Promotion_Code.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.Market') AND i.name = N'UQ_Market_Market_Code'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|UNIQUE|Market_Code||' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.Market DROP CONSTRAINT UQ_Market_Market_Code;
    PRINT N'UQ_Market_Market_Code: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.Market ADD CONSTRAINT UQ_Market_Market_Code UNIQUE (Market_Code);
    PRINT N'Created UQ_Market_Market_Code.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.MarketSegment') AND i.name = N'UQ_MarketSegment_Segment_Code'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|UNIQUE|Segment_Code||' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketSegment DROP CONSTRAINT UQ_MarketSegment_Segment_Code;
    PRINT N'UQ_MarketSegment_Segment_Code: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketSegment ADD CONSTRAINT UQ_MarketSegment_Segment_Code UNIQUE (Segment_Code);
    PRINT N'Created UQ_MarketSegment_Segment_Code.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.CampaignResult') AND i.name = N'UQ_CampaignResult_Marketing_Campaign_ID_Metric_Name_Measurement_Date'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|UNIQUE|Marketing_Campaign_ID,Metric_Name,Measurement_Date||' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.CampaignResult DROP CONSTRAINT UQ_CampaignResult_Marketing_Campaign_ID_Metric_Name_Measurement_Date;
    PRINT N'UQ_CampaignResult_Marketing_Campaign_ID_Metric_Name_Measurement_Date: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.CampaignResult ADD CONSTRAINT UQ_CampaignResult_Marketing_Campaign_ID_Metric_Name_Measurement_Date UNIQUE (Marketing_Campaign_ID, Metric_Name, Measurement_Date);
    PRINT N'Created UQ_CampaignResult_Marketing_Campaign_ID_Metric_Name_Measurement_Date.';
END;
GO

/* ========================================================================
   2. CHECK constraints (business rules of the Stage 6 logical model and the v1.1 decisions)
   ======================================================================== */

-- v1.1: تاریخ پایان بدون تاریخ شروع رد می‌شود
DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'core.Brand') AND name = N'CK_Brand_Brand_End_Date';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Brand_End_Date] IS NULL OR [Brand_Start_Date] IS NOT NULL AND [Brand_End_Date]>=[Brand_Start_Date])' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE core.Brand DROP CONSTRAINT CK_Brand_Brand_End_Date;
    PRINT N'CK_Brand_Brand_End_Date: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE core.Brand WITH CHECK ADD CONSTRAINT CK_Brand_Brand_End_Date CHECK (Brand_End_Date IS NULL OR (Brand_Start_Date IS NOT NULL AND Brand_End_Date >= Brand_Start_Date));
    PRINT N'Created CK_Brand_Brand_End_Date.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'core.Brand') AND name = N'CK_Brand_Brand_Country';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'(([Brand_Country]) collate Latin1_General_BIN like ''[A-Z][A-Z]'')' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE core.Brand DROP CONSTRAINT CK_Brand_Brand_Country;
    PRINT N'CK_Brand_Brand_Country: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE core.Brand WITH CHECK ADD CONSTRAINT CK_Brand_Brand_Country CHECK (Brand_Country COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z]');
    PRINT N'Created CK_Brand_Brand_Country.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'core.Product') AND name = N'CK_Product_Weight';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Weight]>(0))' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE core.Product DROP CONSTRAINT CK_Product_Weight;
    PRINT N'CK_Product_Weight: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE core.Product WITH CHECK ADD CONSTRAINT CK_Product_Weight CHECK (Weight > 0);
    PRINT N'Created CK_Product_Weight.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'core.Product') AND name = N'CK_Product_Tax_Rate';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Tax_Rate]>=(0) AND [Tax_Rate]<=(100))' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE core.Product DROP CONSTRAINT CK_Product_Tax_Rate;
    PRINT N'CK_Product_Tax_Rate: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE core.Product WITH CHECK ADD CONSTRAINT CK_Product_Tax_Rate CHECK (Tax_Rate BETWEEN 0 AND 100);
    PRINT N'Created CK_Product_Tax_Rate.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'core.Product') AND name = N'CK_Product_Product_Updated_Date';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Product_Updated_Date]>=[Product_Created_Date])' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE core.Product DROP CONSTRAINT CK_Product_Product_Updated_Date;
    PRINT N'CK_Product_Product_Updated_Date: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE core.Product WITH CHECK ADD CONSTRAINT CK_Product_Product_Updated_Date CHECK (Product_Updated_Date >= Product_Created_Date);
    PRINT N'Created CK_Product_Product_Updated_Date.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'ref.ProductCategory') AND name = N'CK_ProductCategory_Parent_Category_ID';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Parent_Category_ID]<>[Product_Category_ID])' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE ref.ProductCategory DROP CONSTRAINT CK_ProductCategory_Parent_Category_ID;
    PRINT N'CK_ProductCategory_Parent_Category_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE ref.ProductCategory WITH CHECK ADD CONSTRAINT CK_ProductCategory_Parent_Category_ID CHECK (Parent_Category_ID <> Product_Category_ID);
    PRINT N'Created CK_ProductCategory_Parent_Category_ID.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'ref.ProductCategory') AND name = N'CK_ProductCategory_Category_Level';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Category_Level]>=(1))' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE ref.ProductCategory DROP CONSTRAINT CK_ProductCategory_Category_Level;
    PRINT N'CK_ProductCategory_Category_Level: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE ref.ProductCategory WITH CHECK ADD CONSTRAINT CK_ProductCategory_Category_Level CHECK (Category_Level >= 1);
    PRINT N'Created CK_ProductCategory_Category_Level.';
END;
GO

-- v1.1: جدید
DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'core.SKU') AND name = N'CK_SKU_Weight';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Weight]>(0))' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE core.SKU DROP CONSTRAINT CK_SKU_Weight;
    PRINT N'CK_SKU_Weight: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE core.SKU WITH CHECK ADD CONSTRAINT CK_SKU_Weight CHECK (Weight > 0);
    PRINT N'Created CK_SKU_Weight.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'core.SKU') AND name = N'CK_SKU_Standard_Cost';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Standard_Cost]>=(0))' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE core.SKU DROP CONSTRAINT CK_SKU_Standard_Cost;
    PRINT N'CK_SKU_Standard_Cost: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE core.SKU WITH CHECK ADD CONSTRAINT CK_SKU_Standard_Cost CHECK (Standard_Cost >= 0);
    PRINT N'Created CK_SKU_Standard_Cost.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'core.SKU') AND name = N'CK_SKU_Currency';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'(([Currency]) collate Latin1_General_BIN like ''[A-Z][A-Z][A-Z]'')' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE core.SKU DROP CONSTRAINT CK_SKU_Currency;
    PRINT N'CK_SKU_Currency: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE core.SKU WITH CHECK ADD CONSTRAINT CK_SKU_Currency CHECK (Currency COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z][A-Z]');
    PRINT N'Created CK_SKU_Currency.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'core.SKU') AND name = N'CK_SKU_Standard_Cost_Currency';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Standard_Cost] IS NULL OR [Currency] IS NOT NULL)' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE core.SKU DROP CONSTRAINT CK_SKU_Standard_Cost_Currency;
    PRINT N'CK_SKU_Standard_Cost_Currency: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE core.SKU WITH CHECK ADD CONSTRAINT CK_SKU_Standard_Cost_Currency CHECK (Standard_Cost IS NULL OR Currency IS NOT NULL);
    PRINT N'Created CK_SKU_Standard_Cost_Currency.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.ProductPrice') AND name = N'CK_ProductPrice_Unit_Price';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Unit_Price]>=(0))' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.ProductPrice DROP CONSTRAINT CK_ProductPrice_Unit_Price;
    PRINT N'CK_ProductPrice_Unit_Price: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.ProductPrice WITH CHECK ADD CONSTRAINT CK_ProductPrice_Unit_Price CHECK (Unit_Price >= 0);
    PRINT N'Created CK_ProductPrice_Unit_Price.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.ProductPrice') AND name = N'CK_ProductPrice_Effective_To';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Effective_To]>=[Effective_From])' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.ProductPrice DROP CONSTRAINT CK_ProductPrice_Effective_To;
    PRINT N'CK_ProductPrice_Effective_To: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.ProductPrice WITH CHECK ADD CONSTRAINT CK_ProductPrice_Effective_To CHECK (Effective_To >= Effective_From);
    PRINT N'Created CK_ProductPrice_Effective_To.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.ProductPrice') AND name = N'CK_ProductPrice_Currency';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'(([Currency]) collate Latin1_General_BIN like ''[A-Z][A-Z][A-Z]'')' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.ProductPrice DROP CONSTRAINT CK_ProductPrice_Currency;
    PRINT N'CK_ProductPrice_Currency: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.ProductPrice WITH CHECK ADD CONSTRAINT CK_ProductPrice_Currency CHECK (Currency COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z][A-Z]');
    PRINT N'Created CK_ProductPrice_Currency.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.CampaignChannel') AND name = N'CK_CampaignChannel_Channel_Status';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Channel_Status]=N''Inactive'' OR [Channel_Status]=N''Active'')' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.CampaignChannel DROP CONSTRAINT CK_CampaignChannel_Channel_Status;
    PRINT N'CK_CampaignChannel_Channel_Status: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.CampaignChannel WITH CHECK ADD CONSTRAINT CK_CampaignChannel_Channel_Status CHECK (Channel_Status IN (N'Active', N'Inactive'));
    PRINT N'Created CK_CampaignChannel_Channel_Status.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.CampaignAudience') AND name = N'CK_CampaignAudience_Audience_Status';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Audience_Status]=N''Inactive'' OR [Audience_Status]=N''Active'')' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.CampaignAudience DROP CONSTRAINT CK_CampaignAudience_Audience_Status;
    PRINT N'CK_CampaignAudience_Audience_Status: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.CampaignAudience WITH CHECK ADD CONSTRAINT CK_CampaignAudience_Audience_Status CHECK (Audience_Status IN (N'Active', N'Inactive'));
    PRINT N'Created CK_CampaignAudience_Audience_Status.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.MarketingCampaign') AND name = N'CK_MarketingCampaign_End_Date';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([End_Date]>=[Start_Date])' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketingCampaign DROP CONSTRAINT CK_MarketingCampaign_End_Date;
    PRINT N'CK_MarketingCampaign_End_Date: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketingCampaign WITH CHECK ADD CONSTRAINT CK_MarketingCampaign_End_Date CHECK (End_Date >= Start_Date);
    PRINT N'Created CK_MarketingCampaign_End_Date.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.MarketingCampaign') AND name = N'CK_MarketingCampaign_Campaign_Purpose';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Campaign_Purpose]=N''Marketing'' OR [Campaign_Purpose]=N''Brand'')' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketingCampaign DROP CONSTRAINT CK_MarketingCampaign_Campaign_Purpose;
    PRINT N'CK_MarketingCampaign_Campaign_Purpose: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketingCampaign WITH CHECK ADD CONSTRAINT CK_MarketingCampaign_Campaign_Purpose CHECK (Campaign_Purpose IN (N'Brand', N'Marketing'));
    PRINT N'Created CK_MarketingCampaign_Campaign_Purpose.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.MarketingCampaign') AND name = N'CK_MarketingCampaign_Brand_ID';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Campaign_Purpose]<>N''Brand'' OR [Brand_ID] IS NOT NULL)' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketingCampaign DROP CONSTRAINT CK_MarketingCampaign_Brand_ID;
    PRINT N'CK_MarketingCampaign_Brand_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketingCampaign WITH CHECK ADD CONSTRAINT CK_MarketingCampaign_Brand_ID CHECK (Campaign_Purpose <> N'Brand' OR Brand_ID IS NOT NULL);
    PRINT N'Created CK_MarketingCampaign_Brand_ID.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.CampaignBudget') AND name = N'CK_CampaignBudget_Total_Allocated_Amount';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Total_Allocated_Amount]>=(0))' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.CampaignBudget DROP CONSTRAINT CK_CampaignBudget_Total_Allocated_Amount;
    PRINT N'CK_CampaignBudget_Total_Allocated_Amount: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.CampaignBudget WITH CHECK ADD CONSTRAINT CK_CampaignBudget_Total_Allocated_Amount CHECK (Total_Allocated_Amount >= 0);
    PRINT N'Created CK_CampaignBudget_Total_Allocated_Amount.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.CampaignBudget') AND name = N'CK_CampaignBudget_Currency';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'(([Currency]) collate Latin1_General_BIN like ''[A-Z][A-Z][A-Z]'')' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.CampaignBudget DROP CONSTRAINT CK_CampaignBudget_Currency;
    PRINT N'CK_CampaignBudget_Currency: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.CampaignBudget WITH CHECK ADD CONSTRAINT CK_CampaignBudget_Currency CHECK (Currency COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z][A-Z]');
    PRINT N'Created CK_CampaignBudget_Currency.';
END;
GO

-- v1.1: جدید؛ T2-OI-19 بسته شد
DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.CampaignCost') AND name = N'CK_CampaignCost_Actual_Spent';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Actual_Spent]>=(0))' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.CampaignCost DROP CONSTRAINT CK_CampaignCost_Actual_Spent;
    PRINT N'CK_CampaignCost_Actual_Spent: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.CampaignCost WITH CHECK ADD CONSTRAINT CK_CampaignCost_Actual_Spent CHECK (Actual_Spent >= 0);
    PRINT N'Created CK_CampaignCost_Actual_Spent.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.CampaignCost') AND name = N'CK_CampaignCost_Currency';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'(([Currency]) collate Latin1_General_BIN like ''[A-Z][A-Z][A-Z]'')' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.CampaignCost DROP CONSTRAINT CK_CampaignCost_Currency;
    PRINT N'CK_CampaignCost_Currency: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.CampaignCost WITH CHECK ADD CONSTRAINT CK_CampaignCost_Currency CHECK (Currency COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z][A-Z]');
    PRINT N'Created CK_CampaignCost_Currency.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.Promotion') AND name = N'CK_Promotion_End_Date';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([End_Date]>=[Start_Date])' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.Promotion DROP CONSTRAINT CK_Promotion_End_Date;
    PRINT N'CK_Promotion_End_Date: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.Promotion WITH CHECK ADD CONSTRAINT CK_Promotion_End_Date CHECK (End_Date >= Start_Date);
    PRINT N'Created CK_Promotion_End_Date.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.Promotion') AND name = N'CK_Promotion_Discount_Type';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Discount_Type]=N''Fixed Amount'' OR [Discount_Type]=N''Percentage'')' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.Promotion DROP CONSTRAINT CK_Promotion_Discount_Type;
    PRINT N'CK_Promotion_Discount_Type: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.Promotion WITH CHECK ADD CONSTRAINT CK_Promotion_Discount_Type CHECK (Discount_Type IN (N'Percentage', N'Fixed Amount'));
    PRINT N'Created CK_Promotion_Discount_Type.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.Promotion') AND name = N'CK_Promotion_Discount_Value';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Discount_Value]>=(0) AND ([Discount_Type]<>N''Percentage'' OR [Discount_Value]<=(100)))' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.Promotion DROP CONSTRAINT CK_Promotion_Discount_Value;
    PRINT N'CK_Promotion_Discount_Value: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.Promotion WITH CHECK ADD CONSTRAINT CK_Promotion_Discount_Value CHECK (Discount_Value >= 0 AND (Discount_Type <> N'Percentage' OR Discount_Value <= 100));
    PRINT N'Created CK_Promotion_Discount_Value.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.Promotion') AND name = N'CK_Promotion_Discount_Type_Currency';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Discount_Type]<>N''Fixed Amount'' OR [Currency] IS NOT NULL)' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.Promotion DROP CONSTRAINT CK_Promotion_Discount_Type_Currency;
    PRINT N'CK_Promotion_Discount_Type_Currency: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.Promotion WITH CHECK ADD CONSTRAINT CK_Promotion_Discount_Type_Currency CHECK (Discount_Type <> N'Fixed Amount' OR Currency IS NOT NULL);
    PRINT N'Created CK_Promotion_Discount_Type_Currency.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.Promotion') AND name = N'CK_Promotion_Currency';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'(([Currency]) collate Latin1_General_BIN like ''[A-Z][A-Z][A-Z]'')' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.Promotion DROP CONSTRAINT CK_Promotion_Currency;
    PRINT N'CK_Promotion_Currency: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.Promotion WITH CHECK ADD CONSTRAINT CK_Promotion_Currency CHECK (Currency COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z][A-Z]');
    PRINT N'Created CK_Promotion_Currency.';
END;
GO

-- v1.1: تاریخ پایان بدون تاریخ شروع رد می‌شود
DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.BrandActivity') AND name = N'CK_BrandActivity_Activity_End_Date';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Activity_End_Date] IS NULL OR [Activity_Start_Date] IS NOT NULL AND [Activity_End_Date]>=[Activity_Start_Date])' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.BrandActivity DROP CONSTRAINT CK_BrandActivity_Activity_End_Date;
    PRINT N'CK_BrandActivity_Activity_End_Date: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.BrandActivity WITH CHECK ADD CONSTRAINT CK_BrandActivity_Activity_End_Date CHECK (Activity_End_Date IS NULL OR (Activity_Start_Date IS NOT NULL AND Activity_End_Date >= Activity_Start_Date));
    PRINT N'Created CK_BrandActivity_Activity_End_Date.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.BrandActivity') AND name = N'CK_BrandActivity_Activity_Cost';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Activity_Cost]>=(0))' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.BrandActivity DROP CONSTRAINT CK_BrandActivity_Activity_Cost;
    PRINT N'CK_BrandActivity_Activity_Cost: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.BrandActivity WITH CHECK ADD CONSTRAINT CK_BrandActivity_Activity_Cost CHECK (Activity_Cost >= 0);
    PRINT N'Created CK_BrandActivity_Activity_Cost.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.BrandActivity') AND name = N'CK_BrandActivity_Currency';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'(([Currency]) collate Latin1_General_BIN like ''[A-Z][A-Z][A-Z]'')' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.BrandActivity DROP CONSTRAINT CK_BrandActivity_Currency;
    PRINT N'CK_BrandActivity_Currency: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.BrandActivity WITH CHECK ADD CONSTRAINT CK_BrandActivity_Currency CHECK (Currency COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z][A-Z]');
    PRINT N'Created CK_BrandActivity_Currency.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.BrandActivity') AND name = N'CK_BrandActivity_Activity_Cost_Currency';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Activity_Cost] IS NULL OR [Currency] IS NOT NULL)' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.BrandActivity DROP CONSTRAINT CK_BrandActivity_Activity_Cost_Currency;
    PRINT N'CK_BrandActivity_Activity_Cost_Currency: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.BrandActivity WITH CHECK ADD CONSTRAINT CK_BrandActivity_Activity_Cost_Currency CHECK (Activity_Cost IS NULL OR Currency IS NOT NULL);
    PRINT N'Created CK_BrandActivity_Activity_Cost_Currency.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.MarketSegment') AND name = N'CK_MarketSegment_Segmentation_Basis';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Segmentation_Basis]=N''Behavioral'' OR [Segmentation_Basis]=N''Demographic'' OR [Segmentation_Basis]=N''Geographic'')' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketSegment DROP CONSTRAINT CK_MarketSegment_Segmentation_Basis;
    PRINT N'CK_MarketSegment_Segmentation_Basis: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketSegment WITH CHECK ADD CONSTRAINT CK_MarketSegment_Segmentation_Basis CHECK (Segmentation_Basis IN (N'Geographic', N'Demographic', N'Behavioral'));
    PRINT N'Created CK_MarketSegment_Segmentation_Basis.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.MarketResearch') AND name = N'CK_MarketResearch_End_Date';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([End_Date]>=[Start_Date])' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketResearch DROP CONSTRAINT CK_MarketResearch_End_Date;
    PRINT N'CK_MarketResearch_End_Date: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketResearch WITH CHECK ADD CONSTRAINT CK_MarketResearch_End_Date CHECK (End_Date >= Start_Date);
    PRINT N'Created CK_MarketResearch_End_Date.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.MarketResearch') AND name = N'CK_MarketResearch_Research_Cost';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Research_Cost]>=(0))' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketResearch DROP CONSTRAINT CK_MarketResearch_Research_Cost;
    PRINT N'CK_MarketResearch_Research_Cost: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketResearch WITH CHECK ADD CONSTRAINT CK_MarketResearch_Research_Cost CHECK (Research_Cost >= 0);
    PRINT N'Created CK_MarketResearch_Research_Cost.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.MarketResearch') AND name = N'CK_MarketResearch_Currency';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'(([Currency]) collate Latin1_General_BIN like ''[A-Z][A-Z][A-Z]'')' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketResearch DROP CONSTRAINT CK_MarketResearch_Currency;
    PRINT N'CK_MarketResearch_Currency: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketResearch WITH CHECK ADD CONSTRAINT CK_MarketResearch_Currency CHECK (Currency COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z][A-Z]');
    PRINT N'Created CK_MarketResearch_Currency.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.MarketResearch') AND name = N'CK_MarketResearch_Research_Cost_Currency';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Research_Cost] IS NULL OR [Currency] IS NOT NULL)' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketResearch DROP CONSTRAINT CK_MarketResearch_Research_Cost_Currency;
    PRINT N'CK_MarketResearch_Research_Cost_Currency: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketResearch WITH CHECK ADD CONSTRAINT CK_MarketResearch_Research_Cost_Currency CHECK (Research_Cost IS NULL OR Currency IS NOT NULL);
    PRINT N'Created CK_MarketResearch_Research_Cost_Currency.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.MarketSurvey') AND name = N'CK_MarketSurvey_Sample_Size';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Sample_Size]>(0))' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketSurvey DROP CONSTRAINT CK_MarketSurvey_Sample_Size;
    PRINT N'CK_MarketSurvey_Sample_Size: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketSurvey WITH CHECK ADD CONSTRAINT CK_MarketSurvey_Sample_Size CHECK (Sample_Size > 0);
    PRINT N'Created CK_MarketSurvey_Sample_Size.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.MarketPrice') AND name = N'CK_MarketPrice_Product_ID_Competitor_Product_ID';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Product_ID] IS NOT NULL AND [Competitor_Product_ID] IS NULL OR [Product_ID] IS NULL AND [Competitor_Product_ID] IS NOT NULL)' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketPrice DROP CONSTRAINT CK_MarketPrice_Product_ID_Competitor_Product_ID;
    PRINT N'CK_MarketPrice_Product_ID_Competitor_Product_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketPrice WITH CHECK ADD CONSTRAINT CK_MarketPrice_Product_ID_Competitor_Product_ID CHECK ((Product_ID IS NOT NULL AND Competitor_Product_ID IS NULL) OR (Product_ID IS NULL AND Competitor_Product_ID IS NOT NULL));
    PRINT N'Created CK_MarketPrice_Product_ID_Competitor_Product_ID.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.MarketPrice') AND name = N'CK_MarketPrice_Price_Value';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'([Price_Value]>=(0))' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketPrice DROP CONSTRAINT CK_MarketPrice_Price_Value;
    PRINT N'CK_MarketPrice_Price_Value: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketPrice WITH CHECK ADD CONSTRAINT CK_MarketPrice_Price_Value CHECK (Price_Value >= 0);
    PRINT N'Created CK_MarketPrice_Price_Value.';
END;
GO

DECLARE @sig nvarchar(max);
SELECT @sig = definition FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'marketing.MarketPrice') AND name = N'CK_MarketPrice_Currency';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'(([Currency]) collate Latin1_General_BIN like ''[A-Z][A-Z][A-Z]'')' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketPrice DROP CONSTRAINT CK_MarketPrice_Currency;
    PRINT N'CK_MarketPrice_Currency: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketPrice WITH CHECK ADD CONSTRAINT CK_MarketPrice_Currency CHECK (Currency COLLATE Latin1_General_BIN LIKE '[A-Z][A-Z][A-Z]');
    PRINT N'Created CK_MarketPrice_Currency.';
END;
GO

/* ========================================================================
   3. DEFAULT constraints
   ======================================================================== */

DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(col.name, N'=', d.definition) FROM sys.default_constraints d
JOIN sys.columns col ON col.object_id = d.parent_object_id AND col.column_id = d.parent_column_id
WHERE d.parent_object_id = OBJECT_ID(N'core.Product') AND d.name = N'DF_Product_Product_Created_Date';
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Product_Created_Date=(sysdatetime())' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE core.Product DROP CONSTRAINT DF_Product_Product_Created_Date;
    PRINT N'DF_Product_Product_Created_Date: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE core.Product ADD CONSTRAINT DF_Product_Product_Created_Date DEFAULT (SYSDATETIME()) FOR Product_Created_Date;
    PRINT N'Created DF_Product_Product_Created_Date.';
END;
GO

/* ========================================================================
   4. FOREIGN KEY constraints (ON DELETE / ON UPDATE NO ACTION: no cascading deletes of business history)
   ======================================================================== */

-- R01: Product Category -> Product
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'core.Product') AND f.name = N'FK_Product_ProductCategory_Product_Category_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Product_Category_ID -> ref.ProductCategory(Product_Category_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE core.Product DROP CONSTRAINT FK_Product_ProductCategory_Product_Category_ID;
    PRINT N'FK_Product_ProductCategory_Product_Category_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE core.Product WITH CHECK ADD CONSTRAINT FK_Product_ProductCategory_Product_Category_ID
        FOREIGN KEY (Product_Category_ID) REFERENCES ref.ProductCategory (Product_Category_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_Product_ProductCategory_Product_Category_ID.';
END;
GO

-- R02: Brand -> Product
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'core.Product') AND f.name = N'FK_Product_Brand_Brand_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Brand_ID -> core.Brand(Brand_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE core.Product DROP CONSTRAINT FK_Product_Brand_Brand_ID;
    PRINT N'FK_Product_Brand_Brand_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE core.Product WITH CHECK ADD CONSTRAINT FK_Product_Brand_Brand_ID
        FOREIGN KEY (Brand_ID) REFERENCES core.Brand (Brand_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_Product_Brand_Brand_ID.';
END;
GO

-- R03: Product -> SKU
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'core.SKU') AND f.name = N'FK_SKU_Product_Product_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Product_ID -> core.Product(Product_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE core.SKU DROP CONSTRAINT FK_SKU_Product_Product_ID;
    PRINT N'FK_SKU_Product_Product_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE core.SKU WITH CHECK ADD CONSTRAINT FK_SKU_Product_Product_ID
        FOREIGN KEY (Product_ID) REFERENCES core.Product (Product_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_SKU_Product_Product_ID.';
END;
GO

-- R04: Product -> Market Price
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.MarketPrice') AND f.name = N'FK_MarketPrice_Product_Product_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Product_ID -> core.Product(Product_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketPrice DROP CONSTRAINT FK_MarketPrice_Product_Product_ID;
    PRINT N'FK_MarketPrice_Product_Product_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketPrice WITH CHECK ADD CONSTRAINT FK_MarketPrice_Product_Product_ID
        FOREIGN KEY (Product_ID) REFERENCES core.Product (Product_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_MarketPrice_Product_Product_ID.';
END;
GO

-- R05: Package -> SKU
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'core.SKU') AND f.name = N'FK_SKU_Package_Package_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Package_ID -> ref.Package(Package_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE core.SKU DROP CONSTRAINT FK_SKU_Package_Package_ID;
    PRINT N'FK_SKU_Package_Package_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE core.SKU WITH CHECK ADD CONSTRAINT FK_SKU_Package_Package_ID
        FOREIGN KEY (Package_ID) REFERENCES ref.Package (Package_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_SKU_Package_Package_ID.';
END;
GO

-- R06: SKU -> Product Price
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.ProductPrice') AND f.name = N'FK_ProductPrice_SKU_SKU_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'SKU_ID -> core.SKU(SKU_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.ProductPrice DROP CONSTRAINT FK_ProductPrice_SKU_SKU_ID;
    PRINT N'FK_ProductPrice_SKU_SKU_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.ProductPrice WITH CHECK ADD CONSTRAINT FK_ProductPrice_SKU_SKU_ID
        FOREIGN KEY (SKU_ID) REFERENCES core.SKU (SKU_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_ProductPrice_SKU_SKU_ID.';
END;
GO

-- R07: Brand -> Brand Activity
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.BrandActivity') AND f.name = N'FK_BrandActivity_Brand_Brand_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Brand_ID -> core.Brand(Brand_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.BrandActivity DROP CONSTRAINT FK_BrandActivity_Brand_Brand_ID;
    PRINT N'FK_BrandActivity_Brand_Brand_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.BrandActivity WITH CHECK ADD CONSTRAINT FK_BrandActivity_Brand_Brand_ID
        FOREIGN KEY (Brand_ID) REFERENCES core.Brand (Brand_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_BrandActivity_Brand_Brand_ID.';
END;
GO

-- R08: Brand -> Marketing Campaign
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.MarketingCampaign') AND f.name = N'FK_MarketingCampaign_Brand_Brand_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Brand_ID -> core.Brand(Brand_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketingCampaign DROP CONSTRAINT FK_MarketingCampaign_Brand_Brand_ID;
    PRINT N'FK_MarketingCampaign_Brand_Brand_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketingCampaign WITH CHECK ADD CONSTRAINT FK_MarketingCampaign_Brand_Brand_ID
        FOREIGN KEY (Brand_ID) REFERENCES core.Brand (Brand_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_MarketingCampaign_Brand_Brand_ID.';
END;
GO

-- R09a: Marketing Campaign -> Marketing Campaign Channel
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.MarketingCampaignChannel') AND f.name = N'FK_MarketingCampaignChannel_MarketingCampaign_Marketing_Campaign_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Marketing_Campaign_ID -> marketing.MarketingCampaign(Marketing_Campaign_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketingCampaignChannel DROP CONSTRAINT FK_MarketingCampaignChannel_MarketingCampaign_Marketing_Campaign_ID;
    PRINT N'FK_MarketingCampaignChannel_MarketingCampaign_Marketing_Campaign_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketingCampaignChannel WITH CHECK ADD CONSTRAINT FK_MarketingCampaignChannel_MarketingCampaign_Marketing_Campaign_ID
        FOREIGN KEY (Marketing_Campaign_ID) REFERENCES marketing.MarketingCampaign (Marketing_Campaign_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_MarketingCampaignChannel_MarketingCampaign_Marketing_Campaign_ID.';
END;
GO

-- R09b: Campaign Channel -> Marketing Campaign Channel
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.MarketingCampaignChannel') AND f.name = N'FK_MarketingCampaignChannel_CampaignChannel_Campaign_Channel_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Campaign_Channel_ID -> marketing.CampaignChannel(Campaign_Channel_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketingCampaignChannel DROP CONSTRAINT FK_MarketingCampaignChannel_CampaignChannel_Campaign_Channel_ID;
    PRINT N'FK_MarketingCampaignChannel_CampaignChannel_Campaign_Channel_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketingCampaignChannel WITH CHECK ADD CONSTRAINT FK_MarketingCampaignChannel_CampaignChannel_Campaign_Channel_ID
        FOREIGN KEY (Campaign_Channel_ID) REFERENCES marketing.CampaignChannel (Campaign_Channel_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_MarketingCampaignChannel_CampaignChannel_Campaign_Channel_ID.';
END;
GO

-- R10a: Marketing Campaign -> Marketing Campaign Audience
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.MarketingCampaignAudience') AND f.name = N'FK_MarketingCampaignAudience_MarketingCampaign_Marketing_Campaign_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Marketing_Campaign_ID -> marketing.MarketingCampaign(Marketing_Campaign_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketingCampaignAudience DROP CONSTRAINT FK_MarketingCampaignAudience_MarketingCampaign_Marketing_Campaign_ID;
    PRINT N'FK_MarketingCampaignAudience_MarketingCampaign_Marketing_Campaign_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketingCampaignAudience WITH CHECK ADD CONSTRAINT FK_MarketingCampaignAudience_MarketingCampaign_Marketing_Campaign_ID
        FOREIGN KEY (Marketing_Campaign_ID) REFERENCES marketing.MarketingCampaign (Marketing_Campaign_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_MarketingCampaignAudience_MarketingCampaign_Marketing_Campaign_ID.';
END;
GO

-- R10b: Campaign Audience -> Marketing Campaign Audience
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.MarketingCampaignAudience') AND f.name = N'FK_MarketingCampaignAudience_CampaignAudience_Campaign_Audience_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Campaign_Audience_ID -> marketing.CampaignAudience(Campaign_Audience_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketingCampaignAudience DROP CONSTRAINT FK_MarketingCampaignAudience_CampaignAudience_Campaign_Audience_ID;
    PRINT N'FK_MarketingCampaignAudience_CampaignAudience_Campaign_Audience_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketingCampaignAudience WITH CHECK ADD CONSTRAINT FK_MarketingCampaignAudience_CampaignAudience_Campaign_Audience_ID
        FOREIGN KEY (Campaign_Audience_ID) REFERENCES marketing.CampaignAudience (Campaign_Audience_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_MarketingCampaignAudience_CampaignAudience_Campaign_Audience_ID.';
END;
GO

-- R11: Marketing Campaign -> Campaign Budget
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.CampaignBudget') AND f.name = N'FK_CampaignBudget_MarketingCampaign_Marketing_Campaign_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Marketing_Campaign_ID -> marketing.MarketingCampaign(Marketing_Campaign_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.CampaignBudget DROP CONSTRAINT FK_CampaignBudget_MarketingCampaign_Marketing_Campaign_ID;
    PRINT N'FK_CampaignBudget_MarketingCampaign_Marketing_Campaign_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.CampaignBudget WITH CHECK ADD CONSTRAINT FK_CampaignBudget_MarketingCampaign_Marketing_Campaign_ID
        FOREIGN KEY (Marketing_Campaign_ID) REFERENCES marketing.MarketingCampaign (Marketing_Campaign_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_CampaignBudget_MarketingCampaign_Marketing_Campaign_ID.';
END;
GO

-- R12: Marketing Campaign -> Campaign Cost
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.CampaignCost') AND f.name = N'FK_CampaignCost_MarketingCampaign_Marketing_Campaign_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Marketing_Campaign_ID -> marketing.MarketingCampaign(Marketing_Campaign_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.CampaignCost DROP CONSTRAINT FK_CampaignCost_MarketingCampaign_Marketing_Campaign_ID;
    PRINT N'FK_CampaignCost_MarketingCampaign_Marketing_Campaign_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.CampaignCost WITH CHECK ADD CONSTRAINT FK_CampaignCost_MarketingCampaign_Marketing_Campaign_ID
        FOREIGN KEY (Marketing_Campaign_ID) REFERENCES marketing.MarketingCampaign (Marketing_Campaign_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_CampaignCost_MarketingCampaign_Marketing_Campaign_ID.';
END;
GO

-- R13: Marketing Campaign -> Campaign Result
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.CampaignResult') AND f.name = N'FK_CampaignResult_MarketingCampaign_Marketing_Campaign_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Marketing_Campaign_ID -> marketing.MarketingCampaign(Marketing_Campaign_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.CampaignResult DROP CONSTRAINT FK_CampaignResult_MarketingCampaign_Marketing_Campaign_ID;
    PRINT N'FK_CampaignResult_MarketingCampaign_Marketing_Campaign_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.CampaignResult WITH CHECK ADD CONSTRAINT FK_CampaignResult_MarketingCampaign_Marketing_Campaign_ID
        FOREIGN KEY (Marketing_Campaign_ID) REFERENCES marketing.MarketingCampaign (Marketing_Campaign_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_CampaignResult_MarketingCampaign_Marketing_Campaign_ID.';
END;
GO

-- R14: Marketing Campaign -> Promotion
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.Promotion') AND f.name = N'FK_Promotion_MarketingCampaign_Marketing_Campaign_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Marketing_Campaign_ID -> marketing.MarketingCampaign(Marketing_Campaign_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.Promotion DROP CONSTRAINT FK_Promotion_MarketingCampaign_Marketing_Campaign_ID;
    PRINT N'FK_Promotion_MarketingCampaign_Marketing_Campaign_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.Promotion WITH CHECK ADD CONSTRAINT FK_Promotion_MarketingCampaign_Marketing_Campaign_ID
        FOREIGN KEY (Marketing_Campaign_ID) REFERENCES marketing.MarketingCampaign (Marketing_Campaign_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_Promotion_MarketingCampaign_Marketing_Campaign_ID.';
END;
GO

-- R16: Market -> Market Segment
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.MarketSegment') AND f.name = N'FK_MarketSegment_Market_Market_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Market_ID -> marketing.Market(Market_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketSegment DROP CONSTRAINT FK_MarketSegment_Market_Market_ID;
    PRINT N'FK_MarketSegment_Market_Market_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketSegment WITH CHECK ADD CONSTRAINT FK_MarketSegment_Market_Market_ID
        FOREIGN KEY (Market_ID) REFERENCES marketing.Market (Market_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_MarketSegment_Market_Market_ID.';
END;
GO

-- R17: Market -> Market Research
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.MarketResearch') AND f.name = N'FK_MarketResearch_Market_Market_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Market_ID -> marketing.Market(Market_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketResearch DROP CONSTRAINT FK_MarketResearch_Market_Market_ID;
    PRINT N'FK_MarketResearch_Market_Market_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketResearch WITH CHECK ADD CONSTRAINT FK_MarketResearch_Market_Market_ID
        FOREIGN KEY (Market_ID) REFERENCES marketing.Market (Market_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_MarketResearch_Market_Market_ID.';
END;
GO

-- R18: Market -> Market Price
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.MarketPrice') AND f.name = N'FK_MarketPrice_Market_Market_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Market_ID -> marketing.Market(Market_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketPrice DROP CONSTRAINT FK_MarketPrice_Market_Market_ID;
    PRINT N'FK_MarketPrice_Market_Market_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketPrice WITH CHECK ADD CONSTRAINT FK_MarketPrice_Market_Market_ID
        FOREIGN KEY (Market_ID) REFERENCES marketing.Market (Market_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_MarketPrice_Market_Market_ID.';
END;
GO

-- R19: Market -> Competitor
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.Competitor') AND f.name = N'FK_Competitor_Market_Market_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Market_ID -> marketing.Market(Market_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.Competitor DROP CONSTRAINT FK_Competitor_Market_Market_ID;
    PRINT N'FK_Competitor_Market_Market_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.Competitor WITH CHECK ADD CONSTRAINT FK_Competitor_Market_Market_ID
        FOREIGN KEY (Market_ID) REFERENCES marketing.Market (Market_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_Competitor_Market_Market_ID.';
END;
GO

-- R20: Market Segment -> Market Survey
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.MarketSurvey') AND f.name = N'FK_MarketSurvey_MarketSegment_Market_Segment_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Market_Segment_ID -> marketing.MarketSegment(Market_Segment_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketSurvey DROP CONSTRAINT FK_MarketSurvey_MarketSegment_Market_Segment_ID;
    PRINT N'FK_MarketSurvey_MarketSegment_Market_Segment_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketSurvey WITH CHECK ADD CONSTRAINT FK_MarketSurvey_MarketSegment_Market_Segment_ID
        FOREIGN KEY (Market_Segment_ID) REFERENCES marketing.MarketSegment (Market_Segment_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_MarketSurvey_MarketSegment_Market_Segment_ID.';
END;
GO

-- R21: Market Research -> Market Survey
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.MarketSurvey') AND f.name = N'FK_MarketSurvey_MarketResearch_Market_Research_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Market_Research_ID -> marketing.MarketResearch(Market_Research_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketSurvey DROP CONSTRAINT FK_MarketSurvey_MarketResearch_Market_Research_ID;
    PRINT N'FK_MarketSurvey_MarketResearch_Market_Research_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketSurvey WITH CHECK ADD CONSTRAINT FK_MarketSurvey_MarketResearch_Market_Research_ID
        FOREIGN KEY (Market_Research_ID) REFERENCES marketing.MarketResearch (Market_Research_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_MarketSurvey_MarketResearch_Market_Research_ID.';
END;
GO

-- R22: Market Research -> Research Result
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.ResearchResult') AND f.name = N'FK_ResearchResult_MarketResearch_Market_Research_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Market_Research_ID -> marketing.MarketResearch(Market_Research_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.ResearchResult DROP CONSTRAINT FK_ResearchResult_MarketResearch_Market_Research_ID;
    PRINT N'FK_ResearchResult_MarketResearch_Market_Research_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.ResearchResult WITH CHECK ADD CONSTRAINT FK_ResearchResult_MarketResearch_Market_Research_ID
        FOREIGN KEY (Market_Research_ID) REFERENCES marketing.MarketResearch (Market_Research_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_ResearchResult_MarketResearch_Market_Research_ID.';
END;
GO

-- R25: Competitor -> Competitor Product
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.CompetitorProduct') AND f.name = N'FK_CompetitorProduct_Competitor_Competitor_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Competitor_ID -> marketing.Competitor(Competitor_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.CompetitorProduct DROP CONSTRAINT FK_CompetitorProduct_Competitor_Competitor_ID;
    PRINT N'FK_CompetitorProduct_Competitor_Competitor_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.CompetitorProduct WITH CHECK ADD CONSTRAINT FK_CompetitorProduct_Competitor_Competitor_ID
        FOREIGN KEY (Competitor_ID) REFERENCES marketing.Competitor (Competitor_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_CompetitorProduct_Competitor_Competitor_ID.';
END;
GO

-- R26: Competitor Product -> Market Price
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.MarketPrice') AND f.name = N'FK_MarketPrice_CompetitorProduct_Competitor_Product_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Competitor_Product_ID -> marketing.CompetitorProduct(Competitor_Product_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.MarketPrice DROP CONSTRAINT FK_MarketPrice_CompetitorProduct_Competitor_Product_ID;
    PRINT N'FK_MarketPrice_CompetitorProduct_Competitor_Product_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.MarketPrice WITH CHECK ADD CONSTRAINT FK_MarketPrice_CompetitorProduct_Competitor_Product_ID
        FOREIGN KEY (Competitor_Product_ID) REFERENCES marketing.CompetitorProduct (Competitor_Product_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_MarketPrice_CompetitorProduct_Competitor_Product_ID.';
END;
GO

-- R27: Campaign Channel -> Campaign Budget
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.CampaignBudget') AND f.name = N'FK_CampaignBudget_CampaignChannel_Campaign_Channel_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Campaign_Channel_ID -> marketing.CampaignChannel(Campaign_Channel_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.CampaignBudget DROP CONSTRAINT FK_CampaignBudget_CampaignChannel_Campaign_Channel_ID;
    PRINT N'FK_CampaignBudget_CampaignChannel_Campaign_Channel_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.CampaignBudget WITH CHECK ADD CONSTRAINT FK_CampaignBudget_CampaignChannel_Campaign_Channel_ID
        FOREIGN KEY (Campaign_Channel_ID) REFERENCES marketing.CampaignChannel (Campaign_Channel_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_CampaignBudget_CampaignChannel_Campaign_Channel_ID.';
END;
GO

-- R28: Campaign Channel -> Campaign Cost
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.CampaignCost') AND f.name = N'FK_CampaignCost_CampaignChannel_Campaign_Channel_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Campaign_Channel_ID -> marketing.CampaignChannel(Campaign_Channel_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.CampaignCost DROP CONSTRAINT FK_CampaignCost_CampaignChannel_Campaign_Channel_ID;
    PRINT N'FK_CampaignCost_CampaignChannel_Campaign_Channel_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.CampaignCost WITH CHECK ADD CONSTRAINT FK_CampaignCost_CampaignChannel_Campaign_Channel_ID
        FOREIGN KEY (Campaign_Channel_ID) REFERENCES marketing.CampaignChannel (Campaign_Channel_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_CampaignCost_CampaignChannel_Campaign_Channel_ID.';
END;
GO

-- R29: Product Category -> Product Category
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'ref.ProductCategory') AND f.name = N'FK_ProductCategory_ProductCategory_Parent_Category_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Parent_Category_ID -> ref.ProductCategory(Product_Category_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE ref.ProductCategory DROP CONSTRAINT FK_ProductCategory_ProductCategory_Parent_Category_ID;
    PRINT N'FK_ProductCategory_ProductCategory_Parent_Category_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE ref.ProductCategory WITH CHECK ADD CONSTRAINT FK_ProductCategory_ProductCategory_Parent_Category_ID
        FOREIGN KEY (Parent_Category_ID) REFERENCES ref.ProductCategory (Product_Category_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_ProductCategory_ProductCategory_Parent_Category_ID.';
END;
GO

-- R27 rule: Marketing Campaign Channel -> Campaign Budget  (enforces: channel of a budget/cost row must be a channel of that campaign)
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.CampaignBudget') AND f.name = N'FK_CampaignBudget_MarketingCampaignChannel_Marketing_Campaign_ID_Campaign_Channel_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Marketing_Campaign_ID,Campaign_Channel_ID -> marketing.MarketingCampaignChannel(Marketing_Campaign_ID,Campaign_Channel_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.CampaignBudget DROP CONSTRAINT FK_CampaignBudget_MarketingCampaignChannel_Marketing_Campaign_ID_Campaign_Channel_ID;
    PRINT N'FK_CampaignBudget_MarketingCampaignChannel_Marketing_Campaign_ID_Campaign_Channel_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.CampaignBudget WITH CHECK ADD CONSTRAINT FK_CampaignBudget_MarketingCampaignChannel_Marketing_Campaign_ID_Campaign_Channel_ID
        FOREIGN KEY (Marketing_Campaign_ID, Campaign_Channel_ID) REFERENCES marketing.MarketingCampaignChannel (Marketing_Campaign_ID, Campaign_Channel_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_CampaignBudget_MarketingCampaignChannel_Marketing_Campaign_ID_Campaign_Channel_ID.';
END;
GO

-- R28 rule: Marketing Campaign Channel -> Campaign Cost  (enforces: channel of a budget/cost row must be a channel of that campaign)
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
       OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
       STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
       f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
WHERE f.parent_object_id = OBJECT_ID(N'marketing.CampaignCost') AND f.name = N'FK_CampaignCost_MarketingCampaignChannel_Marketing_Campaign_ID_Campaign_Channel_ID'
GROUP BY f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'Marketing_Campaign_ID,Campaign_Channel_ID -> marketing.MarketingCampaignChannel(Marketing_Campaign_ID,Campaign_Channel_ID)|NO_ACTION|NO_ACTION' COLLATE Latin1_General_BIN2
BEGIN
    ALTER TABLE marketing.CampaignCost DROP CONSTRAINT FK_CampaignCost_MarketingCampaignChannel_Marketing_Campaign_ID_Campaign_Channel_ID;
    PRINT N'FK_CampaignCost_MarketingCampaignChannel_Marketing_Campaign_ID_Campaign_Channel_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    ALTER TABLE marketing.CampaignCost WITH CHECK ADD CONSTRAINT FK_CampaignCost_MarketingCampaignChannel_Marketing_Campaign_ID_Campaign_Channel_ID
        FOREIGN KEY (Marketing_Campaign_ID, Campaign_Channel_ID) REFERENCES marketing.MarketingCampaignChannel (Marketing_Campaign_ID, Campaign_Channel_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION;
    PRINT N'Created FK_CampaignCost_MarketingCampaignChannel_Marketing_Campaign_ID_Campaign_Channel_ID.';
END;
GO

/* ========================================================================
   5. Constraint status: every CHECK and FOREIGN KEY must be enabled and trusted (existing rows validated)
   ======================================================================== */

DECLARE @tbl nvarchar(300), @con sysname, @sql nvarchar(max), @n int = 0;
DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT QUOTENAME(OBJECT_SCHEMA_NAME(k.parent_object_id)) + N'.' + QUOTENAME(OBJECT_NAME(k.parent_object_id)), k.name
    FROM (SELECT parent_object_id, name, is_disabled, is_not_trusted FROM sys.check_constraints
          UNION ALL SELECT parent_object_id, name, is_disabled, is_not_trusted FROM sys.foreign_keys) k
    WHERE (k.is_disabled = 1 OR k.is_not_trusted = 1)
      AND k.parent_object_id IN (SELECT OBJECT_ID(n) FROM (VALUES (N'ref.ProductCategory'), (N'ref.Package'), (N'core.Brand'), (N'core.Product'), (N'core.SKU'), (N'marketing.ProductPrice'), (N'marketing.CampaignChannel'), (N'marketing.CampaignAudience'), (N'marketing.MarketingCampaign'), (N'marketing.MarketingCampaignChannel'), (N'marketing.MarketingCampaignAudience'), (N'marketing.CampaignBudget'), (N'marketing.CampaignCost'), (N'marketing.CampaignResult'), (N'marketing.Promotion'), (N'marketing.BrandActivity'), (N'marketing.Market'), (N'marketing.MarketSegment'), (N'marketing.MarketResearch'), (N'marketing.MarketSurvey'), (N'marketing.ResearchResult'), (N'marketing.Competitor'), (N'marketing.CompetitorProduct'), (N'marketing.MarketPrice')) v(n));
OPEN c; FETCH NEXT FROM c INTO @tbl, @con;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'ALTER TABLE ' + @tbl + N' WITH CHECK CHECK CONSTRAINT ' + QUOTENAME(@con) + N';';
    EXEC (@sql);
    PRINT N'Re-enabled and validated ' + @con + N' (it was disabled or not trusted).';
    SET @n += 1;
    FETCH NEXT FROM c INTO @tbl, @con;
END;
CLOSE c; DEALLOCATE c;
PRINT CONCAT(N'Constraint status checked: ', @n, N' constraint(s) had to be re-enabled.');
GO

/* ========================================================================
   6. Integrity triggers for rules that depend on several rows (a CHECK constraint cannot see other rows)
   ======================================================================== */

-- TR_ProductPrice_NoOverlap: raises error 51001 and rolls the statement back when the rule is broken.
-- Created through EXEC so that the batch also compiles when the prerequisite check above has stopped the script.
IF OBJECT_ID(N'marketing.ProductPrice', N'U') IS NOT NULL
BEGIN
    EXEC (N'
CREATE OR ALTER TRIGGER marketing.TR_ProductPrice_NoOverlap
ON marketing.ProductPrice
AFTER INSERT, UPDATE
AS
BEGIN
    /* Stage 6 rule (Product Price): for one SKU_ID and one Price_Type the validity periods must not overlap.
       Effective_To NULL means open-ended. Every inserted or updated row is compared with all rows of the same
       SKU_ID and Price_Type, including the other rows of the same statement. Uses IX_ProductPrice_SKU_ID_Price_Type_Effective_From. */
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        JOIN marketing.ProductPrice AS p
          ON  p.SKU_ID = i.SKU_ID
          AND p.Price_Type = i.Price_Type
          AND p.Product_Price_ID <> i.Product_Price_ID
          AND p.Effective_From <= ISNULL(i.Effective_To, ''9999-12-31'')
          AND i.Effective_From <= ISNULL(p.Effective_To, ''9999-12-31''))
    BEGIN
        THROW 51001, N''ProductPrice: the validity period overlaps another price of the same SKU_ID and Price_Type.'', 1;
    END;
END;
');
    EXEC (N'ENABLE TRIGGER marketing.TR_ProductPrice_NoOverlap ON marketing.ProductPrice;');
    PRINT N'Trigger marketing.TR_ProductPrice_NoOverlap is in place and enabled (CREATE OR ALTER).';
END;
GO

-- TR_ProductCategory_Hierarchy: raises error 51002 / 51003 and rolls the statement back when the rule is broken.
-- Created through EXEC so that the batch also compiles when the prerequisite check above has stopped the script.
IF OBJECT_ID(N'ref.ProductCategory', N'U') IS NOT NULL
BEGIN
    EXEC (N'
CREATE OR ALTER TRIGGER ref.TR_ProductCategory_Hierarchy
ON ref.ProductCategory
AFTER INSERT, UPDATE
AS
BEGIN
    /* Stage 6 rules (Product Category, R29): (1) no cycles in the parent chain; (2) Category_Level is 1 for a
       root and parent level + 1 for a child. Checked for the inserted/updated rows and for their direct children
       (a change of a parent''s level must move its children in the same statement). */
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;
    DECLARE @bad int;
    WITH up AS (
        SELECT i.Product_Category_ID AS Start_ID, c.Parent_Category_ID AS Ancestor_ID, 1 AS Depth
        FROM inserted AS i
        JOIN ref.ProductCategory AS c ON c.Product_Category_ID = i.Product_Category_ID
        WHERE c.Parent_Category_ID IS NOT NULL
        UNION ALL
        SELECT u.Start_ID, c.Parent_Category_ID, u.Depth + 1
        FROM up AS u
        JOIN ref.ProductCategory AS c ON c.Product_Category_ID = u.Ancestor_ID
        WHERE c.Parent_Category_ID IS NOT NULL AND u.Ancestor_ID <> u.Start_ID AND u.Depth < 100)
    SELECT @bad = COUNT(*) FROM up WHERE Ancestor_ID = Start_ID OR Depth >= 100;
    IF @bad > 0
    BEGIN
        THROW 51003, N''ProductCategory: the parent assignment creates a cycle in the category hierarchy.'', 1;
    END;
    IF EXISTS (
        SELECT 1
        FROM ref.ProductCategory AS c
        LEFT JOIN ref.ProductCategory AS p ON p.Product_Category_ID = c.Parent_Category_ID
        WHERE (c.Product_Category_ID IN (SELECT Product_Category_ID FROM inserted)
               OR c.Parent_Category_ID IN (SELECT Product_Category_ID FROM inserted))
          AND c.Category_Level <> ISNULL(p.Category_Level + 1, 1))
    BEGIN
        THROW 51002, N''ProductCategory: Category_Level must be 1 for a root category and the parent level + 1 for a child category.'', 1;
    END;
END;
');
    EXEC (N'ENABLE TRIGGER ref.TR_ProductCategory_Hierarchy ON ref.ProductCategory;');
    PRINT N'Trigger ref.TR_ProductCategory_Hierarchy is in place and enabled (CREATE OR ALTER).';
END;
GO

/* ---- Verification: existing structure is compared with the expected definition (not assumed to be correct) ---- */
DECLARE @E TABLE (kind nvarchar(10), obj sysname, parent nvarchar(300), sig nvarchar(max));
INSERT @E VALUES
    (N'UQ', N'UQ_ProductCategory_Category_Code', N'ref.ProductCategory', N'NONCLUSTERED|UNIQUE|Category_Code||'),
    (N'UQ', N'UQ_Package_Package_Code', N'ref.Package', N'NONCLUSTERED|UNIQUE|Package_Code||'),
    (N'UQ', N'UQ_Brand_Brand_Code', N'core.Brand', N'NONCLUSTERED|UNIQUE|Brand_Code||'),
    (N'UQ', N'UQ_Product_Product_Code', N'core.Product', N'NONCLUSTERED|UNIQUE|Product_Code||'),
    (N'UQ', N'UQ_SKU_SKU_Code', N'core.SKU', N'NONCLUSTERED|UNIQUE|SKU_Code||'),
    (N'UX', N'UQ_SKU_Barcode', N'core.SKU', N'NONCLUSTERED|UNIQUE|Barcode||([Barcode] IS NOT NULL)'),
    (N'UQ', N'UQ_Promotion_Promotion_Code', N'marketing.Promotion', N'NONCLUSTERED|UNIQUE|Promotion_Code||'),
    (N'UQ', N'UQ_Market_Market_Code', N'marketing.Market', N'NONCLUSTERED|UNIQUE|Market_Code||'),
    (N'UQ', N'UQ_MarketSegment_Segment_Code', N'marketing.MarketSegment', N'NONCLUSTERED|UNIQUE|Segment_Code||'),
    (N'UQ', N'UQ_CampaignResult_Marketing_Campaign_ID_Metric_Name_Measurement_Date', N'marketing.CampaignResult', N'NONCLUSTERED|UNIQUE|Marketing_Campaign_ID,Metric_Name,Measurement_Date||'),
    (N'CK', N'CK_Brand_Brand_End_Date', N'core.Brand', N'([Brand_End_Date] IS NULL OR [Brand_Start_Date] IS NOT NULL AND [Brand_End_Date]>=[Brand_Start_Date])'),
    (N'CK', N'CK_Brand_Brand_Country', N'core.Brand', N'(([Brand_Country]) collate Latin1_General_BIN like ''[A-Z][A-Z]'')'),
    (N'CK', N'CK_Product_Weight', N'core.Product', N'([Weight]>(0))'),
    (N'CK', N'CK_Product_Tax_Rate', N'core.Product', N'([Tax_Rate]>=(0) AND [Tax_Rate]<=(100))'),
    (N'CK', N'CK_Product_Product_Updated_Date', N'core.Product', N'([Product_Updated_Date]>=[Product_Created_Date])'),
    (N'CK', N'CK_ProductCategory_Parent_Category_ID', N'ref.ProductCategory', N'([Parent_Category_ID]<>[Product_Category_ID])'),
    (N'CK', N'CK_ProductCategory_Category_Level', N'ref.ProductCategory', N'([Category_Level]>=(1))'),
    (N'CK', N'CK_SKU_Weight', N'core.SKU', N'([Weight]>(0))'),
    (N'CK', N'CK_SKU_Standard_Cost', N'core.SKU', N'([Standard_Cost]>=(0))'),
    (N'CK', N'CK_SKU_Currency', N'core.SKU', N'(([Currency]) collate Latin1_General_BIN like ''[A-Z][A-Z][A-Z]'')'),
    (N'CK', N'CK_SKU_Standard_Cost_Currency', N'core.SKU', N'([Standard_Cost] IS NULL OR [Currency] IS NOT NULL)'),
    (N'CK', N'CK_ProductPrice_Unit_Price', N'marketing.ProductPrice', N'([Unit_Price]>=(0))'),
    (N'CK', N'CK_ProductPrice_Effective_To', N'marketing.ProductPrice', N'([Effective_To]>=[Effective_From])'),
    (N'CK', N'CK_ProductPrice_Currency', N'marketing.ProductPrice', N'(([Currency]) collate Latin1_General_BIN like ''[A-Z][A-Z][A-Z]'')'),
    (N'CK', N'CK_CampaignChannel_Channel_Status', N'marketing.CampaignChannel', N'([Channel_Status]=N''Inactive'' OR [Channel_Status]=N''Active'')'),
    (N'CK', N'CK_CampaignAudience_Audience_Status', N'marketing.CampaignAudience', N'([Audience_Status]=N''Inactive'' OR [Audience_Status]=N''Active'')'),
    (N'CK', N'CK_MarketingCampaign_End_Date', N'marketing.MarketingCampaign', N'([End_Date]>=[Start_Date])'),
    (N'CK', N'CK_MarketingCampaign_Campaign_Purpose', N'marketing.MarketingCampaign', N'([Campaign_Purpose]=N''Marketing'' OR [Campaign_Purpose]=N''Brand'')'),
    (N'CK', N'CK_MarketingCampaign_Brand_ID', N'marketing.MarketingCampaign', N'([Campaign_Purpose]<>N''Brand'' OR [Brand_ID] IS NOT NULL)'),
    (N'CK', N'CK_CampaignBudget_Total_Allocated_Amount', N'marketing.CampaignBudget', N'([Total_Allocated_Amount]>=(0))'),
    (N'CK', N'CK_CampaignBudget_Currency', N'marketing.CampaignBudget', N'(([Currency]) collate Latin1_General_BIN like ''[A-Z][A-Z][A-Z]'')'),
    (N'CK', N'CK_CampaignCost_Actual_Spent', N'marketing.CampaignCost', N'([Actual_Spent]>=(0))'),
    (N'CK', N'CK_CampaignCost_Currency', N'marketing.CampaignCost', N'(([Currency]) collate Latin1_General_BIN like ''[A-Z][A-Z][A-Z]'')'),
    (N'CK', N'CK_Promotion_End_Date', N'marketing.Promotion', N'([End_Date]>=[Start_Date])'),
    (N'CK', N'CK_Promotion_Discount_Type', N'marketing.Promotion', N'([Discount_Type]=N''Fixed Amount'' OR [Discount_Type]=N''Percentage'')'),
    (N'CK', N'CK_Promotion_Discount_Value', N'marketing.Promotion', N'([Discount_Value]>=(0) AND ([Discount_Type]<>N''Percentage'' OR [Discount_Value]<=(100)))'),
    (N'CK', N'CK_Promotion_Discount_Type_Currency', N'marketing.Promotion', N'([Discount_Type]<>N''Fixed Amount'' OR [Currency] IS NOT NULL)'),
    (N'CK', N'CK_Promotion_Currency', N'marketing.Promotion', N'(([Currency]) collate Latin1_General_BIN like ''[A-Z][A-Z][A-Z]'')'),
    (N'CK', N'CK_BrandActivity_Activity_End_Date', N'marketing.BrandActivity', N'([Activity_End_Date] IS NULL OR [Activity_Start_Date] IS NOT NULL AND [Activity_End_Date]>=[Activity_Start_Date])'),
    (N'CK', N'CK_BrandActivity_Activity_Cost', N'marketing.BrandActivity', N'([Activity_Cost]>=(0))'),
    (N'CK', N'CK_BrandActivity_Currency', N'marketing.BrandActivity', N'(([Currency]) collate Latin1_General_BIN like ''[A-Z][A-Z][A-Z]'')'),
    (N'CK', N'CK_BrandActivity_Activity_Cost_Currency', N'marketing.BrandActivity', N'([Activity_Cost] IS NULL OR [Currency] IS NOT NULL)'),
    (N'CK', N'CK_MarketSegment_Segmentation_Basis', N'marketing.MarketSegment', N'([Segmentation_Basis]=N''Behavioral'' OR [Segmentation_Basis]=N''Demographic'' OR [Segmentation_Basis]=N''Geographic'')'),
    (N'CK', N'CK_MarketResearch_End_Date', N'marketing.MarketResearch', N'([End_Date]>=[Start_Date])'),
    (N'CK', N'CK_MarketResearch_Research_Cost', N'marketing.MarketResearch', N'([Research_Cost]>=(0))'),
    (N'CK', N'CK_MarketResearch_Currency', N'marketing.MarketResearch', N'(([Currency]) collate Latin1_General_BIN like ''[A-Z][A-Z][A-Z]'')'),
    (N'CK', N'CK_MarketResearch_Research_Cost_Currency', N'marketing.MarketResearch', N'([Research_Cost] IS NULL OR [Currency] IS NOT NULL)'),
    (N'CK', N'CK_MarketSurvey_Sample_Size', N'marketing.MarketSurvey', N'([Sample_Size]>(0))'),
    (N'CK', N'CK_MarketPrice_Product_ID_Competitor_Product_ID', N'marketing.MarketPrice', N'([Product_ID] IS NOT NULL AND [Competitor_Product_ID] IS NULL OR [Product_ID] IS NULL AND [Competitor_Product_ID] IS NOT NULL)'),
    (N'CK', N'CK_MarketPrice_Price_Value', N'marketing.MarketPrice', N'([Price_Value]>=(0))'),
    (N'CK', N'CK_MarketPrice_Currency', N'marketing.MarketPrice', N'(([Currency]) collate Latin1_General_BIN like ''[A-Z][A-Z][A-Z]'')'),
    (N'DF', N'DF_Product_Product_Created_Date', N'core.Product', N'Product_Created_Date=(sysdatetime())'),
    (N'FK', N'FK_Product_ProductCategory_Product_Category_ID', N'core.Product', N'Product_Category_ID -> ref.ProductCategory(Product_Category_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_Product_Brand_Brand_ID', N'core.Product', N'Brand_ID -> core.Brand(Brand_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_SKU_Product_Product_ID', N'core.SKU', N'Product_ID -> core.Product(Product_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_MarketPrice_Product_Product_ID', N'marketing.MarketPrice', N'Product_ID -> core.Product(Product_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_SKU_Package_Package_ID', N'core.SKU', N'Package_ID -> ref.Package(Package_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_ProductPrice_SKU_SKU_ID', N'marketing.ProductPrice', N'SKU_ID -> core.SKU(SKU_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_BrandActivity_Brand_Brand_ID', N'marketing.BrandActivity', N'Brand_ID -> core.Brand(Brand_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_MarketingCampaign_Brand_Brand_ID', N'marketing.MarketingCampaign', N'Brand_ID -> core.Brand(Brand_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_MarketingCampaignChannel_MarketingCampaign_Marketing_Campaign_ID', N'marketing.MarketingCampaignChannel', N'Marketing_Campaign_ID -> marketing.MarketingCampaign(Marketing_Campaign_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_MarketingCampaignChannel_CampaignChannel_Campaign_Channel_ID', N'marketing.MarketingCampaignChannel', N'Campaign_Channel_ID -> marketing.CampaignChannel(Campaign_Channel_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_MarketingCampaignAudience_MarketingCampaign_Marketing_Campaign_ID', N'marketing.MarketingCampaignAudience', N'Marketing_Campaign_ID -> marketing.MarketingCampaign(Marketing_Campaign_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_MarketingCampaignAudience_CampaignAudience_Campaign_Audience_ID', N'marketing.MarketingCampaignAudience', N'Campaign_Audience_ID -> marketing.CampaignAudience(Campaign_Audience_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_CampaignBudget_MarketingCampaign_Marketing_Campaign_ID', N'marketing.CampaignBudget', N'Marketing_Campaign_ID -> marketing.MarketingCampaign(Marketing_Campaign_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_CampaignCost_MarketingCampaign_Marketing_Campaign_ID', N'marketing.CampaignCost', N'Marketing_Campaign_ID -> marketing.MarketingCampaign(Marketing_Campaign_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_CampaignResult_MarketingCampaign_Marketing_Campaign_ID', N'marketing.CampaignResult', N'Marketing_Campaign_ID -> marketing.MarketingCampaign(Marketing_Campaign_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_Promotion_MarketingCampaign_Marketing_Campaign_ID', N'marketing.Promotion', N'Marketing_Campaign_ID -> marketing.MarketingCampaign(Marketing_Campaign_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_MarketSegment_Market_Market_ID', N'marketing.MarketSegment', N'Market_ID -> marketing.Market(Market_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_MarketResearch_Market_Market_ID', N'marketing.MarketResearch', N'Market_ID -> marketing.Market(Market_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_MarketPrice_Market_Market_ID', N'marketing.MarketPrice', N'Market_ID -> marketing.Market(Market_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_Competitor_Market_Market_ID', N'marketing.Competitor', N'Market_ID -> marketing.Market(Market_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_MarketSurvey_MarketSegment_Market_Segment_ID', N'marketing.MarketSurvey', N'Market_Segment_ID -> marketing.MarketSegment(Market_Segment_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_MarketSurvey_MarketResearch_Market_Research_ID', N'marketing.MarketSurvey', N'Market_Research_ID -> marketing.MarketResearch(Market_Research_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_ResearchResult_MarketResearch_Market_Research_ID', N'marketing.ResearchResult', N'Market_Research_ID -> marketing.MarketResearch(Market_Research_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_CompetitorProduct_Competitor_Competitor_ID', N'marketing.CompetitorProduct', N'Competitor_ID -> marketing.Competitor(Competitor_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_MarketPrice_CompetitorProduct_Competitor_Product_ID', N'marketing.MarketPrice', N'Competitor_Product_ID -> marketing.CompetitorProduct(Competitor_Product_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_CampaignBudget_CampaignChannel_Campaign_Channel_ID', N'marketing.CampaignBudget', N'Campaign_Channel_ID -> marketing.CampaignChannel(Campaign_Channel_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_CampaignCost_CampaignChannel_Campaign_Channel_ID', N'marketing.CampaignCost', N'Campaign_Channel_ID -> marketing.CampaignChannel(Campaign_Channel_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_ProductCategory_ProductCategory_Parent_Category_ID', N'ref.ProductCategory', N'Parent_Category_ID -> ref.ProductCategory(Product_Category_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_CampaignBudget_MarketingCampaignChannel_Marketing_Campaign_ID_Campaign_Channel_ID', N'marketing.CampaignBudget', N'Marketing_Campaign_ID,Campaign_Channel_ID -> marketing.MarketingCampaignChannel(Marketing_Campaign_ID,Campaign_Channel_ID)|NO_ACTION|NO_ACTION'),
    (N'FK', N'FK_CampaignCost_MarketingCampaignChannel_Marketing_Campaign_ID_Campaign_Channel_ID', N'marketing.CampaignCost', N'Marketing_Campaign_ID,Campaign_Channel_ID -> marketing.MarketingCampaignChannel(Marketing_Campaign_ID,Campaign_Channel_ID)|NO_ACTION|NO_ACTION'),
    (N'TR', N'TR_ProductPrice_NoOverlap', N'marketing.ProductPrice', N'marketing.ProductPrice|AFTER|INSERT,UPDATE|ENABLED'),
    (N'TR', N'TR_ProductCategory_Hierarchy', N'ref.ProductCategory', N'ref.ProductCategory|AFTER|INSERT,UPDATE|ENABLED');
DECLARE @D TABLE (kind nvarchar(10), obj sysname, problem nvarchar(max));
WITH tbl AS (SELECT OBJECT_ID(n) AS object_id, n AS full_name FROM (VALUES (N'ref.ProductCategory'), (N'ref.Package'), (N'core.Brand'), (N'core.Product'), (N'core.SKU'), (N'marketing.ProductPrice'), (N'marketing.CampaignChannel'), (N'marketing.CampaignAudience'), (N'marketing.MarketingCampaign'), (N'marketing.MarketingCampaignChannel'), (N'marketing.MarketingCampaignAudience'), (N'marketing.CampaignBudget'), (N'marketing.CampaignCost'), (N'marketing.CampaignResult'), (N'marketing.Promotion'), (N'marketing.BrandActivity'), (N'marketing.Market'), (N'marketing.MarketSegment'), (N'marketing.MarketResearch'), (N'marketing.MarketSurvey'), (N'marketing.ResearchResult'), (N'marketing.Competitor'), (N'marketing.CompetitorProduct'), (N'marketing.MarketPrice')) v(n) WHERE OBJECT_ID(n) IS NOT NULL),
icols AS (
    SELECT i.object_id, i.index_id, i.name, i.type_desc, i.is_unique, i.is_primary_key, i.is_unique_constraint, i.filter_definition,
           STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',')
               WITHIN GROUP (ORDER BY ic.key_ordinal, col.name) AS keys,
           STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',')
               WITHIN GROUP (ORDER BY ic.key_ordinal, col.name) AS incs
    FROM sys.indexes i
    JOIN tbl t ON t.object_id = i.object_id
    JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
    GROUP BY i.object_id, i.index_id, i.name, i.type_desc, i.is_unique, i.is_primary_key, i.is_unique_constraint, i.filter_definition),
act AS (
    SELECT N'TABLE' AS kind, t.full_name AS obj, t.full_name AS parent,
           (SELECT STRING_AGG(CONCAT(CAST(c.name AS nvarchar(max)), N' ', CASE WHEN ty.name IN (N'nvarchar', N'nchar') THEN ty.name + N'(' + CASE WHEN c.max_length = -1 THEN N'max' ELSE CAST(c.max_length / 2 AS nvarchar(10)) END + N')' WHEN ty.name IN (N'varchar', N'char') THEN ty.name + N'(' + CASE WHEN c.max_length = -1 THEN N'max' ELSE CAST(c.max_length AS nvarchar(10)) END + N')' WHEN ty.name IN (N'decimal', N'numeric') THEN ty.name + N'(' + CAST(c.precision AS nvarchar(10)) + N',' + CAST(c.scale AS nvarchar(10)) + N')' WHEN ty.name = N'datetime2' THEN N'datetime2(' + CAST(c.scale AS nvarchar(10)) + N')' ELSE ty.name END, IIF(c.is_nullable = 1, N' NULL', N' NOT NULL'), IIF(c.is_identity = 1, N' IDENTITY', N'')), N'; ')
                   WITHIN GROUP (ORDER BY c.column_id)
            FROM sys.columns c JOIN sys.types ty ON ty.user_type_id = c.user_type_id WHERE c.object_id = t.object_id) AS sig
    FROM tbl t
    UNION ALL
    SELECT CASE WHEN x.is_primary_key = 1 THEN N'PK' WHEN x.is_unique_constraint = 1 THEN N'UQ' WHEN x.is_unique = 1 THEN N'UX' ELSE N'IX' END,
           x.name, t.full_name,
           CASE WHEN x.is_primary_key = 1 THEN CONCAT(x.type_desc, N':', x.keys)
                ELSE CONCAT(x.type_desc, N'|', IIF(x.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|', x.keys, N'|', x.incs, N'|', x.filter_definition) END
    FROM icols x JOIN tbl t ON t.object_id = x.object_id
    UNION ALL
    SELECT N'CK', k.name, t.full_name, k.definition FROM sys.check_constraints k JOIN tbl t ON t.object_id = k.parent_object_id
    UNION ALL
    SELECT N'DF', d.name, t.full_name, CONCAT(col.name, N'=', d.definition)
    FROM sys.default_constraints d JOIN tbl t ON t.object_id = d.parent_object_id
    JOIN sys.columns col ON col.object_id = d.parent_object_id AND col.column_id = d.parent_column_id
    UNION ALL
    SELECT N'FK', f.name, t.full_name,
           CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
                  OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
                  STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
                  f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
    FROM sys.foreign_keys f JOIN tbl t ON t.object_id = f.parent_object_id
    JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
    JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
    JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
    GROUP BY f.name, t.full_name, f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc
    UNION ALL
    SELECT N'TR', tr.name, t.full_name,
           CONCAT(t.full_name, N'|', IIF(tr.is_instead_of_trigger = 1, N'INSTEAD OF', N'AFTER'), N'|',
                  (SELECT STRING_AGG(CAST(te.type_desc AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY te.type_desc) FROM sys.trigger_events te WHERE te.object_id = tr.object_id),
                  N'|', IIF(tr.is_disabled = 1, N'DISABLED', N'ENABLED'))
    FROM sys.triggers tr JOIN tbl t ON t.object_id = tr.parent_id)
INSERT @D
SELECT COALESCE(e.kind, a.kind), COALESCE(e.obj, a.obj),
       CASE WHEN a.obj IS NULL THEN N'missing'
            WHEN e.obj IS NULL THEN N'unexpected object: ' + a.sig
            ELSE N'expected [' + e.sig + N'] actual [' + a.sig + N']' END
FROM @E e
FULL JOIN (SELECT * FROM act WHERE kind IN (N'UQ', N'UX', N'CK', N'DF', N'FK', N'TR')) a
  ON a.kind = e.kind AND a.obj COLLATE Latin1_General_BIN2 = e.obj COLLATE Latin1_General_BIN2 AND a.parent COLLATE Latin1_General_BIN2 = e.parent COLLATE Latin1_General_BIN2
WHERE a.obj IS NULL OR e.obj IS NULL OR a.sig COLLATE Latin1_General_BIN2 <> e.sig COLLATE Latin1_General_BIN2;
DECLARE @nE int = (SELECT COUNT(*) FROM @E), @nD int = (SELECT COUNT(*) FROM @D), @line nvarchar(max);
IF @nD = 0
    PRINT CONCAT(N'Verification passed: all ', @nE, N' UNIQUE, CHECK, DEFAULT, FOREIGN KEY and trigger definitions match the expected definition.');
ELSE
BEGIN
    DECLARE d CURSOR LOCAL FAST_FORWARD FOR SELECT CONCAT(N'  DIFFERENCE ', kind, N' ', obj, N': ', problem) FROM @D;
    OPEN d; FETCH NEXT FROM d INTO @line;
    WHILE @@FETCH_STATUS = 0 BEGIN PRINT @line; FETCH NEXT FROM d INTO @line; END;
    CLOSE d; DEALLOCATE d;
    RAISERROR(N'Verification FAILED: %d object(s) differ from the expected definition (see the lines above).', 16, 1, @nD);
END;
GO

SET NOEXEC OFF;
GO
PRINT N'07-Team2-04-Create-Constraints.sql finished.';
GO


/*=============================================================================
  STAGE 3.3 - CREATE INDEXES
=============================================================================*/


/*---------------- SOURCE FILE: 07-Team1-03-Create-Indexes.sql ----------------*/
/*
    Project : Food Distribution (Etemad Iranian Food Distribution)
    Stage   : 7 - Physical Data Model
    Team    : Team 1 - Sales & Customer
    Database: FoodDistributionDB
    SQL Server: 2022
    File    : 07-Team1-03-Create-Indexes.sql
    Purpose : Nonclustered indexes that support FOREIGN KEY joins and FK checks on delete of the parent row.
    Run order: 3 (after 07-Team1-02-Create-Constraints.sql)
    Prerequisites: All 24 Team 1 tables exist (07-Team1-01-Create-Tables.sql).
    Source  : 06-Team1-Sales-Customer-Logical-Data-Model.xlsx (Stage 6)
    Schemas : Team 1 proposal for the Entity-to-Schema matrix (ref / core / sales); not yet approved
    Re-run  : Safe. Every object is created only if it does not already exist.
*/

USE [FoodDistributionDB];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

/* ---- Prerequisite check: stop the whole script if a prerequisite is missing ---- */
IF OBJECT_ID(N'ref.Province', N'U') IS NULL
   OR OBJECT_ID(N'ref.City', N'U') IS NULL
   OR OBJECT_ID(N'ref.CustomerSegment', N'U') IS NULL
   OR OBJECT_ID(N'ref.SalesChannel', N'U') IS NULL
   OR OBJECT_ID(N'ref.SalesRegion', N'U') IS NULL
   OR OBJECT_ID(N'ref.SalesTerritory', N'U') IS NULL
   OR OBJECT_ID(N'core.Calendar', N'U') IS NULL
   OR OBJECT_ID(N'core.Branch', N'U') IS NULL
   OR OBJECT_ID(N'core.Salesperson', N'U') IS NULL
   OR OBJECT_ID(N'core.Customer', N'U') IS NULL
   OR OBJECT_ID(N'sales.Lead', N'U') IS NULL
   OR OBJECT_ID(N'sales.CustomerInteraction', N'U') IS NULL
   OR OBJECT_ID(N'sales.SalesOpportunity', N'U') IS NULL
   OR OBJECT_ID(N'sales.Contract', N'U') IS NULL
   OR OBJECT_ID(N'sales.SalesOrder', N'U') IS NULL
   OR OBJECT_ID(N'sales.SalesOrderItem', N'U') IS NULL
   OR OBJECT_ID(N'sales.Invoice', N'U') IS NULL
   OR OBJECT_ID(N'sales.InvoiceItem', N'U') IS NULL
   OR OBJECT_ID(N'sales.Payment', N'U') IS NULL
   OR OBJECT_ID(N'sales.ReturnRequest', N'U') IS NULL
   OR OBJECT_ID(N'sales.CustomerFeedback', N'U') IS NULL
   OR OBJECT_ID(N'sales.Commission', N'U') IS NULL
   OR OBJECT_ID(N'sales.SalesTarget', N'U') IS NULL
   OR OBJECT_ID(N'sales.SalesForecast', N'U') IS NULL
BEGIN
    RAISERROR(N'Team 1 tables are missing. Run 07-Team1-01-Create-Tables.sql first.', 16, 1);
    SET NOEXEC ON;
END;
GO

/* ========================================================================
   Nonclustered indexes (one per FK unless the PK or a UNIQUE key already starts with the FK column;
   optional FKs get a filtered index WHERE column IS NOT NULL)
   ======================================================================== */

-- FK_City_Province_Province_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_City_Province_ID' AND object_id = OBJECT_ID(N'ref.City'))
    CREATE NONCLUSTERED INDEX IX_City_Province_ID ON ref.City (Province_ID);
GO

-- FK_City_City_Parent_City_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_City_Parent_City_ID' AND object_id = OBJECT_ID(N'ref.City'))
    CREATE NONCLUSTERED INDEX IX_City_Parent_City_ID ON ref.City (Parent_City_ID) WHERE Parent_City_ID IS NOT NULL;
GO

-- FK_SalesRegion_SalesRegion_Parent_Sales_Region_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesRegion_Parent_Sales_Region_ID' AND object_id = OBJECT_ID(N'ref.SalesRegion'))
    CREATE NONCLUSTERED INDEX IX_SalesRegion_Parent_Sales_Region_ID ON ref.SalesRegion (Parent_Sales_Region_ID) WHERE Parent_Sales_Region_ID IS NOT NULL;
GO

-- FK_Branch_SalesRegion_Sales_Region_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Branch_Sales_Region_ID' AND object_id = OBJECT_ID(N'core.Branch'))
    CREATE NONCLUSTERED INDEX IX_Branch_Sales_Region_ID ON core.Branch (Sales_Region_ID);
GO

-- FK_Salesperson_Branch_Branch_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Salesperson_Branch_ID' AND object_id = OBJECT_ID(N'core.Salesperson'))
    CREATE NONCLUSTERED INDEX IX_Salesperson_Branch_ID ON core.Salesperson (Branch_ID) WHERE Branch_ID IS NOT NULL;
GO

-- FK_Salesperson_Salesperson_Manager_Salesperson_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Salesperson_Manager_Salesperson_ID' AND object_id = OBJECT_ID(N'core.Salesperson'))
    CREATE NONCLUSTERED INDEX IX_Salesperson_Manager_Salesperson_ID ON core.Salesperson (Manager_Salesperson_ID) WHERE Manager_Salesperson_ID IS NOT NULL;
GO

-- FK_Customer_City_City_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Customer_City_ID' AND object_id = OBJECT_ID(N'core.Customer'))
    CREATE NONCLUSTERED INDEX IX_Customer_City_ID ON core.Customer (City_ID) WHERE City_ID IS NOT NULL;
GO

-- FK_Customer_CustomerSegment_Customer_Segment_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Customer_Customer_Segment_ID' AND object_id = OBJECT_ID(N'core.Customer'))
    CREATE NONCLUSTERED INDEX IX_Customer_Customer_Segment_ID ON core.Customer (Customer_Segment_ID) WHERE Customer_Segment_ID IS NOT NULL;
GO

-- FK_Customer_SalesChannel_Sales_Channel_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Customer_Sales_Channel_ID' AND object_id = OBJECT_ID(N'core.Customer'))
    CREATE NONCLUSTERED INDEX IX_Customer_Sales_Channel_ID ON core.Customer (Sales_Channel_ID) WHERE Sales_Channel_ID IS NOT NULL;
GO

-- FK_Customer_SalesTerritory_Sales_Territory_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Customer_Sales_Territory_ID' AND object_id = OBJECT_ID(N'core.Customer'))
    CREATE NONCLUSTERED INDEX IX_Customer_Sales_Territory_ID ON core.Customer (Sales_Territory_ID) WHERE Sales_Territory_ID IS NOT NULL;
GO

-- FK_Customer_Salesperson_Salesperson_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Customer_Salesperson_ID' AND object_id = OBJECT_ID(N'core.Customer'))
    CREATE NONCLUSTERED INDEX IX_Customer_Salesperson_ID ON core.Customer (Salesperson_ID) WHERE Salesperson_ID IS NOT NULL;
GO

-- FK_Lead_Salesperson_Salesperson_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Lead_Salesperson_ID' AND object_id = OBJECT_ID(N'sales.Lead'))
    CREATE NONCLUSTERED INDEX IX_Lead_Salesperson_ID ON sales.Lead (Salesperson_ID) WHERE Salesperson_ID IS NOT NULL;
GO

-- FK_CustomerInteraction_Customer_Customer_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CustomerInteraction_Customer_ID' AND object_id = OBJECT_ID(N'sales.CustomerInteraction'))
    CREATE NONCLUSTERED INDEX IX_CustomerInteraction_Customer_ID ON sales.CustomerInteraction (Customer_ID);
GO

-- FK_CustomerInteraction_Salesperson_Salesperson_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CustomerInteraction_Salesperson_ID' AND object_id = OBJECT_ID(N'sales.CustomerInteraction'))
    CREATE NONCLUSTERED INDEX IX_CustomerInteraction_Salesperson_ID ON sales.CustomerInteraction (Salesperson_ID) WHERE Salesperson_ID IS NOT NULL;
GO

-- FK_CustomerInteraction_SalesTerritory_Sales_Territory_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CustomerInteraction_Sales_Territory_ID' AND object_id = OBJECT_ID(N'sales.CustomerInteraction'))
    CREATE NONCLUSTERED INDEX IX_CustomerInteraction_Sales_Territory_ID ON sales.CustomerInteraction (Sales_Territory_ID) WHERE Sales_Territory_ID IS NOT NULL;
GO

-- FK_SalesOpportunity_Customer_Customer_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesOpportunity_Customer_ID' AND object_id = OBJECT_ID(N'sales.SalesOpportunity'))
    CREATE NONCLUSTERED INDEX IX_SalesOpportunity_Customer_ID ON sales.SalesOpportunity (Customer_ID) WHERE Customer_ID IS NOT NULL;
GO

-- FK_SalesOpportunity_Lead_Lead_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesOpportunity_Lead_ID' AND object_id = OBJECT_ID(N'sales.SalesOpportunity'))
    CREATE NONCLUSTERED INDEX IX_SalesOpportunity_Lead_ID ON sales.SalesOpportunity (Lead_ID) WHERE Lead_ID IS NOT NULL;
GO

-- FK_SalesOpportunity_Salesperson_Salesperson_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesOpportunity_Salesperson_ID' AND object_id = OBJECT_ID(N'sales.SalesOpportunity'))
    CREATE NONCLUSTERED INDEX IX_SalesOpportunity_Salesperson_ID ON sales.SalesOpportunity (Salesperson_ID);
GO

-- FK_Contract_Customer_Customer_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Contract_Customer_ID' AND object_id = OBJECT_ID(N'sales.Contract'))
    CREATE NONCLUSTERED INDEX IX_Contract_Customer_ID ON sales.Contract (Customer_ID);
GO

-- FK_Contract_SalesOpportunity_Sales_Opportunity_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Contract_Sales_Opportunity_ID' AND object_id = OBJECT_ID(N'sales.Contract'))
    CREATE NONCLUSTERED INDEX IX_Contract_Sales_Opportunity_ID ON sales.Contract (Sales_Opportunity_ID) WHERE Sales_Opportunity_ID IS NOT NULL;
GO

-- FK_Contract_Product_Product_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Contract_Product_ID' AND object_id = OBJECT_ID(N'sales.Contract'))
    CREATE NONCLUSTERED INDEX IX_Contract_Product_ID ON sales.Contract (Product_ID) WHERE Product_ID IS NOT NULL;
GO

-- FK_SalesOrder_Customer_Customer_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesOrder_Customer_ID' AND object_id = OBJECT_ID(N'sales.SalesOrder'))
    CREATE NONCLUSTERED INDEX IX_SalesOrder_Customer_ID ON sales.SalesOrder (Customer_ID);
GO

-- FK_SalesOrder_Salesperson_Salesperson_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesOrder_Salesperson_ID' AND object_id = OBJECT_ID(N'sales.SalesOrder'))
    CREATE NONCLUSTERED INDEX IX_SalesOrder_Salesperson_ID ON sales.SalesOrder (Salesperson_ID) WHERE Salesperson_ID IS NOT NULL;
GO

-- FK_SalesOrder_SalesChannel_Sales_Channel_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesOrder_Sales_Channel_ID' AND object_id = OBJECT_ID(N'sales.SalesOrder'))
    CREATE NONCLUSTERED INDEX IX_SalesOrder_Sales_Channel_ID ON sales.SalesOrder (Sales_Channel_ID);
GO

-- FK_SalesOrder_SalesRegion_Sales_Region_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesOrder_Sales_Region_ID' AND object_id = OBJECT_ID(N'sales.SalesOrder'))
    CREATE NONCLUSTERED INDEX IX_SalesOrder_Sales_Region_ID ON sales.SalesOrder (Sales_Region_ID) WHERE Sales_Region_ID IS NOT NULL;
GO

-- FK_SalesOrder_Promotion_Promotion_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesOrder_Promotion_ID' AND object_id = OBJECT_ID(N'sales.SalesOrder'))
    CREATE NONCLUSTERED INDEX IX_SalesOrder_Promotion_ID ON sales.SalesOrder (Promotion_ID) WHERE Promotion_ID IS NOT NULL;
GO

-- FK_SalesOrder_Contract_Contract_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesOrder_Contract_ID' AND object_id = OBJECT_ID(N'sales.SalesOrder'))
    CREATE NONCLUSTERED INDEX IX_SalesOrder_Contract_ID ON sales.SalesOrder (Contract_ID) WHERE Contract_ID IS NOT NULL;
GO

-- FK_SalesOrder_CustomerInteraction_Customer_Interaction_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesOrder_Customer_Interaction_ID' AND object_id = OBJECT_ID(N'sales.SalesOrder'))
    CREATE NONCLUSTERED INDEX IX_SalesOrder_Customer_Interaction_ID ON sales.SalesOrder (Customer_Interaction_ID) WHERE Customer_Interaction_ID IS NOT NULL;
GO

-- FK_SalesOrder_Calendar_Calendar_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesOrder_Calendar_ID' AND object_id = OBJECT_ID(N'sales.SalesOrder'))
    CREATE NONCLUSTERED INDEX IX_SalesOrder_Calendar_ID ON sales.SalesOrder (Calendar_ID);
GO

-- FK_SalesOrderItem_Product_Product_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesOrderItem_Product_ID' AND object_id = OBJECT_ID(N'sales.SalesOrderItem'))
    CREATE NONCLUSTERED INDEX IX_SalesOrderItem_Product_ID ON sales.SalesOrderItem (Product_ID);
GO

-- FK_Invoice_Customer_Customer_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Invoice_Customer_ID' AND object_id = OBJECT_ID(N'sales.Invoice'))
    CREATE NONCLUSTERED INDEX IX_Invoice_Customer_ID ON sales.Invoice (Customer_ID);
GO

-- FK_Invoice_SalesOrder_Sales_Order_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Invoice_Sales_Order_ID' AND object_id = OBJECT_ID(N'sales.Invoice'))
    CREATE NONCLUSTERED INDEX IX_Invoice_Sales_Order_ID ON sales.Invoice (Sales_Order_ID);
GO

-- FK_InvoiceItem_Invoice_Invoice_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_InvoiceItem_Invoice_ID' AND object_id = OBJECT_ID(N'sales.InvoiceItem'))
    CREATE NONCLUSTERED INDEX IX_InvoiceItem_Invoice_ID ON sales.InvoiceItem (Invoice_ID);
GO

-- FK_InvoiceItem_Product_Product_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_InvoiceItem_Product_ID' AND object_id = OBJECT_ID(N'sales.InvoiceItem'))
    CREATE NONCLUSTERED INDEX IX_InvoiceItem_Product_ID ON sales.InvoiceItem (Product_ID);
GO

-- FK_Payment_Customer_Customer_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Payment_Customer_ID' AND object_id = OBJECT_ID(N'sales.Payment'))
    CREATE NONCLUSTERED INDEX IX_Payment_Customer_ID ON sales.Payment (Customer_ID);
GO

-- FK_Payment_Invoice_Invoice_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Payment_Invoice_ID' AND object_id = OBJECT_ID(N'sales.Payment'))
    CREATE NONCLUSTERED INDEX IX_Payment_Invoice_ID ON sales.Payment (Invoice_ID) WHERE Invoice_ID IS NOT NULL;
GO

-- FK_Payment_SalesOrder_Sales_Order_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Payment_Sales_Order_ID' AND object_id = OBJECT_ID(N'sales.Payment'))
    CREATE NONCLUSTERED INDEX IX_Payment_Sales_Order_ID ON sales.Payment (Sales_Order_ID) WHERE Sales_Order_ID IS NOT NULL;
GO

-- FK_ReturnRequest_SalesOrderItem_Sales_Order_Item_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ReturnRequest_Sales_Order_Item_ID' AND object_id = OBJECT_ID(N'sales.ReturnRequest'))
    CREATE NONCLUSTERED INDEX IX_ReturnRequest_Sales_Order_Item_ID ON sales.ReturnRequest (Sales_Order_Item_ID);
GO

-- FK_ReturnRequest_Payment_Payment_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ReturnRequest_Payment_ID' AND object_id = OBJECT_ID(N'sales.ReturnRequest'))
    CREATE NONCLUSTERED INDEX IX_ReturnRequest_Payment_ID ON sales.ReturnRequest (Payment_ID) WHERE Payment_ID IS NOT NULL;
GO

-- FK_ReturnRequest_Calendar_Calendar_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ReturnRequest_Calendar_ID' AND object_id = OBJECT_ID(N'sales.ReturnRequest'))
    CREATE NONCLUSTERED INDEX IX_ReturnRequest_Calendar_ID ON sales.ReturnRequest (Calendar_ID);
GO

-- FK_CustomerFeedback_Customer_Customer_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CustomerFeedback_Customer_ID' AND object_id = OBJECT_ID(N'sales.CustomerFeedback'))
    CREATE NONCLUSTERED INDEX IX_CustomerFeedback_Customer_ID ON sales.CustomerFeedback (Customer_ID);
GO

-- FK_CustomerFeedback_SalesOrder_Sales_Order_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CustomerFeedback_Sales_Order_ID' AND object_id = OBJECT_ID(N'sales.CustomerFeedback'))
    CREATE NONCLUSTERED INDEX IX_CustomerFeedback_Sales_Order_ID ON sales.CustomerFeedback (Sales_Order_ID) WHERE Sales_Order_ID IS NOT NULL;
GO

-- FK_CustomerFeedback_Product_Product_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CustomerFeedback_Product_ID' AND object_id = OBJECT_ID(N'sales.CustomerFeedback'))
    CREATE NONCLUSTERED INDEX IX_CustomerFeedback_Product_ID ON sales.CustomerFeedback (Product_ID) WHERE Product_ID IS NOT NULL;
GO

-- FK_Commission_Calendar_Calendar_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Commission_Calendar_ID' AND object_id = OBJECT_ID(N'sales.Commission'))
    CREATE NONCLUSTERED INDEX IX_Commission_Calendar_ID ON sales.Commission (Calendar_ID);
GO

-- FK_SalesTarget_Calendar_Calendar_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesTarget_Calendar_ID' AND object_id = OBJECT_ID(N'sales.SalesTarget'))
    CREATE NONCLUSTERED INDEX IX_SalesTarget_Calendar_ID ON sales.SalesTarget (Calendar_ID);
GO

-- FK_SalesTarget_SalesRegion_Sales_Region_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesTarget_Sales_Region_ID' AND object_id = OBJECT_ID(N'sales.SalesTarget'))
    CREATE NONCLUSTERED INDEX IX_SalesTarget_Sales_Region_ID ON sales.SalesTarget (Sales_Region_ID) WHERE Sales_Region_ID IS NOT NULL;
GO

-- FK_SalesTarget_Salesperson_Salesperson_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesTarget_Salesperson_ID' AND object_id = OBJECT_ID(N'sales.SalesTarget'))
    CREATE NONCLUSTERED INDEX IX_SalesTarget_Salesperson_ID ON sales.SalesTarget (Salesperson_ID) WHERE Salesperson_ID IS NOT NULL;
GO

-- FK_SalesTarget_SalesChannel_Sales_Channel_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesTarget_Sales_Channel_ID' AND object_id = OBJECT_ID(N'sales.SalesTarget'))
    CREATE NONCLUSTERED INDEX IX_SalesTarget_Sales_Channel_ID ON sales.SalesTarget (Sales_Channel_ID) WHERE Sales_Channel_ID IS NOT NULL;
GO

-- FK_SalesTarget_Product_Product_ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SalesTarget_Product_ID' AND object_id = OBJECT_ID(N'sales.SalesTarget'))
    CREATE NONCLUSTERED INDEX IX_SalesTarget_Product_ID ON sales.SalesTarget (Product_ID) WHERE Product_ID IS NOT NULL;
GO

/* ---- Summary of Team 1 objects ---- */
DECLARE @t TABLE (object_id int PRIMARY KEY);
INSERT @t (object_id)
SELECT OBJECT_ID(n) FROM (VALUES (N'ref.Province'), (N'ref.City'), (N'ref.CustomerSegment'), (N'ref.SalesChannel'), (N'ref.SalesRegion'), (N'ref.SalesTerritory'), (N'core.Calendar'), (N'core.Branch'), (N'core.Salesperson'), (N'core.Customer'), (N'sales.Lead'), (N'sales.CustomerInteraction'), (N'sales.SalesOpportunity'), (N'sales.Contract'), (N'sales.SalesOrder'), (N'sales.SalesOrderItem'), (N'sales.Invoice'), (N'sales.InvoiceItem'), (N'sales.Payment'), (N'sales.ReturnRequest'), (N'sales.CustomerFeedback'), (N'sales.Commission'), (N'sales.SalesTarget'), (N'sales.SalesForecast')) v(n) WHERE OBJECT_ID(n) IS NOT NULL;
DECLARE @msg nvarchar(600) = CONCAT(
    N'Team 1 objects now in FoodDistributionDB: tables ', (SELECT COUNT(*) FROM @t),
    N', columns ', (SELECT COUNT(*) FROM sys.columns c JOIN @t t ON t.object_id = c.object_id),
    N', PK ', (SELECT COUNT(*) FROM sys.key_constraints k JOIN @t t ON t.object_id = k.parent_object_id WHERE k.type = 'PK'),
    N', UNIQUE ', (SELECT COUNT(*) FROM sys.key_constraints k JOIN @t t ON t.object_id = k.parent_object_id WHERE k.type = 'UQ')
                + (SELECT COUNT(*) FROM sys.indexes i JOIN @t t ON t.object_id = i.object_id WHERE i.is_unique = 1 AND i.has_filter = 1),
    N', CHECK ', (SELECT COUNT(*) FROM sys.check_constraints k JOIN @t t ON t.object_id = k.parent_object_id),
    N', DEFAULT ', (SELECT COUNT(*) FROM sys.default_constraints k JOIN @t t ON t.object_id = k.parent_object_id),
    N', FK ', (SELECT COUNT(*) FROM sys.foreign_keys k JOIN @t t ON t.object_id = k.parent_object_id),
    N', indexes ', (SELECT COUNT(*) FROM sys.indexes i JOIN @t t ON t.object_id = i.object_id WHERE i.type = 2 AND i.is_unique = 0),
    N'.');
PRINT @msg;
GO

SET NOEXEC OFF;
GO
PRINT N'07-Team1-03-Create-Indexes.sql finished.';
GO


/*---------------- SOURCE FILE: 07-Team2-05-Create-Indexes.sql ----------------*/
/*
    Project : Food Distribution (Etemad Iranian Food Distribution)
    Stage   : 7 - Physical Data Model
    Team    : Team 2 - Product & Marketing
    Database: FoodDistributionDB
    SQL Server: 2022
    Version : 1.1 (2026-10-28)
    File    : 07-Team2-05-Create-Indexes.sql
    Purpose : Nonclustered indexes that support FOREIGN KEY joins and the frequent report queries.
    Run order: 5 (after 07-Team2-04-Create-Constraints.sql)
    Prerequisites: All 24 Team 2 tables exist (07-Team2-03-Create-Tables.sql).
    Source  : 06-Team2-Product-Marketing-Logical-Data-Model.xlsx (Stage 6, #175)
    Schemas : Team 2 proposal for #183 (ref / core / marketing); not yet approved
    Re-run  : Safe. An index is created if missing. If one exists with the same name but different key columns,
              column order, INCLUDE columns, uniqueness, type or filter, it is dropped and recreated.
              The verification at the end compares the whole structure with the expected definition.
*/

USE [FoodDistributionDB];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

/* ---- Prerequisite check: stop the whole script if a prerequisite is missing ---- */
IF OBJECT_ID(N'ref.ProductCategory', N'U') IS NULL
   OR OBJECT_ID(N'ref.Package', N'U') IS NULL
   OR OBJECT_ID(N'core.Brand', N'U') IS NULL
   OR OBJECT_ID(N'core.Product', N'U') IS NULL
   OR OBJECT_ID(N'core.SKU', N'U') IS NULL
   OR OBJECT_ID(N'marketing.ProductPrice', N'U') IS NULL
   OR OBJECT_ID(N'marketing.CampaignChannel', N'U') IS NULL
   OR OBJECT_ID(N'marketing.CampaignAudience', N'U') IS NULL
   OR OBJECT_ID(N'marketing.MarketingCampaign', N'U') IS NULL
   OR OBJECT_ID(N'marketing.MarketingCampaignChannel', N'U') IS NULL
   OR OBJECT_ID(N'marketing.MarketingCampaignAudience', N'U') IS NULL
   OR OBJECT_ID(N'marketing.CampaignBudget', N'U') IS NULL
   OR OBJECT_ID(N'marketing.CampaignCost', N'U') IS NULL
   OR OBJECT_ID(N'marketing.CampaignResult', N'U') IS NULL
   OR OBJECT_ID(N'marketing.Promotion', N'U') IS NULL
   OR OBJECT_ID(N'marketing.BrandActivity', N'U') IS NULL
   OR OBJECT_ID(N'marketing.Market', N'U') IS NULL
   OR OBJECT_ID(N'marketing.MarketSegment', N'U') IS NULL
   OR OBJECT_ID(N'marketing.MarketResearch', N'U') IS NULL
   OR OBJECT_ID(N'marketing.MarketSurvey', N'U') IS NULL
   OR OBJECT_ID(N'marketing.ResearchResult', N'U') IS NULL
   OR OBJECT_ID(N'marketing.Competitor', N'U') IS NULL
   OR OBJECT_ID(N'marketing.CompetitorProduct', N'U') IS NULL
   OR OBJECT_ID(N'marketing.MarketPrice', N'U') IS NULL
BEGIN
    RAISERROR(N'Team 2 tables are missing. Run 07-Team2-03-Create-Tables.sql first.', 16, 1);
    SET NOEXEC ON;
END;
GO

/* ========================================================================
   Nonclustered indexes (evaluated with 07-Team2-07-Index-Evaluation.sql)
   ======================================================================== */

-- FK R29
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'ref.ProductCategory') AND i.name = N'IX_ProductCategory_Parent_Category_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Parent_Category_ID||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_ProductCategory_Parent_Category_ID ON ref.ProductCategory;
    PRINT N'IX_ProductCategory_Parent_Category_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_ProductCategory_Parent_Category_ID ON ref.ProductCategory (Parent_Category_ID);
    PRINT N'Created IX_ProductCategory_Parent_Category_ID.';
END;
GO

-- FK R01
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'core.Product') AND i.name = N'IX_Product_Product_Category_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Product_Category_ID||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_Product_Product_Category_ID ON core.Product;
    PRINT N'IX_Product_Product_Category_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_Product_Product_Category_ID ON core.Product (Product_Category_ID);
    PRINT N'Created IX_Product_Product_Category_ID.';
END;
GO

-- FK R02
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'core.Product') AND i.name = N'IX_Product_Brand_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Brand_ID||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_Product_Brand_ID ON core.Product;
    PRINT N'IX_Product_Brand_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_Product_Brand_ID ON core.Product (Brand_ID);
    PRINT N'Created IX_Product_Brand_ID.';
END;
GO

-- FK R03
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'core.SKU') AND i.name = N'IX_SKU_Product_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Product_ID||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_SKU_Product_ID ON core.SKU;
    PRINT N'IX_SKU_Product_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_SKU_Product_ID ON core.SKU (Product_ID);
    PRINT N'Created IX_SKU_Product_ID.';
END;
GO

-- FK R05
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'core.SKU') AND i.name = N'IX_SKU_Package_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Package_ID||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_SKU_Package_ID ON core.SKU;
    PRINT N'IX_SKU_Package_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_SKU_Package_ID ON core.SKU (Package_ID);
    PRINT N'Created IX_SKU_Package_ID.';
END;
GO

-- FK R06
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.ProductPrice') AND i.name = N'IX_ProductPrice_SKU_ID_Price_Type_Effective_From'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|SKU_ID,Price_Type,Effective_From||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_ProductPrice_SKU_ID_Price_Type_Effective_From ON marketing.ProductPrice;
    PRINT N'IX_ProductPrice_SKU_ID_Price_Type_Effective_From: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_ProductPrice_SKU_ID_Price_Type_Effective_From ON marketing.ProductPrice (SKU_ID, Price_Type, Effective_From);
    PRINT N'Created IX_ProductPrice_SKU_ID_Price_Type_Effective_From.';
END;
GO

-- FK R08
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.MarketingCampaign') AND i.name = N'IX_MarketingCampaign_Brand_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Brand_ID||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_MarketingCampaign_Brand_ID ON marketing.MarketingCampaign;
    PRINT N'IX_MarketingCampaign_Brand_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_MarketingCampaign_Brand_ID ON marketing.MarketingCampaign (Brand_ID);
    PRINT N'Created IX_MarketingCampaign_Brand_ID.';
END;
GO

-- FK R09b
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.MarketingCampaignChannel') AND i.name = N'IX_MarketingCampaignChannel_Campaign_Channel_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Campaign_Channel_ID||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_MarketingCampaignChannel_Campaign_Channel_ID ON marketing.MarketingCampaignChannel;
    PRINT N'IX_MarketingCampaignChannel_Campaign_Channel_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_MarketingCampaignChannel_Campaign_Channel_ID ON marketing.MarketingCampaignChannel (Campaign_Channel_ID);
    PRINT N'Created IX_MarketingCampaignChannel_Campaign_Channel_ID.';
END;
GO

-- FK R10b
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.MarketingCampaignAudience') AND i.name = N'IX_MarketingCampaignAudience_Campaign_Audience_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Campaign_Audience_ID||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_MarketingCampaignAudience_Campaign_Audience_ID ON marketing.MarketingCampaignAudience;
    PRINT N'IX_MarketingCampaignAudience_Campaign_Audience_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_MarketingCampaignAudience_Campaign_Audience_ID ON marketing.MarketingCampaignAudience (Campaign_Audience_ID);
    PRINT N'Created IX_MarketingCampaignAudience_Campaign_Audience_ID.';
END;
GO

-- FK R11 و FK قاعده‌ی R27
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.CampaignBudget') AND i.name = N'IX_CampaignBudget_Marketing_Campaign_ID_Campaign_Channel_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Marketing_Campaign_ID,Campaign_Channel_ID||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_CampaignBudget_Marketing_Campaign_ID_Campaign_Channel_ID ON marketing.CampaignBudget;
    PRINT N'IX_CampaignBudget_Marketing_Campaign_ID_Campaign_Channel_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_CampaignBudget_Marketing_Campaign_ID_Campaign_Channel_ID ON marketing.CampaignBudget (Marketing_Campaign_ID, Campaign_Channel_ID);
    PRINT N'Created IX_CampaignBudget_Marketing_Campaign_ID_Campaign_Channel_ID.';
END;
GO

-- FK R12 و FK قاعده‌ی R28
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.CampaignCost') AND i.name = N'IX_CampaignCost_Marketing_Campaign_ID_Campaign_Channel_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Marketing_Campaign_ID,Campaign_Channel_ID||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_CampaignCost_Marketing_Campaign_ID_Campaign_Channel_ID ON marketing.CampaignCost;
    PRINT N'IX_CampaignCost_Marketing_Campaign_ID_Campaign_Channel_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_CampaignCost_Marketing_Campaign_ID_Campaign_Channel_ID ON marketing.CampaignCost (Marketing_Campaign_ID, Campaign_Channel_ID);
    PRINT N'Created IX_CampaignCost_Marketing_Campaign_ID_Campaign_Channel_ID.';
END;
GO

-- FK R28 و داشبورد مرحله ۳ (هزینه به تفکیک کانال و دوره، Q1 و Q3)  [v1.1: جدید]
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.CampaignCost') AND i.name = N'IX_CampaignCost_Campaign_Channel_ID_Cost_Date'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Campaign_Channel_ID,Cost_Date|Actual_Spent,Currency|([Campaign_Channel_ID] IS NOT NULL)' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_CampaignCost_Campaign_Channel_ID_Cost_Date ON marketing.CampaignCost;
    PRINT N'IX_CampaignCost_Campaign_Channel_ID_Cost_Date: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_CampaignCost_Campaign_Channel_ID_Cost_Date ON marketing.CampaignCost (Campaign_Channel_ID, Cost_Date)
        INCLUDE (Actual_Spent, Currency)
        WHERE Campaign_Channel_ID IS NOT NULL;
    PRINT N'Created IX_CampaignCost_Campaign_Channel_ID_Cost_Date.';
END;
GO

-- FK R14
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.Promotion') AND i.name = N'IX_Promotion_Marketing_Campaign_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Marketing_Campaign_ID||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_Promotion_Marketing_Campaign_ID ON marketing.Promotion;
    PRINT N'IX_Promotion_Marketing_Campaign_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_Promotion_Marketing_Campaign_ID ON marketing.Promotion (Marketing_Campaign_ID);
    PRINT N'Created IX_Promotion_Marketing_Campaign_ID.';
END;
GO

-- FK R07
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.BrandActivity') AND i.name = N'IX_BrandActivity_Brand_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Brand_ID||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_BrandActivity_Brand_ID ON marketing.BrandActivity;
    PRINT N'IX_BrandActivity_Brand_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_BrandActivity_Brand_ID ON marketing.BrandActivity (Brand_ID);
    PRINT N'Created IX_BrandActivity_Brand_ID.';
END;
GO

-- FK R16
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.MarketSegment') AND i.name = N'IX_MarketSegment_Market_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Market_ID||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_MarketSegment_Market_ID ON marketing.MarketSegment;
    PRINT N'IX_MarketSegment_Market_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_MarketSegment_Market_ID ON marketing.MarketSegment (Market_ID);
    PRINT N'Created IX_MarketSegment_Market_ID.';
END;
GO

-- FK R17
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.MarketResearch') AND i.name = N'IX_MarketResearch_Market_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Market_ID||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_MarketResearch_Market_ID ON marketing.MarketResearch;
    PRINT N'IX_MarketResearch_Market_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_MarketResearch_Market_ID ON marketing.MarketResearch (Market_ID);
    PRINT N'Created IX_MarketResearch_Market_ID.';
END;
GO

-- FK R21
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.MarketSurvey') AND i.name = N'IX_MarketSurvey_Market_Research_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Market_Research_ID||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_MarketSurvey_Market_Research_ID ON marketing.MarketSurvey;
    PRINT N'IX_MarketSurvey_Market_Research_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_MarketSurvey_Market_Research_ID ON marketing.MarketSurvey (Market_Research_ID);
    PRINT N'Created IX_MarketSurvey_Market_Research_ID.';
END;
GO

-- FK R20 (اختیاری
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.MarketSurvey') AND i.name = N'IX_MarketSurvey_Market_Segment_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Market_Segment_ID||([Market_Segment_ID] IS NOT NULL)' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_MarketSurvey_Market_Segment_ID ON marketing.MarketSurvey;
    PRINT N'IX_MarketSurvey_Market_Segment_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_MarketSurvey_Market_Segment_ID ON marketing.MarketSurvey (Market_Segment_ID)
        WHERE Market_Segment_ID IS NOT NULL;
    PRINT N'Created IX_MarketSurvey_Market_Segment_ID.';
END;
GO

-- FK R22
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.ResearchResult') AND i.name = N'IX_ResearchResult_Market_Research_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Market_Research_ID||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_ResearchResult_Market_Research_ID ON marketing.ResearchResult;
    PRINT N'IX_ResearchResult_Market_Research_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_ResearchResult_Market_Research_ID ON marketing.ResearchResult (Market_Research_ID);
    PRINT N'Created IX_ResearchResult_Market_Research_ID.';
END;
GO

-- FK R19 (اختیاری
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.Competitor') AND i.name = N'IX_Competitor_Market_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Market_ID||([Market_ID] IS NOT NULL)' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_Competitor_Market_ID ON marketing.Competitor;
    PRINT N'IX_Competitor_Market_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_Competitor_Market_ID ON marketing.Competitor (Market_ID)
        WHERE Market_ID IS NOT NULL;
    PRINT N'Created IX_Competitor_Market_ID.';
END;
GO

-- FK R25
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.CompetitorProduct') AND i.name = N'IX_CompetitorProduct_Competitor_ID'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Competitor_ID||' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_CompetitorProduct_Competitor_ID ON marketing.CompetitorProduct;
    PRINT N'IX_CompetitorProduct_Competitor_ID: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_CompetitorProduct_Competitor_ID ON marketing.CompetitorProduct (Competitor_ID);
    PRINT N'Created IX_CompetitorProduct_Competitor_ID.';
END;
GO

-- FK R18  [v1.1: ستون‌های INCLUDE اضافه شد]
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.MarketPrice') AND i.name = N'IX_MarketPrice_Market_ID_Price_Date'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Market_ID,Price_Date|Competitor_Product_ID,Currency,Price_Value,Product_ID|' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_MarketPrice_Market_ID_Price_Date ON marketing.MarketPrice;
    PRINT N'IX_MarketPrice_Market_ID_Price_Date: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_MarketPrice_Market_ID_Price_Date ON marketing.MarketPrice (Market_ID, Price_Date)
        INCLUDE (Product_ID, Competitor_Product_ID, Price_Value, Currency);
    PRINT N'Created IX_MarketPrice_Market_ID_Price_Date.';
END;
GO

-- FK R04
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.MarketPrice') AND i.name = N'IX_MarketPrice_Product_ID_Price_Date'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Product_ID,Price_Date||([Product_ID] IS NOT NULL)' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_MarketPrice_Product_ID_Price_Date ON marketing.MarketPrice;
    PRINT N'IX_MarketPrice_Product_ID_Price_Date: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_MarketPrice_Product_ID_Price_Date ON marketing.MarketPrice (Product_ID, Price_Date)
        WHERE Product_ID IS NOT NULL;
    PRINT N'Created IX_MarketPrice_Product_ID_Price_Date.';
END;
GO

-- FK R26
DECLARE @sig nvarchar(max);
SELECT @sig = CONCAT(i.type_desc, N'|', IIF(i.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|',
       STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',') WITHIN GROUP (ORDER BY ic.key_ordinal, col.name), N'|', i.filter_definition)
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'marketing.MarketPrice') AND i.name = N'IX_MarketPrice_Competitor_Product_ID_Price_Date'
GROUP BY i.type_desc, i.is_unique, i.filter_definition;
IF @sig IS NOT NULL AND @sig COLLATE Latin1_General_BIN2 <> N'NONCLUSTERED|NONUNIQUE|Competitor_Product_ID,Price_Date||([Competitor_Product_ID] IS NOT NULL)' COLLATE Latin1_General_BIN2
BEGIN
    DROP INDEX IX_MarketPrice_Competitor_Product_ID_Price_Date ON marketing.MarketPrice;
    PRINT N'IX_MarketPrice_Competitor_Product_ID_Price_Date: existing definition differed - replaced. Old: ' + @sig;
    SET @sig = NULL;
END;
IF @sig IS NULL
BEGIN
    CREATE NONCLUSTERED INDEX IX_MarketPrice_Competitor_Product_ID_Price_Date ON marketing.MarketPrice (Competitor_Product_ID, Price_Date)
        WHERE Competitor_Product_ID IS NOT NULL;
    PRINT N'Created IX_MarketPrice_Competitor_Product_ID_Price_Date.';
END;
GO

/* ---- Verification: existing structure is compared with the expected definition (not assumed to be correct) ---- */
DECLARE @E TABLE (kind nvarchar(10), obj sysname, parent nvarchar(300), sig nvarchar(max));
INSERT @E VALUES
    (N'IX', N'IX_ProductCategory_Parent_Category_ID', N'ref.ProductCategory', N'NONCLUSTERED|NONUNIQUE|Parent_Category_ID||'),
    (N'IX', N'IX_Product_Product_Category_ID', N'core.Product', N'NONCLUSTERED|NONUNIQUE|Product_Category_ID||'),
    (N'IX', N'IX_Product_Brand_ID', N'core.Product', N'NONCLUSTERED|NONUNIQUE|Brand_ID||'),
    (N'IX', N'IX_SKU_Product_ID', N'core.SKU', N'NONCLUSTERED|NONUNIQUE|Product_ID||'),
    (N'IX', N'IX_SKU_Package_ID', N'core.SKU', N'NONCLUSTERED|NONUNIQUE|Package_ID||'),
    (N'IX', N'IX_ProductPrice_SKU_ID_Price_Type_Effective_From', N'marketing.ProductPrice', N'NONCLUSTERED|NONUNIQUE|SKU_ID,Price_Type,Effective_From||'),
    (N'IX', N'IX_MarketingCampaign_Brand_ID', N'marketing.MarketingCampaign', N'NONCLUSTERED|NONUNIQUE|Brand_ID||'),
    (N'IX', N'IX_MarketingCampaignChannel_Campaign_Channel_ID', N'marketing.MarketingCampaignChannel', N'NONCLUSTERED|NONUNIQUE|Campaign_Channel_ID||'),
    (N'IX', N'IX_MarketingCampaignAudience_Campaign_Audience_ID', N'marketing.MarketingCampaignAudience', N'NONCLUSTERED|NONUNIQUE|Campaign_Audience_ID||'),
    (N'IX', N'IX_CampaignBudget_Marketing_Campaign_ID_Campaign_Channel_ID', N'marketing.CampaignBudget', N'NONCLUSTERED|NONUNIQUE|Marketing_Campaign_ID,Campaign_Channel_ID||'),
    (N'IX', N'IX_CampaignCost_Marketing_Campaign_ID_Campaign_Channel_ID', N'marketing.CampaignCost', N'NONCLUSTERED|NONUNIQUE|Marketing_Campaign_ID,Campaign_Channel_ID||'),
    (N'IX', N'IX_CampaignCost_Campaign_Channel_ID_Cost_Date', N'marketing.CampaignCost', N'NONCLUSTERED|NONUNIQUE|Campaign_Channel_ID,Cost_Date|Actual_Spent,Currency|([Campaign_Channel_ID] IS NOT NULL)'),
    (N'IX', N'IX_Promotion_Marketing_Campaign_ID', N'marketing.Promotion', N'NONCLUSTERED|NONUNIQUE|Marketing_Campaign_ID||'),
    (N'IX', N'IX_BrandActivity_Brand_ID', N'marketing.BrandActivity', N'NONCLUSTERED|NONUNIQUE|Brand_ID||'),
    (N'IX', N'IX_MarketSegment_Market_ID', N'marketing.MarketSegment', N'NONCLUSTERED|NONUNIQUE|Market_ID||'),
    (N'IX', N'IX_MarketResearch_Market_ID', N'marketing.MarketResearch', N'NONCLUSTERED|NONUNIQUE|Market_ID||'),
    (N'IX', N'IX_MarketSurvey_Market_Research_ID', N'marketing.MarketSurvey', N'NONCLUSTERED|NONUNIQUE|Market_Research_ID||'),
    (N'IX', N'IX_MarketSurvey_Market_Segment_ID', N'marketing.MarketSurvey', N'NONCLUSTERED|NONUNIQUE|Market_Segment_ID||([Market_Segment_ID] IS NOT NULL)'),
    (N'IX', N'IX_ResearchResult_Market_Research_ID', N'marketing.ResearchResult', N'NONCLUSTERED|NONUNIQUE|Market_Research_ID||'),
    (N'IX', N'IX_Competitor_Market_ID', N'marketing.Competitor', N'NONCLUSTERED|NONUNIQUE|Market_ID||([Market_ID] IS NOT NULL)'),
    (N'IX', N'IX_CompetitorProduct_Competitor_ID', N'marketing.CompetitorProduct', N'NONCLUSTERED|NONUNIQUE|Competitor_ID||'),
    (N'IX', N'IX_MarketPrice_Market_ID_Price_Date', N'marketing.MarketPrice', N'NONCLUSTERED|NONUNIQUE|Market_ID,Price_Date|Competitor_Product_ID,Currency,Price_Value,Product_ID|'),
    (N'IX', N'IX_MarketPrice_Product_ID_Price_Date', N'marketing.MarketPrice', N'NONCLUSTERED|NONUNIQUE|Product_ID,Price_Date||([Product_ID] IS NOT NULL)'),
    (N'IX', N'IX_MarketPrice_Competitor_Product_ID_Price_Date', N'marketing.MarketPrice', N'NONCLUSTERED|NONUNIQUE|Competitor_Product_ID,Price_Date||([Competitor_Product_ID] IS NOT NULL)');
DECLARE @D TABLE (kind nvarchar(10), obj sysname, problem nvarchar(max));
WITH tbl AS (SELECT OBJECT_ID(n) AS object_id, n AS full_name FROM (VALUES (N'ref.ProductCategory'), (N'ref.Package'), (N'core.Brand'), (N'core.Product'), (N'core.SKU'), (N'marketing.ProductPrice'), (N'marketing.CampaignChannel'), (N'marketing.CampaignAudience'), (N'marketing.MarketingCampaign'), (N'marketing.MarketingCampaignChannel'), (N'marketing.MarketingCampaignAudience'), (N'marketing.CampaignBudget'), (N'marketing.CampaignCost'), (N'marketing.CampaignResult'), (N'marketing.Promotion'), (N'marketing.BrandActivity'), (N'marketing.Market'), (N'marketing.MarketSegment'), (N'marketing.MarketResearch'), (N'marketing.MarketSurvey'), (N'marketing.ResearchResult'), (N'marketing.Competitor'), (N'marketing.CompetitorProduct'), (N'marketing.MarketPrice')) v(n) WHERE OBJECT_ID(n) IS NOT NULL),
icols AS (
    SELECT i.object_id, i.index_id, i.name, i.type_desc, i.is_unique, i.is_primary_key, i.is_unique_constraint, i.filter_definition,
           STRING_AGG(CASE WHEN ic.is_included_column = 0 THEN CAST(col.name AS nvarchar(max)) + IIF(ic.is_descending_key = 1, N' DESC', N'') END, N',')
               WITHIN GROUP (ORDER BY ic.key_ordinal, col.name) AS keys,
           STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN CAST(col.name AS nvarchar(max)) END, N',')
               WITHIN GROUP (ORDER BY ic.key_ordinal, col.name) AS incs
    FROM sys.indexes i
    JOIN tbl t ON t.object_id = i.object_id
    JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
    GROUP BY i.object_id, i.index_id, i.name, i.type_desc, i.is_unique, i.is_primary_key, i.is_unique_constraint, i.filter_definition),
act AS (
    SELECT N'TABLE' AS kind, t.full_name AS obj, t.full_name AS parent,
           (SELECT STRING_AGG(CONCAT(CAST(c.name AS nvarchar(max)), N' ', CASE WHEN ty.name IN (N'nvarchar', N'nchar') THEN ty.name + N'(' + CASE WHEN c.max_length = -1 THEN N'max' ELSE CAST(c.max_length / 2 AS nvarchar(10)) END + N')' WHEN ty.name IN (N'varchar', N'char') THEN ty.name + N'(' + CASE WHEN c.max_length = -1 THEN N'max' ELSE CAST(c.max_length AS nvarchar(10)) END + N')' WHEN ty.name IN (N'decimal', N'numeric') THEN ty.name + N'(' + CAST(c.precision AS nvarchar(10)) + N',' + CAST(c.scale AS nvarchar(10)) + N')' WHEN ty.name = N'datetime2' THEN N'datetime2(' + CAST(c.scale AS nvarchar(10)) + N')' ELSE ty.name END, IIF(c.is_nullable = 1, N' NULL', N' NOT NULL'), IIF(c.is_identity = 1, N' IDENTITY', N'')), N'; ')
                   WITHIN GROUP (ORDER BY c.column_id)
            FROM sys.columns c JOIN sys.types ty ON ty.user_type_id = c.user_type_id WHERE c.object_id = t.object_id) AS sig
    FROM tbl t
    UNION ALL
    SELECT CASE WHEN x.is_primary_key = 1 THEN N'PK' WHEN x.is_unique_constraint = 1 THEN N'UQ' WHEN x.is_unique = 1 THEN N'UX' ELSE N'IX' END,
           x.name, t.full_name,
           CASE WHEN x.is_primary_key = 1 THEN CONCAT(x.type_desc, N':', x.keys)
                ELSE CONCAT(x.type_desc, N'|', IIF(x.is_unique = 1, N'UNIQUE', N'NONUNIQUE'), N'|', x.keys, N'|', x.incs, N'|', x.filter_definition) END
    FROM icols x JOIN tbl t ON t.object_id = x.object_id
    UNION ALL
    SELECT N'CK', k.name, t.full_name, k.definition FROM sys.check_constraints k JOIN tbl t ON t.object_id = k.parent_object_id
    UNION ALL
    SELECT N'DF', d.name, t.full_name, CONCAT(col.name, N'=', d.definition)
    FROM sys.default_constraints d JOIN tbl t ON t.object_id = d.parent_object_id
    JOIN sys.columns col ON col.object_id = d.parent_object_id AND col.column_id = d.parent_column_id
    UNION ALL
    SELECT N'FK', f.name, t.full_name,
           CONCAT(STRING_AGG(CAST(pc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N' -> ',
                  OBJECT_SCHEMA_NAME(f.referenced_object_id), N'.', OBJECT_NAME(f.referenced_object_id), N'(',
                  STRING_AGG(CAST(rc.name AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY fc.constraint_column_id), N')|',
                  f.delete_referential_action_desc, N'|', f.update_referential_action_desc)
    FROM sys.foreign_keys f JOIN tbl t ON t.object_id = f.parent_object_id
    JOIN sys.foreign_key_columns fc ON fc.constraint_object_id = f.object_id
    JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id
    JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id
    GROUP BY f.name, t.full_name, f.referenced_object_id, f.delete_referential_action_desc, f.update_referential_action_desc
    UNION ALL
    SELECT N'TR', tr.name, t.full_name,
           CONCAT(t.full_name, N'|', IIF(tr.is_instead_of_trigger = 1, N'INSTEAD OF', N'AFTER'), N'|',
                  (SELECT STRING_AGG(CAST(te.type_desc AS nvarchar(max)), N',') WITHIN GROUP (ORDER BY te.type_desc) FROM sys.trigger_events te WHERE te.object_id = tr.object_id),
                  N'|', IIF(tr.is_disabled = 1, N'DISABLED', N'ENABLED'))
    FROM sys.triggers tr JOIN tbl t ON t.object_id = tr.parent_id)
INSERT @D
SELECT COALESCE(e.kind, a.kind), COALESCE(e.obj, a.obj),
       CASE WHEN a.obj IS NULL THEN N'missing'
            WHEN e.obj IS NULL THEN N'unexpected object: ' + a.sig
            ELSE N'expected [' + e.sig + N'] actual [' + a.sig + N']' END
FROM @E e
FULL JOIN (SELECT * FROM act WHERE kind IN (N'IX')) a
  ON a.kind = e.kind AND a.obj COLLATE Latin1_General_BIN2 = e.obj COLLATE Latin1_General_BIN2 AND a.parent COLLATE Latin1_General_BIN2 = e.parent COLLATE Latin1_General_BIN2
WHERE a.obj IS NULL OR e.obj IS NULL OR a.sig COLLATE Latin1_General_BIN2 <> e.sig COLLATE Latin1_General_BIN2;
DECLARE @nE int = (SELECT COUNT(*) FROM @E), @nD int = (SELECT COUNT(*) FROM @D), @line nvarchar(max);
IF @nD = 0
    PRINT CONCAT(N'Verification passed: all ', @nE, N' nonclustered indexes (key columns and order, INCLUDE columns, uniqueness, type, filter) match the expected definition.');
ELSE
BEGIN
    DECLARE d CURSOR LOCAL FAST_FORWARD FOR SELECT CONCAT(N'  DIFFERENCE ', kind, N' ', obj, N': ', problem) FROM @D;
    OPEN d; FETCH NEXT FROM d INTO @line;
    WHILE @@FETCH_STATUS = 0 BEGIN PRINT @line; FETCH NEXT FROM d INTO @line; END;
    CLOSE d; DEALLOCATE d;
    RAISERROR(N'Verification FAILED: %d object(s) differ from the expected definition (see the lines above).', 16, 1, @nD);
END;
GO

SET NOEXEC OFF;
GO
PRINT N'07-Team2-05-Create-Indexes.sql finished.';
GO


/*=============================================================================
  DEPLOYMENT SUMMARY
=============================================================================*/
USE [FoodDistributionDB];
GO
PRINT N'Integrated Stage 7 deployment script finished. Review messages above for errors.';
SELECT DB_NAME() AS CurrentDatabase;
SELECT s.name AS SchemaName, COUNT(t.object_id) AS UserTableCount
FROM sys.schemas AS s
LEFT JOIN sys.tables AS t ON t.schema_id = s.schema_id
WHERE s.name IN (N'ref', N'core', N'sales', N'marketing')
GROUP BY s.name
ORDER BY s.name;
GO

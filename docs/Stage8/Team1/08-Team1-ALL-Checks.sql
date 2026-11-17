/*=============================================================================
 08-05-T1-ALL-Checks.sql   (QC for the integrated Team 1 Stage 8 run, guide tests Q01-Q18)
 Read-only: no table is changed. Output: Test_ID | Table | Definition | Checked | Errors | Sample_ID | Result
 Run after 08-03-T1-ALL-Integrated.sql, same database. Not executed in the preparation environment.
=============================================================================*/
USE [FoodDistributionDB];
GO
SET NOCOUNT ON;
DROP TABLE IF EXISTS #R;
CREATE TABLE #R (Seq int IDENTITY(1,1), Test_ID nvarchar(10), Table_Name nvarchar(80), Definition nvarchar(300), Checked bigint, Errors bigint, Sample_ID nvarchar(60));

INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q01', t.n, N'Row count (informational; compare with the approved volume x @Scale)', t.c, 0, NULL FROM (VALUES
 (N'ref.Province',(SELECT COUNT_BIG(*) FROM ref.Province)),(N'ref.City',(SELECT COUNT_BIG(*) FROM ref.City)),(N'core.Calendar',(SELECT COUNT_BIG(*) FROM core.Calendar)),
 (N'core.Branch',(SELECT COUNT_BIG(*) FROM core.Branch)),(N'core.Salesperson',(SELECT COUNT_BIG(*) FROM core.Salesperson)),(N'core.Customer',(SELECT COUNT_BIG(*) FROM core.Customer)),
 (N'sales.Lead',(SELECT COUNT_BIG(*) FROM sales.Lead)),(N'sales.CustomerInteraction',(SELECT COUNT_BIG(*) FROM sales.CustomerInteraction)),(N'sales.SalesOpportunity',(SELECT COUNT_BIG(*) FROM sales.SalesOpportunity)),
 (N'sales.Contract',(SELECT COUNT_BIG(*) FROM sales.Contract)),(N'sales.SalesOrder',(SELECT COUNT_BIG(*) FROM sales.SalesOrder)),(N'sales.SalesOrderItem',(SELECT COUNT_BIG(*) FROM sales.SalesOrderItem)),
 (N'sales.Invoice',(SELECT COUNT_BIG(*) FROM sales.Invoice)),(N'sales.InvoiceItem',(SELECT COUNT_BIG(*) FROM sales.InvoiceItem)),(N'sales.Payment',(SELECT COUNT_BIG(*) FROM sales.Payment)),
 (N'sales.ReturnRequest',(SELECT COUNT_BIG(*) FROM sales.ReturnRequest)),(N'sales.CustomerFeedback',(SELECT COUNT_BIG(*) FROM sales.CustomerFeedback)),
 (N'sales.SalesTarget',(SELECT COUNT_BIG(*) FROM sales.SalesTarget)),(N'sales.SalesForecast',(SELECT COUNT_BIG(*) FROM sales.SalesForecast)),(N'sales.Commission',(SELECT COUNT_BIG(*) FROM sales.Commission))
) t(n,c);


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q02', N'core.Customer', N'Customer_Code is unique', (SELECT COUNT(*) FROM core.Customer), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Customer_Code AS k FROM (SELECT Customer_Code FROM core.Customer GROUP BY Customer_Code HAVING COUNT(*)>1) x) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q02', N'sales.Lead', N'Lead_Code is unique', (SELECT COUNT(*) FROM sales.Lead), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Lead_Code AS k FROM (SELECT Lead_Code FROM sales.Lead GROUP BY Lead_Code HAVING COUNT(*)>1) x) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q02', N'sales.SalesOpportunity', N'Opportunity_Code is unique', (SELECT COUNT(*) FROM sales.SalesOpportunity), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Opportunity_Code AS k FROM (SELECT Opportunity_Code FROM sales.SalesOpportunity GROUP BY Opportunity_Code HAVING COUNT(*)>1) x) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q02', N'sales.Contract', N'Contract_Number is unique', (SELECT COUNT(*) FROM sales.Contract), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Contract_Number AS k FROM (SELECT Contract_Number FROM sales.Contract GROUP BY Contract_Number HAVING COUNT(*)>1) x) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q02', N'sales.SalesOrder', N'Sales_Order_Number is unique', (SELECT COUNT(*) FROM sales.SalesOrder), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Sales_Order_Number AS k FROM (SELECT Sales_Order_Number FROM sales.SalesOrder GROUP BY Sales_Order_Number HAVING COUNT(*)>1) x) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q02', N'sales.Invoice', N'Invoice_Number is unique', (SELECT COUNT(*) FROM sales.Invoice), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Invoice_Number AS k FROM (SELECT Invoice_Number FROM sales.Invoice GROUP BY Invoice_Number HAVING COUNT(*)>1) x) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q02', N'sales.Payment', N'Transaction_Reference is unique', (SELECT COUNT(*) FROM sales.Payment), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Transaction_Reference AS k FROM (SELECT Transaction_Reference FROM sales.Payment WHERE Transaction_Reference IS NOT NULL GROUP BY Transaction_Reference HAVING COUNT(*)>1) x) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q02', N'core.Salesperson', N'Salesperson_Code is unique', (SELECT COUNT(*) FROM core.Salesperson), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Salesperson_Code AS k FROM (SELECT Salesperson_Code FROM core.Salesperson GROUP BY Salesperson_Code HAVING COUNT(*)>1) x) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q02', N'core.Branch', N'Branch_Code is unique', (SELECT COUNT(*) FROM core.Branch), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Branch_Code AS k FROM (SELECT Branch_Code FROM core.Branch GROUP BY Branch_Code HAVING COUNT(*)>1) x) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q02', N'ref.City', N'City_Code is unique', (SELECT COUNT(*) FROM ref.City), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT City_Code AS k FROM (SELECT City_Code FROM ref.City GROUP BY City_Code HAVING COUNT(*)>1) x) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q02', N'sales.InvoiceItem', N'(Invoice_ID, Product_ID) is unique', (SELECT COUNT(*) FROM sales.InvoiceItem), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Invoice_ID AS k FROM (SELECT Invoice_ID FROM sales.InvoiceItem GROUP BY Invoice_ID,Product_ID HAVING COUNT(*)>1) x) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q02', N'sales.SalesOrderItem', N'(Order, Product) is unique', (SELECT COUNT(*) FROM sales.SalesOrderItem), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Sales_Order_ID AS k FROM (SELECT Sales_Order_ID FROM sales.SalesOrderItem GROUP BY Sales_Order_ID,Product_ID HAVING COUNT(*)>1) x) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q02', N'sales.CustomerFeedback', N'natural key (Customer, Order, Type, Date) is unique', (SELECT COUNT(*) FROM sales.CustomerFeedback), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Customer_ID AS k FROM (SELECT Customer_ID FROM sales.CustomerFeedback GROUP BY Customer_ID,Sales_Order_ID,Feedback_Type,Feedback_Date HAVING COUNT(*)>1) x) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q03', N'sales.Payment', N'Payment customer/order = invoice customer/order', (SELECT COUNT(*) FROM sales.Payment), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT p.Payment_ID AS k FROM sales.Payment p JOIN sales.Invoice i ON i.Invoice_ID=p.Invoice_ID WHERE p.Customer_ID<>i.Customer_ID OR p.Sales_Order_ID<>i.Sales_Order_ID) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q03', N'sales.SalesOrder', N'Order contract belongs to the same customer', (SELECT COUNT(*) FROM sales.SalesOrder WHERE Contract_ID IS NOT NULL), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT so.Sales_Order_ID AS k FROM sales.SalesOrder so JOIN sales.Contract c ON c.Contract_ID=so.Contract_ID WHERE c.Customer_ID<>so.Customer_ID) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q03', N'sales.SalesOrder', N'Order interaction belongs to the same customer', (SELECT COUNT(*) FROM sales.SalesOrder WHERE Customer_Interaction_ID IS NOT NULL), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT so.Sales_Order_ID AS k FROM sales.SalesOrder so JOIN sales.CustomerInteraction ci ON ci.Customer_Interaction_ID=so.Customer_Interaction_ID WHERE ci.Customer_ID<>so.Customer_ID) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q03', N'sales.Contract', N'Contract opportunity is a Won opportunity of the same customer', (SELECT COUNT(*) FROM sales.Contract WHERE Sales_Opportunity_ID IS NOT NULL), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT c.Contract_ID AS k FROM sales.Contract c JOIN sales.SalesOpportunity o ON o.Sales_Opportunity_ID=c.Sales_Opportunity_ID WHERE o.Customer_ID IS NULL OR o.Customer_ID<>c.Customer_ID OR o.Opportunity_Status<>N'Won') b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q03', N'sales.InvoiceItem', N'Every invoice item product exists on the order of its invoice', (SELECT COUNT(*) FROM sales.InvoiceItem), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT ii.Invoice_ID AS k FROM sales.InvoiceItem ii JOIN sales.Invoice i ON i.Invoice_ID=ii.Invoice_ID WHERE NOT EXISTS (SELECT 1 FROM sales.SalesOrderItem s WHERE s.Sales_Order_ID=i.Sales_Order_ID AND s.Product_ID=ii.Product_ID)) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q03', N'sales.SalesOrder', N'Salesperson and Sales_Region present and region = branch region of the salesperson', (SELECT COUNT(*) FROM sales.SalesOrder), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT so.Sales_Order_ID AS k FROM sales.SalesOrder so LEFT JOIN core.Salesperson s ON s.Salesperson_ID=so.Salesperson_ID LEFT JOIN core.Branch b ON b.Branch_ID=s.Branch_ID WHERE so.Salesperson_ID IS NULL OR so.Sales_Region_ID IS NULL OR b.Sales_Region_ID<>so.Sales_Region_ID) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q03', N'sales.SalesOrder', N'Promotion used only inside its validity period', (SELECT COUNT(*) FROM sales.SalesOrder WHERE Promotion_ID IS NOT NULL), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT so.Sales_Order_ID AS k FROM sales.SalesOrder so JOIN marketing.Promotion p ON p.Promotion_ID=so.Promotion_ID JOIN core.Calendar c ON c.Calendar_ID=so.Calendar_ID WHERE c.Calendar_Date<p.Start_Date OR c.Calendar_Date>p.End_Date) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q03', N'sales.SalesOrder', N'Order date inside the life of its contract', (SELECT COUNT(*) FROM sales.SalesOrder WHERE Contract_ID IS NOT NULL), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT so.Sales_Order_ID AS k FROM sales.SalesOrder so JOIN sales.Contract k ON k.Contract_ID=so.Contract_ID JOIN core.Calendar c ON c.Calendar_ID=so.Calendar_ID WHERE c.Calendar_Date<k.Start_Date OR c.Calendar_Date>COALESCE(k.Closed_Date,k.End_Date)) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q04', N'core.Customer', N'Registration_Date inside the Calendar range', (SELECT COUNT(*) FROM core.Customer), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Customer_ID AS k FROM core.Customer WHERE Registration_Date<'2019-03-21' OR Registration_Date>'2027-03-20') b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q04', N'sales.Invoice', N'Invoice_Date and Due_Date inside the range', (SELECT COUNT(*) FROM sales.Invoice), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Invoice_ID AS k FROM sales.Invoice WHERE Invoice_Date NOT BETWEEN '2019-03-21' AND '2027-03-20' OR Due_Date>'2027-03-20') b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q05', N'core.Calendar', N'2,922 rows, 2019-03-21..2027-03-20, no gap', (SELECT COUNT(*) FROM core.Calendar), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT 1 AS k FROM (SELECT 1 AS x FROM core.Calendar HAVING COUNT(*)<>2922 OR MIN(Calendar_Date)<>'2019-03-21' OR MAX(Calendar_Date)<>'2027-03-20' OR DATEDIFF(DAY,MIN(Calendar_Date),MAX(Calendar_Date))+1<>COUNT(DISTINCT Calendar_Date)) q) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q06', N'sales.SalesOpportunity', N'Probability 0..100', (SELECT COUNT(*) FROM sales.SalesOpportunity), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Sales_Opportunity_ID AS k FROM sales.SalesOpportunity WHERE Probability<0 OR Probability>100) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q06', N'sales.CustomerFeedback', N'Rating 1..5', (SELECT COUNT(*) FROM sales.CustomerFeedback), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Customer_Feedback_ID AS k FROM sales.CustomerFeedback WHERE Rating NOT BETWEEN 1 AND 5) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q06', N'sales.SalesOrderItem', N'Quantity > 0, Unit_Price > 0, Net >= 0', (SELECT COUNT(*) FROM sales.SalesOrderItem), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Sales_Order_Item_ID AS k FROM sales.SalesOrderItem WHERE Quantity<=0 OR Unit_Price<=0 OR Net_Amount<0) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q07', N'sales.SalesOrder', N'Order date >= customer Registration_Date', (SELECT COUNT(*) FROM sales.SalesOrder), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT so.Sales_Order_ID AS k FROM sales.SalesOrder so JOIN core.Calendar c ON c.Calendar_ID=so.Calendar_ID JOIN core.Customer cu ON cu.Customer_ID=so.Customer_ID WHERE c.Calendar_Date<cu.Registration_Date) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q07', N'sales.SalesOrder', N'Order date >= salesperson Hire_Date', (SELECT COUNT(*) FROM sales.SalesOrder), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT so.Sales_Order_ID AS k FROM sales.SalesOrder so JOIN core.Calendar c ON c.Calendar_ID=so.Calendar_ID JOIN core.Salesperson s ON s.Salesperson_ID=so.Salesperson_ID WHERE c.Calendar_Date<s.Hire_Date) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q07', N'sales.SalesOrderItem', N'Order date >= product Launch_Date', (SELECT COUNT(*) FROM sales.SalesOrderItem), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT i.Sales_Order_Item_ID AS k FROM sales.SalesOrderItem i JOIN sales.SalesOrder so ON so.Sales_Order_ID=i.Sales_Order_ID JOIN core.Calendar c ON c.Calendar_ID=so.Calendar_ID JOIN core.Product p ON p.Product_ID=i.Product_ID WHERE c.Calendar_Date<p.Launch_Date) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q07', N'sales.SalesOrder', N'Delivery_Date >= order date', (SELECT COUNT(*) FROM sales.SalesOrder WHERE Delivery_Date IS NOT NULL), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT so.Sales_Order_ID AS k FROM sales.SalesOrder so JOIN core.Calendar c ON c.Calendar_ID=so.Calendar_ID WHERE so.Delivery_Date<c.Calendar_Date) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q07', N'sales.Invoice', N'Invoice_Date >= order date; Due_Date >= Invoice_Date', (SELECT COUNT(*) FROM sales.Invoice), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT i.Invoice_ID AS k FROM sales.Invoice i JOIN sales.SalesOrder so ON so.Sales_Order_ID=i.Sales_Order_ID JOIN core.Calendar c ON c.Calendar_ID=so.Calendar_ID WHERE i.Invoice_Date<c.Calendar_Date OR i.Due_Date<i.Invoice_Date) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q07', N'sales.Payment', N'Payment_Date >= Invoice_Date and <= as-of date', (SELECT COUNT(*) FROM sales.Payment), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT p.Payment_ID AS k FROM sales.Payment p JOIN sales.Invoice i ON i.Invoice_ID=p.Invoice_ID WHERE p.Payment_Date<i.Invoice_Date OR p.Payment_Date>'2027-03-20') b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q07', N'sales.ReturnRequest', N'Return date >= delivery; Review >= return; Refund >= review', (SELECT COUNT(*) FROM sales.ReturnRequest), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT rr.Return_Request_ID AS k FROM sales.ReturnRequest rr JOIN sales.SalesOrderItem i ON i.Sales_Order_Item_ID=rr.Sales_Order_Item_ID JOIN sales.SalesOrder so ON so.Sales_Order_ID=i.Sales_Order_ID JOIN core.Calendar c ON c.Calendar_ID=rr.Calendar_ID WHERE c.Calendar_Date<so.Delivery_Date OR rr.Review_Date<c.Calendar_Date OR rr.Refund_Date<rr.Review_Date) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q07', N'sales.CustomerInteraction', N'Interaction date >= customer Registration_Date', (SELECT COUNT(*) FROM sales.CustomerInteraction), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT ci.Customer_Interaction_ID AS k FROM sales.CustomerInteraction ci JOIN core.Customer c ON c.Customer_ID=ci.Customer_ID WHERE CONVERT(date,ci.Interaction_DateTime)<c.Registration_Date) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q07', N'sales.SalesOpportunity', N'Opportunity date >= customer Registration_Date / lead Created_Date', (SELECT COUNT(*) FROM sales.SalesOpportunity), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT o.Sales_Opportunity_ID AS k FROM sales.SalesOpportunity o LEFT JOIN core.Customer c ON c.Customer_ID=o.Customer_ID LEFT JOIN sales.Lead l ON l.Lead_ID=o.Lead_ID WHERE o.Opportunity_Date<c.Registration_Date OR o.Opportunity_Date<l.Created_Date OR o.Expected_Close_Date<o.Opportunity_Date) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q07', N'sales.Contract', N'Start <= End; Closed_Date inside the contract life', (SELECT COUNT(*) FROM sales.Contract), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Contract_ID AS k FROM sales.Contract WHERE Start_Date>End_Date OR (Closed_Date IS NOT NULL AND (Closed_Date<Start_Date OR Closed_Date>End_Date))) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q07', N'sales.CustomerFeedback', N'Feedback date >= delivery; Resolution >= Feedback', (SELECT COUNT(*) FROM sales.CustomerFeedback), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT fb.Customer_Feedback_ID AS k FROM sales.CustomerFeedback fb JOIN sales.SalesOrder so ON so.Sales_Order_ID=fb.Sales_Order_ID WHERE fb.Feedback_Date<so.Delivery_Date OR fb.Resolution_Date<fb.Feedback_Date) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q08', N'sales.SalesOrder', N'Total_Amount = SUM(item Net), Discount = SUM(item Discount)', (SELECT COUNT(*) FROM sales.SalesOrder), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT so.Sales_Order_ID AS k FROM sales.SalesOrder so LEFT JOIN (SELECT Sales_Order_ID,SUM(Net_Amount) n,SUM(Discount_Amount) d FROM sales.SalesOrderItem GROUP BY Sales_Order_ID) x ON x.Sales_Order_ID=so.Sales_Order_ID WHERE x.n IS NULL OR so.Total_Amount<>x.n OR so.Discount_Amount<>x.d) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q08', N'sales.SalesOrderItem', N'Net = ROUND(Qty x Price) - Discount', (SELECT COUNT(*) FROM sales.SalesOrderItem), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Sales_Order_Item_ID AS k FROM sales.SalesOrderItem WHERE Net_Amount<>ROUND(Quantity*Unit_Price,0)-Discount_Amount) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q09', N'sales.Invoice', N'Subtotal-Discount = SUM(item Net); Tax/Total = item sums', (SELECT COUNT(*) FROM sales.Invoice), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT i.Invoice_ID AS k FROM sales.Invoice i JOIN (SELECT Invoice_ID,SUM(Net_Amount) n,SUM(Discount_Amount) d,SUM(Tax_Amount) t,SUM(Final_Amount) f FROM sales.InvoiceItem GROUP BY Invoice_ID) x ON x.Invoice_ID=i.Invoice_ID WHERE i.Subtotal-i.Discount_Amount<>x.n OR i.Discount_Amount<>x.d OR i.Tax_Amount<>x.t OR i.Total_Amount<>x.f) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q09', N'sales.InvoiceItem', N'Item Net/Qty/Price = order item; Tax = ROUND(Net x Tax_Rate/100)', (SELECT COUNT(*) FROM sales.InvoiceItem), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT ii.Invoice_ID AS k FROM sales.InvoiceItem ii JOIN sales.Invoice i ON i.Invoice_ID=ii.Invoice_ID JOIN sales.SalesOrderItem s ON s.Sales_Order_ID=i.Sales_Order_ID AND s.Product_ID=ii.Product_ID JOIN core.Product p ON p.Product_ID=ii.Product_ID WHERE s.Net_Amount<>ii.Net_Amount OR s.Quantity<>ii.Quantity OR s.Unit_Price<>ii.Unit_Price OR ii.Tax_Amount<>ROUND(ii.Net_Amount*p.Tax_Rate/100.0,0)) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q10', N'sales.Invoice', N'Successful payments <= Total; Paid = fully paid; Partially Paid strictly between', (SELECT COUNT(*) FROM sales.Invoice), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT i.Invoice_ID AS k FROM sales.Invoice i LEFT JOIN (SELECT Invoice_ID,SUM(Amount) a FROM sales.Payment WHERE Payment_Status=N'Successful' GROUP BY Invoice_ID) x ON x.Invoice_ID=i.Invoice_ID WHERE ISNULL(x.a,0)>i.Total_Amount OR (i.Invoice_Status=N'Paid' AND ISNULL(x.a,0)<>i.Total_Amount) OR (i.Invoice_Status=N'Partially Paid' AND (ISNULL(x.a,0)<=0 OR x.a>=i.Total_Amount)) OR (i.Invoice_Status=N'Issued' AND ISNULL(x.a,0)<>0)) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q10', N'sales.Invoice', N'Overdue only when Due_Date < as-of date; Issued only when not yet due', (SELECT COUNT(*) FROM sales.Invoice), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Invoice_ID AS k FROM sales.Invoice WHERE (Invoice_Status=N'Overdue' AND Due_Date>='2027-03-20') OR (Invoice_Status=N'Issued' AND Due_Date<'2027-03-20')) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q11', N'sales.ReturnRequest', N'Approved <= Requested <= item Quantity; Refund <= item Net', (SELECT COUNT(*) FROM sales.ReturnRequest), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT rr.Return_Request_ID AS k FROM sales.ReturnRequest rr JOIN sales.SalesOrderItem i ON i.Sales_Order_Item_ID=rr.Sales_Order_Item_ID WHERE rr.Approved_Quantity<0 OR rr.Approved_Quantity>rr.Requested_Quantity OR rr.Requested_Quantity>i.Quantity OR rr.Refund_Amount>i.Net_Amount) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q12', N'sales.SalesOrderItem', N'Unit_Price = Standard price of the base SKU valid on the order date (rule T2-S8-01)', (SELECT COUNT(*) FROM sales.SalesOrderItem), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT i.Sales_Order_Item_ID AS k FROM sales.SalesOrderItem i JOIN sales.SalesOrder so ON so.Sales_Order_ID=i.Sales_Order_ID JOIN core.Calendar c ON c.Calendar_ID=so.Calendar_ID WHERE i.Unit_Price<>ISNULL((SELECT TOP (1) pp.Unit_Price FROM core.SKU s JOIN marketing.ProductPrice pp ON pp.SKU_ID=s.SKU_ID AND pp.Price_Type=N'Standard' WHERE s.Product_ID=i.Product_ID AND pp.Effective_From<=c.Calendar_Date AND ISNULL(pp.Effective_To,'9999-12-31')>=c.Calendar_Date ORDER BY s.SKU_Code,pp.Effective_From DESC),-1)) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q12', N'sales.SalesOrder', N'Promotion discount <= 25% on promoted orders', (SELECT COUNT(*) FROM sales.SalesOrder WHERE Promotion_ID IS NOT NULL), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Sales_Order_ID AS k FROM sales.SalesOrder so WHERE Promotion_ID IS NOT NULL AND Discount_Amount>0.25*(Total_Amount+Discount_Amount)+1) b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q16', N'core.Customer', N'E-mail only example.com / .test', (SELECT COUNT(*) FROM core.Customer WHERE Email IS NOT NULL), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Customer_ID AS k FROM core.Customer WHERE Email IS NOT NULL AND Email NOT LIKE N'%@example.com' AND Email NOT LIKE N'%.test') b;


INSERT #R (Test_ID,Table_Name,Definition,Checked,Errors,Sample_ID)
SELECT N'Q16', N'core.Customer', N'Phone/Mobile only in the fictional 000-... format', (SELECT COUNT(*) FROM core.Customer), COUNT(*), CONVERT(nvarchar(60), MIN(k)) FROM (SELECT Customer_ID AS k FROM core.Customer WHERE (Phone IS NOT NULL AND Phone NOT LIKE N'000-%') OR (Mobile IS NOT NULL AND Mobile NOT LIKE N'000-%')) b;

SELECT Test_ID, Table_Name, Definition, Checked, Errors, Sample_ID,
       CASE WHEN Test_ID = N'Q01' THEN N'Info' WHEN Errors = 0 THEN N'Pass' ELSE N'Fail' END AS Result
FROM #R ORDER BY Seq;

/* Q15 - distribution sanity (informational) */
SELECT N'Orders per year' AS Metric, YEAR(c.Calendar_Date) AS K, COUNT(*) AS V FROM sales.SalesOrder so JOIN core.Calendar c ON c.Calendar_ID=so.Calendar_ID GROUP BY YEAR(c.Calendar_Date)
UNION ALL SELECT N'Orders per month', MONTH(c.Calendar_Date), COUNT(*) FROM sales.SalesOrder so JOIN core.Calendar c ON c.Calendar_ID=so.Calendar_ID GROUP BY MONTH(c.Calendar_Date)
UNION ALL SELECT N'Orders per channel', so.Sales_Channel_ID, COUNT(*) FROM sales.SalesOrder so GROUP BY so.Sales_Channel_ID
UNION ALL SELECT N'Order status', NULL, COUNT(*) FROM sales.SalesOrder GROUP BY Order_Status
UNION ALL SELECT N'Invoice status', NULL, COUNT(*) FROM sales.Invoice GROUP BY Invoice_Status
UNION ALL SELECT N'Customers without any order', NULL, COUNT(*) FROM core.Customer c WHERE NOT EXISTS (SELECT 1 FROM sales.SalesOrder so WHERE so.Customer_ID=c.Customer_ID)
UNION ALL SELECT N'Return rate (items x 1000)', NULL, (SELECT COUNT(*) FROM sales.ReturnRequest)*1000/NULLIF((SELECT COUNT(*) FROM sales.SalesOrderItem),0)
ORDER BY 1, 2;
GO

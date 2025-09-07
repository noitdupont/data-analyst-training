-- View Creation and Management
-- Sales Dashboard View
CREATE VIEW SalesDashboard AS
SELECT 
    o.OrderID,
    o.OrderDate,
    YEAR(o.OrderDate) AS OrderYear,
    MONTH(o.OrderDate) AS OrderMonth,
    c.CustomerID,
    c.CustomerName,
    c.City AS CustomerCity,
    c.Country AS CustomerCountry,
    CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
    p.ProductID,
    p.ProductName,
    cat.CategoryName,
    s.SupplierName,
    s.Country AS SupplierCountry,
    od.Quantity,
    p.Price AS UnitPrice,
    (od.Quantity * p.Price) AS LineTotal,
    sh.ShipperName,
    CASE 
        WHEN (od.Quantity * p.Price) > 1000 THEN 'High Value'
        WHEN (od.Quantity * p.Price) > 500 THEN 'Medium Value'
        ELSE 'Standard Value'
    END AS OrderValueCategory,
    CASE 
        WHEN c.Country IN ('USA', 'Canada') THEN 'North America'
        WHEN c.Country IN ('Germany', 'France', 'UK', 'Italy', 'Spain') THEN 'Europe'
        ELSE 'Other Markets'
    END AS Region
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN Employees e ON o.EmployeeID = e.EmployeeID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN Categories cat ON p.CategoryID = cat.CategoryID
JOIN Suppliers s ON p.SupplierID = s.SupplierID
JOIN Shippers sh ON o.ShipperID = sh.ShipperID;

-- Security-Focused Regional Manager View
-- Create separate views for each region
CREATE VIEW NorthAmericaSales AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.City,
    c.Country,
    o.OrderID,
    o.OrderDate,
    p.ProductName,
    cat.CategoryName,
    od.Quantity,
    (od.Quantity * p.Price) AS Revenue,
    'North America' AS AccessibleRegion
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN Categories cat ON p.CategoryID = cat.CategoryID
WHERE c.Country IN ('USA', 'Canada');

CREATE VIEW EuropeSales AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.City,
    c.Country,
    o.OrderID,
    o.OrderDate,
    p.ProductName,
    cat.CategoryName,
    od.Quantity,
    (od.Quantity * p.Price) AS Revenue,
    'Europe' AS AccessibleRegion
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN Categories cat ON p.CategoryID = cat.CategoryID
WHERE c.Country IN ('Germany', 'France', 'UK', 'Italy', 'Spain', 'Austria', 'Switzerland', 'Belgium', 'Denmark', 'Finland', 'Norway', 'Sweden', 'Poland');

CREATE VIEW OtherMarketsSales AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.City,
    c.Country,
    o.OrderID,
    o.OrderDate,
    p.ProductName,
    cat.CategoryName,
    od.Quantity,
    (od.Quantity * p.Price) AS Revenue,
    'Other Markets' AS AccessibleRegion
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN Categories cat ON p.CategoryID = cat.CategoryID
WHERE c.Country NOT IN ('USA', 'Canada', 'Germany', 'France', 'UK', 'Italy', 'Spain', 'Austria', 'Switzerland', 'Belgium', 'Denmark', 'Finland', 'Norway', 'Sweden', 'Poland');

-- Performance Monitoring View
CREATE VIEW PerformanceMetrics AS
SELECT 
    YEAR(o.OrderDate) AS MetricYear,
    MONTH(o.OrderDate) AS MetricMonth,
    DATE_FORMAT(o.OrderDate, '%Y-%m') AS YearMonth,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    COUNT(DISTINCT c.CustomerID) AS ActiveCustomers,
    COUNT(DISTINCT p.ProductID) AS ProductsSold,
    SUM(od.Quantity) AS TotalQuantitySold,
    SUM(od.Quantity * p.Price) AS TotalRevenue,
    AVG(od.Quantity * p.Price) AS AvgOrderValue,
    COUNT(DISTINCT c.Country) AS CountriesServed,
    COUNT(DISTINCT cat.CategoryID) AS CategoriesSold,
    MAX(od.Quantity * p.Price) AS LargestOrderValue,
    MIN(od.Quantity * p.Price) AS SmallestOrderValue
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN Categories cat ON p.CategoryID = cat.CategoryID
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate), DATE_FORMAT(o.OrderDate, '%Y-%m')
ORDER BY MetricYear, MetricMonth;

-- Stored Procedure Development
-- Flexible Reporting Procedure
DELIMITER //
CREATE PROCEDURE FlexibleSalesReport(
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_country VARCHAR(50),
    IN p_category_id INT
)
BEGIN
    DECLARE sql_query TEXT;
    DECLARE where_conditions TEXT DEFAULT '';
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @error_message = MESSAGE_TEXT;
        SELECT CONCAT('Error in flexible report: ', @error_message) AS ErrorMessage;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- Build dynamic WHERE conditions
    SET where_conditions = 'WHERE 1=1 ';
    
    IF p_start_date IS NOT NULL THEN
        SET where_conditions = CONCAT(where_conditions, 'AND o.OrderDate >= "', p_start_date, '" ');
    END IF;
    
    IF p_end_date IS NOT NULL THEN
        SET where_conditions = CONCAT(where_conditions, 'AND o.OrderDate <= "', p_end_date, '" ');
    END IF;
    
    IF p_country IS NOT NULL AND p_country != '' THEN
        SET where_conditions = CONCAT(where_conditions, 'AND c.Country = "', p_country, '" ');
    END IF;
    
    IF p_category_id IS NOT NULL AND p_category_id > 0 THEN
        SET where_conditions = CONCAT(where_conditions, 'AND p.CategoryID = ', p_category_id, ' ');
    END IF;
    
    SET sql_query = CONCAT(
        'SELECT ',
        'c.CustomerName, ',
        'c.Country, ',
        'cat.CategoryName, ',
        'p.ProductName, ',
        'o.OrderDate, ',
        'od.Quantity, ',
        'p.Price, ',
        '(od.Quantity * p.Price) AS LineTotal ',
        'FROM Orders o ',
        'JOIN Customers c ON o.CustomerID = c.CustomerID ',
        'JOIN OrderDetails od ON o.OrderID = od.OrderID ',
        'JOIN Products p ON od.ProductID = p.ProductID ',
        'JOIN Categories cat ON p.CategoryID = cat.CategoryID ',
        where_conditions,
        'ORDER BY o.OrderDate DESC, LineTotal DESC'
    );
    
    SET @sql = sql_query;
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    COMMIT;
END //
DELIMITER ;

-- Customer Segmentation Procedure
DELIMITER //
CREATE PROCEDURE SegmentCustomers()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Create temporary table for customer metrics
    DROP TEMPORARY TABLE IF EXISTS CustomerMetrics;
    CREATE TEMPORARY TABLE CustomerMetrics (
        CustomerID INT,
        CustomerName VARCHAR(50),
        Country VARCHAR(15),
        TotalOrders INT,
        TotalRevenue DECIMAL(10,2),
        AvgOrderValue DECIMAL(10,2),
        DaysSinceLastOrder INT,
        CategoryCount INT,
        Segment VARCHAR(20)
    );
    
    -- Calculate customer metrics
    INSERT INTO CustomerMetrics (CustomerID, CustomerName, Country, TotalOrders, TotalRevenue, AvgOrderValue, DaysSinceLastOrder, CategoryCount)
    SELECT 
        c.CustomerID,
        c.CustomerName,
        c.Country,
        COUNT(DISTINCT o.OrderID) AS TotalOrders,
        COALESCE(SUM(od.Quantity * p.Price), 0) AS TotalRevenue,
        COALESCE(AVG(od.Quantity * p.Price), 0) AS AvgOrderValue,
        COALESCE(DATEDIFF('1998-05-06', MAX(o.OrderDate)), 9999) AS DaysSinceLastOrder,
        COUNT(DISTINCT p.CategoryID) AS CategoryCount
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
    LEFT JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY c.CustomerID, c.CustomerName, c.Country;
    
    -- Apply segmentation logic
    UPDATE CustomerMetrics 
    SET Segment = CASE
        WHEN TotalRevenue >= 10000 AND DaysSinceLastOrder <= 90 THEN 'VIP Active'
        WHEN TotalRevenue >= 5000 AND DaysSinceLastOrder <= 180 THEN 'High Value'
        WHEN TotalRevenue >= 1000 AND DaysSinceLastOrder <= 365 THEN 'Regular'
        WHEN TotalOrders > 0 AND DaysSinceLastOrder > 365 THEN 'At Risk'
        WHEN TotalOrders = 0 THEN 'Prospect'
        ELSE 'Low Value'
    END;
    
    -- Return segmentation results
    SELECT 
        Segment,
        COUNT(*) AS CustomerCount,
        AVG(TotalRevenue) AS AvgRevenue,
        AVG(TotalOrders) AS AvgOrders,
        AVG(AvgOrderValue) AS AvgOrderValue,
        AVG(CategoryCount) AS AvgCategories
    FROM CustomerMetrics
    GROUP BY Segment
    ORDER BY AvgRevenue DESC;
    
    -- Detailed customer list by segment
    SELECT 
        CustomerID,
        CustomerName,
        Country,
        TotalOrders,
        TotalRevenue,
        AvgOrderValue,
        DaysSinceLastOrder,
        CategoryCount,
        Segment
    FROM CustomerMetrics
    ORDER BY Segment, TotalRevenue DESC;
    
    COMMIT;
END //
DELIMITER ;

-- Data Quality Validation Procedure
DELIMITER //
CREATE PROCEDURE ValidateDataQuality()
BEGIN
    DECLARE issue_count INT DEFAULT 0;
    
    -- Create temporary table for issues
    DROP TEMPORARY TABLE IF EXISTS DataQualityIssues;
    CREATE TEMPORARY TABLE DataQualityIssues (
        IssueType VARCHAR(50),
        TableName VARCHAR(50),
        IssueDescription TEXT,
        RecordCount INT
    );
    
    -- Check for orders without order details
    INSERT INTO DataQualityIssues
    SELECT 
        'Orphaned Records',
        'Orders',
        'Orders without corresponding OrderDetails',
        COUNT(*)
    FROM Orders o
    LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
    WHERE od.OrderID IS NULL;
    
    -- Check for order details with invalid product references
    INSERT INTO DataQualityIssues
    SELECT 
        'Referential Integrity',
        'OrderDetails',
        'OrderDetails with invalid ProductID references',
        COUNT(*)
    FROM OrderDetails od
    LEFT JOIN Products p ON od.ProductID = p.ProductID
    WHERE p.ProductID IS NULL;
    
    -- Check for negative quantities
    INSERT INTO DataQualityIssues
    SELECT 
        'Data Validity',
        'OrderDetails',
        'OrderDetails with negative or zero quantities',
        COUNT(*)
    FROM OrderDetails
    WHERE Quantity <= 0;
    
    -- Check for products without categories
    INSERT INTO DataQualityIssues
    SELECT 
        'Missing Data',
        'Products',
        'Products without valid CategoryID',
        COUNT(*)
    FROM Products p
    LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
    WHERE c.CategoryID IS NULL;
    
    -- Check for customers without orders
    INSERT INTO DataQualityIssues
    SELECT 
        'Business Logic',
        'Customers',
        'Customers with no order history',
        COUNT(*)
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    WHERE o.CustomerID IS NULL;
    
    -- Check for future order dates
    INSERT INTO DataQualityIssues
    SELECT 
        'Data Validity',
        'Orders',
        'Orders with future dates',
        COUNT(*)
    FROM Orders
    WHERE OrderDate > CURDATE();
    
    -- Check for products with zero or negative prices
    INSERT INTO DataQualityIssues
    SELECT 
        'Data Validity',
        'Products',
        'Products with zero or negative prices',
        COUNT(*)
    FROM Products
    WHERE Price <= 0;
    
    -- Return summary of issues
    SELECT 
        IssueType,
        TableName,
        IssueDescription,
        RecordCount
    FROM DataQualityIssues
    WHERE RecordCount > 0
    ORDER BY RecordCount DESC;
    
    -- Return overall data quality score
    SELECT 
        COUNT(*) AS TotalIssueTypes,
        SUM(RecordCount) AS TotalProblemRecords,
        CASE 
            WHEN SUM(RecordCount) = 0 THEN 'Excellent'
            WHEN SUM(RecordCount) <= 5 THEN 'Good'
            WHEN SUM(RecordCount) <= 20 THEN 'Fair'
            ELSE 'Poor'
        END AS DataQualityRating
    FROM DataQualityIssues
    WHERE RecordCount > 0;
    
END //
DELIMITER ;

-- Functions and Automation
-- Profit Margin Calculation Function
DELIMITER //
CREATE FUNCTION CalculateProfitMargin(
    p_selling_price DECIMAL(10,2),
    p_cost_price DECIMAL(10,2)
)
RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE margin DECIMAL(5,2);
    
    IF p_cost_price IS NULL OR p_cost_price <= 0 THEN
        RETURN NULL;
    END IF;
    
    IF p_selling_price IS NULL OR p_selling_price <= 0 THEN
        RETURN NULL;
    END IF;
    
    SET margin = ((p_selling_price - p_cost_price) / p_selling_price) * 100;
    
    RETURN ROUND(margin, 2);
END //
DELIMITER ;

-- Optimal Reorder Quantity Function
DELIMITER //
CREATE FUNCTION CalculateReorderQuantity(p_product_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE avg_monthly_sales DECIMAL(10,2);
    DECLARE lead_time_months DECIMAL(3,2) DEFAULT 0.5; -- Assuming 2-week lead time
    DECLARE safety_stock_multiplier DECIMAL(3,2) DEFAULT 1.5;
    DECLARE reorder_qty INT;
    
    -- Calculate average monthly sales for the product
    SELECT 
        COALESCE(AVG(monthly_sales), 0) INTO avg_monthly_sales
    FROM (
        SELECT 
            YEAR(o.OrderDate) AS order_year,
            MONTH(o.OrderDate) AS order_month,
            SUM(od.Quantity) AS monthly_sales
        FROM Orders o
        JOIN OrderDetails od ON o.OrderID = od.OrderID
        WHERE od.ProductID = p_product_id
        GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
    ) monthly_data;
    
    -- Calculate reorder quantity: (average monthly sales * lead time) + safety stock
    SET reorder_qty = CEIL(avg_monthly_sales * lead_time_months * safety_stock_multiplier);
    
    -- Minimum reorder quantity of 1
    IF reorder_qty < 1 THEN
        SET reorder_qty = 1;
    END IF;
    
    RETURN reorder_qty;
END //
DELIMITER ;

-- Audit Trail Triggers
-- Create audit table
CREATE TABLE AuditTrail (
    AuditID INT AUTO_INCREMENT PRIMARY KEY,
    TableName VARCHAR(50),
    Operation VARCHAR(10),
    RecordID INT,
    OldValues JSON,
    NewValues JSON,
    ChangedBy VARCHAR(50),
    ChangeDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products audit trigger
DELIMITER //
CREATE TRIGGER ProductsAudit
    AFTER UPDATE ON Products
    FOR EACH ROW
BEGIN
    INSERT INTO AuditTrail (TableName, Operation, RecordID, OldValues, NewValues, ChangedBy)
    VALUES (
        'Products',
        'UPDATE',
        NEW.ProductID,
        JSON_OBJECT(
            'ProductName', OLD.ProductName,
            'Price', OLD.Price,
            'CategoryID', OLD.CategoryID,
            'SupplierID', OLD.SupplierID
        ),
        JSON_OBJECT(
            'ProductName', NEW.ProductName,
            'Price', NEW.Price,
            'CategoryID', NEW.CategoryID,
            'SupplierID', NEW.SupplierID
        ),
        USER()
    );
END //
DELIMITER ;

-- Orders audit trigger
DELIMITER //
CREATE TRIGGER OrdersAudit
    AFTER INSERT ON Orders
    FOR EACH ROW
BEGIN
    INSERT INTO AuditTrail (TableName, Operation, RecordID, NewValues, ChangedBy)
    VALUES (
        'Orders',
        'INSERT',
        NEW.OrderID,
        JSON_OBJECT(
            'CustomerID', NEW.CustomerID,
            'EmployeeID', NEW.EmployeeID,
            'OrderDate', NEW.OrderDate,
            'ShipperID', NEW.ShipperID
        ),
        USER()
    );
END //
DELIMITER ;

-- Advanced Integration Projects
-- Monthly Business Reporting Framework
DELIMITER //
CREATE PROCEDURE GenerateMonthlyBusinessReport(
    IN p_report_year INT,
    IN p_report_month INT
)
BEGIN
    DECLARE report_start_date DATE;
    DECLARE report_end_date DATE;
    
    SET report_start_date = DATE(CONCAT(p_report_year, '-', LPAD(p_report_month, 2, '0'), '-01'));
    SET report_end_date = LAST_DAY(report_start_date);
    
    -- Sales Summary
    SELECT 'SALES SUMMARY' AS ReportSection;
    SELECT 
        COUNT(DISTINCT o.OrderID) AS TotalOrders,
        COUNT(DISTINCT c.CustomerID) AS ActiveCustomers,
        SUM(od.Quantity * p.Price) AS TotalRevenue,
        AVG(od.Quantity * p.Price) AS AvgOrderValue
    FROM Orders o
    JOIN Customers c ON o.CustomerID = c.CustomerID
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE o.OrderDate BETWEEN report_start_date AND report_end_date;
    
    -- Top Products
    SELECT 'TOP PRODUCTS' AS ReportSection;
    SELECT 
        p.ProductName,
        cat.CategoryName,
        SUM(od.Quantity) AS TotalQuantitySold,
        SUM(od.Quantity * p.Price) AS TotalRevenue,
        CalculateProfitMargin(p.Price, p.Price * 0.6) AS EstimatedMargin
    FROM Products p
    JOIN Categories cat ON p.CategoryID = cat.CategoryID
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    JOIN Orders o ON od.OrderID = o.OrderID
    WHERE o.OrderDate BETWEEN report_start_date AND report_end_date
    GROUP BY p.ProductID, p.ProductName, cat.CategoryName
    ORDER BY TotalRevenue DESC
    LIMIT 10;
    
    -- Customer Performance
    SELECT 'CUSTOMER PERFORMANCE' AS ReportSection;
    SELECT 
        c.CustomerName,
        c.Country,
        COUNT(o.OrderID) AS OrderCount,
        SUM(od.Quantity * p.Price) AS TotalRevenue
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE o.OrderDate BETWEEN report_start_date AND report_end_date
    GROUP BY c.CustomerID, c.CustomerName, c.Country
    ORDER BY TotalRevenue DESC
    LIMIT 10;
    
END //
DELIMITER ;

-- Customer Lifecycle Management System
DELIMITER //
CREATE PROCEDURE ManageCustomerLifecycle()
BEGIN
    -- Update customer tiers based on recent activity
    DROP TEMPORARY TABLE IF EXISTS CustomerTierUpdates;
    CREATE TEMPORARY TABLE CustomerTierUpdates (
        CustomerID INT,
        CurrentTier VARCHAR(20),
        RecommendedAction VARCHAR(100)
    );
    
    -- Identify customers for tier promotion
    INSERT INTO CustomerTierUpdates
    SELECT 
        c.CustomerID,
        'Promotion Candidate',
        CONCAT('Promote to Premium - Revenue: $', ROUND(SUM(od.Quantity * p.Price), 2))
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE o.OrderDate >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY c.CustomerID
    HAVING SUM(od.Quantity * p.Price) > 5000;
    
    -- Identify at-risk customers
    INSERT INTO CustomerTierUpdates
    SELECT 
        c.CustomerID,
        'At Risk',
        'Send retention campaign - No orders in 6+ months'
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    WHERE c.CustomerID NOT IN (
        SELECT DISTINCT CustomerID 
        FROM Orders 
        WHERE OrderDate >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    )
    AND c.CustomerID IN (
        SELECT DISTINCT CustomerID 
        FROM Orders 
        WHERE OrderDate >= DATE_SUB(CURDATE(), INTERVAL 24 MONTH)
    );
    
    -- Return recommendations
    SELECT * FROM CustomerTierUpdates;
    
END //
DELIMITER ;

-- Performance Monitoring System with Alerts
-- Create performance alerts table
CREATE TABLE PerformanceAlerts (
    AlertID INT AUTO_INCREMENT PRIMARY KEY,
    AlertType VARCHAR(50),
    AlertMessage TEXT,
    MetricValue DECIMAL(10,2),
    ThresholdValue DECIMAL(10,2),
    AlertDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Resolved BOOLEAN DEFAULT FALSE
);

DELIMITER //
CREATE PROCEDURE MonitorPerformanceMetrics()
BEGIN
    DECLARE daily_revenue DECIMAL(10,2);
    DECLARE daily_orders INT;
    DECLARE avg_order_value DECIMAL(10,2);
    DECLARE active_customers INT;
    
    -- Calculate today's metrics (using latest available date from data)
    SELECT 
        COALESCE(SUM(od.Quantity * p.Price), 0),
        COUNT(DISTINCT o.OrderID),
        COALESCE(AVG(od.Quantity * p.Price), 0),
        COUNT(DISTINCT o.CustomerID)
    INTO daily_revenue, daily_orders, avg_order_value, active_customers
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE DATE(o.OrderDate) = (SELECT MAX(DATE(OrderDate)) FROM Orders);
    
    -- Check revenue threshold
    IF daily_revenue < 5000 THEN
        INSERT INTO PerformanceAlerts (AlertType, AlertMessage, MetricValue, ThresholdValue)
        VALUES ('Low Revenue', 'Daily revenue below threshold', daily_revenue, 5000);
    END IF;
    
    -- Check order volume threshold
    IF daily_orders < 10 THEN
        INSERT INTO PerformanceAlerts (AlertType, AlertMessage, MetricValue, ThresholdValue)
        VALUES ('Low Order Volume', 'Daily orders below threshold', daily_orders, 10);
    END IF;
    
    -- Check average order value
    IF avg_order_value < 100 THEN
        INSERT INTO PerformanceAlerts (AlertType, AlertMessage, MetricValue, ThresholdValue)
        VALUES ('Low AOV', 'Average order value below threshold', avg_order_value, 100);
    END IF;
    
    -- Return current alerts
    SELECT 
        AlertType,
        AlertMessage,
        MetricValue,
        ThresholdValue,
        AlertDate
    FROM PerformanceAlerts
    WHERE Resolved = FALSE
    ORDER BY AlertDate DESC;
    
END //
DELIMITER ;

-- Create trigger to automatically monitor performance
DELIMITER //
CREATE TRIGGER AutoPerformanceMonitor
    AFTER INSERT ON OrderDetails
    FOR EACH ROW
BEGIN
    -- Call monitoring procedure for every 10th order detail insert
    IF (SELECT COUNT(*) FROM OrderDetails) % 10 = 0 THEN
        CALL MonitorPerformanceMetrics();
    END IF;
END //
DELIMITER ;
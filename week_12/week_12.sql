-- Introduction to Database Objects
-- Simple view for customer order summary
CREATE VIEW CustomerOrderSummary AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Country,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(od.Quantity * p.Price) AS TotalRevenue
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
LEFT JOIN Products p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.CustomerName, c.Country;

-- Using the view
SELECT * FROM CustomerOrderSummary WHERE Country = 'Germany';

-- Views - Data Abstraction and Security
-- Security-focused view hiding sensitive customer data
CREATE VIEW PublicCustomerInfo AS
SELECT 
    CustomerID,
    CustomerName,
    City,
    Country,
    CASE 
        WHEN Country IN ('USA', 'Canada') THEN 'North America'
        WHEN Country IN ('Germany', 'France', 'UK') THEN 'Europe'
        ELSE 'Other'
    END AS Region
FROM Customers;

-- Complex analytical view for sales performance
CREATE VIEW MonthlySalesAnalysis AS
SELECT 
    YEAR(o.OrderDate) AS SalesYear,
    MONTH(o.OrderDate) AS SalesMonth,
    c.CategoryName,
    COUNT(DISTINCT o.OrderID) AS OrderCount,
    SUM(od.Quantity) AS TotalQuantity,
    SUM(od.Quantity * p.Price) AS MonthlyRevenue,
    AVG(od.Quantity * p.Price) AS AvgOrderValue
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN Categories c ON p.CategoryID = c.CategoryID
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate), c.CategoryID, c.CategoryName;

-- Using the analytical view
SELECT 
    SalesYear,
    SalesMonth,
    CategoryName,
    MonthlyRevenue,
    LAG(MonthlyRevenue) OVER (PARTITION BY CategoryName ORDER BY SalesYear, SalesMonth) AS PrevMonthRevenue
FROM MonthlySalesAnalysis
WHERE SalesYear = 1997
ORDER BY CategoryName, SalesMonth;

-- Stored Procedures - Encapsulating Business Logic
-- Customer analysis procedure with parameters
DELIMITER //
CREATE PROCEDURE GetCustomerAnalysis(
    IN p_country VARCHAR(50),
    IN p_min_orders INT,
    OUT p_total_customers INT,
    OUT p_avg_revenue DECIMAL(10,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    SELECT 
        COUNT(*) INTO p_total_customers
    FROM CustomerOrderSummary 
    WHERE Country = p_country AND TotalOrders >= p_min_orders;
    
    SELECT 
        AVG(TotalRevenue) INTO p_avg_revenue
    FROM CustomerOrderSummary 
    WHERE Country = p_country AND TotalOrders >= p_min_orders;
    
    COMMIT;
END //
DELIMITER ;

-- Product performance analysis procedure
DELIMITER //
CREATE PROCEDURE AnalyseProductPerformance(
    IN p_category_id INT,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT 
        p.ProductID,
        p.ProductName,
        COUNT(DISTINCT o.OrderID) AS OrderFrequency,
        SUM(od.Quantity) AS TotalQuantitySold,
        SUM(od.Quantity * p.Price) AS TotalRevenue,
        AVG(od.Quantity) AS AvgQuantityPerOrder,
        RANK() OVER (ORDER BY SUM(od.Quantity * p.Price) DESC) AS RevenueRank
    FROM Products p
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    JOIN Orders o ON od.OrderID = o.OrderID
    WHERE p.CategoryID = p_category_id
        AND o.OrderDate BETWEEN p_start_date AND p_end_date
    GROUP BY p.ProductID, p.ProductName
    HAVING SUM(od.Quantity * p.Price) > 0
    ORDER BY TotalRevenue DESC;
END //
DELIMITER ;

-- Using the procedures
CALL GetCustomerAnalysis('Germany', 2, @total_customers, @avg_revenue);
SELECT @total_customers AS TotalCustomers, @avg_revenue AS AverageRevenue;
CALL AnalyseProductPerformance(1, '1996-01-01', '1996-12-31');

-- Advanced Stored Procedure Techniques
-- Dynamic report generation procedure
DELIMITER //
CREATE PROCEDURE GenerateDynamicSalesReport(
    IN p_group_by VARCHAR(20),  -- 'country', 'category', 'employee'
    IN p_year INT,
    IN p_top_n INT
)
BEGIN
    DECLARE sql_statement TEXT;
    DECLARE v_top_n INT DEFAULT 10;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @error_message = MESSAGE_TEXT;
        SELECT CONCAT('Error in report generation: ', @error_message) AS ErrorMessage;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- Handle default value for top_n
    IF p_top_n IS NULL OR p_top_n <= 0 THEN
        SET v_top_n = 10;
    ELSE
        SET v_top_n = p_top_n;
    END IF;
    
    CASE p_group_by
        WHEN 'country' THEN
            SET sql_statement = CONCAT(
                'SELECT c.Country, ',
                'COUNT(DISTINCT o.OrderID) AS TotalOrders, ',
                'SUM(od.Quantity * p.Price) AS TotalRevenue ',
                'FROM Customers c ',
                'JOIN Orders o ON c.CustomerID = o.CustomerID ',
                'JOIN OrderDetails od ON o.OrderID = od.OrderID ',
                'JOIN Products p ON od.ProductID = p.ProductID ',
                'WHERE YEAR(o.OrderDate) = ', p_year, ' ',
                'GROUP BY c.Country ',
                'ORDER BY TotalRevenue DESC ',
                'LIMIT ', v_top_n
            );
            
        WHEN 'category' THEN
            SET sql_statement = CONCAT(
                'SELECT cat.CategoryName, ',
                'COUNT(DISTINCT o.OrderID) AS TotalOrders, ',
                'SUM(od.Quantity * p.Price) AS TotalRevenue ',
                'FROM Categories cat ',
                'JOIN Products p ON cat.CategoryID = p.CategoryID ',
                'JOIN OrderDetails od ON p.ProductID = od.ProductID ',
                'JOIN Orders o ON od.OrderID = o.OrderID ',
                'WHERE YEAR(o.OrderDate) = ', p_year, ' ',
                'GROUP BY cat.CategoryID, cat.CategoryName ',
                'ORDER BY TotalRevenue DESC ',
                'LIMIT ', v_top_n
            );
            
        WHEN 'employee' THEN
            SET sql_statement = CONCAT(
                'SELECT CONCAT(e.FirstName, " ", e.LastName) AS EmployeeName, ',
                'COUNT(DISTINCT o.OrderID) AS TotalOrders, ',
                'SUM(od.Quantity * p.Price) AS TotalRevenue ',
                'FROM Employees e ',
                'JOIN Orders o ON e.EmployeeID = o.EmployeeID ',
                'JOIN OrderDetails od ON o.OrderID = od.OrderID ',
                'JOIN Products p ON od.ProductID = p.ProductID ',
                'WHERE YEAR(o.OrderDate) = ', p_year, ' ',
                'GROUP BY e.EmployeeID, e.FirstName, e.LastName ',
                'ORDER BY TotalRevenue DESC ',
                'LIMIT ', v_top_n
            );
            
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid group_by parameter. Use: country, category, or employee';
    END CASE;
    
    SET @sql = sql_statement;
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    COMMIT;
END //
DELIMITER ;

-- Batch processing procedure with cursor
DELIMITER //
CREATE PROCEDURE ProcessCustomerTiers()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_customer_id INT;
    DECLARE v_total_revenue DECIMAL(10,2);
    DECLARE v_tier VARCHAR(20);
    
    DECLARE customer_cursor CURSOR FOR
        SELECT CustomerID, TotalRevenue 
        FROM CustomerOrderSummary 
        WHERE TotalRevenue IS NOT NULL;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Create temporary table for results
    CREATE TEMPORARY TABLE IF NOT EXISTS CustomerTiers (
        CustomerID INT,
        TotalRevenue DECIMAL(10,2),
        Tier VARCHAR(20),
        ProcessedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    OPEN customer_cursor;
    
    customer_loop: LOOP
        FETCH customer_cursor INTO v_customer_id, v_total_revenue;
        
        IF done THEN
            LEAVE customer_loop;
        END IF;
        
        -- Determine tier based on revenue
        CASE
            WHEN v_total_revenue >= 10000 THEN SET v_tier = 'Platinum';
            WHEN v_total_revenue >= 5000 THEN SET v_tier = 'Gold';
            WHEN v_total_revenue >= 1000 THEN SET v_tier = 'Silver';
            ELSE SET v_tier = 'Bronze';
        END CASE;
        
        INSERT INTO CustomerTiers (CustomerID, TotalRevenue, Tier)
        VALUES (v_customer_id, v_total_revenue, v_tier);
        
    END LOOP;
    
    CLOSE customer_cursor;
    
    -- Return results
    SELECT 
        Tier,
        COUNT(*) AS CustomerCount,
        AVG(TotalRevenue) AS AvgRevenue,
        MIN(TotalRevenue) AS MinRevenue,
        MAX(TotalRevenue) AS MaxRevenue
    FROM CustomerTiers
    GROUP BY Tier
    ORDER BY AvgRevenue DESC;
    
END //
DELIMITER ;

-- Using advanced procedures
CALL GenerateDynamicSalesReport('country', 1997, 5);
CALL ProcessCustomerTiers();

-- Functions and Triggers for Automation
-- Scalar function for customer lifetime value calculation
DELIMITER //
CREATE FUNCTION CalculateCustomerLTV(p_customer_id INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE ltv DECIMAL(10,2) DEFAULT 0;
    
    SELECT 
        COALESCE(SUM(od.Quantity * p.Price), 0) INTO ltv
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE o.CustomerID = p_customer_id;
    
    RETURN ltv;
END //
DELIMITER ;

-- Table-valued function equivalent (using procedure)
DELIMITER //
CREATE PROCEDURE GetTopProductsByCategory(IN p_category_id INT, IN p_limit INT)
BEGIN
    SELECT 
        p.ProductID,
        p.ProductName,
        SUM(od.Quantity) AS TotalSold,
        SUM(od.Quantity * p.Price) AS TotalRevenue,
        RANK() OVER (ORDER BY SUM(od.Quantity * p.Price) DESC) AS RevenueRank
    FROM Products p
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    WHERE p.CategoryID = p_category_id
    GROUP BY p.ProductID, p.ProductName
    ORDER BY TotalRevenue DESC
    LIMIT p_limit;
END //
DELIMITER ;

-- Audit trigger for order tracking
CREATE TABLE OrderAudit (
    AuditID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT,
    Action VARCHAR(10),
    OldCustomerID INT,
    NewCustomerID INT,
    OldOrderDate DATE,
    NewOrderDate DATE,
    ModifiedBy VARCHAR(50),
    ModifiedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER OrderUpdateAudit
    AFTER UPDATE ON Orders
    FOR EACH ROW
BEGIN
    INSERT INTO OrderAudit (
        OrderID, Action, OldCustomerID, NewCustomerID, 
        OldOrderDate, NewOrderDate, ModifiedBy
    )
    VALUES (
        NEW.OrderID, 'UPDATE', OLD.CustomerID, NEW.CustomerID,
        OLD.OrderDate, NEW.OrderDate, USER()
    );
END //
DELIMITER ;

-- Automatic derived field calculation trigger
DELIMITER //
CREATE TRIGGER CalculateOrderTotal
    AFTER INSERT ON OrderDetails
    FOR EACH ROW
BEGIN
    DECLARE order_total DECIMAL(10,2);
    
    -- Calculate total for the order
    SELECT SUM(od.Quantity * p.Price) INTO order_total
    FROM OrderDetails od
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE od.OrderID = NEW.OrderID;
    
    -- Update a hypothetical order total field
    -- UPDATE Orders SET OrderTotal = order_total WHERE OrderID = NEW.OrderID;
    
    -- Log the calculation for audit purposes
    INSERT INTO OrderAudit (OrderID, Action, ModifiedBy)
    VALUES (NEW.OrderID, 'CALCULATE', USER());
END //
DELIMITER ;

-- Using functions
SELECT 
    CustomerName,
    CalculateCustomerLTV(CustomerID) AS LifetimeValue
FROM Customers
WHERE Country = 'Germany'
ORDER BY LifetimeValue DESC
LIMIT 10;

CALL GetTopProductsByCategory(1, 5);

-- Assignment Starting Point
-- Basic view template
CREATE VIEW SalesSummaryView AS
SELECT 
    c.CustomerName,
    c.Country,
    -- Add your calculations here
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Basic procedure template
DELIMITER //
CREATE PROCEDURE AnalyseSales(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    -- Add your business logic here
    SELECT 'Analysis complete' AS Status;
END //
DELIMITER ;

-- Basic function template
DELIMITER //
CREATE FUNCTION CalculateMetric(p_value DECIMAL(10,2))
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    -- Add your calculation logic here
    RETURN p_value;
END //
DELIMITER ;
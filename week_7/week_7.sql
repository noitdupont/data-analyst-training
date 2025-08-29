-- Introduction to Aggregate Functions
-- Individual product prices (raw data)
SELECT ProductName, Price FROM Products;

-- Aggregate insights (business intelligence)
SELECT COUNT(*) AS TotalProducts,
       AVG(Price) AS AveragePrice,
       MIN(Price) AS CheapestProduct,
       MAX(Price) AS MostExpensiveProduct
FROM Products;

-- COUNT Function Deep Dive
-- Different COUNT variations
SELECT COUNT(*) AS AllRows,
       COUNT(PostalCode) AS RowsWithPostalCode,
       COUNT(DISTINCT Country) AS UniqueCountries
FROM Customers;

-- COUNT with GROUP BY
SELECT Country, 
       COUNT(*) AS TotalCustomers,
       COUNT(PostalCode) AS CustomersWithPostalCode
FROM Customers 
GROUP BY Country
ORDER BY TotalCustomers DESC;

-- Finding missing data patterns
SELECT 
    CASE 
        WHEN PostalCode IS NULL THEN 'Missing Postal Code'
        ELSE 'Has Postal Code'
    END AS DataStatus,
    COUNT(*) AS CustomerCount
FROM Customers
GROUP BY 
    CASE 
        WHEN PostalCode IS NULL THEN 'Missing Postal Code'
        ELSE 'Has Postal Code'
    END;

-- SUM and Mathematical Aggregates
-- Basic SUM operations
SELECT SUM(Price) AS TotalInventoryValue
FROM Products;

-- SUM with calculations
SELECT CategoryID,
       COUNT(*) AS ProductCount,
       SUM(Price) AS TotalCategoryValue,
       SUM(Price * 1.2) AS ValueWithTax
FROM Products 
GROUP BY CategoryID;

-- Revenue calculations (requires JOIN)
SELECT c.CategoryName,
       SUM(od.Quantity * p.Price) AS CategoryRevenue,
       COUNT(DISTINCT od.OrderID) AS OrdersInCategory
FROM Categories c
JOIN Products p ON c.CategoryID = p.CategoryID
JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY c.CategoryID, c.CategoryName
ORDER BY CategoryRevenue DESC;

-- AVG, MIN, and MAX Functions
-- Statistical analysis of product prices
SELECT CategoryID,
       COUNT(*) AS ProductCount,
       ROUND(AVG(Price), 2) AS AveragePrice,
       MIN(Price) AS LowestPrice,
       MAX(Price) AS HighestPrice,
       ROUND(MAX(Price) - MIN(Price), 2) AS PriceRange
FROM Products 
GROUP BY CategoryID
ORDER BY AveragePrice DESC;

-- Customer order patterns
SELECT c.Country,
       COUNT(DISTINCT c.CustomerID) AS CustomerCount,
       COUNT(o.OrderID) AS TotalOrders,
       ROUND(AVG(order_values.OrderValue), 2) AS AvgOrderValue,
       MIN(order_values.OrderValue) AS SmallestOrder,
       MAX(order_values.OrderValue) AS LargestOrder
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN (
    SELECT OrderID, SUM(Quantity * 
        (SELECT Price FROM Products WHERE ProductID = od.ProductID)
    ) AS OrderValue
    FROM OrderDetails od
    GROUP BY OrderID
) order_values ON o.OrderID = order_values.OrderID
GROUP BY c.Country
HAVING COUNT(o.OrderID) >= 5
ORDER BY AvgOrderValue DESC;

-- Advanced Aggregate Techniques
-- Conditional aggregates
SELECT c.CategoryName,
       COUNT(*) AS TotalProducts,
       SUM(CASE WHEN p.Price < 20 THEN 1 ELSE 0 END) AS BudgetProducts,
       SUM(CASE WHEN p.Price >= 20 AND p.Price < 50 THEN 1 ELSE 0 END) AS MidRangeProducts,
       SUM(CASE WHEN p.Price >= 50 THEN 1 ELSE 0 END) AS PremiumProducts,
       ROUND(AVG(CASE WHEN p.Price < 20 THEN p.Price END), 2) AS AvgBudgetPrice
FROM Categories c
JOIN Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID, c.CategoryName;

-- Complex business metrics
SELECT 
    customer_metrics.Country,
    COUNT(*) AS CustomerCount,
    ROUND(AVG(customer_metrics.TotalSpent), 2) AS AvgCustomerValue,
    SUM(CASE WHEN customer_metrics.TotalSpent > country_avg.AvgSpending 
             THEN 1 ELSE 0 END) AS AboveAverageCustomers,
    ROUND(country_avg.AvgSpending, 2) AS CountryAverage
FROM (
    SELECT c.CustomerID, c.Country,
           COALESCE(SUM(od.Quantity * p.Price), 0) AS TotalSpent
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
    LEFT JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY c.CustomerID, c.Country
) customer_metrics
JOIN (
    SELECT Country, AVG(TotalSpent) AS AvgSpending
    FROM (
        SELECT c.CustomerID, c.Country,
               COALESCE(SUM(od.Quantity * p.Price), 0) AS TotalSpent
        FROM Customers c
        LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
        LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
        LEFT JOIN Products p ON od.ProductID = p.ProductID
        GROUP BY c.CustomerID, c.Country
    ) inner_metrics
    GROUP BY Country
) country_avg ON customer_metrics.Country = country_avg.Country
GROUP BY customer_metrics.Country, country_avg.AvgSpending
ORDER BY AvgCustomerValue DESC;

-- Assignment Starting Point
-- Assignment 1.1 - Basic product statistics
SELECT COUNT(*) AS TotalProducts,
       ROUND(AVG(Price), 2) AS AveragePrice,
       MIN(Price) AS LowestPrice,
       MAX(Price) AS HighestPrice
FROM Products;

-- Assignment 2.1 - Total business revenue
SELECT SUM(od.Quantity * p.Price) AS TotalRevenue
FROM OrderDetails od
JOIN Products p ON od.ProductID = p.ProductID;

-- Assignment 4.1 - Price segmentation template
SELECT c.CategoryName,
       COUNT(*) AS TotalProducts,
       SUM(CASE WHEN p.Price < 20 THEN 1 ELSE 0 END) AS BudgetProducts
       -- Add more conditional aggregates here
FROM Categories c
JOIN Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID, c.CategoryName;
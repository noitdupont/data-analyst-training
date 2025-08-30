-- Understanding Data Types in MySQL
-- Examine data types in Northwind tables
DESCRIBE Products;
DESCRIBE Orders;
DESCRIBE Customers;

-- Data type demonstrations
SELECT ProductID,           -- INT
       ProductName,         -- VARCHAR
       Price,              -- DECIMAL/NUMERIC
       'Current Stock'     -- String literal
FROM Products
LIMIT 5;

-- String Functions for Text Analysis
-- String analysis and manipulation
SELECT CustomerName,
       LENGTH(CustomerName) AS NameLength,
       UPPER(CustomerName) AS UpperName,
       LOWER(CustomerName) AS LowerName,
       LEFT(CustomerName, 5) AS FirstFiveChars,
       SUBSTRING(CustomerName, 1, 3) AS FirstThreeChars
FROM Customers
WHERE Country = 'Germany'
ORDER BY NameLength DESC;

-- Text cleaning and formatting
SELECT CustomerName,
       TRIM(CustomerName) AS CleanName,
       CONCAT(CustomerName, ' - ', Country) AS FormattedName,
       REPLACE(CustomerName, ' ', '_') AS NoSpaces,
       LOCATE(' ', CustomerName) AS SpacePosition
FROM Customers
WHERE CustomerName LIKE '% %'
LIMIT 10;

-- Extract postal code patterns
SELECT CustomerName,
       PostalCode,
       LENGTH(PostalCode) AS CodeLength,
       CASE 
           WHEN LENGTH(PostalCode) = 5 THEN 'Standard'
           WHEN LENGTH(PostalCode) > 5 THEN 'Extended'
           ELSE 'Short'
       END AS PostalCodeType
FROM Customers
WHERE PostalCode IS NOT NULL
ORDER BY Country, PostalCodeType;

-- Numeric Functions for Mathematical Analysis
-- Price analysis with numeric functions
SELECT ProductName,
       Price,
       ROUND(Price, 0) AS RoundedPrice,
       FLOOR(Price) AS FloorPrice,
       CEILING(Price) AS CeilingPrice,
       ABS(Price - 25) AS DifferenceFromTarget,
       MOD(ROUND(Price), 10) AS PriceEndingDigit
FROM Products
WHERE Price IS NOT NULL
ORDER BY Price DESC
LIMIT 15;

-- Financial calculations
SELECT ProductName,
       Price AS OriginalPrice,
       ROUND(Price * 1.20, 2) AS PriceWithTax,
       ROUND(Price * 0.85, 2) AS DiscountedPrice,
       POWER(Price, 2) AS PriceSquared,
       CASE 
           WHEN Price > SQRT(500) THEN 'High Value'
           ELSE 'Standard Value'
       END AS ValueCategory
FROM Products
WHERE CategoryID = 1
ORDER BY Price DESC;

-- Statistical analysis
SELECT CategoryID,
       COUNT(*) AS ProductCount,
       ROUND(AVG(Price), 2) AS AvgPrice,
       ROUND(MIN(Price), 2) AS MinPrice,
       ROUND(MAX(Price), 2) AS MaxPrice,
       GREATEST(MAX(Price) - AVG(Price), AVG(Price) - MIN(Price)) AS MaxDeviation
FROM Products
GROUP BY CategoryID
ORDER BY AvgPrice DESC;

-- Date and Time Functions
-- Date component analysis
SELECT OrderDate,
       YEAR(OrderDate) AS OrderYear,
       MONTH(OrderDate) AS OrderMonth,
       MONTHNAME(OrderDate) AS MonthName,
       DAYOFWEEK(OrderDate) AS DayOfWeek,
       QUARTER(OrderDate) AS OrderQuarter,
       WEEK(OrderDate) AS WeekNumber
FROM Orders
WHERE YEAR(OrderDate) = 1996
ORDER BY OrderDate
LIMIT 20;

-- Date arithmetic and calculations
SELECT CustomerID,
       MIN(OrderDate) AS FirstOrder,
       MAX(OrderDate) AS LastOrder,
       DATEDIFF(MAX(OrderDate), MIN(OrderDate)) AS DaysBetweenOrders,
       COUNT(*) AS TotalOrders,
       DATEDIFF(CURDATE(), MAX(OrderDate)) AS DaysSinceLastOrder
FROM Orders
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY DaysBetweenOrders DESC
LIMIT 15;

-- Seasonal analysis
SELECT QUARTER(OrderDate) AS Quarter,
       MONTHNAME(OrderDate) AS Month,
       COUNT(*) AS OrderCount,
       ROUND(AVG(DATEDIFF(OrderDate, 
           DATE_SUB(OrderDate, INTERVAL DAYOFMONTH(OrderDate)-1 DAY))), 1) AS AvgDayInMonth
FROM Orders
WHERE YEAR(OrderDate) = 1996
GROUP BY QUARTER(OrderDate), MONTH(OrderDate), MONTHNAME(OrderDate)
ORDER BY Quarter, MONTH(OrderDate);

-- Conditional Functions and Data Transformation
-- Customer categorization using CASE
SELECT CustomerName,
       Country,
       customer_metrics.OrderCount,
       customer_metrics.TotalSpent,
       CASE 
           WHEN customer_metrics.OrderCount >= 10 THEN 'VIP Customer'
           WHEN customer_metrics.OrderCount >= 5 THEN 'Regular Customer'
           WHEN customer_metrics.OrderCount >= 2 THEN 'Occasional Customer'
           ELSE 'New Customer'
       END AS CustomerType,
       CASE 
           WHEN customer_metrics.TotalSpent >= 2000 THEN 'High Value'
           WHEN customer_metrics.TotalSpent >= 1000 THEN 'Medium Value'
           ELSE 'Standard Value'
       END AS ValueSegment
FROM Customers c
JOIN (
    SELECT CustomerID,
           COUNT(*) AS OrderCount,
           SUM(od.Quantity * p.Price) AS TotalSpent
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY CustomerID
) customer_metrics ON c.CustomerID = customer_metrics.CustomerID
ORDER BY customer_metrics.TotalSpent DESC;

-- Product performance scoring
SELECT p.ProductName,
       c.CategoryName,
       p.Price,
       COALESCE(SUM(od.Quantity), 0) AS UnitsSold,
       COALESCE(SUM(od.Quantity * p.Price), 0) AS Revenue,
       IF(SUM(od.Quantity) > 100, 'High Performer', 'Standard Performer') AS SalesStatus,
       CASE 
           WHEN p.Price IS NULL THEN 'No Price'
           WHEN p.Price < 10 THEN 'Budget'
           WHEN p.Price BETWEEN 10 AND 30 THEN 'Standard'
           WHEN p.Price BETWEEN 30 AND 60 THEN 'Premium'
           ELSE 'Luxury'
       END AS PriceCategory,
       IFNULL(ROUND(SUM(od.Quantity * p.Price) / NULLIF(SUM(od.Quantity), 0), 2), 0) AS AvgRevenuePerUnit
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, c.CategoryName, p.Price
ORDER BY Revenue DESC;

-- Assignment Starting Point
-- Assignment 1.1 - Long customer names with formatting
SELECT CustomerName,
       Country,
       LENGTH(CustomerName) AS NameLength,
       CONCAT(UPPER(CustomerName), ' (', Country, ')') AS FormattedName
FROM Customers
WHERE LENGTH(CustomerName) > 20
ORDER BY NameLength DESC;

-- Assignment 2.1 - Price band analysis
SELECT 
    CASE 
        WHEN Price < 15 THEN 'Budget'
        WHEN Price BETWEEN 15 AND 40 THEN 'Standard'
        ELSE 'Premium'
    END AS PriceBand,
    COUNT(*) AS ProductCount,
    ROUND(AVG(Price), 2) AS AvgPrice
FROM Products
GROUP BY -- Complete the CASE statement here
ORDER BY AvgPrice;

-- Assignment 4.1 - Customer scoring template
SELECT c.CustomerName,
       c.Country,
       -- Add scoring calculations here
       CASE 
           WHEN -- Add scoring logic
       END AS CustomerScore
FROM Customers c
-- Add necessary JOINs
ORDER BY -- Add scoring criteria
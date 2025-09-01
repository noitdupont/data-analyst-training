-- Introduction to Advanced SQL Techniques
-- Traditional GROUP BY - loses individual rows
SELECT CustomerID, SUM(od.Quantity * p.Price) AS TotalSpent
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY CustomerID;

-- Window function - preserves individual orders whilst adding calculations
SELECT o.OrderID, o.CustomerID, o.OrderDate,
       SUM(od.Quantity * p.Price) AS OrderValue,
       SUM(SUM(od.Quantity * p.Price)) OVER (PARTITION BY o.CustomerID ORDER BY o.OrderDate) AS RunningTotal
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY o.OrderID, o.CustomerID, o.OrderDate
ORDER BY o.CustomerID, o.OrderDate;

-- Ranking and Row Number Functions
-- Customer ranking by total spending
SELECT c.CustomerName,
       c.Country,
       SUM(od.Quantity * p.Price) AS TotalSpent,
       ROW_NUMBER() OVER (ORDER BY SUM(od.Quantity * p.Price) DESC) AS OverallRank,
       RANK() OVER (PARTITION BY c.Country ORDER BY SUM(od.Quantity * p.Price) DESC) AS CountryRank,
       DENSE_RANK() OVER (ORDER BY SUM(od.Quantity * p.Price) DESC) AS DenseRank,
       NTILE(4) OVER (ORDER BY SUM(od.Quantity * p.Price) DESC) AS Quartile
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.CustomerName, c.Country
ORDER BY TotalSpent DESC;

-- Top 3 products in each category
SELECT ProductName, CategoryName, TotalRevenue, CategoryRank
FROM (
    SELECT p.ProductName,
           c.CategoryName,
           SUM(od.Quantity * p.Price) AS TotalRevenue,
           RANK() OVER (PARTITION BY c.CategoryID ORDER BY SUM(od.Quantity * p.Price) DESC) AS CategoryRank
    FROM Products p
    JOIN Categories c ON p.CategoryID = c.CategoryID
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY p.ProductID, p.ProductName, c.CategoryName, c.CategoryID
) ranked_products
WHERE CategoryRank <= 3
ORDER BY CategoryName, CategoryRank;

-- Aggregate Window Functions
-- Monthly sales with running totals and moving averages
WITH MonthlySales AS (
    SELECT YEAR(o.OrderDate) AS SalesYear,
           MONTH(o.OrderDate) AS SalesMonth,
           SUM(od.Quantity * p.Price) AS MonthlyRevenue
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
)
SELECT SalesYear,
       SalesMonth,
       ROUND(MonthlyRevenue, 2) AS MonthlyRevenue,
       ROUND(SUM(MonthlyRevenue) OVER (ORDER BY SalesYear, SalesMonth), 2) AS RunningTotal,
       ROUND(AVG(MonthlyRevenue) OVER (ORDER BY SalesYear, SalesMonth 
                                     ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS ThreeMonthAvg,
       ROUND(AVG(MonthlyRevenue) OVER (PARTITION BY SalesYear), 2) AS YearlyAverage
FROM MonthlySales
ORDER BY SalesYear, SalesMonth;

-- Customer purchase patterns with cumulative analysis
SELECT c.CustomerName,
       o.OrderDate,
       SUM(od.Quantity * p.Price) AS OrderValue,
       SUM(SUM(od.Quantity * p.Price)) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate) AS CumulativeSpent,
       COUNT(*) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate) AS OrderNumber,
       ROUND(AVG(SUM(od.Quantity * p.Price)) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate), 2) AS AvgOrderValue
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE c.Country = 'Germany'
GROUP BY c.CustomerID, c.CustomerName, o.OrderID, o.OrderDate
ORDER BY c.CustomerName, o.OrderDate;

-- LAG, LEAD, and Analytical Functions
-- Monthly growth analysis with LAG
WITH MonthlyMetrics AS (
    SELECT YEAR(o.OrderDate) AS Year,
           MONTH(o.OrderDate) AS Month,
           COUNT(DISTINCT o.OrderID) AS OrderCount,
           SUM(od.Quantity * p.Price) AS Revenue
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
)
SELECT Year, Month,
       OrderCount, 
       ROUND(Revenue, 2) AS Revenue,
       LAG(Revenue) OVER (ORDER BY Year, Month) AS PreviousMonthRevenue,
       ROUND(Revenue - LAG(Revenue) OVER (ORDER BY Year, Month), 2) AS RevenueChange,
       ROUND((Revenue - LAG(Revenue) OVER (ORDER BY Year, Month)) / 
             LAG(Revenue) OVER (ORDER BY Year, Month) * 100, 2) AS GrowthPercentage,
       FIRST_VALUE(Revenue) OVER (PARTITION BY Year ORDER BY Month) AS FirstMonthOfYear,
       LAST_VALUE(Revenue) OVER (PARTITION BY Year ORDER BY Month 
                                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LastMonthOfYear
FROM MonthlyMetrics
ORDER BY Year, Month;

-- Customer ordering patterns with LEAD/LAG
SELECT c.CustomerName,
       o.OrderDate,
       SUM(od.Quantity * p.Price) AS OrderValue,
       LAG(o.OrderDate) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate) AS PreviousOrderDate,
       DATEDIFF(o.OrderDate, LAG(o.OrderDate) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate)) AS DaysBetweenOrders,
       LEAD(o.OrderDate) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate) AS NextOrderDate
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.CustomerName, o.OrderID, o.OrderDate
ORDER BY c.CustomerName, o.OrderDate;

-- Complex JOIN Patterns
-- Self-JOIN for product comparison within categories
SELECT p1.ProductName AS Product1,
       p2.ProductName AS Product2,
       c.CategoryName,
       p1.Price AS Price1,
       p2.Price AS Price2,
       ROUND(ABS(p1.Price - p2.Price), 2) AS PriceDifference
FROM Products p1
JOIN Products p2 ON p1.CategoryID = p2.CategoryID AND p1.ProductID < p2.ProductID
JOIN Categories c ON p1.CategoryID = c.CategoryID
WHERE ABS(p1.Price - p2.Price) > 10
ORDER BY c.CategoryName, PriceDifference DESC;

-- Complex multi-table analysis with conditional JOINs
SELECT c.CustomerName,
       c.Country,
       COUNT(DISTINCT o.OrderID) AS TotalOrders,
       COUNT(DISTINCT CASE WHEN YEAR(o.OrderDate) = 1996 THEN o.OrderID END) AS Orders1996,
       COUNT(DISTINCT CASE WHEN YEAR(o.OrderDate) = 1997 THEN o.OrderID END) AS Orders1997,
       SUM(od.Quantity * p.Price) AS TotalSpent,
       COUNT(DISTINCT p.CategoryID) AS CategoriesPurchased
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID 
    AND od.Quantity > 0  -- Conditional JOIN criteria
LEFT JOIN Products p ON od.ProductID = p.ProductID 
    AND p.Price IS NOT NULL  -- Another conditional criteria
LEFT JOIN Categories cat ON p.CategoryID = cat.CategoryID
GROUP BY c.CustomerID, c.CustomerName, c.Country
HAVING TotalOrders > 0
ORDER BY TotalSpent DESC;

-- Market basket analysis using self-JOINs
SELECT p1.ProductName AS Product1,
       p2.ProductName AS Product2,
       COUNT(*) AS TimesPurchasedTogether,
       ROUND(COUNT(*) * 100.0 / (
           SELECT COUNT(DISTINCT OrderID) FROM OrderDetails
       ), 2) AS CoOccurrencePercentage
FROM OrderDetails od1
JOIN OrderDetails od2 ON od1.OrderID = od2.OrderID 
    AND od1.ProductID < od2.ProductID
JOIN Products p1 ON od1.ProductID = p1.ProductID
JOIN Products p2 ON od2.ProductID = p2.ProductID
GROUP BY od1.ProductID, od2.ProductID, p1.ProductName, p2.ProductName
HAVING COUNT(*) >= 3
ORDER BY TimesPurchasedTogether DESC
LIMIT 20;

-- Assignment Starting Point
-- Assignment 1.1 - Customer ranking within countries
SELECT c.CustomerName,
       c.Country,
       SUM(od.Quantity * p.Price) AS TotalSpent,
       RANK() OVER (PARTITION BY c.Country ORDER BY SUM(od.Quantity * p.Price) DESC) AS CountryRank
FROM Customers c
-- Add necessary JOINs here
GROUP BY c.CustomerID, c.CustomerName, c.Country
ORDER BY c.Country, CountryRank;

-- Assignment 2.1 - Month-over-month growth template
WITH MonthlyData AS (
    SELECT YEAR(o.OrderDate) AS Year,
           MONTH(o.OrderDate) AS Month,
           SUM(od.Quantity * p.Price) AS Revenue
    FROM Orders o
    -- Add JOINs here
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
)
SELECT Year, Month, Revenue,
       LAG(Revenue) OVER (ORDER BY Year, Month) AS PreviousMonth,
       -- Add growth calculations here
FROM MonthlyData
ORDER BY Year, Month;

-- Assignment 4.1 - Comprehensive dashboard template
WITH CustomerMetrics AS (
    -- Add customer calculations here
),
ProductPerformance AS (
    -- Add product analysis here
)
SELECT -- Combine insights from both CTEs
FROM CustomerMetrics cm
-- Add appropriate JOINs to combine analysis
ORDER BY -- Add relevant ordering
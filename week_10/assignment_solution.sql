-- Window Function Fundamentals
-- Rank customers by total spending within each country
SELECT c.CustomerName,
       c.Country,
       ROUND(SUM(od.Quantity * p.Price), 2) AS TotalSpent,
       RANK() OVER (PARTITION BY c.Country ORDER BY SUM(od.Quantity * p.Price) DESC) AS CountryRank,
       RANK() OVER (ORDER BY SUM(od.Quantity * p.Price) DESC) AS OverallRank
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.CustomerName, c.Country
ORDER BY c.Country, CountryRank;

-- Calculate running totals of monthly sales revenue
WITH MonthlySales AS (
    SELECT YEAR(o.OrderDate) AS SalesYear,
           MONTH(o.OrderDate) AS SalesMonth,
           ROUND(SUM(od.Quantity * p.Price), 2) AS MonthlyRevenue
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
)
SELECT SalesYear,
       SalesMonth,
       MonthlyRevenue,
       ROUND(SUM(MonthlyRevenue) OVER (ORDER BY SalesYear, SalesMonth), 2) AS RunningTotal,
       ROUND(SUM(MonthlyRevenue) OVER (PARTITION BY SalesYear ORDER BY SalesMonth), 2) AS YearToDateTotal
FROM MonthlySales
ORDER BY SalesYear, SalesMonth;

-- Find the top 3 products by revenue in each category using window functions
SELECT CategoryName, ProductName, TotalRevenue, CategoryRank
FROM (
    SELECT c.CategoryName,
           p.ProductName,
           ROUND(SUM(od.Quantity * p.Price), 2) AS TotalRevenue,
           RANK() OVER (PARTITION BY c.CategoryID ORDER BY SUM(od.Quantity * p.Price) DESC) AS CategoryRank
    FROM Categories c
    JOIN Products p ON c.CategoryID = p.CategoryID
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY c.CategoryID, c.CategoryName, p.ProductID, p.ProductName
) ranked_products
WHERE CategoryRank <= 3
ORDER BY CategoryName, CategoryRank;

-- Advanced Analytical Functions
-- Month-over-month growth analysis
WITH MonthlyMetrics AS (
    SELECT YEAR(o.OrderDate) AS Year,
           MONTH(o.OrderDate) AS Month,
           ROUND(SUM(od.Quantity * p.Price), 2) AS Revenue,
           COUNT(DISTINCT o.OrderID) AS OrderCount
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
)
SELECT Year, Month,
       Revenue,
       OrderCount,
       LAG(Revenue) OVER (ORDER BY Year, Month) AS PreviousMonthRevenue,
       ROUND(Revenue - LAG(Revenue) OVER (ORDER BY Year, Month), 2) AS RevenueChange,
       CASE 
           WHEN LAG(Revenue) OVER (ORDER BY Year, Month) IS NULL THEN NULL
           ELSE ROUND((Revenue - LAG(Revenue) OVER (ORDER BY Year, Month)) / 
                     LAG(Revenue) OVER (ORDER BY Year, Month) * 100, 2)
       END AS GrowthPercentage
FROM MonthlyMetrics
ORDER BY Year, Month;

-- Customer lifetime value analysis
SELECT c.CustomerName,
       c.Country,
       o.OrderDate,
       ROUND(SUM(od.Quantity * p.Price), 2) AS OrderValue,
       ROUND(SUM(SUM(od.Quantity * p.Price)) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate), 2) AS CumulativeSpending,
       COUNT(*) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate) AS OrderNumber,
       ROUND(AVG(SUM(od.Quantity * p.Price)) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate), 2) AS AvgOrderValueToDate,
       FIRST_VALUE(o.OrderDate) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate) AS FirstOrderDate,
       DATEDIFF(o.OrderDate, FIRST_VALUE(o.OrderDate) OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate)) AS DaysSinceFirstOrder
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.CustomerName, c.Country, o.OrderID, o.OrderDate
ORDER BY c.CustomerName, o.OrderDate;

-- Year-over-year sales trend analysis
WITH MonthlySales AS (
    SELECT YEAR(o.OrderDate) AS Year,
           MONTH(o.OrderDate) AS Month,
           ROUND(SUM(od.Quantity * p.Price), 2) AS Revenue
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
)
SELECT Year, Month,
       Revenue,
       LAG(Revenue, 12) OVER (ORDER BY Year, Month) AS SameMonthPreviousYear,
       CASE 
           WHEN LAG(Revenue, 12) OVER (ORDER BY Year, Month) IS NULL THEN NULL
           ELSE ROUND((Revenue - LAG(Revenue, 12) OVER (ORDER BY Year, Month)) / 
                     LAG(Revenue, 12) OVER (ORDER BY Year, Month) * 100, 2)
       END AS YearOverYearGrowth
FROM MonthlySales
ORDER BY Year, Month;

-- Complex JOIN Scenarios
-- Market basket analysis - products frequently bought together
SELECT p1.ProductName AS Product1,
       p2.ProductName AS Product2,
       c1.CategoryName AS Category1,
       c2.CategoryName AS Category2,
       COUNT(*) AS TimesBoughtTogether,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT OrderID) FROM OrderDetails), 2) AS CoOccurrenceRate
FROM OrderDetails od1
JOIN OrderDetails od2 ON od1.OrderID = od2.OrderID AND od1.ProductID < od2.ProductID
JOIN Products p1 ON od1.ProductID = p1.ProductID
JOIN Products p2 ON od2.ProductID = p2.ProductID
JOIN Categories c1 ON p1.CategoryID = c1.CategoryID
JOIN Categories c2 ON p2.CategoryID = c2.CategoryID
GROUP BY od1.ProductID, od2.ProductID, p1.ProductName, p2.ProductName, c1.CategoryName, c2.CategoryName
HAVING COUNT(*) >= 3
ORDER BY TimesBoughtTogether DESC
LIMIT 15;

-- Customer analysis with conditional JOINs
SELECT c.CustomerName,
       c.Country,
       c.City,
       COUNT(DISTINCT o.OrderID) AS TotalOrders,
       ROUND(SUM(od.Quantity * p.Price), 2) AS TotalSpent,
       COUNT(DISTINCT p.CategoryID) AS CategoriesPurchased,
       COUNT(DISTINCT s.SupplierID) AS SuppliersPatronized,
       MIN(o.OrderDate) AS FirstOrderDate,
       MAX(o.OrderDate) AS LastOrderDate,
       COUNT(DISTINCT CASE WHEN p.Price > 50 THEN p.ProductID END) AS PremiumProductsPurchased,
       ROUND(AVG(CASE WHEN p.CategoryID = 1 THEN od.Quantity * p.Price END), 2) AS BeverageSpending
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
LEFT JOIN Products p ON od.ProductID = p.ProductID AND p.Price > 0
LEFT JOIN Suppliers s ON p.SupplierID = s.SupplierID
GROUP BY c.CustomerID, c.CustomerName, c.Country, c.City
HAVING TotalOrders > 0
ORDER BY TotalSpent DESC;

-- Product comparison using self-JOINs
SELECT p1.ProductName AS Product1,
       p2.ProductName AS Product2,
       c.CategoryName,
       p1.Price AS Price1,
       p2.Price AS Price2,
       ROUND(ABS(p1.Price - p2.Price), 2) AS PriceDifference,
       ROUND((ABS(p1.Price - p2.Price) / GREATEST(p1.Price, p2.Price)) * 100, 2) AS PriceDifferencePercent,
       CASE 
           WHEN ABS(p1.Price - p2.Price) < 5 THEN 'Similar Pricing'
           WHEN ABS(p1.Price - p2.Price) < 15 THEN 'Moderate Difference'
           ELSE 'Significant Difference'
       END AS PriceComparison
FROM Products p1
JOIN Products p2 ON p1.CategoryID = p2.CategoryID 
    AND p1.ProductID < p2.ProductID
    AND p1.Price IS NOT NULL 
    AND p2.Price IS NOT NULL
JOIN Categories c ON p1.CategoryID = c.CategoryID
ORDER BY c.CategoryName, PriceDifference DESC;

-- Integrated Advanced Analysis
-- Sales performance dashboard
WITH ProductSales AS (
    SELECT p.ProductID,
           p.ProductName,
           c.CategoryName,
           p.Price,
           SUM(od.Quantity) AS TotalUnitsSold,
           SUM(od.Quantity * p.Price) AS TotalRevenue,
           COUNT(DISTINCT od.OrderID) AS OrdersContainingProduct
    FROM Products p
    JOIN Categories c ON p.CategoryID = c.CategoryID
    LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY p.ProductID, p.ProductName, c.CategoryName, p.Price
),
CategoryTotals AS (
    SELECT CategoryName,
           SUM(TotalRevenue) AS CategoryRevenue
    FROM ProductSales
    GROUP BY CategoryName
)
SELECT ps.ProductName,
       ps.CategoryName,
       ps.Price,
       COALESCE(ps.TotalUnitsSold, 0) AS TotalUnitsSold,
       ROUND(COALESCE(ps.TotalRevenue, 0), 2) AS TotalRevenue,
       RANK() OVER (ORDER BY COALESCE(ps.TotalRevenue, 0) DESC) AS OverallRank,
       RANK() OVER (PARTITION BY ps.CategoryName ORDER BY COALESCE(ps.TotalRevenue, 0) DESC) AS CategoryRank,
       ROUND(COALESCE(ps.TotalRevenue, 0) / ct.CategoryRevenue * 100, 2) AS CategoryMarketShare,
       CASE 
           WHEN ps.TotalRevenue IS NULL THEN 'No Sales'
           WHEN ps.TotalRevenue >= 5000 THEN 'Star Performer'
           WHEN ps.TotalRevenue >= 2000 THEN 'Good Performer'
           WHEN ps.TotalRevenue >= 500 THEN 'Average Performer'
           ELSE 'Poor Performer'
       END AS PerformanceRating
FROM ProductSales ps
LEFT JOIN CategoryTotals ct ON ps.CategoryName = ct.CategoryName
ORDER BY ps.TotalRevenue DESC;

-- Customer segmentation with quartiles and patterns
WITH CustomerMetrics AS (
    SELECT c.CustomerID,
           c.CustomerName,
           c.Country,
           COUNT(o.OrderID) AS OrderCount,
           ROUND(SUM(od.Quantity * p.Price), 2) AS TotalSpent,
           ROUND(AVG(od.Quantity * p.Price), 2) AS AvgOrderValue,
           DATEDIFF(MAX(o.OrderDate), MIN(o.OrderDate)) AS CustomerLifespanDays,
           COUNT(DISTINCT p.CategoryID) AS CategoriesPurchased
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
    LEFT JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY c.CustomerID, c.CustomerName, c.Country
)
SELECT CustomerName,
       Country,
       OrderCount,
       TotalSpent,
       AvgOrderValue,
       CategoriesPurchased,
       NTILE(4) OVER (ORDER BY TotalSpent DESC) AS SpendingQuartile,
       NTILE(4) OVER (ORDER BY OrderCount DESC) AS FrequencyQuartile,
       CASE 
           WHEN TotalSpent = 0 THEN 'Non-Purchaser'
           WHEN OrderCount = 1 THEN 'One-time Buyer'
           WHEN OrderCount BETWEEN 2 AND 5 THEN 'Occasional Customer'
           WHEN OrderCount BETWEEN 6 AND 10 THEN 'Regular Customer'
           ELSE 'Loyal Customer'
       END AS CustomerSegment,
       CASE 
           WHEN TotalSpent >= 2000 AND OrderCount >= 8 THEN 'VIP'
           WHEN TotalSpent >= 1000 AND OrderCount >= 5 THEN 'Premium'
           WHEN TotalSpent >= 500 AND OrderCount >= 3 THEN 'Standard'
           WHEN TotalSpent > 0 THEN 'Basic'
           ELSE 'Inactive'
       END AS CustomerTier
FROM CustomerMetrics
ORDER BY TotalSpent DESC;

-- Product lifecycle analysis
WITH ProductPerformance AS (
    SELECT p.ProductID,
           p.ProductName,
           c.CategoryName,
           p.Price,
           COALESCE(SUM(od.Quantity), 0) AS TotalUnitsSold,
           COALESCE(SUM(od.Quantity * p.Price), 0) AS TotalRevenue,
           COUNT(DISTINCT od.OrderID) AS OrdersContainingProduct,
           MIN(o.OrderDate) AS FirstSold,
           MAX(o.OrderDate) AS LastSold
    FROM Products p
    JOIN Categories c ON p.CategoryID = c.CategoryID
    LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
    LEFT JOIN Orders o ON od.OrderID = o.OrderID
    GROUP BY p.ProductID, p.ProductName, c.CategoryName, p.Price
),
CategoryStats AS (
    SELECT CategoryName,
           AVG(TotalRevenue) AS CategoryAvgRevenue,
           SUM(TotalRevenue) AS CategoryTotalRevenue
    FROM ProductPerformance
    GROUP BY CategoryName
)
SELECT pp.ProductName,
       pp.CategoryName,
       pp.Price,
       pp.TotalUnitsSold,
       ROUND(pp.TotalRevenue, 2) AS TotalRevenue,
       RANK() OVER (PARTITION BY pp.CategoryName ORDER BY pp.TotalRevenue DESC) AS CategoryRank,
       ROUND(pp.TotalRevenue / cs.CategoryTotalRevenue * 100, 2) AS CategoryMarketShare,
       CASE 
           WHEN pp.TotalRevenue > cs.CategoryAvgRevenue * 2 THEN 'Market Leader'
           WHEN pp.TotalRevenue > cs.CategoryAvgRevenue THEN 'Above Average'
           WHEN pp.TotalRevenue > cs.CategoryAvgRevenue * 0.5 THEN 'Below Average'
           WHEN pp.TotalRevenue > 0 THEN 'Poor Performer'
           ELSE 'No Sales'
       END AS MarketPosition,
       CASE 
           WHEN pp.FirstSold IS NULL THEN 'Never Sold'
           WHEN DATEDIFF(pp.LastSold, pp.FirstSold) > 150 THEN 'Long Lifecycle'
           WHEN DATEDIFF(pp.LastSold, pp.FirstSold) > 90 THEN 'Medium Lifecycle'
           WHEN DATEDIFF(pp.LastSold, pp.FirstSold) > 30 THEN 'Short Lifecycle'
           ELSE 'Single Period'
       END AS LifecycleStage
FROM ProductPerformance pp
JOIN CategoryStats cs ON pp.CategoryName = cs.CategoryName
ORDER BY pp.CategoryName, CategoryRank;

-- Executive summary report
WITH BusinessMetrics AS (
    SELECT 
        COUNT(DISTINCT c.CustomerID) AS TotalCustomers,
        COUNT(DISTINCT o.OrderID) AS TotalOrders,
        COUNT(DISTINCT p.ProductID) AS TotalProducts,
        ROUND(SUM(od.Quantity * p.Price), 2) AS TotalRevenue,
        ROUND(AVG(order_values.OrderValue), 2) AS AvgOrderValue
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
    LEFT JOIN Products p ON od.ProductID = p.ProductID
    LEFT JOIN (
        SELECT od.OrderID, SUM(od.Quantity * p.Price) AS OrderValue
        FROM OrderDetails od
        JOIN Products p ON od.ProductID = p.ProductID
        GROUP BY od.OrderID
    ) order_values ON o.OrderID = order_values.OrderID
),
TopPerformers AS (
    SELECT 'Top Customer' AS Category,
           c.CustomerName AS Name,
           ROUND(SUM(od.Quantity * p.Price), 2) AS Value
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY c.CustomerID, c.CustomerName
    ORDER BY SUM(od.Quantity * p.Price) DESC
    LIMIT 1
),
TopProduct AS (
    SELECT 'Top Product' AS Category,
           p.ProductName AS Name,
           ROUND(SUM(od.Quantity * p.Price), 2) AS Value
    FROM Products p
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY p.ProductID, p.ProductName
    ORDER BY SUM(od.Quantity * p.Price) DESC
    LIMIT 1
),
TopCategory AS (
    SELECT 'Top Category' AS Category,
           c.CategoryName AS Name,
           ROUND(SUM(od.Quantity * p.Price), 2) AS Value
    FROM Categories c
    JOIN Products p ON c.CategoryID = p.CategoryID
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY c.CategoryID, c.CategoryName
    ORDER BY SUM(od.Quantity * p.Price) DESC
    LIMIT 1
)
SELECT 'Business Overview' AS ReportSection,
       CONCAT('Total Customers: ', TotalCustomers, 
              ' | Total Orders: ', TotalOrders,
              ' | Total Revenue: £', TotalRevenue,
              ' | Avg Order Value: £', AvgOrderValue) AS Metrics
FROM BusinessMetrics

UNION ALL

SELECT 'Top Performers' AS ReportSection,
       CONCAT(tp.Category, ': ', tp.Name, ' (£', tp.Value, ')') AS Metrics
FROM TopPerformers tp

UNION ALL

SELECT '' AS ReportSection,
       CONCAT(tp.Category, ': ', tp.Name, ' (£', tp.Value, ')') AS Metrics
FROM TopProduct tp

UNION ALL

SELECT '' AS ReportSection,
       CONCAT(tc.Category, ': ', tc.Name, ' (£', tc.Value, ')') AS Metrics
FROM TopCategory tc;
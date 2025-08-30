-- String Function Analysis
-- Find customers with names longer than 20 characters and format them as "NAME (COUNTRY)"
SELECT CustomerName,
       Country,
       LENGTH(CustomerName) AS NameLength,
       CONCAT(UPPER(CustomerName), ' (', Country, ')') AS FormattedName
FROM Customers
WHERE LENGTH(CustomerName) > 20
ORDER BY NameLength DESC;

-- Extract the first word from product names and count how many products start with each word
SELECT SUBSTRING_INDEX(ProductName, ' ', 1) AS FirstWord,
       COUNT(*) AS ProductCount
FROM Products
GROUP BY SUBSTRING_INDEX(ProductName, ' ', 1)
ORDER BY ProductCount DESC, FirstWord;

-- Clean and standardize customer contact names by removing extra spaces and converting to title case
SELECT ContactName AS OriginalName,
       TRIM(ContactName) AS TrimmedName,
       CONCAT(
           UPPER(LEFT(TRIM(ContactName), 1)),
           LOWER(SUBSTRING(TRIM(ContactName), 2))
       ) AS TitleCase,
       LENGTH(ContactName) - LENGTH(TRIM(ContactName)) AS SpacesRemoved
FROM Customers
WHERE ContactName IS NOT NULL
ORDER BY ContactName;

-- Numeric Function Applications
-- Create price bands for products (Budget: <£15, Standard: £15-£40, Premium: >£40) and show count in each band
SELECT 
    CASE 
        WHEN Price < 15 THEN 'Budget (<£15)'
        WHEN Price BETWEEN 15 AND 40 THEN 'Standard (£15-£40)'
        ELSE 'Premium (>£40)'
    END AS PriceBand,
    COUNT(*) AS ProductCount,
    ROUND(AVG(Price), 2) AS AvgPrice,
    ROUND(MIN(Price), 2) AS MinPrice,
    ROUND(MAX(Price), 2) AS MaxPrice
FROM Products
WHERE Price IS NOT NULL
GROUP BY 
    CASE 
        WHEN Price < 15 THEN 'Budget (<£15)'
        WHEN Price BETWEEN 15 AND 40 THEN 'Standard (£15-£40)'
        ELSE 'Premium (>£40)'
    END
ORDER BY AvgPrice;

-- Calculate percentage markup for each product assuming cost is 60% of selling price
SELECT ProductName,
       Price AS SellingPrice,
       ROUND(Price * 0.60, 2) AS EstimatedCost,
       ROUND(Price * 0.40, 2) AS GrossProfit,
       ROUND((Price * 0.40) / (Price * 0.60) * 100, 2) AS MarkupPercentage
FROM Products
WHERE Price IS NOT NULL
ORDER BY MarkupPercentage DESC;

-- Find products where the price rounded to nearest £5 would create a "cleaner" pricing structure
SELECT ProductName,
       Price AS CurrentPrice,
       ROUND(Price / 5) * 5 AS RoundedToNearest5,
       ABS(Price - (ROUND(Price / 5) * 5)) AS PriceDifference,
       CASE 
           WHEN ABS(Price - (ROUND(Price / 5) * 5)) <= 1 THEN 'Good candidate for rounding'
           ELSE 'Keep current price'
       END AS RoundingRecommendation
FROM Products
WHERE Price IS NOT NULL
ORDER BY PriceDifference;

-- Date Analysis Challenges
-- Analyze order patterns by day of the week and identify the busiest/quietest days
SELECT 
    CASE DAYOFWEEK(OrderDate)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END AS DayOfWeek,
    DAYOFWEEK(OrderDate) AS DayNumber,
    COUNT(*) AS OrderCount,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Orders), 2) AS Percentage
FROM Orders
GROUP BY DAYOFWEEK(OrderDate),
         CASE DAYOFWEEK(OrderDate)
             WHEN 1 THEN 'Sunday'
             WHEN 2 THEN 'Monday'
             WHEN 3 THEN 'Tuesday'
             WHEN 4 THEN 'Wednesday'
             WHEN 5 THEN 'Thursday'
             WHEN 6 THEN 'Friday'
             WHEN 7 THEN 'Saturday'
         END
ORDER BY DayNumber;

-- Calculate customer lifetime (days between first and last order) and categorize customers by engagement
SELECT c.CustomerName,
       c.Country,
       MIN(o.OrderDate) AS FirstOrder,
       MAX(o.OrderDate) AS LastOrder,
       DATEDIFF(MAX(o.OrderDate), MIN(o.OrderDate)) AS LifetimeDays,
       COUNT(o.OrderID) AS TotalOrders,
       CASE 
           WHEN DATEDIFF(MAX(o.OrderDate), MIN(o.OrderDate)) = 0 THEN 'Single Day Customer'
           WHEN DATEDIFF(MAX(o.OrderDate), MIN(o.OrderDate)) <= 30 THEN 'Short-term (≤30 days)'
           WHEN DATEDIFF(MAX(o.OrderDate), MIN(o.OrderDate)) <= 90 THEN 'Medium-term (31-90 days)'
           WHEN DATEDIFF(MAX(o.OrderDate), MIN(o.OrderDate)) <= 180 THEN 'Long-term (91-180 days)'
           ELSE 'Very Long-term (>180 days)'
       END AS EngagementCategory
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName, c.Country
ORDER BY LifetimeDays DESC;

-- Find seasonal trends by comparing quarterly sales performance across available years
SELECT YEAR(o.OrderDate) AS SalesYear,
       QUARTER(o.OrderDate) AS Quarter,
       CASE QUARTER(o.OrderDate)
           WHEN 1 THEN 'Q1 (Jan-Mar)'
           WHEN 2 THEN 'Q2 (Apr-Jun)'
           WHEN 3 THEN 'Q3 (Jul-Sep)'
           WHEN 4 THEN 'Q4 (Oct-Dec)'
       END AS QuarterName,
       COUNT(DISTINCT o.OrderID) AS OrderCount,
       ROUND(SUM(od.Quantity * p.Price), 2) AS QuarterlyRevenue,
       COUNT(DISTINCT o.CustomerID) AS ActiveCustomers
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY YEAR(o.OrderDate), 
         QUARTER(o.OrderDate),
         CASE QUARTER(o.OrderDate)
             WHEN 1 THEN 'Q1 (Jan-Mar)'
             WHEN 2 THEN 'Q2 (Apr-Jun)'
             WHEN 3 THEN 'Q3 (Jul-Sep)'
             WHEN 4 THEN 'Q4 (Oct-Dec)'
         END
ORDER BY SalesYear, Quarter;

-- Advanced Function Integration
-- Build a customer scoring system combining order frequency, total spend, and recency
WITH CustomerMetrics AS (
    SELECT c.CustomerID,
           c.CustomerName,
           c.Country,
           COUNT(o.OrderID) AS OrderFrequency,
           COALESCE(SUM(od.Quantity * p.Price), 0) AS TotalSpend,
           DATEDIFF(CURDATE(), MAX(o.OrderDate)) AS DaysSinceLastOrder,
           DATEDIFF(MAX(o.OrderDate), MIN(o.OrderDate)) AS CustomerLifetime
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
    LEFT JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY c.CustomerID, c.CustomerName, c.Country
)
SELECT CustomerName,
       Country,
       OrderFrequency,
       ROUND(TotalSpend, 2) AS TotalSpend,
       DaysSinceLastOrder,
       -- Scoring components (0-100 each)
       CASE 
           WHEN OrderFrequency >= 10 THEN 100
           WHEN OrderFrequency >= 5 THEN 75
           WHEN OrderFrequency >= 2 THEN 50
           ELSE 25
       END AS FrequencyScore,
       CASE 
           WHEN TotalSpend >= 2000 THEN 100
           WHEN TotalSpend >= 1000 THEN 75
           WHEN TotalSpend >= 500 THEN 50
           ELSE 25
       END AS SpendScore,
       CASE 
           WHEN DaysSinceLastOrder IS NULL THEN 0
           WHEN DaysSinceLastOrder <= 30 THEN 100
           WHEN DaysSinceLastOrder <= 90 THEN 75
           WHEN DaysSinceLastOrder <= 180 THEN 50
           ELSE 25
       END AS RecencyScore,
       -- Overall composite score
       ROUND((
           CASE WHEN OrderFrequency >= 10 THEN 100 WHEN OrderFrequency >= 5 THEN 75 WHEN OrderFrequency >= 2 THEN 50 ELSE 25 END +
           CASE WHEN TotalSpend >= 2000 THEN 100 WHEN TotalSpend >= 1000 THEN 75 WHEN TotalSpend >= 500 THEN 50 ELSE 25 END +
           CASE WHEN DaysSinceLastOrder IS NULL THEN 0 WHEN DaysSinceLastOrder <= 30 THEN 100 WHEN DaysSinceLastOrder <= 90 THEN 75 WHEN DaysSinceLastOrder <= 180 THEN 50 ELSE 25 END
       ) / 3, 0) AS OverallScore
FROM CustomerMetrics
WHERE TotalSpend > 0
ORDER BY OverallScore DESC;

-- Create a product performance dashboard showing sales rank, price position, and category performance
WITH ProductSales AS (
    SELECT p.ProductID,
           p.ProductName,
           c.CategoryName,
           p.Price,
           COALESCE(SUM(od.Quantity), 0) AS TotalUnitsSold,
           COALESCE(SUM(od.Quantity * p.Price), 0) AS TotalRevenue
    FROM Products p
    JOIN Categories c ON p.CategoryID = c.CategoryID
    LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY p.ProductID, p.ProductName, c.CategoryName, p.Price
)
SELECT ProductName,
       CategoryName,
       Price,
       TotalUnitsSold,
       ROUND(TotalRevenue, 2) AS TotalRevenue,
       RANK() OVER (ORDER BY TotalRevenue DESC) AS SalesRank,
       RANK() OVER (PARTITION BY CategoryName ORDER BY TotalRevenue DESC) AS CategoryRank,
       CASE 
           WHEN Price < 10 THEN 'Budget Position'
           WHEN Price BETWEEN 10 AND 30 THEN 'Standard Position'
           WHEN Price BETWEEN 30 AND 60 THEN 'Premium Position'
           ELSE 'Luxury Position'
       END AS PricePosition,
       CASE 
           WHEN TotalRevenue >= 5000 THEN 'Star Performer'
           WHEN TotalRevenue >= 2000 THEN 'Good Performer'
           WHEN TotalRevenue >= 500 THEN 'Average Performer'
           ELSE 'Poor Performer'
       END AS PerformanceRating
FROM ProductSales
ORDER BY SalesRank;

-- Design a monthly business report showing growth rates, seasonal adjustments, and performance indicators
WITH MonthlyMetrics AS (
    SELECT YEAR(o.OrderDate) AS Year,
           MONTH(o.OrderDate) AS Month,
           COUNT(DISTINCT o.OrderID) AS OrderCount,
           ROUND(SUM(od.Quantity * p.Price), 2) AS MonthlyRevenue,
           COUNT(DISTINCT o.CustomerID) AS ActiveCustomers,
           ROUND(AVG(od.Quantity * p.Price), 2) AS AvgOrderValue
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
),
MonthlyTrends AS (
    SELECT Year, Month,
           OrderCount, MonthlyRevenue, ActiveCustomers, AvgOrderValue,
           LAG(MonthlyRevenue) OVER (ORDER BY Year, Month) AS PrevMonthRevenue,
           AVG(MonthlyRevenue) OVER (ORDER BY Year, Month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ThreeMonthAvg
    FROM MonthlyMetrics
)
SELECT Year, Month,
       MONTHNAME(STR_TO_DATE(CONCAT(Year, '-', Month, '-01'), '%Y-%m-%d')) AS MonthName,
       OrderCount, MonthlyRevenue, ActiveCustomers,
       ROUND(AvgOrderValue, 2) AS AvgOrderValue,
       ROUND(ThreeMonthAvg, 2) AS ThreeMonthMovingAvg,
       CASE 
           WHEN PrevMonthRevenue IS NULL THEN NULL
           ELSE ROUND(((MonthlyRevenue - PrevMonthRevenue) / PrevMonthRevenue * 100), 2)
       END AS MonthOverMonthGrowth,
       CASE 
           WHEN MonthlyRevenue > ThreeMonthAvg THEN 'Above Trend'
           ELSE 'Below Trend'
       END AS TrendIndicator
FROM MonthlyTrends
ORDER BY Year, Month;

-- Develop a data quality report identifying missing values, inconsistent formatting, and outliers across all tables
-- Customers data quality
SELECT 'Customers' AS TableName,
       COUNT(*) AS TotalRows,
       COUNT(CASE WHEN CustomerName IS NULL OR TRIM(CustomerName) = '' THEN 1 END) AS MissingNames,
       COUNT(CASE WHEN ContactName IS NULL OR TRIM(ContactName) = '' THEN 1 END) AS MissingContacts,
       COUNT(CASE WHEN PostalCode IS NULL OR TRIM(PostalCode) = '' THEN 1 END) AS MissingPostalCodes,
       COUNT(CASE WHEN LENGTH(CustomerName) > 50 THEN 1 END) AS LongNames
FROM Customers
UNION ALL
-- Products data quality
SELECT 'Products' AS TableName,
       COUNT(*) AS TotalRows,
       COUNT(CASE WHEN ProductName IS NULL OR TRIM(ProductName) = '' THEN 1 END) AS MissingNames,
       COUNT(CASE WHEN Price IS NULL OR Price <= 0 THEN 1 END) AS InvalidPrices,
       COUNT(CASE WHEN Price > 200 THEN 1 END) AS HighPrices,
       COUNT(CASE WHEN CategoryID IS NULL THEN 1 END) AS MissingCategories
FROM Products
UNION ALL
-- Orders data quality
SELECT 'Orders' AS TableName,
       COUNT(*) AS TotalRows,
       COUNT(CASE WHEN OrderDate IS NULL THEN 1 END) AS MissingDates,
       COUNT(CASE WHEN CustomerID IS NULL THEN 1 END) AS MissingCustomers,
       COUNT(CASE WHEN EmployeeID IS NULL THEN 1 END) AS MissingEmployees,
       COUNT(CASE WHEN OrderDate > CURDATE() THEN 1 END) AS FutureDates
FROM Orders;
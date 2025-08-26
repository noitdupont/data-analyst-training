-- Basic JOINs
-- List all products with their category names and supplier information
SELECT p.ProductName, 
       c.CategoryName, 
       s.SupplierName,
       s.Country AS SupplierCountry,
       p.Price
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
JOIN Suppliers s ON p.SupplierID = s.SupplierID
ORDER BY c.CategoryName, p.ProductName;

-- Show all orders with customer names, employee names, and shipper details
SELECT o.OrderID,
       o.OrderDate,
       c.CustomerName,
       CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
       s.ShipperName
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN Employees e ON o.EmployeeID = e.EmployeeID
JOIN Shippers s ON o.ShipperID = s.ShipperID
ORDER BY o.OrderDate DESC;

-- Find customers who have never placed an order
SELECT c.CustomerName, 
       c.ContactName,
       c.Country,
       c.City
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.CustomerID IS NULL
ORDER BY c.Country, c.CustomerName;

-- Advanced JOIN Analysis
-- Calculate total revenue by employee (who processed the orders)
SELECT CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
       COUNT(DISTINCT o.OrderID) AS OrdersProcessed,
       ROUND(SUM(od.Quantity * p.Price), 2) AS TotalRevenue,
       ROUND(AVG(od.Quantity * p.Price), 2) AS AvgRevenuePerItem
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY e.EmployeeID, e.FirstName, e.LastName
ORDER BY TotalRevenue DESC;

-- Show product sales performance including products that were never ordered
SELECT p.ProductName,
       c.CategoryName,
       p.Price,
       COALESCE(SUM(od.Quantity), 0) AS TotalQuantitySold,
       COALESCE(SUM(od.Quantity * p.Price), 0) AS TotalRevenue,
       CASE 
           WHEN SUM(od.Quantity) IS NULL THEN 'Never Ordered'
           WHEN SUM(od.Quantity) < 50 THEN 'Low Sales'
           WHEN SUM(od.Quantity) < 200 THEN 'Medium Sales'
           ELSE 'High Sales'
       END AS SalesPerformance
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, c.CategoryName, p.Price
ORDER BY TotalRevenue DESC, p.ProductName;

-- Create a detailed order analysis for orders from 1996
SELECT o.OrderID,
       o.OrderDate,
       c.CustomerName,
       c.Country AS CustomerCountry,
       p.ProductName,
       cat.CategoryName,
       s.SupplierName,
       od.Quantity,
       p.Price,
       (od.Quantity * p.Price) AS LineTotal
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN Categories cat ON p.CategoryID = cat.CategoryID
JOIN Suppliers s ON p.SupplierID = s.SupplierID
WHERE YEAR(o.OrderDate) = 1996
ORDER BY o.OrderDate, o.OrderID, cat.CategoryName;

-- Subquery Challenges
-- Find products priced above their category average
SELECT p.ProductName,
       c.CategoryName,
       p.Price,
       ROUND((SELECT AVG(p2.Price) 
              FROM Products p2 
              WHERE p2.CategoryID = p.CategoryID), 2) AS CategoryAverage,
       ROUND(p.Price - (SELECT AVG(p2.Price) 
                        FROM Products p2 
                        WHERE p2.CategoryID = p.CategoryID), 2) AS PriceAboveAverage
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > (SELECT AVG(p2.Price) 
                 FROM Products p2 
                 WHERE p2.CategoryID = p.CategoryID)
ORDER BY c.CategoryName, PriceAboveAverage DESC;

-- Identify customers who have spent more than the overall customer average
SELECT c.CustomerName,
       c.Country,
       ROUND(SUM(od.Quantity * p.Price), 2) AS TotalSpent,
       ROUND((SELECT AVG(customer_totals.total) 
              FROM (SELECT SUM(od2.Quantity * p2.Price) AS total
                    FROM Orders o2
                    JOIN OrderDetails od2 ON o2.OrderID = od2.OrderID
                    JOIN Products p2 ON od2.ProductID = p2.ProductID
                    GROUP BY o2.CustomerID) customer_totals), 2) AS OverallAverage
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.CustomerName, c.Country
HAVING SUM(od.Quantity * p.Price) > (
    SELECT AVG(customer_totals.total) 
    FROM (SELECT SUM(od2.Quantity * p2.Price) AS total
          FROM Orders o2
          JOIN OrderDetails od2 ON o2.OrderID = od2.OrderID
          JOIN Products p2 ON od2.ProductID = p2.ProductID
          GROUP BY o2.CustomerID) customer_totals
)
ORDER BY TotalSpent DESC;

-- List categories that have more products than the average category size
SELECT c.CategoryName,
       COUNT(p.ProductID) AS ProductCount,
       (SELECT ROUND(AVG(category_counts.product_count), 0)
        FROM (SELECT COUNT(*) AS product_count
              FROM Products 
              GROUP BY CategoryID) category_counts) AS AverageCategorySize
FROM Categories c
JOIN Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID, c.CategoryName
HAVING COUNT(p.ProductID) > (
    SELECT AVG(category_counts.product_count)
    FROM (SELECT COUNT(*) AS product_count
          FROM Products 
          GROUP BY CategoryID) category_counts
)
ORDER BY ProductCount DESC;

-- CTE Complex Analysis
-- Customer ranking system by country
WITH CustomerMetrics AS (
    SELECT c.CustomerID,
           c.CustomerName,
           c.Country,
           COUNT(o.OrderID) AS OrderCount,
           COALESCE(SUM(od.Quantity * p.Price), 0) AS TotalSpent
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
    LEFT JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY c.CustomerID, c.CustomerName, c.Country
)
SELECT CustomerName,
       Country,
       OrderCount,
       ROUND(TotalSpent, 2) AS TotalSpent,
       RANK() OVER (PARTITION BY Country ORDER BY TotalSpent DESC) AS CountryRank,
       RANK() OVER (ORDER BY TotalSpent DESC) AS OverallRank
FROM CustomerMetrics
WHERE TotalSpent > 0
ORDER BY Country, CountryRank;

-- Monthly sales analysis with growth rates and moving averages
WITH MonthlySales AS (
    SELECT YEAR(o.OrderDate) AS SalesYear,
           MONTH(o.OrderDate) AS SalesMonth,
           SUM(od.Quantity * p.Price) AS MonthlyRevenue,
           COUNT(DISTINCT o.OrderID) AS OrderCount
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
),
SalesWithTrends AS (
    SELECT SalesYear,
           SalesMonth,
           ROUND(MonthlyRevenue, 2) AS MonthlyRevenue,
           OrderCount,
           LAG(MonthlyRevenue) OVER (ORDER BY SalesYear, SalesMonth) AS PreviousMonth,
           AVG(MonthlyRevenue) OVER (ORDER BY SalesYear, SalesMonth 
                                   ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ThreeMonthMovingAvg
    FROM MonthlySales
)
SELECT SalesYear,
       SalesMonth,
       MonthlyRevenue,
       OrderCount,
       ROUND(ThreeMonthMovingAvg, 2) AS ThreeMonthMovingAvg,
       CASE 
           WHEN PreviousMonth IS NULL THEN NULL
           ELSE ROUND(((MonthlyRevenue - PreviousMonth) / PreviousMonth * 100), 2)
       END AS GrowthPercentage
FROM SalesWithTrends
ORDER BY SalesYear, SalesMonth;

-- Product performance report with category and business rankings
WITH ProductSales AS (
    SELECT p.ProductID,
           p.ProductName,
           c.CategoryName,
           p.CategoryID,
           COALESCE(SUM(od.Quantity), 0) AS TotalQuantitySold,
           COALESCE(SUM(od.Quantity * p.Price), 0) AS TotalRevenue
    FROM Products p
    JOIN Categories c ON p.CategoryID = c.CategoryID
    LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY p.ProductID, p.ProductName, c.CategoryName, p.CategoryID
),
BusinessTotals AS (
    SELECT SUM(TotalRevenue) AS TotalBusinessRevenue
    FROM ProductSales
)
SELECT ps.ProductName,
       ps.CategoryName,
       ps.TotalQuantitySold,
       ROUND(ps.TotalRevenue, 2) AS TotalRevenue,
       RANK() OVER (PARTITION BY ps.CategoryID ORDER BY ps.TotalRevenue DESC) AS CategoryRank,
       RANK() OVER (ORDER BY ps.TotalRevenue DESC) AS BusinessRank,
       ROUND((ps.TotalRevenue / bt.TotalBusinessRevenue * 100), 2) AS BusinessContributionPercent
FROM ProductSales ps
CROSS JOIN BusinessTotals bt
ORDER BY ps.TotalRevenue DESC;

-- Supplier performance analysis
WITH SupplierMetrics AS (
    SELECT s.SupplierID,
           s.SupplierName,
           s.Country,
           COUNT(p.ProductID) AS ProductCount,
           ROUND(AVG(p.Price), 2) AS AvgProductPrice,
           COALESCE(SUM(od.Quantity * p.Price), 0) AS TotalRevenueGenerated,
           COALESCE(SUM(od.Quantity), 0) AS TotalUnitsSold
    FROM Suppliers s
    JOIN Products p ON s.SupplierID = p.SupplierID
    LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY s.SupplierID, s.SupplierName, s.Country
)
SELECT SupplierName,
       Country,
       ProductCount,
       AvgProductPrice,
       ROUND(TotalRevenueGenerated, 2) AS TotalRevenueGenerated,
       TotalUnitsSold,
       ROUND(TotalRevenueGenerated / ProductCount, 2) AS RevenuePerProduct,
       RANK() OVER (ORDER BY TotalRevenueGenerated DESC) AS RevenueRank,
       RANK() OVER (ORDER BY ProductCount DESC) AS ProductCountRank
FROM SupplierMetrics
ORDER BY TotalRevenueGenerated DESC;
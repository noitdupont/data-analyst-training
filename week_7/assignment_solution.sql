-- Basic Aggregates
-- Calculate total number of products, average price, lowest and highest prices
SELECT COUNT(*) AS TotalProducts,
       ROUND(AVG(Price), 2) AS AveragePrice,
       MIN(Price) AS LowestPrice,
       MAX(Price) AS HighestPrice
FROM Products;

-- Count customers by country and show the country with most customers
SELECT Country, 
       COUNT(*) AS CustomerCount
FROM Customers 
GROUP BY Country
ORDER BY CustomerCount DESC;

-- Find the total quantity of all products ever ordered
SELECT SUM(Quantity) AS TotalQuantityOrdered
FROM OrderDetails;

-- Revenue Analysis
-- Calculate total revenue for the entire business
SELECT ROUND(SUM(od.Quantity * p.Price), 2) AS TotalRevenue
FROM OrderDetails od
JOIN Products p ON od.ProductID = p.ProductID;

-- Find average order value across all orders
SELECT ROUND(AVG(OrderValue), 2) AS AverageOrderValue
FROM (
    SELECT SUM(od.Quantity * p.Price) AS OrderValue
    FROM OrderDetails od
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY od.OrderID
) order_totals;

-- Determine which product category generates the most revenue
SELECT c.CategoryName,
       ROUND(SUM(od.Quantity * p.Price), 2) AS CategoryRevenue
FROM Categories c
JOIN Products p ON c.CategoryID = p.CategoryID
JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY c.CategoryID, c.CategoryName
ORDER BY CategoryRevenue DESC;

-- Customer Analytics
-- Identify customers who have spent more than £1000 total
SELECT c.CustomerName,
       c.Country,
       ROUND(SUM(od.Quantity * p.Price), 2) AS TotalSpent
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.CustomerName, c.Country
HAVING SUM(od.Quantity * p.Price) > 1000
ORDER BY TotalSpent DESC;

-- Calculate average number of orders per customer by country
SELECT c.Country,
       COUNT(DISTINCT c.CustomerID) AS CustomerCount,
       COUNT(o.OrderID) AS TotalOrders,
       ROUND(COUNT(o.OrderID) / COUNT(DISTINCT c.CustomerID), 2) AS AvgOrdersPerCustomer
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.Country
ORDER BY AvgOrdersPerCustomer DESC;

-- Find customers with above-average order values
SELECT c.CustomerName,
       c.Country,
       ROUND(AVG(order_values.OrderValue), 2) AS AvgOrderValue,
       overall_avg.OverallAverage
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN (
    SELECT OrderID, SUM(od.Quantity * p.Price) AS OrderValue
    FROM OrderDetails od
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY OrderID
) order_values ON o.OrderID = order_values.OrderID
CROSS JOIN (
    SELECT ROUND(AVG(OrderValue), 2) AS OverallAverage
    FROM (
        SELECT SUM(od.Quantity * p.Price) AS OrderValue
        FROM OrderDetails od
        JOIN Products p ON od.ProductID = p.ProductID
        GROUP BY od.OrderID
    ) all_orders
) overall_avg
GROUP BY c.CustomerID, c.CustomerName, c.Country, overall_avg.OverallAverage
HAVING AVG(order_values.OrderValue) > overall_avg.OverallAverage
ORDER BY AvgOrderValue DESC;

-- Advanced Challenges
-- Price analysis by category
SELECT c.CategoryName,
       COUNT(*) AS TotalProducts,
       SUM(CASE WHEN p.Price < 20 THEN 1 ELSE 0 END) AS BudgetProducts,
       SUM(CASE WHEN p.Price >= 20 AND p.Price <= 50 THEN 1 ELSE 0 END) AS StandardProducts,
       SUM(CASE WHEN p.Price > 50 THEN 1 ELSE 0 END) AS PremiumProducts,
       ROUND(AVG(p.Price), 2) AS AveragePrice
FROM Categories c
JOIN Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID, c.CategoryName
ORDER BY c.CategoryName;

-- Monthly revenue trends
SELECT YEAR(o.OrderDate) AS Year,
       MONTH(o.OrderDate) AS Month,
       ROUND(SUM(od.Quantity * p.Price), 2) AS MonthlySales,
       ROUND(AVG(order_values.OrderValue), 2) AS AvgOrderValue,
       COUNT(DISTINCT o.CustomerID) AS UniqueCustomers
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN (
    SELECT od.OrderID, SUM(od.Quantity * p.Price) AS OrderValue
    FROM OrderDetails od
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY od.OrderID
) order_values ON o.OrderID = order_values.OrderID
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY Year, Month;

-- Top 5 products by revenue with percentage
SELECT p.ProductName,
       ROUND(SUM(od.Quantity * p.Price), 2) AS ProductRevenue,
       ROUND((SUM(od.Quantity * p.Price) / total_revenue.TotalRevenue * 100), 2) AS PercentageOfTotal
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
CROSS JOIN (
    SELECT SUM(od.Quantity * p.Price) AS TotalRevenue
    FROM OrderDetails od
    JOIN Products p ON od.ProductID = p.ProductID
) total_revenue
GROUP BY p.ProductID, p.ProductName, total_revenue.TotalRevenue
ORDER BY ProductRevenue DESC
LIMIT 5;

-- Customer segmentation analysis
SELECT CustomerSegment,
       COUNT(*) AS CustomerCount,
       ROUND(AVG(AvgOrderValue), 2) AS SegmentAvgOrderValue,
       ROUND(AVG(TotalSpent), 2) AS SegmentAvgLifetimeValue
FROM (
    SELECT c.CustomerName,
           c.Country,
           COUNT(o.OrderID) AS OrderCount,
           ROUND(AVG(order_values.OrderValue), 2) AS AvgOrderValue,
           ROUND(SUM(order_values.OrderValue), 2) AS TotalSpent,
           CASE 
               WHEN COUNT(o.OrderID) = 1 THEN 'One-time Buyers'
               WHEN COUNT(o.OrderID) BETWEEN 2 AND 5 THEN 'Regular Customers'
               WHEN COUNT(o.OrderID) >= 6 THEN 'Loyal Customers'
           END AS CustomerSegment
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN (
        SELECT od.OrderID, SUM(od.Quantity * p.Price) AS OrderValue
        FROM OrderDetails od
        JOIN Products p ON od.ProductID = p.ProductID
        GROUP BY od.OrderID
    ) order_values ON o.OrderID = order_values.OrderID
    GROUP BY c.CustomerID, c.CustomerName, c.Country
) customer_analysis
GROUP BY CustomerSegment
ORDER BY SegmentAvgLifetimeValue DESC;
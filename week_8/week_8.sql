-- Connecting Data Across Tables
-- Single table - limited insights
SELECT CustomerName FROM Customers WHERE Country = 'Germany';

-- Multi-table analysis - complete picture
SELECT c.CustomerName, COUNT(o.OrderID) AS OrderCount,
       SUM(od.Quantity * p.Price) AS TotalSpent
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE c.Country = 'Germany'
GROUP BY c.CustomerID, c.CustomerName;

-- Understanding JOIN Types
-- INNER JOIN - only customers with orders
SELECT c.CustomerName, COUNT(o.OrderID) AS OrderCount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- LEFT JOIN - all customers, including those without orders
SELECT c.CustomerName, COUNT(o.OrderID) AS OrderCount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY OrderCount;

-- Finding customers who never ordered
SELECT c.CustomerName, c.Country
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.CustomerID IS NULL;

-- Advanced JOIN Techniques
-- Multiple JOINs - complete order analysis
SELECT c.CustomerName, c.Country,
       o.OrderDate,
       p.ProductName, cat.CategoryName,
       od.Quantity, p.Price,
       (od.Quantity * p.Price) AS LineTotal
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN Categories cat ON p.CategoryID = cat.CategoryID
WHERE c.Country = 'Germany'
ORDER BY o.OrderDate, c.CustomerName;

-- Self JOIN - employees and their managers (hypothetical)
SELECT e1.FirstName AS Employee,
       e2.FirstName AS Manager
FROM Employees e1
LEFT JOIN Employees e2 ON e1.EmployeeID = e2.EmployeeID + 1
ORDER BY e1.FirstName;

-- Complex JOIN conditions
SELECT c.CustomerName, o.OrderDate,
       SUM(od.Quantity * p.Price) AS OrderValue
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
    AND o.OrderDate BETWEEN '1996-01-01' AND '1996-12-31'
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.CustomerName, o.OrderID, o.OrderDate;

-- Subqueries: Queries Within Queries
-- Scalar subquery - average comparison
SELECT ProductName, Price,
       (SELECT AVG(Price) FROM Products) AS OverallAverage,
       (Price - (SELECT AVG(Price) FROM Products)) AS PriceDifference
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);

-- List subquery - customers who ordered specific products
SELECT CustomerName, Country
FROM Customers
WHERE CustomerID IN (
    SELECT DISTINCT o.CustomerID
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    WHERE od.ProductID IN (1, 2, 3)
);

-- Correlated subquery - customers above their country average
SELECT c1.CustomerName, c1.Country,
       customer_totals.TotalSpent
FROM Customers c1
JOIN (
    SELECT c.CustomerID, SUM(od.Quantity * p.Price) AS TotalSpent
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY c.CustomerID
) customer_totals ON c1.CustomerID = customer_totals.CustomerID
WHERE customer_totals.TotalSpent > (
    SELECT AVG(ct2.TotalSpent)
    FROM (
        SELECT SUM(od2.Quantity * p2.Price) AS TotalSpent
        FROM Customers c2
        JOIN Orders o2 ON c2.CustomerID = o2.CustomerID
        JOIN OrderDetails od2 ON o2.OrderID = od2.OrderID
        JOIN Products p2 ON od2.ProductID = p2.ProductID
        WHERE c2.Country = c1.Country
        GROUP BY c2.CustomerID
    ) ct2
);

-- Common Table Expressions (CTEs)
-- Simple CTE - customer order summaries
WITH CustomerOrderSummary AS (
    SELECT c.CustomerID, c.CustomerName, c.Country,
           COUNT(o.OrderID) AS OrderCount,
           SUM(od.Quantity * p.Price) AS TotalSpent
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
    LEFT JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY c.CustomerID, c.CustomerName, c.Country
)
SELECT Country, 
       COUNT(*) AS CustomerCount,
       AVG(TotalSpent) AS AvgSpentPerCustomer,
       MAX(TotalSpent) AS HighestSpender
FROM CustomerOrderSummary
GROUP BY Country
ORDER BY AvgSpentPerCustomer DESC;

-- Multiple CTEs - complex business analysis
WITH MonthlyRevenue AS (
    SELECT YEAR(o.OrderDate) AS Year,
           MONTH(o.OrderDate) AS Month,
           SUM(od.Quantity * p.Price) AS Revenue
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
),
RevenueWithTrends AS (
    SELECT Year, Month, Revenue,
           LAG(Revenue, 1) OVER (ORDER BY Year, Month) AS PreviousMonth,
           AVG(Revenue) OVER (ORDER BY Year, Month 
                             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ThreeMonthAvg
    FROM MonthlyRevenue
)
SELECT Year, Month, Revenue,
       (Revenue - PreviousMonth) AS MonthlyGrowth,
       ThreeMonthAvg,
       CASE 
           WHEN Revenue > ThreeMonthAvg THEN 'Above Trend'
           ELSE 'Below Trend'
       END AS TrendStatus
FROM RevenueWithTrends
ORDER BY Year, Month;

-- Assignment Starting Point
-- Assignment 1.1 - Products with category and supplier
SELECT p.ProductName, c.CategoryName, s.SupplierName
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
JOIN Suppliers s ON p.SupplierID = s.SupplierID
ORDER BY c.CategoryName, p.ProductName;

-- Assignment 3.1 - Products above category average
SELECT p.ProductName, p.Price, c.CategoryName
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > (
    SELECT AVG(p2.Price)
    FROM Products p2
    WHERE p2.CategoryID = p.CategoryID
);

-- Assignment 4.1 - Customer ranking CTE template
WITH CustomerMetrics AS (
    SELECT c.CustomerID, c.CustomerName, c.Country
           -- Add calculations here
    FROM Customers c
    -- Add JOINs here
    GROUP BY c.CustomerID, c.CustomerName, c.Country
)
SELECT CustomerName, Country
       -- Add ranking functions here
FROM CustomerMetrics
ORDER BY Country -- Add ranking criteria
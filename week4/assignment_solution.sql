-- 1. Basic Sorting
-- List all products ordered by price (highest first)
SELECT ProductName, Price 
FROM Products 
ORDER BY Price DESC;

-- Show customers alphabetically by country, then by name
SELECT CustomerName, Country, City 
FROM Customers 
ORDER BY Country ASC, CustomerName ASC;

-- Display recent orders first (most recent OrderDate first)
SELECT OrderID, CustomerID, OrderDate, EmployeeID 
FROM Orders 
ORDER BY OrderDate DESC;

-- 2. Simple Grouping
-- Count how many products exist in each category
SELECT CategoryID, COUNT(*) AS ProductCount
FROM Products 
GROUP BY CategoryID
ORDER BY CategoryID;

-- Find the average price of products by category
SELECT CategoryID, AVG(Price) AS AveragePrice
FROM Products 
GROUP BY CategoryID
ORDER BY CategoryID;

-- Count customers by country
SELECT Country, COUNT(*) AS CustomerCount
FROM Customers 
GROUP BY Country
ORDER BY CustomerCount DESC;

-- 3. Advanced Analysis
-- Show categories with more than 10 products
SELECT CategoryID, COUNT(*) AS ProductCount
FROM Products 
GROUP BY CategoryID
HAVING COUNT(*) > 10
ORDER BY ProductCount DESC;

-- Find countries with exactly 5 customers
SELECT Country, COUNT(*) AS CustomerCount
FROM Customers 
GROUP BY Country
HAVING COUNT(*) = 5
ORDER BY Country;

-- List the most expensive product in each category
SELECT CategoryID, MAX(Price) AS MostExpensivePrice
FROM Products 
GROUP BY CategoryID
ORDER BY CategoryID;

-- 4. Complex Challenges
-- Find the top 3 countries by customer count
SELECT Country, COUNT(*) AS CustomerCount
FROM Customers 
GROUP BY Country
ORDER BY CustomerCount DESC
LIMIT 3;

-- Show monthly order counts for 1996 (grouped by year and month)
SELECT YEAR(OrderDate) AS OrderYear, 
       MONTH(OrderDate) AS OrderMonth, 
       COUNT(*) AS OrderCount
FROM Orders 
WHERE YEAR(OrderDate) = 1996
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY OrderYear, OrderMonth;

-- Identify categories where average product price exceeds £30
SELECT CategoryID, AVG(Price) AS AveragePrice
FROM Products 
GROUP BY CategoryID
HAVING AVG(Price) > 30
ORDER BY AveragePrice DESC;

-- Calculate total sales revenue by category (requires joining with OrderDetails)
SELECT p.CategoryID, SUM(od.Quantity * p.Price) AS TotalRevenue
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.CategoryID
ORDER BY TotalRevenue DESC;

-- Note: The last query introduces a JOIN operation between Products and OrderDetails tables.
-- This technique will be covered in detail in week 8, but notice how it allows us to combine
-- product information with sales data to calculate meaningful business metrics.
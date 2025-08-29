-- Unorganised data - hard to interpret
SELECT CustomerName, Country FROM Customers;

-- Organised data - patterns emerge
SELECT CustomerName, Country 
FROM Customers 
ORDER BY Country, CustomerName;

-- Single column ascending
SELECT ProductName, Price 
FROM Products 
ORDER BY Price ASC;

-- Single column descending
SELECT ProductName, Price 
FROM Products 
ORDER BY Price DESC;

-- Multiple columns with different directions
SELECT CustomerName, Country, City 
FROM Customers 
ORDER BY Country ASC, CustomerName DESC;

-- Sorting by column position
SELECT CustomerName, Country 
FROM Customers 
ORDER BY 2, 1;

-- Count customers by country
SELECT Country, COUNT(*) AS CustomerCount
FROM Customers 
GROUP BY Country;

-- Show categories (basic grouping)
SELECT CategoryID 
FROM Products 
GROUP BY CategoryID;

-- Invalid query - mixing grouped and non-grouped columns
-- SELECT CategoryID, ProductName FROM Products GROUP BY CategoryID;

-- Count products by category
SELECT CategoryID, COUNT(*) AS ProductCount
FROM Products 
GROUP BY CategoryID;

-- Calculate average price by category
SELECT CategoryID, AVG(Price) AS AveragePrice
FROM Products 
GROUP BY CategoryID;

-- Multiple aggregates together
SELECT CategoryID, 
       COUNT(*) AS ProductCount,
       AVG(Price) AS AveragePrice,
       MIN(Price) AS LowestPrice,
       MAX(Price) AS HighestPrice
FROM Products 
GROUP BY CategoryID;

-- COUNT variations
SELECT COUNT(*) AS TotalCustomers,
       COUNT(PostalCode) AS CustomersWithPostalCode,
       COUNT(DISTINCT Country) AS UniqueCountries
FROM Customers;

-- Groups with more than 5 products
SELECT CategoryID, COUNT(*) AS ProductCount
FROM Products 
GROUP BY CategoryID
HAVING COUNT(*) > 5;

-- Countries with high-value customers (using WHERE and HAVING)
SELECT c.Country, COUNT(*) AS CustomerCount, AVG(order_totals.OrderValue) AS AvgOrderValue
FROM Customers c
JOIN (
    SELECT o.CustomerID, SUM(od.Quantity * p.Price) AS OrderValue
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE o.OrderDate >= '1996-01-01'
    GROUP BY o.CustomerID
) order_totals ON c.CustomerID = order_totals.CustomerID
GROUP BY c.Country
HAVING AVG(order_totals.OrderValue) > 500
ORDER BY AvgOrderValue DESC;

-- Multiple grouping columns
SELECT Country, City, COUNT(*) AS CustomerCount
FROM Customers 
GROUP BY Country, City
ORDER BY Country, CustomerCount DESC;

-- Assignment Sample Starting Points
-- Assignment 1.1 - Price sorting
SELECT ProductName, Price 
FROM Products 
ORDER BY ? ?;

-- Assignment 2.1 - Category counts
SELECT CategoryID, COUNT(*) AS ProductCount
FROM Products 
GROUP BY ?;

-- Assignment 3.1 - Filtered groups
SELECT CategoryID, COUNT(*) AS ProductCount
FROM Products 
GROUP BY CategoryID
HAVING ? ? ?;
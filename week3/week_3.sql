-- Without filtering - overwhelming results
SELECT CustomerName, Country FROM Customers;

-- With filtering - focused results
SELECT CustomerName, Country 
FROM Customers 
WHERE Country = 'Germany';

-- Exact text match
SELECT ProductName, Price 
FROM Products 
WHERE CategoryID = 1;

-- Numeric range
SELECT ProductName, Price 
FROM Products 
WHERE Price > 50;

-- Date comparison
SELECT OrderID, OrderDate 
FROM Orders 
WHERE OrderDate >= '1997-01-01';

-- AND: Both conditions required
SELECT ProductName, Price 
FROM Products 
WHERE Price > 20 AND CategoryID = 1;

-- OR: Either condition works
SELECT CustomerName, Country 
FROM Customers 
WHERE Country = 'Germany' OR Country = 'France';

-- NOT: Exclude specific values
SELECT ProductName, Price 
FROM Products 
WHERE NOT CategoryID = 8;

-- Grouped conditions
SELECT CustomerName, Country 
FROM Customers 
WHERE (Country = 'Germany' OR Country = 'France') 
  AND CustomerName LIKE 'A%';

-- Starts with pattern
SELECT CustomerName 
FROM Customers 
WHERE CustomerName LIKE 'A%';

-- Ends with pattern
SELECT CustomerName 
FROM Customers 
WHERE CustomerName LIKE '%Market%';

-- Contains pattern
SELECT ProductName 
FROM Products 
WHERE ProductName LIKE '%Chocolate%';

-- Specific position matching
SELECT CustomerName 
FROM Customers 
WHERE CustomerName LIKE 'A_t%';

-- IN operator for multiple values
SELECT CustomerName, Country 
FROM Customers 
WHERE Country IN ('Germany', 'France', 'UK');

-- BETWEEN for ranges
SELECT ProductName, Price 
FROM Products 
WHERE Price BETWEEN 20 AND 50;

-- NULL handling
SELECT CustomerName, ContactName 
FROM Customers 
WHERE ContactName IS NOT NULL;

-- Complex combination
SELECT ProductName, Price, CategoryID 
FROM Products 
WHERE CategoryID IN (1, 2, 3) 
  AND Price BETWEEN 10 AND 30 
  AND ProductName LIKE '%a%';

-- Assignment Sample Starting Points
-- Assignment 1.1 - Multiple countries
SELECT CustomerName, Country 
FROM Customers 
WHERE Country IN (?, ?, ?);

-- Assignment 2.1 - Price range
SELECT ProductName, Price 
FROM Products 
WHERE Price BETWEEN ? AND ?;

-- Assignment 3.1 - Date filtering
SELECT OrderID, OrderDate 
FROM Orders 
WHERE OrderDate BETWEEN ? AND ?;
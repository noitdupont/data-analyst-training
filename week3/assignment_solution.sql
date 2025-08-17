-- 1. Customer Analysis
-- Find all customers from Germany, France, or UK
SELECT CustomerName, Country 
FROM Customers 
WHERE Country IN ('Germany', 'France', 'UK');

-- List customers whose names start with 'B'
SELECT CustomerName, ContactName, Country 
FROM Customers 
WHERE CustomerName LIKE 'B%';

-- Identify customers with missing postal codes
SELECT CustomerName, City, Country, PostalCode 
FROM Customers 
WHERE PostalCode IS NULL OR PostalCode = '';

-- 2. Product Investigation
-- Show products priced between £15 and £40
SELECT ProductName, Price, Unit 
FROM Products 
WHERE Price BETWEEN 15 AND 40;

-- Find all products from category 1 (Beverages) or category 8 (Seafood)
SELECT ProductName, CategoryID, Price 
FROM Products 
WHERE CategoryID IN (1, 8);

-- List products whose names contain 'cheese' (case-insensitive)
SELECT ProductName, Price, CategoryID 
FROM Products 
WHERE ProductName LIKE '%cheese%';

-- 3. Order Examination
-- Display orders placed in December 1996
SELECT OrderID, CustomerID, OrderDate, EmployeeID 
FROM Orders 
WHERE OrderDate BETWEEN '1996-12-01' AND '1996-12-31';

-- Find orders handled by employees 1, 3, or 5
SELECT OrderID, CustomerID, EmployeeID, OrderDate 
FROM Orders 
WHERE EmployeeID IN (1, 3, 5);

-- Show orders where customer ID is greater than 50
SELECT OrderID, CustomerID, EmployeeID, OrderDate 
FROM Orders 
WHERE CustomerID > 50;

-- 4. Advanced Challenges
-- Find German customers whose names don't start with 'A'
SELECT CustomerName, ContactName, City 
FROM Customers 
WHERE Country = 'Germany' 
  AND CustomerName NOT LIKE 'A%';

-- List expensive products (price > £50) from dairy or confection categories
SELECT ProductName, Price, CategoryID 
FROM Products 
WHERE Price > 50 
  AND CategoryID IN (3, 4);

-- Identify orders from the last quarter of 1996 shipped by 'Speedy Express'
SELECT o.OrderID, o.CustomerID, o.OrderDate, s.ShipperName 
FROM Orders o
JOIN Shippers s ON o.ShipperID = s.ShipperID
WHERE o.OrderDate BETWEEN '1996-10-01' AND '1996-12-31' 
  AND s.ShipperName = 'Speedy Express';

-- Note: The last query introduces a JOIN operation to connect the Orders table with the Shippers table,
-- which will be covered in detail in upcoming weeks. For now, focus on understanding how the WHERE clause filters
-- the results based on date range and shipper name.
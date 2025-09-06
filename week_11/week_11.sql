-- Introduction to Advanced Data Combination Techniques
-- Basic approach: Single table query
SELECT CustomerName, Country FROM Customers WHERE Country = 'Germany';

-- Advanced approach: Multi-source combination
SELECT CustomerName, Country, 'Customer' AS SourceType FROM Customers WHERE Country = 'Germany'
UNION ALL
SELECT SupplierName, Country, 'Supplier' AS SourceType FROM Suppliers WHERE Country = 'Germany';

-- UNION Operations and Data Consolidation
-- UNION: Remove duplicates from country list
SELECT Country FROM Customers
UNION
SELECT Country FROM Suppliers
ORDER BY Country;

-- UNION ALL: Keep all records for contact analysis
SELECT CustomerName AS ContactName, City, Country, 'Customer' AS Type FROM Customers
UNION ALL
SELECT SupplierName, City, Country, 'Supplier' FROM Suppliers
ORDER BY Country, City;

-- Complex consolidation: High-value vs regular orders
SELECT OrderID, CustomerID, OrderDate, 'High Value' AS OrderType
FROM Orders o
WHERE EXISTS (SELECT 1 FROM OrderDetails od WHERE od.OrderID = o.OrderID 
              GROUP BY od.OrderID HAVING SUM(od.Quantity * 
              (SELECT Price FROM Products WHERE ProductID = od.ProductID)) > 1000)
UNION ALL
SELECT OrderID, CustomerID, OrderDate, 'Regular'
FROM Orders o
WHERE NOT EXISTS (SELECT 1 FROM OrderDetails od WHERE od.OrderID = o.OrderID 
                  GROUP BY od.OrderID HAVING SUM(od.Quantity * 
                  (SELECT Price FROM Products WHERE ProductID = od.ProductID)) > 1000);

-- EXISTS and Correlated Subqueries
-- EXISTS: Find customers who have placed orders
SELECT CustomerID, CustomerName, Country
FROM Customers c
WHERE EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID);

-- NOT EXISTS: Find products never ordered
SELECT ProductID, ProductName, CategoryID, Price
FROM Products p
WHERE NOT EXISTS (SELECT 1 FROM OrderDetails od WHERE od.ProductID = p.ProductID);

-- Complex correlated subquery: Customers with above-average order values
SELECT c.CustomerID, c.CustomerName, c.Country
FROM Customers c
WHERE EXISTS (
    SELECT 1 FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE o.CustomerID = c.CustomerID
    GROUP BY o.CustomerID
    HAVING AVG(od.Quantity * p.Price) > (
        SELECT AVG(od2.Quantity * p2.Price)
        FROM OrderDetails od2
        JOIN Products p2 ON od2.ProductID = p2.ProductID
    )
);

-- Advanced: Customers who ordered from every category
SELECT c.CustomerID, c.CustomerName
FROM Customers c
WHERE NOT EXISTS (
    SELECT cat.CategoryID
    FROM Categories cat
    WHERE NOT EXISTS (
        SELECT 1
        FROM Orders o
        JOIN OrderDetails od ON o.OrderID = od.OrderID
        JOIN Products p ON od.ProductID = p.ProductID
        WHERE o.CustomerID = c.CustomerID AND p.CategoryID = cat.CategoryID
    )
);

-- Conditional JOINs and Advanced Filtering
-- Conditional JOIN: Orders with seasonal product matching
SELECT c.CustomerName, o.OrderDate, p.ProductName, cat.CategoryName
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID 
    AND (
        (MONTH(o.OrderDate) IN (12, 1, 2) AND p.CategoryID = 1) -- Beverages in winter
        OR (MONTH(o.OrderDate) IN (6, 7, 8) AND p.CategoryID = 7) -- Produce in summer
    )
JOIN Categories cat ON p.CategoryID = cat.CategoryID;

-- Advanced filtering with CASE in JOIN
SELECT e1.FirstName + ' ' + e1.LastName AS Employee,
       e2.FirstName + ' ' + e2.LastName AS Manager,
       o.OrderDate
FROM Employees e1
LEFT JOIN Employees e2 ON CASE 
    WHEN e1.EmployeeID IN (1, 2, 3) THEN e2.EmployeeID = 2  -- Report to Andrew
    WHEN e1.EmployeeID IN (4, 5, 6) THEN e2.EmployeeID = 5  -- Report to Steven
    ELSE e2.EmployeeID = 1  -- Others report to Nancy
END
LEFT JOIN Orders o ON e1.EmployeeID = o.EmployeeID AND o.OrderDate >= '1996-08-01';

-- Complex temporal JOIN: Customer loyalty analysis
SELECT c.CustomerName, 
       COUNT(DISTINCT first_orders.OrderID) AS FirstYearOrders,
       COUNT(DISTINCT repeat_orders.OrderID) AS RepeatOrders
FROM Customers c
LEFT JOIN Orders first_orders ON c.CustomerID = first_orders.CustomerID 
    AND first_orders.OrderDate BETWEEN '1996-07-01' AND '1996-12-31'
LEFT JOIN Orders repeat_orders ON c.CustomerID = repeat_orders.CustomerID 
    AND repeat_orders.OrderDate >= '1997-01-01'
    AND EXISTS (SELECT 1 FROM Orders prev WHERE prev.CustomerID = c.CustomerID 
                AND prev.OrderDate < repeat_orders.OrderDate)
GROUP BY c.CustomerID, c.CustomerName
HAVING COUNT(DISTINCT first_orders.OrderID) > 0;

-- Multiple condition JOIN with performance optimisation
SELECT s.SupplierName, p.ProductName, AVG(od.Quantity) AS AvgOrderQuantity
FROM Suppliers s
JOIN Products p ON s.SupplierID = p.SupplierID
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID 
    AND o.OrderDate >= '1996-01-01' 
    AND o.OrderDate < '1997-01-01'
WHERE s.Country IN ('USA', 'UK', 'Germany')
    AND p.Price > 20
GROUP BY s.SupplierID, s.SupplierName, p.ProductID, p.ProductName
HAVING AVG(od.Quantity) > 10;

-- Assignment Starting Point
-- Practice starter: Basic UNION structure
SELECT CustomerName AS Name, City, Country, 'Customer' AS Type FROM Customers WHERE Country = 'Germany'
UNION ALL
SELECT SupplierName, City, Country, 'Supplier' FROM Suppliers WHERE Country = 'Germany';

-- Practice starter: EXISTS pattern
SELECT ProductName FROM Products p 
WHERE EXISTS (SELECT 1 FROM OrderDetails od WHERE od.ProductID = p.ProductID);

-- Practice starter: Conditional JOIN framework
SELECT c.CustomerName, o.OrderDate 
FROM Customers c 
JOIN Orders o ON c.CustomerID = o.CustomerID 
    AND YEAR(o.OrderDate) = 1997;
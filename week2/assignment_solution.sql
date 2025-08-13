-- What is the total sales revenue for each product category?
SELECT 
    c.CategoryName,
    SUM(od.Quantity * p.Price) AS TotalRevenue
FROM Categories c
JOIN Products p ON c.CategoryID = p.CategoryID
JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY c.CategoryID, c.CategoryName
ORDER BY TotalRevenue DESC;

-- How many customers made purchases in the last month?
SELECT COUNT(DISTINCT CustomerID) AS CustomersLastMonth
FROM Orders
WHERE OrderDate >= '1997-01-12';

-- What are the top 5 products by sales volume?
SELECT 
    p.ProductName,
    SUM(od.Quantity) AS TotalQuantitySold
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalQuantitySold DESC
LIMIT 5;

-- What is the average order value for each month?
SELECT 
    YEAR(o.OrderDate) AS OrderYear,
    MONTH(o.OrderDate) AS OrderMonth,
    AVG(order_totals.OrderTotal) AS AverageOrderValue
FROM Orders o
JOIN (
    SELECT 
        od.OrderID,
        SUM(od.Quantity * p.Price) AS OrderTotal
    FROM OrderDetails od
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY od.OrderID
) order_totals ON o.OrderID = order_totals.OrderID
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY OrderYear, OrderMonth;

-- Which customers have not made a purchase in the last six months?
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.ContactName,
    MAX(o.OrderDate) AS LastOrderDate
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName, c.ContactName
HAVING MAX(o.OrderDate) < '1996-08-12' OR MAX(o.OrderDate) IS NULL
ORDER BY LastOrderDate DESC;

-- What is the trend of sales over the past year?
SELECT 
    YEAR(o.OrderDate) AS OrderYear,
    MONTH(o.OrderDate) AS OrderMonth,
    SUM(od.Quantity * p.Price) AS MonthlySales,
    COUNT(DISTINCT o.OrderID) AS OrderCount
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE o.OrderDate >= '1996-02-12'
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY OrderYear, OrderMonth;

-- How many new customers were acquired each month?
SELECT 
    YEAR(FirstOrderDate) AS AcquisitionYear,
    MONTH(FirstOrderDate) AS AcquisitionMonth,
    COUNT(*) AS NewCustomers
FROM (
    SELECT 
        CustomerID,
        MIN(OrderDate) AS FirstOrderDate
    FROM Orders
    GROUP BY CustomerID
) customer_first_orders
GROUP BY YEAR(FirstOrderDate), MONTH(FirstOrderDate)
ORDER BY AcquisitionYear, AcquisitionMonth;

-- Note: We've adjusted the date filters to work with the actual data in the Northwind database,
-- which contains orders from 1996-1997. The "last month" and "last six months" references
-- use 1997-02-12 as the reference point (the latest order date in the dataset).
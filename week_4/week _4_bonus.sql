-- =====================================================
-- NORTHWIND TRADING COMPANY - BUSINESS ANALYSIS
-- =====================================================
-- Business Requirement: Create a complete performance review for Northwind Trading Company
-- covering customer analysis, product performance, sales trends, and operational insights
-- using only fundamental SQL concepts (SELECT, WHERE, ORDER BY, GROUP BY, basic JOINs)
-- =====================================================
-- The analysis below covers only concepts from Weeks 1-4:

-- Week 1: Basic SELECT statements, database exploration
-- Week 2: WHERE clauses for filtering data
-- Week 3: Advanced filtering with LIKE, IN, BETWEEN, NULL handling
-- Week 4: ORDER BY for sorting, GROUP BY for aggregation, HAVING for group filtering
-- =====================================================

-- 1.1 Get overall database statistics
SELECT 'Total Customers' AS Metric, COUNT(*) AS Value FROM Customers
UNION ALL
SELECT 'Total Products', COUNT(*) FROM Products
UNION ALL
SELECT 'Total Orders', COUNT(*) FROM Orders
UNION ALL
SELECT 'Total Categories', COUNT(*) FROM Categories
UNION ALL
SELECT 'Total Suppliers', COUNT(*) FROM Suppliers;

-- 1.2 Examine date range of business operations
SELECT 
    MIN(OrderDate) AS FirstOrder,
    MAX(OrderDate) AS LastOrder,
    DATEDIFF(MAX(OrderDate), MIN(OrderDate)) AS DaysInOperation
FROM Orders;

-- 1.3 Basic table exploration - Categories
SELECT CategoryID, CategoryName, Description
FROM Categories
ORDER BY CategoryID;

-- 1.4 Sample of customer data across different countries
SELECT CustomerName, ContactName, City, Country
FROM Customers
WHERE Country IN ('Germany', 'France', 'UK', 'USA')
ORDER BY Country, CustomerName
LIMIT 20;

-- =====================================================
-- SECTION 2: CUSTOMER ANALYSIS
-- =====================================================

-- 2.1 Customer distribution by country
SELECT 
    Country,
    COUNT(*) AS CustomerCount,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Customers)), 2) AS PercentageOfTotal
FROM Customers
GROUP BY Country
ORDER BY CustomerCount DESC;

-- 2.2 Customers by city (top 10 cities)
SELECT 
    City,
    Country,
    COUNT(*) AS CustomerCount
FROM Customers
GROUP BY City, Country
ORDER BY CustomerCount DESC, Country
LIMIT 10;

-- 2.3 Find customers with missing contact information
SELECT 
    CustomerName,
    ContactName,
    City,
    Country,
    CASE 
        WHEN ContactName IS NULL OR ContactName = '' THEN 'Missing Contact'
        WHEN PostalCode IS NULL OR PostalCode = '' THEN 'Missing Postal Code'
        ELSE 'Complete Info'
    END AS DataQuality
FROM Customers
WHERE ContactName IS NULL OR ContactName = '' OR PostalCode IS NULL OR PostalCode = ''
ORDER BY Country, CustomerName;

-- 2.4 Customer names analysis - patterns and lengths
SELECT 
    CASE 
        WHEN LENGTH(CustomerName) < 15 THEN 'Short (< 15 chars)'
        WHEN LENGTH(CustomerName) BETWEEN 15 AND 25 THEN 'Medium (15-25 chars)'
        ELSE 'Long (> 25 chars)'
    END AS NameLength,
    COUNT(*) AS CustomerCount
FROM Customers
GROUP BY 
    CASE 
        WHEN LENGTH(CustomerName) < 15 THEN 'Short (< 15 chars)'
        WHEN LENGTH(CustomerName) BETWEEN 15 AND 25 THEN 'Medium (15-25 chars)'
        ELSE 'Long (> 25 chars)'
    END
ORDER BY CustomerCount DESC;

-- 2.5 Customers starting with specific letters
SELECT 
    LEFT(CustomerName, 1) AS FirstLetter,
    COUNT(*) AS CustomerCount
FROM Customers
GROUP BY LEFT(CustomerName, 1)
ORDER BY CustomerCount DESC, FirstLetter;

-- =====================================================
-- SECTION 3: PRODUCT ANALYSIS
-- =====================================================

-- 3.1 Product inventory overview by category
SELECT 
    c.CategoryName,
    COUNT(p.ProductID) AS ProductCount,
    AVG(p.Price) AS AveragePrice,
    MIN(p.Price) AS LowestPrice,
    MAX(p.Price) AS HighestPrice,
    SUM(p.Price) AS TotalInventoryValue
FROM Categories c
JOIN Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID, c.CategoryName
ORDER BY ProductCount DESC;

-- 3.2 Most expensive products in each category
SELECT 
    c.CategoryName,
    p.ProductName,
    p.Price,
    p.Unit
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price = (
    SELECT MAX(p2.Price)
    FROM Products p2
    WHERE p2.CategoryID = p.CategoryID
)
ORDER BY p.Price DESC;

-- 3.3 Products priced above average in their category
SELECT 
    c.CategoryName,
    p.ProductName,
    p.Price,
    ROUND(avg_prices.CategoryAverage, 2) AS CategoryAverage,
    ROUND(p.Price - avg_prices.CategoryAverage, 2) AS PriceAboveAverage
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
JOIN (
    SELECT 
        CategoryID,
        AVG(Price) AS CategoryAverage
    FROM Products
    GROUP BY CategoryID
) avg_prices ON p.CategoryID = avg_prices.CategoryID
WHERE p.Price > avg_prices.CategoryAverage
ORDER BY c.CategoryName, PriceAboveAverage DESC;

-- 3.4 Price distribution analysis
SELECT 
    CASE 
        WHEN Price < 10 THEN 'Budget (< £10)'
        WHEN Price BETWEEN 10 AND 25 THEN 'Standard (£10-£25)'
        WHEN Price BETWEEN 25 AND 50 THEN 'Premium (£25-£50)'
        ELSE 'Luxury (> £50)'
    END AS PriceCategory,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AveragePrice
FROM Products
GROUP BY 
    CASE 
        WHEN Price < 10 THEN 'Budget (< £10)'
        WHEN Price BETWEEN 10 AND 25 THEN 'Standard (£10-£25)'
        WHEN Price BETWEEN 25 AND 50 THEN 'Premium (£25-£50)'
        ELSE 'Luxury (> £50)'
    END
ORDER BY AveragePrice;

-- 3.5 Products with unusual pricing (outliers)
SELECT 
    ProductName,
    Price,
    c.CategoryName,
    CASE 
        WHEN Price < 5 THEN 'Very Low Price'
        WHEN Price > 100 THEN 'Very High Price'
        ELSE 'Normal Range'
    END AS PriceStatus
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE Price < 5 OR Price > 100
ORDER BY Price DESC;

-- =====================================================
-- SECTION 4: SUPPLIER ANALYSIS
-- =====================================================

-- 4.1 Supplier geographic distribution
SELECT 
    Country,
    COUNT(*) AS SupplierCount,
    COUNT(DISTINCT City) AS CitiesRepresented
FROM Suppliers
GROUP BY Country
ORDER BY SupplierCount DESC;

-- 4.2 Suppliers and their product portfolio
SELECT 
    s.SupplierName,
    s.Country,
    COUNT(p.ProductID) AS ProductsSupplied,
    AVG(p.Price) AS AverageProductPrice,
    MIN(p.Price) AS LowestPrice,
    MAX(p.Price) AS HighestPrice
FROM Suppliers s
JOIN Products p ON s.SupplierID = p.SupplierID
GROUP BY s.SupplierID, s.SupplierName, s.Country
ORDER BY ProductsSupplied DESC;

-- 4.3 Suppliers with limited product range
SELECT 
    s.SupplierName,
    s.Country,
    COUNT(p.ProductID) AS ProductCount
FROM Suppliers s
JOIN Products p ON s.SupplierID = p.SupplierID
GROUP BY s.SupplierID, s.SupplierName, s.Country
HAVING COUNT(p.ProductID) <= 2
ORDER BY ProductCount, s.SupplierName;

-- 4.4 Top suppliers by average product value
SELECT 
    s.SupplierName,
    s.Country,
    COUNT(p.ProductID) AS ProductCount,
    ROUND(AVG(p.Price), 2) AS AveragePrice
FROM Suppliers s
JOIN Products p ON s.SupplierID = p.SupplierID
GROUP BY s.SupplierID, s.SupplierName, s.Country
HAVING COUNT(p.ProductID) >= 3
ORDER BY AveragePrice DESC
LIMIT 10;

-- =====================================================
-- SECTION 5: ORDER ANALYSIS
-- =====================================================

-- 5.1 Order volume by year and month
SELECT 
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonth,
    COUNT(*) AS OrderCount,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers,
    COUNT(DISTINCT EmployeeID) AS EmployeesInvolved
FROM Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY OrderYear, OrderMonth;

-- 5.2 Daily order patterns (day of week analysis)
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
    COUNT(*) AS OrderCount,
    AVG(COUNT(*)) OVER() AS AverageDailyOrders
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
ORDER BY DAYOFWEEK(OrderDate);

-- 5.3 Customer ordering frequency
SELECT 
    c.CustomerName,
    c.Country,
    COUNT(o.OrderID) AS TotalOrders,
    MIN(o.OrderDate) AS FirstOrder,
    MAX(o.OrderDate) AS LastOrder,
    DATEDIFF(MAX(o.OrderDate), MIN(o.OrderDate)) AS DaysBetweenFirstLast
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName, c.Country
ORDER BY TotalOrders DESC
LIMIT 20;

-- 5.4 Customers with single orders only
SELECT 
    c.CustomerName,
    c.Country,
    o.OrderDate
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerID IN (
    SELECT CustomerID
    FROM Orders
    GROUP BY CustomerID
    HAVING COUNT(*) = 1
)
ORDER BY c.Country, c.CustomerName;

-- 5.5 Orders by shipping company
SELECT 
    s.ShipperName,
    COUNT(o.OrderID) AS OrdersShipped,
    ROUND((COUNT(o.OrderID) * 100.0 / (SELECT COUNT(*) FROM Orders)), 2) AS MarketSharePercent
FROM Shippers s
JOIN Orders o ON s.ShipperID = o.ShipperID
GROUP BY s.ShipperID, s.ShipperName
ORDER BY OrdersShipped DESC;

-- =====================================================
-- SECTION 6: EMPLOYEE PERFORMANCE ANALYSIS
-- =====================================================

-- 6.1 Employee order handling statistics
SELECT 
    e.FirstName,
    e.LastName,
    COUNT(o.OrderID) AS OrdersHandled,
    COUNT(DISTINCT o.CustomerID) AS UniqueCustomers,
    MIN(o.OrderDate) AS FirstOrderHandled,
    MAX(o.OrderDate) AS LastOrderHandled
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
GROUP BY e.EmployeeID, e.FirstName, e.LastName
ORDER BY OrdersHandled DESC;

-- 6.2 Employee productivity by month
SELECT 
    e.FirstName,
    e.LastName,
    YEAR(o.OrderDate) AS Year,
    MONTH(o.OrderDate) AS Month,
    COUNT(o.OrderID) AS MonthlyOrders
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
WHERE YEAR(o.OrderDate) = 1996
GROUP BY e.EmployeeID, e.FirstName, e.LastName, YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY Year, Month, MonthlyOrders DESC;

-- 6.3 Employee experience analysis
SELECT 
    CONCAT(FirstName, ' ', LastName) AS EmployeeName,
    BirthDate,
    YEAR(CURDATE()) - YEAR(BirthDate) AS CurrentAge,
    CASE 
        WHEN YEAR(CURDATE()) - YEAR(BirthDate) < 30 THEN 'Young (< 30)'
        WHEN YEAR(CURDATE()) - YEAR(BirthDate) BETWEEN 30 AND 50 THEN 'Middle-aged (30-50)'
        ELSE 'Senior (> 50)'
    END AS AgeGroup
FROM Employees
ORDER BY BirthDate;

-- =====================================================
-- SECTION 7: SALES PERFORMANCE ANALYSIS
-- =====================================================

-- 7.1 Revenue by product category
SELECT 
    c.CategoryName,
    COUNT(DISTINCT od.OrderID) AS OrdersContainingCategory,
    SUM(od.Quantity) AS TotalUnitsSold,
    SUM(od.Quantity * p.Price) AS TotalRevenue,
    AVG(od.Quantity * p.Price) AS AverageOrderValue
FROM Categories c
JOIN Products p ON c.CategoryID = p.CategoryID
JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY c.CategoryID, c.CategoryName
ORDER BY TotalRevenue DESC;

-- 7.2 Top performing products by revenue
SELECT 
    p.ProductName,
    c.CategoryName,
    SUM(od.Quantity) AS TotalUnitsSold,
    SUM(od.Quantity * p.Price) AS TotalRevenue,
    COUNT(DISTINCT od.OrderID) AS OrdersContainingProduct
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, c.CategoryName
ORDER BY TotalRevenue DESC
LIMIT 15;

-- 7.3 Products with high volume but low revenue
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price,
    SUM(od.Quantity) AS TotalUnitsSold,
    SUM(od.Quantity * p.Price) AS TotalRevenue,
    ROUND(SUM(od.Quantity * p.Price) / SUM(od.Quantity), 2) AS AverageSellingPrice
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, c.CategoryName, p.Price
HAVING SUM(od.Quantity) > 100 AND SUM(od.Quantity * p.Price) < 2000
ORDER BY TotalUnitsSold DESC;

-- 7.4 Monthly sales trends
SELECT 
    YEAR(o.OrderDate) AS SalesYear,
    MONTH(o.OrderDate) AS SalesMonth,
    COUNT(DISTINCT o.OrderID) AS OrderCount,
    SUM(od.Quantity) AS TotalUnits,
    SUM(od.Quantity * p.Price) AS MonthlyRevenue,
    COUNT(DISTINCT o.CustomerID) AS UniqueCustomers
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY SalesYear, SalesMonth;

-- 7.5 Customer value analysis
SELECT 
    c.CustomerName,
    c.Country,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    SUM(od.Quantity) AS TotalUnits,
    SUM(od.Quantity * p.Price) AS TotalSpent,
    ROUND(SUM(od.Quantity * p.Price) / COUNT(DISTINCT o.OrderID), 2) AS AverageOrderValue
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.CustomerName, c.Country
ORDER BY TotalSpent DESC
LIMIT 20;

-- =====================================================
-- SECTION 8: OPERATIONAL INSIGHTS
-- =====================================================

-- 8.1 Order size distribution
SELECT 
    CASE 
        WHEN OrderSize = 1 THEN 'Single Item'
        WHEN OrderSize BETWEEN 2 AND 5 THEN 'Small (2-5 items)'
        WHEN OrderSize BETWEEN 6 AND 10 THEN 'Medium (6-10 items)'
        ELSE 'Large (>10 items)'
    END AS OrderSizeCategory,
    COUNT(*) AS OrderCount,
    AVG(OrderSize) AS AverageItemsPerOrder
FROM (
    SELECT 
        OrderID,
        COUNT(*) AS OrderSize
    FROM OrderDetails
    GROUP BY OrderID
) order_sizes
GROUP BY 
    CASE 
        WHEN OrderSize = 1 THEN 'Single Item'
        WHEN OrderSize BETWEEN 2 AND 5 THEN 'Small (2-5 items)'
        WHEN OrderSize BETWEEN 6 AND 10 THEN 'Medium (6-10 items)'
        ELSE 'Large (>10 items)'
    END
ORDER BY AverageItemsPerOrder;

-- 8.2 Product popularity analysis
SELECT 
    p.ProductName,
    c.CategoryName,
    COUNT(od.OrderDetailID) AS TimesOrdered,
    SUM(od.Quantity) AS TotalQuantityOrdered,
    COUNT(DISTINCT od.OrderID) AS UniqueOrders,
    ROUND(SUM(od.Quantity) / COUNT(DISTINCT od.OrderID), 2) AS AvgQuantityPerOrder
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, c.CategoryName
ORDER BY TimesOrdered DESC
LIMIT 20;

-- 8.3 Seasonal patterns (quarterly analysis)
SELECT 
    YEAR(o.OrderDate) AS Year,
    CASE 
        WHEN MONTH(o.OrderDate) IN (1,2,3) THEN 'Q1'
        WHEN MONTH(o.OrderDate) IN (4,5,6) THEN 'Q2'
        WHEN MONTH(o.OrderDate) IN (7,8,9) THEN 'Q3'
        ELSE 'Q4'
    END AS Quarter,
    COUNT(DISTINCT o.OrderID) AS Orders,
    SUM(od.Quantity * p.Price) AS Revenue,
    COUNT(DISTINCT o.CustomerID) AS ActiveCustomers
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY YEAR(o.OrderDate), 
    CASE 
        WHEN MONTH(o.OrderDate) IN (1,2,3) THEN 'Q1'
        WHEN MONTH(o.OrderDate) IN (4,5,6) THEN 'Q2'
        WHEN MONTH(o.OrderDate) IN (7,8,9) THEN 'Q3'
        ELSE 'Q4'
    END
ORDER BY Year, Quarter;

-- =====================================================
-- SECTION 9: BUSINESS INTELLIGENCE SUMMARY
-- =====================================================

-- 9.1 Key performance indicators
SELECT 
    'Total Revenue' AS KPI,
    CONCAT('£', FORMAT(SUM(od.Quantity * p.Price), 2)) AS Value
FROM OrderDetails od
JOIN Products p ON od.ProductID = p.ProductID
UNION ALL
SELECT 
    'Average Order Value',
    CONCAT('£', FORMAT(AVG(order_values.OrderValue), 2))
FROM (
    SELECT SUM(od.Quantity * p.Price) AS OrderValue
    FROM OrderDetails od
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY od.OrderID
) order_values
UNION ALL
SELECT 
    'Total Orders Processed',
    FORMAT(COUNT(*), 0)
FROM Orders
UNION ALL
SELECT 
    'Active Customers',
    FORMAT(COUNT(DISTINCT CustomerID), 0)
FROM Orders
UNION ALL
SELECT 
    'Products in Catalog',
    FORMAT(COUNT(*), 0)
FROM Products;

-- 9.2 Top performing segments summary
SELECT 
    'Best Country by Customer Count' AS Segment,
    Country AS Name,
    CONCAT(COUNT(*), ' customers') AS Performance
FROM Customers
GROUP BY Country
ORDER BY COUNT(*) DESC
LIMIT 1;

-- 9.3 Product category performance ranking
SELECT 
    c.CategoryName,
    COUNT(p.ProductID) AS Products,
    ROUND(AVG(p.Price), 2) AS AvgPrice,
    COALESCE(SUM(od.Quantity * p.Price), 0) AS Revenue,
    RANK() OVER (ORDER BY COALESCE(SUM(od.Quantity * p.Price), 0) DESC) AS RevenueRank
FROM Categories c
LEFT JOIN Products p ON c.CategoryID = p.CategoryID
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY c.CategoryID, c.CategoryName
ORDER BY RevenueRank;

-- 9.4 Customer loyalty analysis
SELECT 
    CASE 
        WHEN OrderCount = 1 THEN 'One-time Customer'
        WHEN OrderCount BETWEEN 2 AND 5 THEN 'Occasional Customer'
        WHEN OrderCount BETWEEN 6 AND 10 THEN 'Regular Customer'
        ELSE 'Loyal Customer'
    END AS CustomerType,
    COUNT(*) AS CustomerCount,
    ROUND(AVG(TotalSpent), 2) AS AvgLifetimeValue
FROM (
    SELECT 
        c.CustomerID,
        COUNT(o.OrderID) AS OrderCount,
        COALESCE(SUM(od.Quantity * p.Price), 0) AS TotalSpent
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
    LEFT JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY c.CustomerID
) customer_metrics
GROUP BY 
    CASE 
        WHEN OrderCount = 1 THEN 'One-time Customer'
        WHEN OrderCount BETWEEN 2 AND 5 THEN 'Occasional Customer'
        WHEN OrderCount BETWEEN 6 AND 10 THEN 'Regular Customer'
        ELSE 'Loyal Customer'
    END
ORDER BY AvgLifetimeValue DESC;

-- =====================================================
-- SECTION 10: FINAL BUSINESS RECOMMENDATIONS
-- =====================================================

-- 10.1 Underperforming products that need attention
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price,
    COALESCE(SUM(od.Quantity), 0) AS TotalSold,
    CASE 
        WHEN COALESCE(SUM(od.Quantity), 0) = 0 THEN 'Never Sold'
        WHEN COALESCE(SUM(od.Quantity), 0) < 5 THEN 'Very Low Sales'
        ELSE 'Low Sales'
    END AS PerformanceStatus
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, c.CategoryName, p.Price
HAVING COALESCE(SUM(od.Quantity), 0) < 10
ORDER BY TotalSold ASC, p.Price DESC;

-- 10.2 Growth opportunities by untapped markets
SELECT 
    c.Country,
    COUNT(c.CustomerID) AS ExistingCustomers,
    COALESCE(MAX(total_orders.OrderCount), 0) AS TotalOrders,
    COALESCE(MAX(total_revenue.Revenue), 0) AS TotalRevenue,
    CASE 
        WHEN COUNT(c.CustomerID) < 3 THEN 'High Growth Potential'
        WHEN COUNT(c.CustomerID) < 6 THEN 'Medium Growth Potential'
        ELSE 'Saturated Market'
    END AS GrowthOpportunity
FROM Customers c
LEFT JOIN (
    SELECT 
        c2.Country,
        COUNT(o.OrderID) AS OrderCount
    FROM Customers c2
    JOIN Orders o ON c2.CustomerID = o.CustomerID
    GROUP BY c2.Country
) total_orders ON c.Country = total_orders.Country
LEFT JOIN (
    SELECT 
        c3.Country,
        SUM(od.Quantity * p.Price) AS Revenue
    FROM Customers c3
    JOIN Orders o ON c3.CustomerID = o.CustomerID
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY c3.Country
) total_revenue ON c.Country = total_revenue.Country
GROUP BY c.Country
ORDER BY ExistingCustomers ASC, TotalRevenue DESC;

-- =====================================================
-- END OF ANALYSIS
-- =====================================================
-- UNION and Data Consolidation
-- Consolidated Customer Contact List
-- Consolidated customer and supplier contact information
SELECT 
    CustomerName AS ContactName,
    ContactName AS ContactPerson,
    Address,
    City,
    PostalCode,
    Country,
    'Customer' AS ContactType,
    NULL AS Phone
FROM Customers
UNION ALL
SELECT 
    SupplierName,
    ContactName,
    Address,
    City,
    PostalCode,
    Country,
    'Supplier',
    Phone
FROM Suppliers
ORDER BY Country, City, ContactName;

-- Product Availability Report
-- Product availability combining current and discontinued products
SELECT 
    ProductID,
    ProductName,
    CategoryID,
    SupplierID,
    Unit,
    Price,
    'Available' AS Status,
    'Current Product Line' AS Availability
FROM Products
UNION ALL
SELECT 
    ProductID + 1000 AS ProductID,  -- Simulating discontinued products
    ProductName + ' (Legacy)',
    CategoryID,
    SupplierID,
    Unit,
    Price * 0.8,  -- Discounted legacy pricing
    'Discontinued',
    'Legacy Product Line'
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products)
ORDER BY CategoryID, ProductName;

-- Unified Order Summary
-- Regular vs high-value orders classification
WITH OrderValues AS (
    SELECT 
        o.OrderID,
        o.CustomerID,
        o.EmployeeID,
        o.OrderDate,
        SUM(od.Quantity * p.Price) AS OrderTotal
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY o.OrderID, o.CustomerID, o.EmployeeID, o.OrderDate
),
AvgOrderValue AS (
    SELECT AVG(OrderTotal) AS AvgTotal FROM OrderValues
)
SELECT 
    OrderID,
    CustomerID,
    EmployeeID,
    OrderDate,
    OrderTotal,
    'High Value' AS OrderCategory
FROM OrderValues
WHERE OrderTotal > (SELECT AvgTotal FROM AvgOrderValue)
UNION ALL
SELECT 
    OrderID,
    CustomerID,
    EmployeeID,
    OrderDate,
    OrderTotal,
    'Regular'
FROM OrderValues
WHERE OrderTotal <= (SELECT AvgTotal FROM AvgOrderValue)
ORDER BY OrderTotal DESC;

-- EXISTS and Correlated Subqueries
-- Customers Who Ordered from Every Category
-- Customers with orders spanning all categories
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Country,
    (SELECT COUNT(DISTINCT cat.CategoryID) 
     FROM Categories cat) AS TotalCategories,
    (SELECT COUNT(DISTINCT p.CategoryID)
     FROM Orders o
     JOIN OrderDetails od ON o.OrderID = od.OrderID
     JOIN Products p ON od.ProductID = p.ProductID
     WHERE o.CustomerID = c.CustomerID) AS CategoriesOrdered
FROM Customers c
WHERE NOT EXISTS (
    SELECT cat.CategoryID
    FROM Categories cat
    WHERE NOT EXISTS (
        SELECT 1
        FROM Orders o
        JOIN OrderDetails od ON o.OrderID = od.OrderID
        JOIN Products p ON od.ProductID = p.ProductID
        WHERE o.CustomerID = c.CustomerID 
        AND p.CategoryID = cat.CategoryID
    )
)
ORDER BY c.CustomerName;

-- Products Never Ordered
-- Products with no order history
SELECT 
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    s.SupplierName,
    p.Price,
    p.Unit
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
JOIN Suppliers s ON p.SupplierID = s.SupplierID
WHERE NOT EXISTS (
    SELECT 1 
    FROM OrderDetails od 
    WHERE od.ProductID = p.ProductID
)
ORDER BY c.CategoryName, p.ProductName;

-- Customers with Above-Average Quantities
-- Customers ordering above-average quantities
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Country,
    AVG(od.Quantity) AS AvgQuantityOrdered,
    COUNT(DISTINCT o.OrderID) AS TotalOrders
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
WHERE EXISTS (
    SELECT 1
    FROM OrderDetails od2
    WHERE od2.OrderID IN (
        SELECT o2.OrderID 
        FROM Orders o2 
        WHERE o2.CustomerID = c.CustomerID
    )
    GROUP BY od2.OrderID
    HAVING AVG(od2.Quantity) > (
        SELECT AVG(Quantity) FROM OrderDetails
    )
)
GROUP BY c.CustomerID, c.CustomerName, c.Country
HAVING AVG(od.Quantity) > (SELECT AVG(Quantity) FROM OrderDetails)
ORDER BY AvgQuantityOrdered DESC;

-- Advanced JOIN Conditions
-- Seasonal Sales Analysis
-- Seasonal product performance with conditional joins
SELECT 
    c.CategoryName,
    CASE 
        WHEN MONTH(o.OrderDate) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH(o.OrderDate) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(o.OrderDate) IN (6, 7, 8) THEN 'Summer'
        WHEN MONTH(o.OrderDate) IN (9, 10, 11) THEN 'Autumn'
    END AS Season,
    COUNT(DISTINCT o.OrderID) AS OrderCount,
    SUM(od.Quantity) AS TotalQuantitySold,
    SUM(od.Quantity * p.Price) AS SeasonalRevenue
FROM Categories c
JOIN Products p ON c.CategoryID = p.CategoryID
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID 
    AND (
        (c.CategoryID = 1 AND MONTH(o.OrderDate) IN (12, 1, 2)) OR  -- Beverages in winter
        (c.CategoryID = 7 AND MONTH(o.OrderDate) IN (6, 7, 8)) OR   -- Produce in summer
        (c.CategoryID NOT IN (1, 7))  -- All other categories year-round
    )
GROUP BY c.CategoryID, c.CategoryName,
    CASE 
        WHEN MONTH(o.OrderDate) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH(o.OrderDate) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(o.OrderDate) IN (6, 7, 8) THEN 'Summer'
        WHEN MONTH(o.OrderDate) IN (9, 10, 11) THEN 'Autumn'
    END
ORDER BY c.CategoryName, Season;

-- Customer Loyalty Report
-- Customer loyalty based on repeat purchase patterns
SELECT 
    c.CustomerName,
    c.Country,
    MIN(o.OrderDate) AS FirstOrderDate,
    MAX(o.OrderDate) AS LastOrderDate,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    COUNT(DISTINCT repeat_orders.OrderID) AS RepeatOrders,
    CASE 
        WHEN COUNT(DISTINCT repeat_orders.OrderID) >= 5 THEN 'Highly Loyal'
        WHEN COUNT(DISTINCT repeat_orders.OrderID) >= 2 THEN 'Moderately Loyal'
        ELSE 'New Customer'
    END AS LoyaltySegment
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN Orders repeat_orders ON c.CustomerID = repeat_orders.CustomerID 
    AND repeat_orders.OrderDate > (
        SELECT MIN(o2.OrderDate) + 30  -- 30 days after first order
        FROM Orders o2 
        WHERE o2.CustomerID = c.CustomerID
    )
GROUP BY c.CustomerID, c.CustomerName, c.Country
HAVING COUNT(DISTINCT o.OrderID) > 1  -- Only customers with multiple orders
ORDER BY RepeatOrders DESC, TotalOrders DESC;

-- Supplier Performance Analysis
-- Supplier performance with delivery and product success metrics
SELECT 
    s.SupplierName,
    s.Country AS SupplierCountry,
    COUNT(DISTINCT p.ProductID) AS ProductsSupplied,
    COUNT(DISTINCT active_products.ProductID) AS ActiveProducts,
    AVG(p.Price) AS AvgProductPrice,
    SUM(od.Quantity) AS TotalQuantityDelivered,
    COUNT(DISTINCT o.OrderID) AS OrdersFulfilled,
    CASE 
        WHEN COUNT(DISTINCT active_products.ProductID) >= 3 THEN 'High Performance'
        WHEN COUNT(DISTINCT active_products.ProductID) >= 1 THEN 'Standard Performance'
        ELSE 'Underperforming'
    END AS PerformanceRating
FROM Suppliers s
JOIN Products p ON s.SupplierID = p.SupplierID
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
LEFT JOIN Orders o ON od.OrderID = o.OrderID 
    AND o.OrderDate >= '1996-01-01'
LEFT JOIN Products active_products ON s.SupplierID = active_products.SupplierID
    AND active_products.ProductID IN (
        SELECT DISTINCT od2.ProductID 
        FROM OrderDetails od2
        JOIN Orders o2 ON od2.OrderID = o2.OrderID
        WHERE o2.OrderDate >= '1996-01-01'
    )
GROUP BY s.SupplierID, s.SupplierName, s.Country
ORDER BY PerformanceRating DESC, TotalQuantityDelivered DESC;

-- Integrated Complex Analysis
-- Business Intelligence Report
-- Multi-dimensional business intelligence combining all techniques
WITH CustomerMetrics AS (
    SELECT 
        c.CustomerID,
        c.CustomerName,
        c.Country,
        COUNT(DISTINCT o.OrderID) AS TotalOrders,
        SUM(od.Quantity * p.Price) AS TotalRevenue,
        COUNT(DISTINCT p.CategoryID) AS CategoriesPurchased
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY c.CustomerID, c.CustomerName, c.Country
),
SupplierMetrics AS (
    SELECT 
        s.SupplierID,
        s.SupplierName,
        COUNT(DISTINCT p.ProductID) AS ProductCount,
        SUM(od.Quantity) AS TotalQuantitySupplied
    FROM Suppliers s
    JOIN Products p ON s.SupplierID = p.SupplierID
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY s.SupplierID, s.SupplierName
)
SELECT 
    'Customer Performance' AS ReportSection,
    CustomerName AS EntityName,
    Country AS Location,
    TotalRevenue AS MetricValue,
    'Revenue' AS MetricType
FROM CustomerMetrics
WHERE TotalRevenue > (SELECT AVG(TotalRevenue) FROM CustomerMetrics)
UNION ALL
SELECT 
    'Supplier Performance',
    SupplierName,
    'N/A',
    TotalQuantitySupplied,
    'Quantity Supplied'
FROM SupplierMetrics
WHERE TotalQuantitySupplied > (SELECT AVG(TotalQuantitySupplied) FROM SupplierMetrics)
ORDER BY ReportSection, MetricValue DESC;

-- Market Analysis Dashboard
-- Product performance across customer segments
SELECT 
    p.ProductName,
    c.CategoryName,
    CASE 
        WHEN cust.Country IN ('USA', 'Canada') THEN 'North America'
        WHEN cust.Country IN ('Germany', 'France', 'UK') THEN 'Europe'
        ELSE 'Other Markets'
    END AS MarketSegment,
    COUNT(DISTINCT o.OrderID) AS OrderFrequency,
    SUM(od.Quantity) AS TotalQuantitySold,
    SUM(od.Quantity * p.Price) AS SegmentRevenue,
    AVG(od.Quantity) AS AvgOrderQuantity,
    RANK() OVER (
        PARTITION BY c.CategoryName, 
        CASE 
            WHEN cust.Country IN ('USA', 'Canada') THEN 'North America'
            WHEN cust.Country IN ('Germany', 'France', 'UK') THEN 'Europe'
            ELSE 'Other Markets'
        END 
        ORDER BY SUM(od.Quantity * p.Price) DESC
    ) AS RevenueRank
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID
JOIN Customers cust ON o.CustomerID = cust.CustomerID
WHERE EXISTS (
    SELECT 1 FROM OrderDetails od2 
    WHERE od2.ProductID = p.ProductID
    GROUP BY od2.ProductID
    HAVING SUM(od2.Quantity) > 50  -- Products with significant volume
)
GROUP BY p.ProductID, p.ProductName, c.CategoryName,
    CASE 
        WHEN cust.Country IN ('USA', 'Canada') THEN 'North America'
        WHEN cust.Country IN ('Germany', 'France', 'UK') THEN 'Europe'
        ELSE 'Other Markets'
    END
HAVING SUM(od.Quantity * p.Price) > 1000  -- Minimum revenue threshold
ORDER BY MarketSegment, c.CategoryName, RevenueRank;

-- Strategic Growth Opportunities Analysis
-- Growth opportunities using advanced data combination
WITH CategoryGrowth AS (
    SELECT 
        c.CategoryID,
        c.CategoryName,
        COUNT(DISTINCT p.ProductID) AS ProductCount,
        AVG(p.Price) AS AvgPrice,
        SUM(od.Quantity) AS TotalVolume
    FROM Categories c
    JOIN Products p ON c.CategoryID = p.CategoryID
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY c.CategoryID, c.CategoryName
),
UnderservedMarkets AS (
    SELECT 
        cust.Country,
        COUNT(DISTINCT cust.CustomerID) AS CustomerCount,
        COUNT(DISTINCT o.OrderID) AS OrderCount,
        SUM(od.Quantity * p.Price) AS MarketRevenue
    FROM Customers cust
    LEFT JOIN Orders o ON cust.CustomerID = o.CustomerID
    LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
    LEFT JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY cust.Country
    HAVING COUNT(DISTINCT o.OrderID) < 10  -- Underserved markets
),
ProductGaps AS (
    SELECT 
        c.CategoryName,
        COUNT(p.ProductID) AS CurrentProducts,
        8 - COUNT(p.ProductID) AS PotentialNewProducts  -- Assuming 8 products per category optimal
    FROM Categories c
    LEFT JOIN Products p ON c.CategoryID = p.CategoryID
    GROUP BY c.CategoryID, c.CategoryName
    HAVING COUNT(p.ProductID) < 8
)
SELECT 
    'Category Expansion' AS OpportunityType,
    CategoryName AS OpportunityArea,
    CAST(PotentialNewProducts AS CHAR) + ' new products' AS GrowthPotential,
    'High' AS Priority
FROM ProductGaps
WHERE PotentialNewProducts >= 3
UNION ALL
SELECT 
    'Market Expansion',
    Country,
    CAST(CustomerCount AS CHAR) + ' customers, low penetration',
    CASE 
        WHEN CustomerCount >= 5 THEN 'Medium'
        ELSE 'High'
    END
FROM UnderservedMarkets
UNION ALL
SELECT 
    'Category Investment',
    CategoryName,
    'High volume, ' + CAST(ProductCount AS CHAR) + ' products',
    'Medium'
FROM CategoryGrowth
WHERE TotalVolume > (SELECT AVG(TotalVolume) FROM CategoryGrowth) * 1.5
ORDER BY Priority DESC, OpportunityType;
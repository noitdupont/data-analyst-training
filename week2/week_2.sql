-- My first SQL Query

-- Keywords: SELECT, FROM, WHERE, LIKE, ORDER BY, LIMIT
-- SELECT: Used to specify the columns that you want to retrieve from a database.
-- FROM: Indicates the table from which to retrieve the data.
-- WHERE: Used to filter records based on specified conditions.
-- LIKE: A comparison operator used in the WHERE clause to search for a specified pattern in a column.
-- ORDER BY: Used to sort the result set in either ascending or descending order.
-- LIMIT: Restricts the number of rows returned by the query.

-- Finn's Definition of SQL: SQL is the conversion of Natural Language to database language.
-- Data Analysis is the translation of questions and business requirements to SQL.

-- I want to see all customers
SELECT * FROM Customers;
    
-- I want to see the customer name and their country
SELECT CustomerName, Country
FROM Customers;
    
-- I want to find all the customers in France
-- I know I have customers in France, but what's their city?
-- Without comment
SELECT CustomerName, City
FROM Customers
WHERE Country = 'France';
    
-- With comment
SELECT CustomerName, City -- I want these columns
FROM Customers -- from this table
WHERE Country = 'France'; -- in this country
    
-- I want to find the most expensive products
SELECT ProductName, Price
FROM Products
WHERE Price > 50;
    
-- Pattern Matching: LIKE
SELECT CustomerName, City, Country
FROM Customers
WHERE CustomerName LIKE 'B%';

-- I want to sort my customers alphabetically (Ascending Order)
SELECT CustomerName, Country
FROM Customers
ORDER BY CustomerName ASC;

-- I want to sort my customers alphabetically (Descending Order)
SELECT CustomerName, Country
FROM Customers
ORDER BY CustomerName DESC;

-- I want to find the top 5 most expensive products
SELECT ProductName, Price
FROM Products
ORDER BY Price DESC
LIMIT 5;
    
-- I want to see the recent orders first
-- Also, limit it to 10 most recent orders
SELECT OrderID, OrderDate, CustomerID
FROM Orders
ORDER BY OrderDate DESC
LIMIT 10;

-- As a business owner, I want to see the top 3 French customers by name
SELECT CustomerName, ContactName, City
FROM Customers
WHERE Country = 'France'
ORDER BY CustomerName ASC
LIMIT 3;

-- As a business owner, what are our 5 cheapest products
-- Initial Business Requirement: As a business owner, what are our 5 cheapest products under £20
SELECT ProductName, Price, Unit
FROM Products
WHERE Price < 20
ORDER BY Price ASC
LIMIT 5;

-- Second Business Requirement: As a business owner, what are our 10 cheapest products under £20
SELECT ProductName, Price, Unit
FROM Products
WHERE Price < 20
ORDER BY Price ASC
LIMIT 10;
## SQL Cheatsheet

The cheatsheet covers the SQL operations you'll need for database work. The table structure allows you to quickly reference the syntax, see practical examples, and understand the purpose of each operation.

The progression moves from basic data retrieval through complex operations like window functions and performance optimisation. Each section builds upon previous concepts. Understanding basic `SELECT` statements prepares you for joins, which then enables subqueries and advanced analysis.

### Key Mental Models to Remember

+ SQL operates on sets of data. Every operation transforms one set into another set.
+ Performance depends on how the database engine executes your queries. Indexes speed up `WHERE` clauses and `JOIN` operations, but slow down `INSERT/UPDATE` operations.
+ Query complexity affects maintenance costs. Simple, readable queries prevent debugging headaches and make code changes safer for your team.

Focus on mastering the basic operations first. `SELECT`, `WHERE`, `JOIN`, and `GROUP BY` handle 80% of typical database work. The advanced features become valuable once you're working with larger datasets or building complex applications.

### Basic Operations

| Operation | Syntax | Example | Notes |
|-----------|--------|---------|-------|
| **SELECT** | `SELECT column1, column2 FROM table` | `SELECT name, age FROM users` | Retrieves data from tables |
| **SELECT ALL** | `SELECT * FROM table` | `SELECT * FROM products` | Returns all columns |
| **DISTINCT** | `SELECT DISTINCT column FROM table` | `SELECT DISTINCT country FROM users` | Removes duplicate values |
| **WHERE** | `SELECT * FROM table WHERE condition` | `SELECT * FROM users WHERE age > 25` | Filters rows based on conditions |
| **ORDER BY** | `SELECT * FROM table ORDER BY column ASC/DESC` | `SELECT * FROM users ORDER BY age DESC` | Sorts results |
| **LIMIT** | `SELECT * FROM table LIMIT number` | `SELECT * FROM users LIMIT 10` | Restricts number of results |

### Data Modification

| Operation | Syntax | Example | Notes |
|-----------|--------|---------|-------|
| **INSERT** | `INSERT INTO table (col1, col2) VALUES (val1, val2)` | `INSERT INTO users (name, age) VALUES ('John', 30)` | Adds new records |
| **INSERT MULTIPLE** | `INSERT INTO table VALUES (val1, val2), (val3, val4)` | `INSERT INTO users VALUES ('Alice', 25), ('Bob', 35)` | Adds multiple records |
| **UPDATE** | `UPDATE table SET col1 = val1 WHERE condition` | `UPDATE users SET age = 31 WHERE name = 'John'` | Modifies existing records |
| **DELETE** | `DELETE FROM table WHERE condition` | `DELETE FROM users WHERE age < 18` | Removes records |
| **TRUNCATE** | `TRUNCATE TABLE table` | `TRUNCATE TABLE temp_data` | Removes all records quickly |

### Table Structure

| Operation | Syntax | Example | Notes |
|-----------|--------|---------|-------|
| **CREATE TABLE** | `CREATE TABLE table (col1 TYPE, col2 TYPE)` | `CREATE TABLE users (id INT, name VARCHAR(50))` | Creates new table |
| **DROP TABLE** | `DROP TABLE table` | `DROP TABLE old_users` | Deletes entire table |
| **ALTER TABLE ADD** | `ALTER TABLE table ADD COLUMN col TYPE` | `ALTER TABLE users ADD COLUMN email VARCHAR(100)` | Adds new column |
| **ALTER TABLE DROP** | `ALTER TABLE table DROP COLUMN col` | `ALTER TABLE users DROP COLUMN temp_field` | Removes column |
| **ALTER TABLE MODIFY** | `ALTER TABLE table MODIFY col TYPE` | `ALTER TABLE users MODIFY age BIGINT` | Changes column type |

### Data Types

| Category | Types | Examples | Usage |
|----------|-------|----------|-------|
| **Numeric** | INT, BIGINT, DECIMAL, FLOAT | `age INT`, `price DECIMAL(10,2)` | Whole numbers, decimals |
| **Text** | VARCHAR, CHAR, TEXT | `name VARCHAR(50)`, `description TEXT` | String data |
| **Date/Time** | DATE, TIME, DATETIME, TIMESTAMP | `created_at DATETIME`, `birth_date DATE` | Temporal data |
| **Boolean** | BOOLEAN, TINYINT(1) | `is_active BOOLEAN` | True/false values |
| **Binary** | BLOB, BINARY | `image BLOB` | File storage |

### Constraints

| Constraint | Syntax | Example | Purpose |
|------------|--------|---------|---------|
| **PRIMARY KEY** | `col TYPE PRIMARY KEY` | `id INT PRIMARY KEY` | Unique identifier |
| **FOREIGN KEY** | `FOREIGN KEY (col) REFERENCES table(col)` | `FOREIGN KEY (user_id) REFERENCES users(id)` | Links tables |
| **UNIQUE** | `col TYPE UNIQUE` | `email VARCHAR(100) UNIQUE` | Prevents duplicates |
| **NOT NULL** | `col TYPE NOT NULL` | `name VARCHAR(50) NOT NULL` | Requires value |
| **CHECK** | `CHECK (condition)` | `CHECK (age >= 0)` | Validates data |
| **DEFAULT** | `col TYPE DEFAULT value` | `status VARCHAR(20) DEFAULT 'active'` | Sets default value |

### Joins

| Join Type | Syntax | Example | Result |
|-----------|--------|---------|---------|
| **INNER JOIN** | `SELECT * FROM t1 INNER JOIN t2 ON t1.id = t2.id` | `SELECT * FROM users u INNER JOIN orders o ON u.id = o.user_id` | Only matching records |
| **LEFT JOIN** | `SELECT * FROM t1 LEFT JOIN t2 ON t1.id = t2.id` | `SELECT * FROM users u LEFT JOIN orders o ON u.id = o.user_id` | All left records + matches |
| **RIGHT JOIN** | `SELECT * FROM t1 RIGHT JOIN t2 ON t1.id = t2.id` | `SELECT * FROM users u RIGHT JOIN orders o ON u.id = o.user_id` | All right records + matches |
| **FULL JOIN** | `SELECT * FROM t1 FULL JOIN t2 ON t1.id = t2.id` | `SELECT * FROM users u FULL JOIN orders o ON u.id = o.user_id` | All records from both |
| **CROSS JOIN** | `SELECT * FROM t1 CROSS JOIN t2` | `SELECT * FROM colours CROSS JOIN sizes` | Cartesian product |

### Aggregate Functions

| Function | Syntax | Example | Purpose |
|----------|--------|---------|---------|
| **COUNT** | `COUNT(column)` or `COUNT(*)` | `SELECT COUNT(*) FROM users` | Counts rows |
| **SUM** | `SUM(column)` | `SELECT SUM(amount) FROM orders` | Adds numeric values |
| **AVG** | `AVG(column)` | `SELECT AVG(age) FROM users` | Calculates average |
| **MIN** | `MIN(column)` | `SELECT MIN(price) FROM products` | Finds minimum value |
| **MAX** | `MAX(column)` | `SELECT MAX(salary) FROM employees` | Finds maximum value |
| **GROUP_CONCAT** | `GROUP_CONCAT(column)` | `SELECT GROUP_CONCAT(name) FROM users` | Concatenates values |

### Grouping and Filtering

| Operation | Syntax | Example | Usage |
|-----------|--------|---------|-------|
| **GROUP BY** | `SELECT col, COUNT(*) FROM table GROUP BY col` | `SELECT country, COUNT(*) FROM users GROUP BY country` | Groups rows |
| **HAVING** | `SELECT col FROM table GROUP BY col HAVING condition` | `SELECT country FROM users GROUP BY country HAVING COUNT(*) > 5` | Filters groups |
| **ROLLUP** | `SELECT col1, col2, COUNT(*) FROM table GROUP BY ROLLUP(col1, col2)` | `SELECT region, country, COUNT(*) FROM sales GROUP BY ROLLUP(region, country)` | Creates subtotals |

### String Functions

| Function | Syntax | Example | Purpose |
|----------|--------|---------|---------|
| **CONCAT** | `CONCAT(str1, str2)` | `SELECT CONCAT(first_name, ' ', last_name) FROM users` | Joins strings |
| **LENGTH** | `LENGTH(string)` | `SELECT LENGTH(name) FROM users` | String length |
| **UPPER** | `UPPER(string)` | `SELECT UPPER(name) FROM users` | Converts to uppercase |
| **LOWER** | `LOWER(string)` | `SELECT LOWER(email) FROM users` | Converts to lowercase |
| **SUBSTRING** | `SUBSTRING(string, start, length)` | `SELECT SUBSTRING(name, 1, 3) FROM users` | Extracts portion |
| **REPLACE** | `REPLACE(string, old, new)` | `SELECT REPLACE(phone, '-', '') FROM users` | Replaces text |
| **TRIM** | `TRIM(string)` | `SELECT TRIM(name) FROM users` | Removes whitespace |

### Date Functions

| Function | Syntax | Example | Purpose |
|----------|--------|---------|---------|
| **NOW** | `NOW()` | `SELECT NOW()` | Current datetime |
| **CURDATE** | `CURDATE()` | `SELECT CURDATE()` | Current date |
| **CURTIME** | `CURTIME()` | `SELECT CURTIME()` | Current time |
| **DATE** | `DATE(datetime)` | `SELECT DATE(created_at) FROM orders` | Extracts date part |
| **YEAR** | `YEAR(date)` | `SELECT YEAR(birth_date) FROM users` | Extracts year |
| **MONTH** | `MONTH(date)` | `SELECT MONTH(order_date) FROM orders` | Extracts month |
| **DAY** | `DAY(date)` | `SELECT DAY(created_at) FROM posts` | Extracts day |
| **DATEDIFF** | `DATEDIFF(date1, date2)` | `SELECT DATEDIFF(end_date, start_date) FROM projects` | Days between dates |
| **DATE_ADD** | `DATE_ADD(date, INTERVAL value unit)` | `SELECT DATE_ADD(NOW(), INTERVAL 7 DAY)` | Adds time interval |

### Conditional Logic

| Function | Syntax | Example | Purpose |
|----------|--------|---------|---------|
| **CASE** | `CASE WHEN condition THEN result ELSE result END` | `SELECT CASE WHEN age < 18 THEN 'Minor' ELSE 'Adult' END FROM users` | Conditional values |
| **IF** | `IF(condition, true_value, false_value)` | `SELECT IF(age >= 18, 'Adult', 'Minor') FROM users` | Simple condition |
| **IFNULL** | `IFNULL(expression, value)` | `SELECT IFNULL(middle_name, 'N/A') FROM users` | Handles null values |
| **COALESCE** | `COALESCE(val1, val2, val3)` | `SELECT COALESCE(phone, mobile, 'No contact') FROM users` | First non-null value |

### Subqueries

| Type | Syntax | Example | Usage |
|------|--------|---------|-------|
| **Scalar** | `SELECT * FROM table WHERE col = (SELECT ...)` | `SELECT * FROM products WHERE price = (SELECT MAX(price) FROM products)` | Single value |
| **Multiple Row** | `SELECT * FROM table WHERE col IN (SELECT ...)` | `SELECT * FROM users WHERE id IN (SELECT user_id FROM orders)` | Multiple values |
| **Correlated** | `SELECT * FROM t1 WHERE EXISTS (SELECT * FROM t2 WHERE t2.id = t1.id)` | `SELECT * FROM customers WHERE EXISTS (SELECT * FROM orders WHERE orders.customer_id = customers.id)` | References outer query |

### Window Functions

| Function | Syntax | Example | Purpose |
|----------|--------|---------|---------|
| **ROW_NUMBER** | `ROW_NUMBER() OVER (ORDER BY col)` | `SELECT name, ROW_NUMBER() OVER (ORDER BY salary DESC) FROM employees` | Sequential numbering |
| **RANK** | `RANK() OVER (ORDER BY col)` | `SELECT name, RANK() OVER (ORDER BY score DESC) FROM students` | Ranking with ties |
| **DENSE_RANK** | `DENSE_RANK() OVER (ORDER BY col)` | `SELECT name, DENSE_RANK() OVER (ORDER BY score DESC) FROM students` | Dense ranking |
| **LAG** | `LAG(col, offset) OVER (ORDER BY col)` | `SELECT date, sales, LAG(sales, 1) OVER (ORDER BY date) FROM monthly_sales` | Previous row value |
| **LEAD** | `LEAD(col, offset) OVER (ORDER BY col)` | `SELECT date, sales, LEAD(sales, 1) OVER (ORDER BY date) FROM monthly_sales` | Next row value |

### Advanced Operations

| Operation | Syntax | Example | Purpose |
|-----------|--------|---------|---------|
| **UNION** | `SELECT col FROM table1 UNION SELECT col FROM table2` | `SELECT name FROM customers UNION SELECT name FROM suppliers` | Combines results |
| **UNION ALL** | `SELECT col FROM table1 UNION ALL SELECT col FROM table2` | `SELECT product FROM inventory UNION ALL SELECT product FROM orders` | Includes duplicates |
| **INTERSECT** | `SELECT col FROM table1 INTERSECT SELECT col FROM table2` | `SELECT email FROM users INTERSECT SELECT email FROM subscribers` | Common records |
| **EXCEPT** | `SELECT col FROM table1 EXCEPT SELECT col FROM table2` | `SELECT email FROM users EXCEPT SELECT email FROM unsubscribed` | Records in first only |

### Comparison Operators

| Operator | Meaning | Example | Usage |
|----------|---------|---------|-------|
| **=** | Equal | `WHERE age = 25` | Exact match |
| **!=** or **<>** | Not equal | `WHERE status != 'inactive'` | Exclusion |
| **>** | Greater than | `WHERE price > 100` | Numeric/date comparison |
| **<** | Less than | `WHERE quantity < 10` | Numeric/date comparison |
| **>=** | Greater or equal | `WHERE age >= 18` | Inclusive comparison |
| **<=** | Less or equal | `WHERE score <= 100` | Inclusive comparison |
| **BETWEEN** | Range | `WHERE age BETWEEN 18 AND 65` | Inclusive range |
| **IN** | Match list | `WHERE country IN ('UK', 'US', 'CA')` | Multiple values |
| **LIKE** | Pattern match | `WHERE name LIKE 'John%'` | String patterns |
| **IS NULL** | Null check | `WHERE email IS NULL` | Missing values |

### Pattern Matching

| Wildcard | Meaning | Example | Matches |
|----------|---------|---------|---------|
| **%** | Any characters | `LIKE 'John%'` | John, Johnson, Johnny |
| **_** | Single character | `LIKE 'J_hn'` | John, Jahn, Juhn |
| **[abc]** | Character set | `LIKE '[JM]ohn'` | John, Mohn |
| **[a-z]** | Character range | `LIKE '[A-M]%'` | Names starting A-M |
| **[^abc]** | Not in set | `LIKE '[^JM]ohn'` | Cohn, Rohn, etc |

### Indexes

| Operation | Syntax | Example | Purpose |
|-----------|--------|---------|---------|
| **CREATE INDEX** | `CREATE INDEX idx_name ON table(column)` | `CREATE INDEX idx_email ON users(email)` | Speeds up queries |
| **UNIQUE INDEX** | `CREATE UNIQUE INDEX idx_name ON table(column)` | `CREATE UNIQUE INDEX idx_username ON users(username)` | Unique + fast access |
| **COMPOSITE INDEX** | `CREATE INDEX idx_name ON table(col1, col2)` | `CREATE INDEX idx_name_email ON users(last_name, email)` | Multiple column index |
| **DROP INDEX** | `DROP INDEX idx_name` | `DROP INDEX idx_email` | Removes index |

### Transactions

| Operation | Syntax | Example | Purpose |
|-----------|--------|---------|---------|
| **BEGIN** | `BEGIN` or `START TRANSACTION` | `BEGIN; UPDATE...; COMMIT;` | Starts transaction |
| **COMMIT** | `COMMIT` | `INSERT...; COMMIT;` | Saves changes |
| **ROLLBACK** | `ROLLBACK` | `UPDATE...; ROLLBACK;` | Undoes changes |
| **SAVEPOINT** | `SAVEPOINT name` | `SAVEPOINT sp1; ...ROLLBACK TO sp1;` | Partial rollback |

### Views

| Operation | Syntax | Example | Purpose |
|-----------|--------|---------|---------|
| **CREATE VIEW** | `CREATE VIEW view_name AS SELECT...` | `CREATE VIEW active_users AS SELECT * FROM users WHERE status = 'active'` | Virtual table |
| **DROP VIEW** | `DROP VIEW view_name` | `DROP VIEW active_users` | Removes view |
| **UPDATE VIEW** | `CREATE OR REPLACE VIEW view_name AS SELECT...` | `CREATE OR REPLACE VIEW user_summary AS SELECT id, name FROM users` | Modifies view |

### Performance Tips

| Technique | Example | Benefit |
|-----------|---------|---------|
| **Use indexes on WHERE columns** | `CREATE INDEX idx_status ON users(status)` | Faster filtering |
| **Limit results** | `SELECT * FROM large_table LIMIT 1000` | Reduces memory usage |
| **Use EXISTS instead of IN** | `WHERE EXISTS (SELECT 1 FROM...)` | Better performance |
| **Avoid SELECT *** | `SELECT id, name FROM users` | Reduces data transfer |
| **Use INNER JOIN over WHERE** | `FROM a INNER JOIN b ON a.id = b.id` | Clearer intent |
## Power BI Measures

Power BI Measures are DAX (Data Analysis Expressions) formulas that perform dynamic, real-time calculations on aggregated data, responding to report filters and slicers.

### Revenue

Revenue calculates the total sales amount by multiplying each order line's quantity by its product price and summing those values. The measure updates automatically when you filter or slice the report so numbers always reflect the current view.

```sh
Revenue = SUMX ( 'northwind orderdetails', 'northwind orderdetails'[Quantity] * RELATED ( 'northwind products'[Price] ) )
```

### Total Orders

Total Orders counts the number of unique orders placed, giving the total order transactions in the selected context. It changes with filters (dates, customers, products) to show the correct order count for that view.

```sh
Total Orders = DISTINCTCOUNT ( 'northwind orders'[OrderID] )
```

### Average Order Value

Avg Order Value divides total revenue by total orders to show how much revenue is earned per order on average. It helps compare order value across customers, products, or time periods and adapts to filters in the report.

```sh
Avg Order Value = DIVIDE ( [Revenue], [Total Orders] )
```

### PAGE 1 – Sales Overview

+ Clustered column chart: Revenue by Category (axis: Categories[CategoryName]; values: [Revenue])
+ Line chart: Revenue by Month (axis: Orders[OrderDate] hierarchy → Month; values: [Revenue])

### PAGE 2 – Top Customers

+ Matrix visual: CustomerName | Revenue | Total Orders | Avg Order Value
+ Top-N filter on Customers → Top 10 by [Revenue]
+ Map visual (filled map): Revenue by Country (Customers[Country])

### PAGE 3 – Product Deep Dive

+ Table visual: ProductName, CategoryName, Revenue, Quantity Sold = SUM ( OrderDetails[Quantity] )
+ Scatter chart: X-axis = Unit Price, Y-axis = Quantity Sold, Details = ProductName
+ Slicer: Category

### PAGE 4 – Employees & Shippers

+ Stacked bar chart: Revenue by Employee (Employees[LastName])
+ Stacked bar chart: Revenue by Shipper (Shippers[ShipperName])
+ Card: % of revenue shipped by “Speedy Express”
+ = CALCULATE ( [Revenue], Shippers[ShipperName] = "Speedy Express" ) / [Revenue]
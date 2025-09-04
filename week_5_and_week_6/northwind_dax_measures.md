### DAX Measures

1. In the Fields Pane (Right Side)

+ **Look for the table where you want to add the measure (usually your fact table like "Orders" or "OrderDetails")**
+ Right-click on the table name
+ Select "New measure"

2. In the Formula Bar

+ When you select "New measure", a formula bar appears at the top. Replace the default text with one of the DAX measures. For example:

```dax
Total Revenue = 
SUMX(OrderDetails, OrderDetails[Quantity] * RELATED(Products[Price]))
```

3. Alternative Method - Modeling Tab

+ **Click the "Modeling" tab in the ribbon**
+ Click "New measure" button
+ Paste the DAX code in the formula bar

4. For Multiple Measures

+ Repeat this process for each measure below:

```dax
// Revenue Measures
Total Revenue = 
SUMX(OrderDetails, OrderDetails[Quantity] * RELATED(Products[Price]))

Monthly Revenue = 
CALCULATE([Total Revenue], DATESMTD(Orders[OrderDate]))

// Customer Metrics
Total Customers = DISTINCTCOUNT(Orders[CustomerID])

Avg Order Value = 
DIVIDE([Total Revenue], DISTINCTCOUNT(Orders[OrderID]))

// Product Performance
Top Product by Revenue = 
CALCULATE(
    SELECTEDVALUE(Products[ProductName]),
    TOPN(1, Products, [Total Revenue])
)

// Growth Calculations
Revenue Growth = 
VAR CurrentRevenue = [Total Revenue]
VAR PreviousRevenue = 
    CALCULATE(
        [Total Revenue],
        DATEADD(Orders[OrderDate], -1, MONTH)
    )
RETURN
DIVIDE(CurrentRevenue - PreviousRevenue, PreviousRevenue)
```

5. Important Notes

+ Each measure becomes a new field in your table
+ Measures appear with a calculator icon (fx) in the Fields pane
+ You can drag these measures into visualizations
+ Press Enter or click the checkmark to confirm each measure

6. Where You'll See Them

After creating measures, they appear in the Fields pane under the table you selected, and you can drag them into charts, cards, or tables for your dashboard.
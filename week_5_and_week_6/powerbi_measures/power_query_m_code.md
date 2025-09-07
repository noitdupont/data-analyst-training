```m
let
    Source = MySQL.Database("localhost", "Northwind"),
    
    // Import all tables
    Customers = Source{[Schema="northwind",Item="Customers"]}[Data],
    Orders = Source{[Schema="northwind",Item="Orders"]}[Data],
    OrderDetails = Source{[Schema="northwind",Item="OrderDetails"]}[Data],
    Products = Source{[Schema="northwind",Item="Products"]}[Data],
    Categories = Source{[Schema="northwind",Item="Categories"]}[Data],
    Suppliers = Source{[Schema="northwind",Item="Suppliers"]}[Data],
    Employees = Source{[Schema="northwind",Item="Employees"]}[Data],
    Shippers = Source{[Schema="northwind",Item="Shippers"]}[Data]
in
    Source
```
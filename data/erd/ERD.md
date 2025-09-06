## Database Structure Explanation

### Core Entities

+ **Customers**: store basic customer information including names, contact details, and addresses. Each customer gets a unique ID.
+ **Employees**: contain staff records with personal details like names, birth dates, and notes. Photos can be stored as well.
+ **Suppliers**: hold vendor information including company names, contact details, and addresses.
+ **Categories**: define product groupings with names and descriptions.
+ **Products**: represent items for sale, linked to both suppliers and categories. Each product has a name, unit type, and price.
+ **Shippers**: are delivery companies with contact information.

### Transaction Flow

+ **Orders**: connect customers to employees who process them. Each order includes the date and which shipping company handles delivery.
+ **OrderDetails**: break down what's in each order. This shows which products were ordered and how many of each item.

### Key Relationships

- Customers place multiple orders
- Employees process multiple orders  
- Orders contain multiple products through OrderDetails
- Products belong to one category and one supplier
- Shippers handle multiple orders

### Business Logic

The structure supports a typical sales operation where:

+ Customers place orders through employees
+ Orders get broken into specific product quantities  
+ Inventory tracking becomes possible through supplier relationships, whilst shipping coordination happens through shipper assignments

The design separates customer management from inventory management, allowing independent scaling of both areas. Product categorisation enables reporting and analysis by business segment. Supplier relationships help track stock levels and ensure timely deliveries.
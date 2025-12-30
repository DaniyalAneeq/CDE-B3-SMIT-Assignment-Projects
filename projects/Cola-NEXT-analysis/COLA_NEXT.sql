
-- Q1. List top 5 customers by total order amount.
-- Retrieve the top 5 customers who have spent the most across all sales orders. 
-- Show CustomerID, CustomerName, and TotalSpent.

SELECT TOP(5) 
       i.CustomerID,
       n.Name,
       a.TotalAmount
FROM 
[dbo].[SalesOrder] i
JOIN [dbo].[Customer] n
ON n.CustomerID = i.CustomerID
JOIN [dbo].[SalesOrderDetail] a
ON a.OrderID = I.OrderID
ORDER BY 
a.TotalAmount DESC;

-- Q2. Find the number of products supplied by each supplier.
-- Display SupplierID, SupplierName, and ProductCount. 
-- Only include suppliers that have more than 10 products.

SELECT 
    n.SupplierID,
    n.Name SupplierName,
    q.Quantity ProductCount
FROM [dbo].[Supplier] n
JOIN [dbo].[PurchaseOrder] o
ON o.SupplierID = n.SupplierID
JOIN [dbo].[PurchaseOrderDetail] q
ON  o.OrderID = q.OrderID
WHERE q.OrderID > 10;


-- Q3. Identify products that have been ordered but never returned.
-- Show ProductID, ProductName, and total order quantity.

SELECT 
    p.ProductID,
    p.Name AS ProductName,
    SUM(sod.Quantity) AS TotalOrderedQuantity
FROM product p
INNER JOIN SalesOrderDetail sod
    ON p.ProductID = sod.ProductID
LEFT JOIN ReturnDetail rd
    ON p.ProductID = rd.ProductID
WHERE rd.ProductID IS NULL
GROUP BY 
    p.ProductID,
    p.Name
ORDER BY 
    TotalOrderedQuantity DESC;

-- Q4. For each category, find the most expensive product.
-- Display CategoryID, CategoryName, ProductName, and Price.
-- Use a subquery to get the max price per category

SELECT 
    c.CategoryID,
    c.Name CategoryName,
    p.Name ProductName,
    p.Price max_price
FROM [dbo].[Category] c
JOIN [dbo].[Product] p
    ON c.CategoryID = p.CategoryID
WHERE p.Price = (
    SELECT MAX(p2.Price)
    FROM [dbo].[Product] p2
    WHERE p2.CategoryID = c.CategoryID
)
ORDER BY 
    c.CategoryID;



-- Q5. List all sales orders with customer name, product name, category, and supplier.
-- For each sales order, display:
-- OrderID, CustomerName, ProductName, CategoryName, SupplierName, and Quantity.

SELECT 
    s.OrderID,
    c.Name CustomerName,
    p.Name ProductName,
    ct.Name CategoryName,
    pd.Quantity,
    sup.Name SupplierName
FROM [dbo].[Customer] c
JOIN [dbo].[SalesOrder] s
ON s.CustomerID = c.CustomerID
JOIN [dbo].[SalesOrderDetail] sd
ON sd.OrderID = s.OrderID
JOIN [dbo].[Product] p
ON sd.ProductID = p.ProductID
JOIN [dbo].[Category] ct
ON p.CategoryID = ct.CategoryID
JOIN [dbo].[PurchaseOrderDetail] pd
ON pd.ProductID = p.ProductID
JOIN [dbo].[PurchaseOrder] po
ON po.OrderID = pd.OrderID
JOIN [dbo].[Supplier] sup
ON  po.SupplierID = sup.SupplierID;


-- Q6. Find all shipments with details of warehouse, manager, and products shipped.
-- Display:
-- ShipmentID, WarehouseName, ManagerName, ProductName, QuantityShipped, and TrackingNumber.


SELECT 
    s.ShipmentID,
    w.WarehouseID AS WarehouseID,
    e.Name AS ManagerName,
    p.Name AS ProductName,
    sd.Quantity AS QuantityShipped,
    s.TrackingNumber
FROM shipment s
INNER JOIN warehouse w 
    ON s.WarehouseID = w.WarehouseID
INNER JOIN employee e 
    ON w.ManagerID = e.EmployeeID
INNER JOIN shipmentdetail sd 
    ON s.ShipmentID = sd.ShipmentID
INNER JOIN product p 
    ON sd.ProductID = p.ProductID
ORDER BY 
    s.ShipmentID,
    p.Name;

-- Q7. Find the top 3 highest-value orders per customer using RANK(). 
-- Display CustomerID, CustomerName, OrderID, and TotalAmount.

WITH RankedOrders AS (
    SELECT 
        c.CustomerID,
        c.Name AS CustomerName,
        so.OrderID,
        so.TotalAmount,
        RANK() OVER (
            PARTITION BY c.CustomerID
            ORDER BY so.TotalAmount DESC
        ) AS OrderRank
    FROM SalesOrder so
    INNER JOIN customer c
        ON so.CustomerID = c.CustomerID
)
SELECT 
    CustomerID,
    CustomerName,
    OrderID,
    TotalAmount
FROM RankedOrders
WHERE OrderRank <= 3
ORDER BY 
    CustomerID,
    TotalAmount DESC;

-- Q8. For each product, show its sales history with the previous and next sales quantities (based on order date). 
-- Display ProductID, ProductName, OrderID, OrderDate, Quantity, PrevQuantity, and NextQuantity.

SELECT 
    p.ProductID,
    p.Name AS ProductName,
    so.OrderID,
    so.OrderDate,
    sod.Quantity,
    
    LAG(sod.Quantity) OVER (
        PARTITION BY p.ProductID
        ORDER BY so.OrderDate, so.OrderID
    ) AS PrevQuantity,
    
    LEAD(sod.Quantity) OVER (
        PARTITION BY p.ProductID
        ORDER BY so.OrderDate, so.OrderID
    ) AS NextQuantity

FROM SalesOrderDetail sod
INNER JOIN SalesOrder so 
    ON sod.OrderID = so.OrderID
INNER JOIN product p 
    ON sod.ProductID = p.ProductID
ORDER BY 
    p.ProductID,
    so.OrderDate,
    so.OrderID;

-- Q9. Create a view named vw_CustomerOrderSummary that shows for each customer:
-- CustomerID, CustomerName, TotalOrders, TotalAmountSpent, and LastOrderDate.

CREATE VIEW vw_CustomerOrderSummary
AS
SELECT 
    c.CustomerID,
    c.Name AS CustomerName,
    COUNT(so.OrderID) AS TotalOrders,
    SUM(so.TotalAmount) AS TotalAmountSpent,
    MAX(so.OrderDate) AS LastOrderDate
FROM customer c
LEFT JOIN SalesOrder so 
    ON c.CustomerID = so.CustomerID
GROUP BY 
    c.CustomerID,
    c.Name;

SELECT * FROM vw_CustomerOrderSummary;

-- Q10. Write a stored procedure sp_GetSupplierSales that takes 
-- a SupplierID as input and returns the total sales amount for all products supplied by that supplier.

CREATE PROCEDURE sp_GetSupplierSales
    @SupplierID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.SupplierID,
        s.Name AS SupplierName,
        SUM(sod.Quantity * sod.UnitPrice) AS TotalSalesAmount
    FROM supplier s
    INNER JOIN PurchaseOrder sp 
        ON s.SupplierID = sp.SupplierID
    INNER JOIN PurchaseOrderDetail pod
        ON sp.OrderID = pod.OrderID
    INNER JOIN product p
        ON pod.ProductID = p.ProductID
    INNER JOIN SalesOrderDetail sod
        ON p.ProductID = sod.ProductID
    INNER JOIN SalesOrder so
        ON sod.OrderID = so.OrderID
    WHERE s.SupplierID = @SupplierID
    GROUP BY 
        s.SupplierID,
        s.Name;
END;


EXEC sp_GetSupplierSales @SupplierID = 3;
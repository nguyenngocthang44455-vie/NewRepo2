-- Tạo database nếu chưa có và chuyển sang sử dụng [My Store]
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'My Store')
BEGIN
    CREATE DATABASE [My Store];
END
GO

USE [My Store];
GO

-- 1. Bảng User: quản lý tài khoản Khách hàng và Admin
CREATE TABLE [dbo].[User] (
    [Username]  NVARCHAR (255) NOT NULL,
    [Password]  NCHAR (50)     NOT NULL,
    [UserRole]  NCHAR (1)      NOT NULL, -- A: admin, C: customer
    PRIMARY KEY CLUSTERED ([Username] ASC)
);

-- 2. Bảng Customer: lưu thông tin khách hàng
CREATE TABLE [dbo].[Customer] (
    [CustomerID]      INT            IDENTITY (1, 1) NOT NULL,
    [CustomerName]    NVARCHAR (MAX) NOT NULL,
    [CustomerPhone]   NVARCHAR (15)  NOT NULL,
    [CustomerEmail]   NVARCHAR (MAX) NULL,
    [CustomerAddress] NVARCHAR (MAX) NULL,
    [Username]        NVARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([CustomerID] ASC),
    CONSTRAINT [FK_User_Customer] FOREIGN KEY ([Username]) REFERENCES [dbo].[User] ([Username])
);

-- 3. Bảng Category: lưu thông tin danh mục sản phẩm
CREATE TABLE [dbo].[Category] (
    [CategoryID]   INT            IDENTITY (1, 1) NOT NULL,
    [CategoryName] NVARCHAR (MAX) NOT NULL,
    PRIMARY KEY CLUSTERED ([CategoryID] ASC)
);

-- 4. Bảng Product: lưu thông tin sản phẩm
CREATE TABLE [dbo].[Product] (
    [ProductID]         INT             IDENTITY (1, 1) NOT NULL,
    [CategoryID]        INT             NOT NULL,
    [ProductName]       NVARCHAR (MAX)  NOT NULL,
    [ProductDecription] NVARCHAR (MAX)  NOT NULL,
    [ProductPrice]      DECIMAL (18, 2) NOT NULL,
    [ProductImage]      NVARCHAR (MAX)  NULL,
    PRIMARY KEY CLUSTERED ([ProductID] ASC),
    CONSTRAINT [FK_Pro_Category] FOREIGN KEY ([CategoryID]) REFERENCES [dbo].[Category] ([CategoryID])
);

-- 5. Bảng Order: lưu thông tin đơn hàng
CREATE TABLE [dbo].[Order] (
    [OrderID]         INT             IDENTITY (1, 1) NOT NULL,
    [CustomerID]      INT             NOT NULL,
    [OrderDate]       DATE            NOT NULL,
    [TotalAmount]     DECIMAL (18, 2) NOT NULL,
    [PaymentStatus]   NVARCHAR (MAX)  NULL,
    [AddressDelivery] NVARCHAR (MAX)  NOT NULL,
    PRIMARY KEY CLUSTERED ([OrderID] ASC),
    FOREIGN KEY ([CustomerID]) REFERENCES [dbo].[Customer] ([CustomerID])
);

-- 6. Bảng OrderDetail: lưu thông tin chi tiết đơn hàng
CREATE TABLE [dbo].[OrderDetail] (
    [ID]        INT             IDENTITY (1, 1) NOT NULL,
    [ProductID] INT             NOT NULL,
    [OrderID]   INT             NOT NULL,
    [Quantity]  INT             NOT NULL,
    [UnitPrice] DECIMAL (18, 2) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC),
    FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Product] ([ProductID]),
    FOREIGN KEY ([OrderID]) REFERENCES [dbo].[Order] ([OrderID])
);
GO

ALTER AUTHORIZATION ON DATABASE::[My Store] TO sa;
GO

-- =============================================
-- CÁC LỆNH CẬP NHẬT CẤU TRÚC BẢNG (ĐÃ SỬA THỨ TỰ)
-- =============================================

-- Thêm cột tính tự động cho OrderDetail
ALTER TABLE OrderDetail 
ADD TotalPrice AS (Quantity * UnitPrice) PERSISTED;
GO

-- Đổi tên cột ProductDecription thành ProductDescription
EXEC sp_rename 'Product.ProductDecription', 'ProductDescription', 'COLUMN';
GO

-- Đổi tên cột địa chỉ giao hàng
EXEC sp_rename '[Order].AddressDelivery', 'ShippingAddress', 'COLUMN';
GO

-- Thêm hình thức giao hàng
ALTER TABLE [Order]
ADD DeliveryMethod NVARCHAR(MAX) NULL;
GO

-- Thêm hình thức thanh toán
ALTER TABLE [Order]
ADD PaymentMethod NVARCHAR(MAX) NULL;
GO

-- 1. Thêm cột Quantity vào bảng Product trước
ALTER TABLE Product
ADD Quantity INT NULL;
GO

-- 2. Cập nhật những sản phẩm đang bị NULL về số 0
UPDATE Product 
SET Quantity = 0 
WHERE Quantity IS NULL;
GO

-- 3. Sửa cột Quantity thành NOT NULL để C# nhận diện là kiểu 'int' chuẩn
ALTER TABLE Product
ALTER COLUMN Quantity INT NOT NULL;
GO

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
    [Password]  NVARCHAR (255) NOT NULL,
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

-- Đã khóa dòng dưới để tránh lỗi khi máy chấm dùng Windows Authentication và tắt tài khoản sa
-- ALTER AUTHORIZATION ON DATABASE::[My Store] TO sa;
-- GO

-- =============================================
-- CÁC LỆNH CẬP NHẬT CẤU TRÚC BẢNG
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

-- 4. Cập nhật cột Password sang NVARCHAR(255) và xóa khoảng trắng thừa nếu bảng đã tồn tại từ trước
ALTER TABLE [dbo].[User]
ALTER COLUMN [Password] NVARCHAR(255) NOT NULL;
GO

UPDATE [dbo].[User]
SET [Password] = RTRIM([Password]);
GO

-- =============================================
-- DỮ LIỆU MẪU DEMO (CHẠY AN TOÀN KHÔNG TRÙNG LẶP)
-- =============================================

-- Thêm tài khoản mặc định
IF NOT EXISTS (SELECT 1 FROM [dbo].[User] WHERE [Username] = N'admin')
    INSERT INTO [dbo].[User] ([Username], [Password], [UserRole]) VALUES (N'admin', N'123456', N'A');

IF NOT EXISTS (SELECT 1 FROM [dbo].[User] WHERE [Username] = N'khachhang1')
    INSERT INTO [dbo].[User] ([Username], [Password], [UserRole]) VALUES (N'khachhang1', N'123456', N'C');

IF NOT EXISTS (SELECT 1 FROM [dbo].[Customer] WHERE [Username] = N'khachhang1')
    INSERT INTO [dbo].[Customer] ([CustomerName], [CustomerPhone], [CustomerEmail], [CustomerAddress], [Username])
    VALUES (N'Khách Hàng 1', N'0901234567', N'khachhang1@gmail.com', N'TP. Hồ Chí Minh', N'khachhang1');
GO

-- Thêm danh mục sản phẩm mẫu
IF NOT EXISTS (SELECT 1 FROM [dbo].[Category])
BEGIN
    INSERT INTO [dbo].[Category] ([CategoryName]) VALUES
    (N'Điện thoại'),
    (N'Laptop'),
    (N'Phụ kiện');
END
GO

-- Thêm sản phẩm mẫu có sẵn số lượng tồn kho
IF NOT EXISTS (SELECT 1 FROM [dbo].[Product])
BEGIN
    DECLARE @CatPhone INT = (SELECT TOP 1 CategoryID FROM [dbo].[Category] WHERE CategoryName = N'Điện thoại');
    DECLARE @CatLaptop INT = (SELECT TOP 1 CategoryID FROM [dbo].[Category] WHERE CategoryName = N'Laptop');
    DECLARE @CatAcc INT = (SELECT TOP 1 CategoryID FROM [dbo].[Category] WHERE CategoryName = N'Phụ kiện');

    INSERT INTO [dbo].[Product] ([CategoryID], [ProductName], [ProductDescription], [ProductPrice], [ProductImage], [Quantity]) VALUES
    (@CatPhone, N'iPhone 15 Pro Max 256GB', N'Thiết kế khung viền Titan siêu bền, chip A17 Pro mạnh mẽ.', 29990000, N'/Content/images/hinh01.jpg', 15),
    (@CatPhone, N'Samsung Galaxy S24 Ultra', N'Tích hợp bút S-Pen, camera 200MP và Galaxy AI thông minh.', 26990000, N'/Content/images/hinh02.jpg', 12),
    (@CatLaptop, N'MacBook Air M2 13 inch', N'Mỏng nhẹ, chip Apple M2 hiệu năng cao, pin lên đến 18 giờ.', 24500000, N'/Content/images/1.png', 8),
    (@CatLaptop, N'ASUS ROG Strix G16', N'Laptop Gaming hiệu năng đỉnh cao cho game thủ và đồ họa.', 32990000, N'/Content/images/2.png', 5),
    (@CatAcc, N'Tai nghe AirPods Pro 2', N'Chống ồn chủ động vượt trội, cổng sạc USB-C tiện lợi.', 5490000, N'/Content/images/3.png', 20);
END
GO

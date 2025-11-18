
--create table dbo.DimCustomer
DROP TABLE IF EXISTS dbo.DimCustomer
CREATE TABLE dbo.DimCustomer
(
CustomerID INT,
FirstName VARCHAR(100),
LastName VARCHAR(100),
DOB DATE,
Email VARCHAR(255),
Phone VARCHAR(100),
AddressLine1 VARCHAR(255),
City VARCHAR(100),
State VARCHAR(100),
PostalCode VARCHAR(50),
Country VARCHAR(50),
CreatedDate DATETIME DEFAULT getdate()
)

TRUNCATE TABLE  dbo.DimCustomer

--create dbo.FactLoanOrigination

CREATE TABLE dbo.FactLoanOrigination
(
LoanOriginationID INT,
LoanID VARCHAR(50),
CustomerID INT,
ApplicationDate DATE,
ApprovalDate DATE,
LoanAmount DECIMAL,
InterestRate DECIMAL(4,3),
LoanTermMonths INT,
LoanType VARCHAR(50),
Channel VARCHAR(50),
Status VARCHAR(50),
CreatedDate DATETIME
)


--Insert the values in dbo.DimCustomer table
INSERT INTO dbo.DimCustomer
(CustomerID, FirstName,LastName, DOB, Email, Phone, AddressLine1, City, State, PostalCode, Country)
VALUES
(1001, 'Anish', 'Sharma', '1995-03-10', 'anish.sharma@example.com', '415-555-0101', '101 Oak Street', 'San Jose', 'CA','95112','USA'),
(1002, 'Priya', 'Patel', '1992-07-21', 'priya.patel@example.com','408-555-0102','202 Pine Avenue', 'Fremont', 'CA','94538','USA'),
(1003, 'Rohan', 'Verma', '1998-11-02', 'rohan.verma@example.com','510-555-0102', '303 Maple Drive', 'Oakland', 'CA','94607','USA'),
(1004, 'Sophia', 'Lee', '1990-01-30', 'sophia.Lee@example.com', '650-555-0104', '404 Cedar Lane' , 'San Mateo', 'CA','94401','USA'),
(1005, 'Miguel', 'Garcia', '1997-05-15','miguel.garcia@example.com', '415-555-0105','505 Elm Boulevard','San Francisco', 'CA','94103','USA')

SELECT * FROM dbo.DimCustomer



--Insert the values in dbo.FactLoanOrigination table


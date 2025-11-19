
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
INSERT INTO dbo.FactLoanOrigination
(LoanOriginationID, LoanID, CustomerID, ApplicationDate, ApprovalDate, LoanAmount, InterestRate, LoanTermMonths, LoanType, Channel, Status)
VALUES
(1, 'LOAN-1001', 1001, '2024-01-10', '2024-01-12', 10000.00, 0.075, 36, 'Personal', 'Online', 'Approved'),
(2, 'LOAN-1002', 1002, '2024-01-15', '2024-01-17', 25000.00, 0.065, 60, 'Auto', 'Branch', 'Approved'),
(3, 'LOAN-1003', 1003, '2024-01-20', '2024-01-22', 5000.00, 0.095, 24, 'Personal', 'Online', 'Approved'),
(4, 'LOAN-1004', 1004, '2024-01-25', NULL, 150000.00, 0.045, 360, 'Mortgage', 'Branch', 'Pending'),
(5, 'LOAN-1005', 1005, '2024-02-01', '2024-02-03', 8000.00, 0.085, 36, 'Personal', 'Agent', 'Approved'),
(6, 'LOAN-1006', 1002, '2024-02-05', '2024-02-07', 12000.00, 0.072, 48, 'Personal', 'Online', 'Approved'),
(7, 'LOAN-1003', 1003, '2024-01-20', '2024-01-22', 5000.00, 0.095, 24, 'Personal', 'Online', 'Approved')

SELECT * FROM dbo.FactLoanOrigination


-- Altering the colum to add default constraint for Created Date
--ALTER TABLE dbo.FactLoanOrigination
--ADD CONSTRAINT df_CreatedDate
--DEFAULT(getDate()) FOR CreatedDate






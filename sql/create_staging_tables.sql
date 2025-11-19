CREATE SCHEMA stg AUTHORIZATION dbo;
GO
CREATE SCHEMA dw AUTHORIZATION dbo;


--creating stg.DimCustomer table
DROP TABLE IF EXISTS stg.DimCustomer;

CREATE TABLE stg.DimCustomer (
    CustomerID     INT           NOT NULL,
    FirstName      NVARCHAR(50)  NULL,
    LastName       NVARCHAR(50)  NULL,
    DOB            DATE          NULL,
    Email          NVARCHAR(100) NULL,
    Phone          NVARCHAR(20)  NULL,
    AddressLine1   NVARCHAR(100) NULL,
    City           NVARCHAR(50)  NULL,
    State          NVARCHAR(50)  NULL,
    PostalCode     NVARCHAR(20)  NULL,
    Country        NVARCHAR(50)  NULL,
    CreatedDate    DATETIME2     NULL
);


--creating stg.FactLoanOrigination table

DROP TABLE IF EXISTS stg.FactLoanOrigination;

CREATE TABLE stg.FactLoanOrigination (
    LoanOriginationID INT            NOT NULL,
    LoanID            NVARCHAR(50)   NOT NULL,
    CustomerID        INT            NOT NULL,
    ApplicationDate   DATE           NULL,
    ApprovalDate      DATE           NULL,
    LoanAmount        DECIMAL(18,2)  NULL,
    InterestRate      DECIMAL(5,4)   NULL,
    LoanTermMonths    INT            NULL,
    LoanType          NVARCHAR(50)   NULL,
    Channel           NVARCHAR(50)   NULL,
    Status            NVARCHAR(50)   NULL,
    CreatedDate       DATETIME2      NULL
);


--creating stg.FactLoanDisbursement table

DROP TABLE IF EXISTS stg.FactLoanDisbursement;

CREATE TABLE stg.FactLoanDisbursement (
    DisbursementID     INT            NOT NULL,
    LoanID             NVARCHAR(50)   NOT NULL,
    CustomerID         INT            NOT NULL,
    DisbursementDate   DATE           NULL,
    DisbursedAmount    DECIMAL(18,2)  NULL,
    DisbursementMethod NVARCHAR(50)   NULL,
    CreatedDate        DATETIME2      NULL
);


--creating stg.FactLoanRepayment table

DROP TABLE IF EXISTS stg.FactLoanRepayment;

CREATE TABLE stg.FactLoanRepayment (
    RepaymentID       INT            NOT NULL,
    LoanID            NVARCHAR(50)   NOT NULL,
    CustomerID        INT            NOT NULL,
    PaymentDate       DATE           NULL,
    PaymentAmount     DECIMAL(18,2)  NULL,
    PrincipalComponent DECIMAL(18,2) NULL,
    InterestComponent  DECIMAL(18,2) NULL,
    LateFee           DECIMAL(18,2)  NULL,
    PaymentStatus     NVARCHAR(20)   NULL,
    CreatedDate       DATETIME2      NULL
);




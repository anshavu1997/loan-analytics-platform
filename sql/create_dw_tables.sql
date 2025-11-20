--creating the dw.DimCustomer with surrogate key

DROP TABLE IF EXISTS dw.DimCustomer;

CREATE TABLE dw.DimCustomer (
    DimCustomerKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CustomerID     INT           NOT NULL UNIQUE,
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
    CreatedDate    DATETIME2     NULL,
);

--creating the dw.DimDate table

DROP TABLE IF EXISTS dw.DimDate;

CREATE TABLE dw.DimDate (
    DateKey        INT          NOT NULL PRIMARY KEY,  -- format: YYYYMMDD
    [Date]         DATE         NOT NULL,
    [Year]         SMALLINT     NOT NULL,
    [Quarter]      TINYINT      NOT NULL,
    [Month]        TINYINT      NOT NULL,
    MonthName      NVARCHAR(20) NOT NULL,
    [Day]          TINYINT      NOT NULL,
    DayOfWeekName  NVARCHAR(20) NOT NULL
);


--creating dw.Factloan with surrogate key

DROP TABLE IF EXISTS dw.FactLoan;

CREATE TABLE dw.FactLoan (
    LoanKey             INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    LoanID              NVARCHAR(50)   NOT NULL,
    CustomerID          INT            NOT NULL,
    OriginationDateKey  INT            NOT NULL,
    DisbursementDateKey INT            NULL,
    MaturityDateKey     INT            NULL,
    ApprovedAmount      DECIMAL(18,2)  NULL,
    DisbursedAmount     DECIMAL(18,2)  NULL,
    InterestRate        DECIMAL(5,4)   NULL,
    LoanTermMonths      INT            NULL,
    LoanType            NVARCHAR(50)   NULL,
    Channel             NVARCHAR(50)   NULL,
    Status              NVARCHAR(50)   NULL,
    TotalPaidAmount     DECIMAL(18,2)  NULL,
    OutstandingPrincipal DECIMAL(18,2) NULL,
    DefaultFlag         BIT            NULL
);

--Altering columns to add foriegn relationships

ALTER TABLE dw.FactLoan
    ADD CONSTRAINT FK_FactLoan_DimCustomer
    FOREIGN KEY (CustomerID)
    REFERENCES dw.DimCustomer (CustomerID);

ALTER TABLE dw.FactLoan
    ADD CONSTRAINT FK_FactLoan_OrigDate
    FOREIGN KEY (OriginationDateKey)
    REFERENCES dw.DimDate (DateKey);

ALTER TABLE dw.FactLoan
    ADD CONSTRAINT FK_FactLoan_DisbDate
    FOREIGN KEY (DisbursementDateKey)
    REFERENCES dw.DimDate (DateKey);

ALTER TABLE dw.FactLoan
    ADD CONSTRAINT FK_FactLoan_MaturityDate
    FOREIGN KEY (MaturityDateKey)
    REFERENCES dw.DimDate (DateKey);


    --creating dw.FactRepayment table with surrogate key

 DROP TABLE IF EXISTS dw.FactRepayment;

CREATE TABLE dw.FactRepayment (
    RepaymentKey       INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    LoanID             NVARCHAR(50)   NOT NULL,
    CustomerID         INT            NOT NULL,
    PaymentDateKey     INT            NOT NULL,
    PaymentAmount      DECIMAL(18,2)  NULL,
    PrincipalComponent DECIMAL(18,2)  NULL,
    InterestComponent  DECIMAL(18,2)  NULL,
    LateFee            DECIMAL(18,2)  NULL,
    PaymentStatus      NVARCHAR(20)   NULL
);

--altering columns to add foriegn relationships to some of the columns

ALTER TABLE dw.FactRepayment
    ADD CONSTRAINT FK_FactRepayment_DimCustomer
    FOREIGN KEY (CustomerID)
    REFERENCES dw.DimCustomer (CustomerID);

ALTER TABLE dw.FactRepayment
    ADD CONSTRAINT FK_FactRepayment_DimDate
    FOREIGN KEY (PaymentDateKey)
    REFERENCES dw.DimDate (DateKey);


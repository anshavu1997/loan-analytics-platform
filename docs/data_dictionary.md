# Loan Analytics Platform – Data Dictionary

This document explains the main tables and columns in the `LoanAnalytics` database.  
Types are shown in a SQL-style format; adjust as needed for your actual implementation.

---

## 1. Staging tables (`stg` schema)

These tables mirror the source systems as closely as possible and are loaded by `PL_Ingest_To_Staging`.

### 1.1 `stg.DimCustomer`

One row per customer record as it appears in the source system.

| Column        | Type            | Meaning |
|---------------|-----------------|---------|
| `CustomerID`  | INT             | Business key of the customer from the source system. |
| `FirstName`   | NVARCHAR(50)    | Customer’s first name. |
| `LastName`    | NVARCHAR(50)    | Customer’s last name. |
| `DOB`         | DATE            | Date of birth. |
| `Email`       | NVARCHAR(100)   | Primary email address. |
| `Phone`       | NVARCHAR(20)    | Primary phone number. |
| `AddressLine1`| NVARCHAR(100)   | First line of the street address. |
| `City`        | NVARCHAR(50)    | City. |
| `State`       | NVARCHAR(50)    | State or province. |
| `PostalCode`  | NVARCHAR(20)    | Postal or ZIP code. |
| `Country`     | NVARCHAR(50)    | Country. |
| `CreatedDate` | DATETIME2       | When this record was created or last updated in the source. Used for deduplication. |

---

### 1.2 `stg.FactLoanOrigination`

Each row represents a loan application or origination event from the source system.

| Column              | Type           | Meaning |
|---------------------|----------------|---------|
| `LoanOriginationID` | INT            | Internal ID of the origination record in the source. |
| `LoanID`            | NVARCHAR(50)   | Business identifier for the loan. Used as the key across tables. |
| `CustomerID`        | INT            | Customer associated with the loan. |
| `ApplicationDate`   | DATE           | Date the loan application was submitted. |
| `ApprovalDate`      | DATE           | Date the loan was approved. |
| `LoanAmount`        | DECIMAL(18,2)  | Approved loan amount. |
| `InterestRate`      | DECIMAL(5,4)   | Interest rate as a decimal (e.g., 0.0750 = 7.5%). |
| `LoanTermMonths`    | INT            | Length of the loan in months. |
| `LoanType`          | NVARCHAR(50)   | Type of loan (e.g., Personal, Auto, Mortgage). |
| `Channel`           | NVARCHAR(50)   | Origination channel (e.g., Branch, Online). |
| `Status`            | NVARCHAR(50)   | Status at the time of origination (e.g., Approved, Rejected, Pending). |
| `CreatedDate`       | DATETIME2      | When this record was created/updated in the source. Used for deduplication. |

---

### 1.3 `stg.FactLoanDisbursement`

Each row represents a disbursement of funds for a loan.

| Column               | Type           | Meaning |
|----------------------|----------------|---------|
| `DisbursementID`     | INT            | Internal ID of the disbursement record in the source. |
| `LoanID`             | NVARCHAR(50)   | Loan associated with the disbursement. |
| `CustomerID`         | INT            | Customer receiving the funds. |
| `DisbursementDate`   | DATE           | Date funds were released. |
| `DisbursedAmount`    | DECIMAL(18,2)  | Amount disbursed. |
| `DisbursementMethod` | NVARCHAR(50)   | How the funds were sent (e.g., Bank Transfer, Check). |
| `CreatedDate`        | DATETIME2      | Timestamp used for deduplication. |

---

### 1.4 `stg.FactLoanRepayment`

Each row is a raw repayment transaction from the CSV or upstream system.

| Column              | Type           | Meaning |
|---------------------|----------------|---------|
| `RepaymentID`       | INT            | Internal ID of the repayment record (if available; otherwise synthetic). |
| `LoanID`            | NVARCHAR(50)   | Loan being repaid. |
| `CustomerID`        | INT            | Customer making the payment. |
| `PaymentDate`       | DATE           | Date the payment was booked. |
| `PaymentAmount`     | DECIMAL(18,2)  | Total amount paid in this transaction. |
| `PrincipalComponent`| DECIMAL(18,2)  | Portion applied to principal. |
| `InterestComponent` | DECIMAL(18,2)  | Portion applied to interest. |
| `LateFee`           | DECIMAL(18,2)  | Any late fee charged as part of this payment. |
| `PaymentStatus`     | NVARCHAR(20)   | Status of the payment (e.g., OnTime, Late, Missed). |
| `CreatedDate`       | DATETIME2      | Timestamp used for deduplication. |

---

## 2. Dimension tables (`dw` schema)

### 2.1 `dw.DimCustomer`

Clean, deduplicated view of customers.

| Column            | Type           | Meaning |
|-------------------|----------------|---------|
| `DimCustomerKey`  | INT IDENTITY   | Surrogate key for the dimension. |
| `CustomerID`      | INT            | Business key from the source system. Unique within the dimension. |
| `FirstName`       | NVARCHAR(50)   | Customer’s first name. |
| `LastName`        | NVARCHAR(50)   | Customer’s last name. |
| `DOB`             | DATE           | Date of birth. |
| `Email`           | NVARCHAR(100)  | Primary contact email. |
| `Phone`           | NVARCHAR(20)   | Primary contact phone. |
| `AddressLine1`    | NVARCHAR(100)  | Street address. |
| `City`            | NVARCHAR(50)   | City. |
| `State`           | NVARCHAR(50)   | State or province. |
| `PostalCode`      | NVARCHAR(20)   | Postal or ZIP code. |
| `Country`         | NVARCHAR(50)   | Country. |
| `CreatedDate`     | DATETIME2      | Timestamp of the version selected as the “winner” during deduplication. |

---

### 2.2 `dw.DimDate`

Standard calendar dimension.

| Column          | Type         | Meaning |
|-----------------|--------------|---------|
| `DateKey`       | INT          | Surrogate key in `YYYYMMDD` format. Primary key. |
| `Date`          | DATE         | Actual calendar date. |
| `Year`          | SMALLINT     | Calendar year (e.g., 2024). |
| `Quarter`       | TINYINT      | Quarter of the year (1–4). |
| `Month`         | TINYINT      | Month number (1–12). |
| `MonthName`     | NVARCHAR(20) | Month name (e.g., “January”). |
| `Day`           | TINYINT      | Day of the month (1–31). |
| `DayOfWeekName` | NVARCHAR(20) | Day of week name (e.g., “Monday”). |

---

## 3. Fact tables (`dw` schema)

### 3.1 `dw.FactLoan`

One row per loan, combining origination and disbursement with derived metrics.

| Column                | Type           | Meaning |
|-----------------------|----------------|---------|
| `LoanKey`             | INT IDENTITY   | Surrogate key for the fact table. |
| `LoanID`              | NVARCHAR(50)   | Business identifier for the loan. Unique per loan. |
| `CustomerID`          | INT            | Foreign key to `dw.DimCustomer.CustomerID`. |
| `OriginationDateKey`  | INT            | FK to `dw.DimDate.DateKey` for the origination date. |
| `DisbursementDateKey` | INT            | FK to `dw.DimDate.DateKey` for the disbursement date (if any). |
| `MaturityDateKey`     | INT            | FK to `dw.DimDate.DateKey` for the expected maturity date (optional). |
| `ApprovedAmount`      | DECIMAL(18,2)  | Loan amount approved at origination. |
| `DisbursedAmount`     | DECIMAL(18,2)  | Amount actually disbursed. |
| `InterestRate`        | DECIMAL(5,4)   | Interest rate as decimal. |
| `LoanTermMonths`      | INT            | Length of the loan in months. |
| `LoanType`            | NVARCHAR(50)   | Type/category of loan. |
| `Channel`             | NVARCHAR(50)   | Origination channel. |
| `Status`              | NVARCHAR(50)   | Current business status of the loan (Active, Closed, Delinquent, etc.). |
| `TotalPaidAmount`     | DECIMAL(18,2)  | Total payments received on this loan (all components). |
| `OutstandingPrincipal`| DECIMAL(18,2)  | Remaining principal balance, after subtracting principal paid. |
| `DefaultFlag`         | BIT or INT     | 1 if the loan is considered in default/delinquent, otherwise 0. |

---

### 3.2 `dw.FactRepayment`

One row per repayment transaction.

| Column              | Type           | Meaning |
|---------------------|----------------|---------|
| `RepaymentKey`      | INT IDENTITY   | Surrogate key. |
| `LoanID`            | NVARCHAR(50)   | FK to `dw.FactLoan.LoanID`. |
| `CustomerID`        | INT            | FK to `dw.DimCustomer.CustomerID`. |
| `PaymentDateKey`    | INT            | FK to `dw.DimDate.DateKey` for the payment date. |
| `PaymentAmount`     | DECIMAL(18,2)  | Total cash received in this payment. |
| `PrincipalComponent`| DECIMAL(18,2)  | Amount applied toward principal. |
| `InterestComponent` | DECIMAL(18,2)  | Amount applied toward interest. |
| `LateFee`           | DECIMAL(18,2)  | Late fee included in this payment. |
| `PaymentStatus`     | NVARCHAR(20)   | Status of the payment (OnTime, Late, Missed, etc.). |

---

## 4. Logging table (`etl` schema)

### 4.1 `etl.PipelineRunLog`

High-level log of ETL pipeline runs.

| Column         | Type           | Meaning |
|----------------|----------------|---------|
| `LogID`        | INT IDENTITY   | Primary key of the log record. |
| `PipelineName` | NVARCHAR(200)  | Name of the pipeline that ran (e.g., `PL_Ingest_To_Staging`). |
| `RunStatus`    | NVARCHAR(50)   | Status of the run (Started, Completed, Failed, etc.). |
| `RunStartedUTC`| DATETIME2      | UTC timestamp when the pipeline started. |
| `RunEndedUTC`  | DATETIME2      | UTC timestamp when the pipeline finished (if set). |
| `Notes`        | NVARCHAR(500)  | Optional field for additional comments or error messages. |

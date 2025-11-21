# Loan Analytics Platform – Design Document

## 1. Overview and business problem

This project builds a small but realistic loan analytics platform on Azure.

The idea is simple: a lender has loan data scattered across an on-premises SQL Server and a few flat files in cloud storage. Business users want a single place to answer questions like:

- How much have we approved, disbursed, and actually collected?
- Which loan types and channels are performing best?
- What is our default rate and how is it trending over time?

To support this, we:

1. Pull raw loan origination data from an on-premises SQL Server database (`LoanCoreOnPrem`).
2. Pull disbursement and repayment files from Azure Blob Storage.
3. Land everything in a cloud data warehouse (`LoanAnalytics` on Azure SQL Database).
4. Clean, deduplicate, and model the data into star-schema tables.
5. Expose it to Power BI so business users can explore and build reports.

Azure Data Factory orchestrates the entire data flow and runs on a schedule, so that the warehouse and dashboards stay up to date without manual work.

---

## 2. Data model (tables and relationships)

The core of the model is a simple star schema with two dimensions and two fact tables.

### Dimensions

- **`dw.DimCustomer`**  
  One row per customer. Stores name, contact details, and basic demographic columns.  
  Business key: `CustomerID`.

- **`dw.DimDate`**  
  One row per calendar date. Used to slice facts by day, month, quarter, and year.  
  Business key: the calendar date itself, represented as `DateKey` in `YYYYMMDD` format.

### Facts

- **`dw.FactLoan`**  
  One row per loan. Combines origination and disbursement details:
  approved amount, disbursed amount, interest rate, term, channel, loan type, and current status.  
  It also carries derived metrics such as `TotalPaidAmount`, `OutstandingPrincipal`, and `DefaultFlag`.

- **`dw.FactRepayment`**  
  One row per repayment transaction. Tracks the total payment amount as well as its principal, interest, and late fee components, mapped to a payment date.

### Relationships

The main relationships are:

- **Customer → Loans**  
  `dw.DimCustomer.CustomerID (1)` → `dw.FactLoan.CustomerID (*)`  
  One customer can have many loans.

- **Date → Loans**  
  `dw.DimDate.DateKey (1)` → `dw.FactLoan.OriginationDateKey (*)`  
  `dw.DimDate.DateKey (1)` → `dw.FactLoan.DisbursementDateKey (*)`  
  One date can be the origination or disbursement date for many loans.

- **Date → Repayments**  
  `dw.DimDate.DateKey (1)` → `dw.FactRepayment.PaymentDateKey (*)`  
  One date can have many repayment transactions.

- **Loan → Repayments**  
  `dw.FactLoan.LoanID (1)` → `dw.FactRepayment.LoanID (*)`  
  A single loan can have multiple payments over time.

In Power BI, `DimCustomer` and `DimDate` act as filter tables, while `FactLoan` and `FactRepayment` hold the measures that drive most visuals.

We also have separate **staging tables** under the `stg` schema (`stg.DimCustomer`, `stg.FactLoanOrigination`, `stg.FactLoanDisbursement`, `stg.FactLoanRepayment`) which mirror the raw source structures before any cleaning or deduplication is applied.

---

## 3. ETL flow (staging → data warehouse)

The ETL flow is split into two main phases and orchestrated by a master pipeline.

### 3.1 Ingestion to staging

Pipeline: **`PL_Ingest_To_Staging`**

This pipeline is responsible for copying raw data from the source systems into Azure SQL staging tables.

- **Sources**
  - On-prem SQL Server (`LoanCoreOnPrem`), connected via a Self-Hosted Integration Runtime.
    - `dbo.DimCustomer`
    - `dbo.FactLoanOrigination`
  - Azure Blob Storage (container `loan-raw`):
    - `loan_disbursement.csv`
    - `loan_repayment.csv`

- **Sinks (staging in Azure SQL / LoanAnalytics)**
  - `stg.DimCustomer`
  - `stg.FactLoanOrigination`
  - `stg.FactLoanDisbursement`
  - `stg.FactLoanRepayment`

Each Copy activity optionally truncates the target staging table before loading, so staging always reflects the latest snapshot of the source data. The pipeline writes a row to `etl.PipelineRunLog` at the start and updates it once the run completes.

### 3.2 Transform and load into the warehouse

Pipeline: **`PL_Transform_To_DW`**

This pipeline runs a series of stored procedures in Azure SQL to transform staging data into the dimensional model.

The main procedures are:

- `dw.usp_Load_DimDate`  
  Ensures `dw.DimDate` contains one row per day for the required date range. It is implemented as an incremental loader that inserts missing dates but never deletes existing ones, which keeps foreign key relationships intact.

- `dw.usp_Load_DimCustomer`  
  Reads customers from `stg.DimCustomer`, deduplicates them, and upserts them into `dw.DimCustomer`.

- `dw.usp_Load_FactLoan`  
  Deduplicates `stg.FactLoanOrigination` and `stg.FactLoanDisbursement`, combines them into one row per loan, derives date keys from `dw.DimDate`, and upserts into `dw.FactLoan`.

- `dw.usp_Load_FactRepayment`  
  Deduplicates `stg.FactLoanRepayment` and loads it into `dw.FactRepayment`, mapping each payment to a `PaymentDateKey` in `dw.DimDate`.

- `dw.usp_Update_Loan_Status`  
  Aggregates repayments at the loan level, calculates total paid amounts and outstanding principal, and updates `Status` and `DefaultFlag` on `dw.FactLoan` using simple business rules.

This pipeline also logs its runs to the `etl.PipelineRunLog` table.

### 3.3 Master orchestration

Pipeline: **`PL_Master_Loan_ETL`**

The master pipeline simply chains the two phases:

1. Execute `PL_Ingest_To_Staging`.
2. If ingestion succeeds, execute `PL_Transform_To_DW`.

A scheduled trigger runs this master pipeline automatically (for example, every day at 1:00 AM), so the warehouse and Power BI reports stay fresh.

---

## 4. Deduplication logic (CTEs and rules)

Deduplication is handled centrally in the stored procedures using Common Table Expressions (CTEs) and `ROW_NUMBER()`.

The general pattern is:

1. Partition rows by the business key.
2. Order by `CreatedDate` (and sometimes an ID) so that the “latest” or “best” record comes first.
3. Assign row numbers per partition.
4. Keep only `ROW_NUMBER() = 1` as the canonical record.

### 4.1 Customers

Procedure: **`dw.usp_Load_DimCustomer`**

- **Business key:** `CustomerID`
- **CTE:** `DedupStage`
  - Partitions by `CustomerID`.
  - Orders by `CreatedDate` (latest first).
  - Keeps only `rn = 1`.
- The result is merged into `dw.DimCustomer`. New `CustomerID`s are inserted; existing ones are updated in place (Type 1 slowly changing dimension).

### 4.2 Loan origination

Procedure: **`dw.usp_Load_FactLoan`**

- **Business key:** `LoanID`
- **Origination CTE:** `OrigDedup`
  - Partitions by `LoanID`.
  - Orders by `CreatedDate` and `LoanOriginationID`.
  - Keeps the latest record per loan.
- **Disbursement CTE:** `DisbDedup`
  - Same pattern, but on `stg.FactLoanDisbursement`.

These two deduped sets are then joined together, dates are mapped to `DimDate`, and the result is merged into `dw.FactLoan`.

Only loans with a valid `OriginationDateKey` are loaded into the fact table. Any loans with missing or out-of-range dates are skipped to preserve referential integrity.

### 4.3 Repayments

Procedure: **`dw.usp_Load_FactRepayment`**

- **Business key:** the combination of:
  - `LoanID`
  - `CustomerID`
  - `PaymentDate`
  - `PaymentAmount`
- **CTE:** `RepDedup`
  - Partitions by that composite key.
  - Orders by `CreatedDate` (latest first).
  - Keeps `rn = 1`.

Payments are mapped to `PaymentDateKey` using `dw.DimDate`, and only rows with a valid date key are loaded into `dw.FactRepayment`.

### 4.4 Loan status and default flags

Procedure: **`dw.usp_Update_Loan_Status`**

This procedure aggregates payments from `dw.FactRepayment` by `LoanID` and updates `dw.FactLoan` with:

- `TotalPaidAmount` and `OutstandingPrincipal`
- `Status`, using simple business rules:
  - If the principal paid is greater than or equal to the disbursed amount, the loan is marked as **Closed**.
  - If the loan still has outstanding principal and has missed or repeated late payments, it is marked as **Delinquent**.
  - Otherwise, it is marked as **Active** (or keeps its existing status if not yet disbursed).

It also sets a `DefaultFlag` (0/1) to make it easy to track defaulted loans in Power BI measures and visuals.

---

## 5. Power BI usage (short overview)

Power BI connects directly to the `LoanAnalytics` database and uses the `dw.*` tables. Measures are defined on top of the fact tables to support:

- Total approved, disbursed, and repaid amounts.
- Default counts and default rates.
- Monthly trends for originations and repayments.
- Breakdowns by loan type, channel, status, and customer.

The combination of a clean star schema, deduplicated facts, and robust date and customer dimensions makes the model easy to use and hard to misuse.

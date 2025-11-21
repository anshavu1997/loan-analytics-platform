# Loan Analytics Platform – ETL Runbook

This runbook explains how to run, monitor, and troubleshoot the ETL pipelines for the Loan Analytics Platform.

---

## 1. Environment overview

- **Source systems**
  - On-prem SQL Server database: `LoanCoreOnPrem`
    - `dbo.DimCustomer`
    - `dbo.FactLoanOrigination`
  - Azure Blob Storage:
    - Container: `loan-raw`
    - Files: `loan_disbursement.csv`, `loan_repayment.csv`

- **Target warehouse**
  - Azure SQL Database: `LoanAnalytics`
  - Schemas:
    - `stg` – staging tables that mirror the raw sources
    - `dw` – dimensional model used by Power BI
    - `etl` – logging and operational tables

- **Orchestration**
  - Azure Data Factory: `adf-loan-analytics-dev`
  - Pipelines:
    - `PL_Ingest_To_Staging`
    - `PL_Transform_To_DW`
    - `PL_Master_Loan_ETL`
  - Trigger:
    - `TRG_Daily_Master_ETL` – runs the master pipeline on a schedule

---

## 2. Normal daily run (scheduled)

The normal operating mode is fully automated.

1. **Schedule**
   - Trigger `TRG_Daily_Master_ETL` is set to run once per day (for example, at 1:00 AM).
   - The trigger calls `PL_Master_Loan_ETL`.

2. **Master pipeline**
   - `PL_Master_Loan_ETL` runs two child pipelines in order:
     1. `PL_Ingest_To_Staging`
     2. `PL_Transform_To_DW` (only if the ingestion step succeeds)

3. **Expected outcome**
   - Staging tables are fully refreshed with the latest data.
   - Dimension and fact tables in `dw` are updated and deduplicated.
   - Power BI reports that point to `LoanAnalytics` show up-to-date numbers once they refresh.

No manual actions are required for a normal daily run.

---

## 3. Manual run instructions

Sometimes you’ll want to run the ETL manually after making changes or loading new sample data.

### 3.1 Run ingestion only

1. Open **Azure Data Factory Studio**.
2. Go to the **Author** pane and select `PL_Ingest_To_Staging`.
3. Click **Debug** (for an ad-hoc run) or **Add trigger → Trigger now**.
4. Wait for the pipeline to complete.
5. Verify in Azure SQL (`LoanAnalytics`) that:
   - `stg.DimCustomer` has rows.
   - `stg.FactLoanOrigination`, `stg.FactLoanDisbursement`, and `stg.FactLoanRepayment` have the expected data.

### 3.2 Run transforms only

If staging is already loaded and you only want to recompute the DW layer:

1. In ADF Studio, select `PL_Transform_To_DW`.
2. Click **Debug** or run via a trigger.
3. Once done, verify in Azure SQL:
   - `dw.DimDate` covers the expected date range.
   - `dw.DimCustomer` has one row per customer.
   - `dw.FactLoan` has one row per loan and has been updated with the latest status/metrics.
   - `dw.FactRepayment` has one row per unique payment.

### 3.3 Run the full master pipeline

This is the best way to mimic the daily scheduled run.

1. In ADF Studio, select `PL_Master_Loan_ETL`.
2. Click **Debug** or **Trigger now**.
3. Confirm both child activities:
   - `Exec_PL_Ingest_To_Staging`
   - `Exec_PL_Transform_To_DW`
   finish with status **Succeeded**.

---

## 4. Logging and monitoring

### 4.1 ADF Monitor tab

1. Go to the **Monitor** blade in ADF Studio.
2. Under **Pipeline runs**, filter by pipeline name:
   - `PL_Ingest_To_Staging`
   - `PL_Transform_To_DW`
   - `PL_Master_Loan_ETL`
3. Click any run to see:
   - Start and end times
   - Activity-level status
   - Error messages and diagnostic output if something failed

### 4.2 SQL-level log (`etl.PipelineRunLog`)

The pipelines also write simple logs into the database.

To see them, connect to the `LoanAnalytics` database in SSMS and run:

```sql
SELECT *
FROM etl.PipelineRunLog
ORDER BY LogID DESC;

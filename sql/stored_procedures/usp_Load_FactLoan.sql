-- Create dw.usp_Load_FactLoan table 

CREATE OR ALTER PROCEDURE dw.usp_Load_FactLoan
AS
BEGIN
    SET NOCOUNT ON;

   
    WITH OrigDedup AS (
        SELECT
              LoanOriginationID
            , LoanID
            , CustomerID
            , ApplicationDate
            , ApprovalDate
            , LoanAmount
            , InterestRate
            , LoanTermMonths
            , LoanType
            , Channel
            , Status
            , CreatedDate
            , ROW_NUMBER() OVER (
                  PARTITION BY LoanID
                  ORDER BY 
                        CASE 
                            WHEN CreatedDate IS NULL THEN 1 
                            ELSE 0 
                        END,        
                        CreatedDate DESC,
                        LoanOriginationID DESC  
              ) AS rn
        FROM stg.FactLoanOrigination
        WHERE LoanID IS NOT NULL
    ),
    OrigFinal AS (
        SELECT
              LoanOriginationID
            , LoanID
            , CustomerID
            , ApplicationDate
            , ApprovalDate
            , LoanAmount
            , InterestRate
            , LoanTermMonths
            , LoanType
            , Channel
            , Status
            , CreatedDate
        FROM OrigDedup
        WHERE rn = 1      
    ),

   
    DisbDedup AS (
        SELECT
              DisbursementID
            , LoanID
            , CustomerID
            , DisbursementDate
            , DisbursedAmount
            , DisbursementMethod
            , CreatedDate
            , ROW_NUMBER() OVER (
                  PARTITION BY LoanID
                  ORDER BY 
                        CASE 
                            WHEN CreatedDate IS NULL THEN 1 
                            ELSE 0 
                        END,
                        CreatedDate DESC,
                        DisbursementID DESC
              ) AS rn
        FROM stg.FactLoanDisbursement
        WHERE LoanID IS NOT NULL
    ),
    DisbFinal AS (
        SELECT
              DisbursementID
            , LoanID
            , CustomerID
            , DisbursementDate
            , DisbursedAmount
            , DisbursementMethod
            , CreatedDate
        FROM DisbDedup
        WHERE rn = 1
    ),

  
    LoanBase AS (
        SELECT
              o.LoanID
            , o.CustomerID
            , o.ApplicationDate
            , o.ApprovalDate
            , o.LoanAmount        AS ApprovedAmount
            , o.InterestRate
            , o.LoanTermMonths
            , o.LoanType
            , o.Channel
            , o.Status
            , d.DisbursementDate
            , d.DisbursedAmount
        FROM OrigFinal o
        LEFT JOIN DisbFinal d
               ON d.LoanID = o.LoanID
    ),

    
    LoanWithDateKeys AS (
        SELECT
              lb.LoanID
            , lb.CustomerID
            , lb.ApprovedAmount
            , lb.InterestRate
            , lb.LoanTermMonths
            , lb.LoanType
            , lb.Channel
            , lb.Status
            , lb.DisbursedAmount
            , lb.DisbursementDate

            
            , COALESCE(lb.ApprovalDate, lb.ApplicationDate) AS OriginationDate
        FROM LoanBase lb
    ),
    LoanWithDimDates AS (
        SELECT
              l.LoanID
            , l.CustomerID
            , l.ApprovedAmount
            , l.InterestRate
            , l.LoanTermMonths
            , l.LoanType
            , l.Channel
            , l.Status
            , l.DisbursedAmount
            , l.DisbursementDate
            , l.OriginationDate

            
            , oDate.DateKey AS OriginationDateKey
            , dDate.DateKey AS DisbursementDateKey
            , mDate.DateKey AS MaturityDateKey
        FROM LoanWithDateKeys l
        OUTER APPLY (
            SELECT DateKey
            FROM dw.DimDate
            WHERE [Date] = l.OriginationDate
        ) oDate
        OUTER APPLY (
            SELECT DateKey
            FROM dw.DimDate
            WHERE [Date] = l.DisbursementDate
        ) dDate
        OUTER APPLY (
            SELECT DateKey
            FROM dw.DimDate
            WHERE [Date] = 
                  CASE 
                      WHEN l.LoanTermMonths IS NOT NULL 
                           AND l.OriginationDate IS NOT NULL 
                      THEN DATEADD(MONTH, l.LoanTermMonths, l.OriginationDate)
                      ELSE NULL
                  END
        ) mDate
    )

   
   MERGE dw.FactLoan AS tgt
USING (
    SELECT *
    FROM LoanWithDimDates
    WHERE OriginationDateKey IS NOT NULL
) AS src
    ON tgt.LoanID = src.LoanID
WHEN MATCHED THEN
    UPDATE SET
          tgt.CustomerID          = src.CustomerID
        , tgt.OriginationDateKey  = src.OriginationDateKey
        , tgt.DisbursementDateKey = src.DisbursementDateKey
        , tgt.MaturityDateKey     = src.MaturityDateKey
        , tgt.ApprovedAmount      = src.ApprovedAmount
        , tgt.DisbursedAmount     = src.DisbursedAmount
        , tgt.InterestRate        = src.InterestRate
        , tgt.LoanTermMonths      = src.LoanTermMonths
        , tgt.LoanType            = src.LoanType
        , tgt.Channel             = src.Channel
        , tgt.Status              = src.Status
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
          LoanID
        , CustomerID
        , OriginationDateKey
        , DisbursementDateKey
        , MaturityDateKey
        , ApprovedAmount
        , DisbursedAmount
        , InterestRate
        , LoanTermMonths
        , LoanType
        , Channel
        , Status
        , TotalPaidAmount
        , OutstandingPrincipal
        , DefaultFlag
    )
    VALUES (
          src.LoanID
        , src.CustomerID
        , src.OriginationDateKey
        , src.DisbursementDateKey
        , src.MaturityDateKey
        , src.ApprovedAmount
        , src.DisbursedAmount
        , src.InterestRate
        , src.LoanTermMonths
        , src.LoanType
        , src.Channel
        , src.Status
        , 0.0                     
        , src.DisbursedAmount     
        , 0                       
    );


END;
GO

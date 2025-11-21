-- Create Stored Procedure to Load FactRepayment 

CREATE OR ALTER PROCEDURE dw.usp_Load_FactRepayment
AS
BEGIN
    SET NOCOUNT ON;

   
    ;WITH RepDedup AS (
        SELECT
              RepaymentID
            , LoanID
            , CustomerID
            , PaymentDate
            , PaymentAmount
            , PrincipalComponent
            , InterestComponent
            , LateFee
            , PaymentStatus
            , CreatedDate
            , ROW_NUMBER() OVER (
                  PARTITION BY 
                        LoanID,
                        CustomerID,
                        PaymentDate,
                        PaymentAmount
                  ORDER BY 
                        CASE 
                            WHEN CreatedDate IS NULL THEN 1 
                            ELSE 0 
                        END,           
                        CreatedDate DESC,
                        RepaymentID DESC  
              ) AS rn
        FROM stg.FactLoanRepayment
        WHERE LoanID      IS NOT NULL
          AND CustomerID  IS NOT NULL
          AND PaymentDate IS NOT NULL
    ),
    RepFinal AS (
        SELECT
              RepaymentID
            , LoanID
            , CustomerID
            , PaymentDate
            , PaymentAmount
            , PrincipalComponent
            , InterestComponent
            , LateFee
            , PaymentStatus
            , CreatedDate
        FROM RepDedup
        WHERE rn = 1    
    ),

 
    RepWithKeys AS (
        SELECT
              r.LoanID
            , r.CustomerID
            , r.PaymentDate
            , r.PaymentAmount
            , r.PrincipalComponent
            , r.InterestComponent
            , r.LateFee
            , r.PaymentStatus
            , dDate.DateKey AS PaymentDateKey
        FROM RepFinal r
       
        OUTER APPLY (
            SELECT DateKey
            FROM dw.DimDate
            WHERE [Date] = r.PaymentDate
        ) dDate
    ),
    RepValid AS (
        SELECT
              rw.LoanID
            , rw.CustomerID
            , rw.PaymentDateKey
            , rw.PaymentAmount
            , rw.PrincipalComponent
            , rw.InterestComponent
            , rw.LateFee
            , rw.PaymentStatus
        FROM RepWithKeys rw
        WHERE rw.PaymentDateKey IS NOT NULL     
    )

   
    MERGE dw.FactRepayment AS tgt
    USING RepValid AS src
        ON  tgt.LoanID         = src.LoanID
        AND tgt.CustomerID     = src.CustomerID
        AND tgt.PaymentDateKey = src.PaymentDateKey
        AND tgt.PaymentAmount  = src.PaymentAmount
    WHEN MATCHED THEN
        UPDATE SET
              tgt.PrincipalComponent = src.PrincipalComponent
            , tgt.InterestComponent  = src.InterestComponent
            , tgt.LateFee            = src.LateFee
            , tgt.PaymentStatus      = src.PaymentStatus
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
              LoanID
            , CustomerID
            , PaymentDateKey
            , PaymentAmount
            , PrincipalComponent
            , InterestComponent
            , LateFee
            , PaymentStatus
        )
        VALUES (
              src.LoanID
            , src.CustomerID
            , src.PaymentDateKey
            , src.PaymentAmount
            , src.PrincipalComponent
            , src.InterestComponent
            , src.LateFee
            , src.PaymentStatus
        );

END;
GO

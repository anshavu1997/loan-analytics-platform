-- Create stored procedure to check the loan status

CREATE OR ALTER PROCEDURE dw.usp_Update_Loan_Status
AS
BEGIN
    SET NOCOUNT ON;

  
    ;WITH RepAgg AS (
        SELECT
              LoanID
            , SUM(PaymentAmount)      AS TotalPaidAmount
            , SUM(PrincipalComponent) AS TotalPrincipalPaid
            , SUM(InterestComponent)  AS TotalInterestPaid
            , SUM(LateFee)            AS TotalLateFee
            , SUM(CASE WHEN PaymentStatus = 'Late'   THEN 1 ELSE 0 END) AS LateCount
            , SUM(CASE WHEN PaymentStatus = 'Missed' THEN 1 ELSE 0 END) AS MissedCount
        FROM dw.FactRepayment
        GROUP BY LoanID
    )

   
    UPDATE fl
    SET
        
        fl.TotalPaidAmount = ISNULL(ra.TotalPaidAmount, 0),

        
        fl.OutstandingPrincipal =
            CASE 
                WHEN fl.DisbursedAmount IS NULL THEN fl.OutstandingPrincipal  
                ELSE
                    CASE 
                        WHEN fl.DisbursedAmount - ISNULL(ra.TotalPrincipalPaid, 0) < 0 
                            THEN 0
                        ELSE fl.DisbursedAmount - ISNULL(ra.TotalPrincipalPaid, 0)
                    END
            END,

        
        fl.Status =
            CASE 
                
                WHEN fl.DisbursedAmount IS NULL THEN fl.Status

                
                WHEN fl.DisbursedAmount IS NOT NULL
                     AND ISNULL(ra.TotalPrincipalPaid, 0) >= fl.DisbursedAmount
                     AND ISNULL(ra.TotalPrincipalPaid, 0) > 0 THEN 'Closed'

                
                WHEN (ISNULL(ra.MissedCount, 0) >= 1 OR ISNULL(ra.LateCount, 0) >= 2)
                     AND (
                            fl.DisbursedAmount IS NOT NULL
                        AND fl.DisbursedAmount - ISNULL(ra.TotalPrincipalPaid, 0) > 0
                     ) THEN 'Delinquent'

                
                ELSE 'Active'
            END,

        
        fl.DefaultFlag =
            CASE 
                WHEN (ISNULL(ra.MissedCount, 0) >= 1 OR ISNULL(ra.LateCount, 0) >= 2)
                     AND (
                            fl.DisbursedAmount IS NOT NULL
                        AND fl.DisbursedAmount - ISNULL(ra.TotalPrincipalPaid, 0) > 0
                     ) THEN 1
                ELSE 0
            END
    FROM dw.FactLoan fl
    LEFT JOIN RepAgg ra
        ON ra.LoanID = fl.LoanID;

END;
GO

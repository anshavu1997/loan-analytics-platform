-- Creating the stored procedures Load_DimCustomer to load the customer

CREATE OR ALTER PROCEDURE dw.usp_Load_DimCustomer
AS
BEGIN
    SET NOCOUNT ON;

    WITH DedupStage AS (
        SELECT
              CustomerID
            , FirstName
            , LastName
            , DOB
            , Email
            , Phone
            , AddressLine1
            , City
            , State
            , PostalCode
            , Country
            , CreatedDate
            , ROW_NUMBER() OVER (
                  PARTITION BY CustomerID
                  ORDER BY 
                        CASE 
                            WHEN CreatedDate IS NULL THEN 1 
                            ELSE 0 
                        END,  
                        CreatedDate DESC,
                        CustomerID      
              ) AS rn
        FROM stg.DimCustomer
        WHERE CustomerID IS NOT NULL    
    ),
    FinalCustomers AS (
        SELECT
              CustomerID
            , FirstName
            , LastName
            , DOB
            , Email
            , Phone
            , AddressLine1
            , City
            , State
            , PostalCode
            , Country
            , CreatedDate
        FROM DedupStage
        WHERE rn = 1                     
    )

    MERGE dw.DimCustomer AS tgt
    USING FinalCustomers AS src
        ON tgt.CustomerID = src.CustomerID
    WHEN MATCHED THEN
        UPDATE SET
              tgt.FirstName    = src.FirstName
            , tgt.LastName     = src.LastName
            , tgt.DOB          = src.DOB
            , tgt.Email        = src.Email
            , tgt.Phone        = src.Phone
            , tgt.AddressLine1 = src.AddressLine1
            , tgt.City         = src.City
            , tgt.State        = src.State
            , tgt.PostalCode   = src.PostalCode
            , tgt.Country      = src.Country
            , tgt.CreatedDate  = src.CreatedDate   
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
              CustomerID
            , FirstName
            , LastName
            , DOB
            , Email
            , Phone
            , AddressLine1
            , City
            , State
            , PostalCode
            , Country
            , CreatedDate
        )
        VALUES (
              src.CustomerID
            , src.FirstName
            , src.LastName
            , src.DOB
            , src.Email
            , src.Phone
            , src.AddressLine1
            , src.City
            , src.State
            , src.PostalCode
            , src.Country
            , src.CreatedDate
        );

END;
GO

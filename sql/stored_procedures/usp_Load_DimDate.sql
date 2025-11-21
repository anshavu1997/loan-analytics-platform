
--Created the dimDate table to load the time
CREATE OR ALTER PROCEDURE dw.usp_Load_DimDate
    @StartDate DATE = '2020-01-01',
    @EndDate   DATE = '2030-12-31'
AS
BEGIN
    SET NOCOUNT ON;

   
    IF @EndDate < @StartDate
    BEGIN
        RAISERROR('End date must be greater than or equal to start date.', 16, 1);
        RETURN;
    END;

   
    DECLARE @CurrentDate DATE = @StartDate;

    WHILE @CurrentDate <= @EndDate
    BEGIN
        DECLARE @Year         SMALLINT;
        DECLARE @Month        TINYINT;
        DECLARE @Day          TINYINT;
        DECLARE @Quarter      TINYINT;
        DECLARE @DateKey      INT;
        DECLARE @MonthName    NVARCHAR(20);
        DECLARE @DayOfWeek    NVARCHAR(20);

        SET @Year      = YEAR(@CurrentDate);
        SET @Month     = MONTH(@CurrentDate);
        SET @Day       = DAY(@CurrentDate);
        SET @Quarter   = ((@Month - 1) / 3) + 1;
        SET @DateKey   = (@Year * 10000) + (@Month * 100) + @Day; 
        SET @MonthName = DATENAME(MONTH, @CurrentDate);
        SET @DayOfWeek = DATENAME(WEEKDAY, @CurrentDate);

       
        IF NOT EXISTS (
            SELECT 1 
            FROM dw.DimDate 
            WHERE DateKey = @DateKey
        )
        BEGIN
            INSERT INTO dw.DimDate (
                  DateKey
                , [Date]
                , [Year]
                , [Quarter]
                , [Month]
                , MonthName
                , [Day]
                , DayOfWeekName
            )
            VALUES (
                  @DateKey
                , @CurrentDate
                , @Year
                , @Quarter
                , @Month
                , @MonthName
                , @Day
                , @DayOfWeek
            );
        END;

        SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
    END;
END;
GO

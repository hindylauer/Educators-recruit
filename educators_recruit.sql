-- Educators Recruit business scenario implementation in T-SQL
-- This script creates the schema, loads sample data, and produces the requested reports.

/*
    Clean up previous run (if any)
*/
IF OBJECT_ID('dbo.Educator', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Educator;
END;
GO

/*
    Table definition capturing educator demographics, education background,
    and placement lifecycle with the recruiting company.
*/
CREATE TABLE dbo.Educator
(
    EducatorID        INT            IDENTITY(1, 1) PRIMARY KEY,
    FirstName         NVARCHAR(50)   NOT NULL,
    LastName          NVARCHAR(50)   NOT NULL,
    DateOfBirth       DATE           NOT NULL,
    Gender            NVARCHAR(10)   NOT NULL,
    CollegeAttended   NVARCHAR(100)  NOT NULL,
    DegreeTitle       NVARCHAR(100)  NOT NULL,
    DiscoveryChannel  NVARCHAR(50)   NOT NULL,
    DateContacted     DATE           NOT NULL,
    SchoolPlaced      NVARCHAR(100)  NULL,
    DatePlaced        DATE           NULL,
    CONSTRAINT CK_Educator_DatePlaced_AfterContact CHECK
        (DatePlaced IS NULL OR DatePlaced >= DateContacted),
    CONSTRAINT CK_Educator_Gender CHECK
        (Gender IN (N'female', N'male')),
    CONSTRAINT CK_Educator_DiscoveryChannel CHECK
        (DiscoveryChannel IN (N'magazine', N'newspaper', N'social media', N'social media site', N'word of mouth')),
    CONSTRAINT CK_Educator_ContactedAfterFounding CHECK
        (DateContacted >= '2017-02-17'),
    CONSTRAINT CK_Educator_ContactedAfterBirth CHECK
        (DateContacted >= DateOfBirth),
    CONSTRAINT CK_Educator_PlacementConsistency CHECK
        ((SchoolPlaced IS NULL AND DatePlaced IS NULL)
         OR (SchoolPlaced IS NOT NULL AND DatePlaced IS NOT NULL))
);
GO

/*
    Sample data provided by the business owner.
*/
INSERT INTO dbo.Educator
    (FirstName, LastName, DateOfBirth, Gender, CollegeAttended,
     DegreeTitle, DiscoveryChannel, DateContacted, SchoolPlaced, DatePlaced)
VALUES
    ('Mary',     'Lynn',    '2000-09-13', 'female', 'Excelsior College',       'BA in Mathematics Education', 'magazine',          '2022-05-02', 'Brooklyn High School',      '2022-05-09'),
    ('Josh',     'Frank',   '1998-04-23', 'male',   'Georgia State University', 'MA in Social Studies Education', 'social media site', '2022-02-12', 'Manhattan Elementary School', '2022-05-09'),
    ('Charles',  'Smith',   '1994-07-09', 'male',   'Excelsior College',       'PhD in Education',             'social media site', '2021-08-07', 'New York City Day School',    '2021-08-12'),
    ('Samantha', 'Brown',   '1999-09-24', 'female', 'Columbia University',     'BA in English Education',      'newspaper',         '2021-05-23', 'Brooklyn High School',       '2021-07-30'),
    ('Howard',   'Lang',    '1998-08-04', 'male',   'Georgia State University', 'MA in History Education',      'word of mouth',     '2022-01-31', NULL,                         NULL),
    ('Sarah',    'Blanks',  '1995-10-20', 'female', 'Columbia University',     'MA in Science Education',      'social media',      '2020-05-23', 'New York City Day School',    '2020-08-17'),
    ('Ella',     'Lewis',   '2000-08-22', 'female', 'Excelsior College',       'BA in English Education',      'word of mouth',     '2022-04-01', NULL,                         NULL),
    ('Julie',    'Goldman', '1997-03-30', 'female', 'University of Denver',    'MA in Social Studies Education','social media',      '2020-07-14', 'Manhattan Elementary School', '2020-08-17');
GO

/*
    1. Count of educators placed within 14 days of first contact, grouped by college.
*/
SELECT
    CollegeAttended,
    COUNT(*) AS PlacedWithin14Days
FROM dbo.Educator
WHERE
    DatePlaced IS NOT NULL
    AND DATEDIFF(DAY, DateContacted, DatePlaced) <= 14
GROUP BY CollegeAttended
ORDER BY PlacedWithin14Days DESC, CollegeAttended;
GO

/*
    2. Placement success by gender (number of educators placed).
*/
SELECT
    Gender,
    COUNT(*) AS PlacedEducators
FROM dbo.Educator
WHERE DatePlaced IS NOT NULL
GROUP BY Gender;
GO

/*
    3. Average contacts per day and discovery channel performance.
       - Overall contacts per distinct day.
       - Average contacts per day per discovery channel (normalized to distinct contact days per channel).
*/
-- Overall average contacts per day
SELECT
    CAST(COUNT(*) AS DECIMAL(10, 2)) / NULLIF(COUNT(DISTINCT DateContacted), 0) AS AvgContactsPerDay
FROM dbo.Educator;
GO

-- Average contacts per day for each discovery channel
WITH ChannelActivity AS
(
    SELECT
        DiscoveryChannel,
        COUNT(*) AS TotalContacts,
        COUNT(DISTINCT DateContacted) AS ActiveDays
    FROM dbo.Educator
    GROUP BY DiscoveryChannel
)
SELECT
    DiscoveryChannel,
    TotalContacts,
    ActiveDays,
    CAST(TotalContacts AS DECIMAL(10, 2)) / NULLIF(ActiveDays, 0) AS AvgContactsPerActiveDay
FROM ChannelActivity
ORDER BY DiscoveryChannel;
GO

/*
    4. Average placements per day.
*/
SELECT
    CAST(COUNT(*) AS DECIMAL(10, 2)) / NULLIF(COUNT(DISTINCT DatePlaced), 0) AS AvgPlacementsPerDay
FROM dbo.Educator
WHERE DatePlaced IS NOT NULL;
GO

/*
    5. Daily placements broken out by degree title.
*/
SELECT
    DegreeTitle,
    DatePlaced,
    COUNT(*) AS EducatorsPlaced
FROM dbo.Educator
WHERE DatePlaced IS NOT NULL
GROUP BY DegreeTitle, DatePlaced
ORDER BY DegreeTitle, DatePlaced;
GO

/*
    6. Contact list displaying first name, last name, age, and degree title.
       Age is calculated relative to the current date.
*/
SELECT
    FirstName,
    LastName,
    DATEDIFF(YEAR, DateOfBirth, CAST(GETDATE() AS DATE))
        - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, DateOfBirth, CAST(GETDATE() AS DATE)), DateOfBirth) > CAST(GETDATE() AS DATE)
               THEN 1 ELSE 0 END AS Age,
    DegreeTitle
FROM dbo.Educator
ORDER BY LastName, FirstName;
GO

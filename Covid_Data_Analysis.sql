USE CovidPandemic
GO


-- 1.Total cases and Total deaths in the World until 2022-03-31
-- The Result is:
-- 488 437 812 - 6 143 147

SELECT location, total_cases, total_deaths
FROM [dbo].[Covid19]
WHERE date = '2022-03-31' AND location = 'World'
GO


-- 2.Total cases and Total deaths per location until 2022-03-31 
-- The Result is:
-- Europe: 180 559 221 - 1 772 895;
-- North America: 94 614 384 - 1 414 214
-- Asia: 140 133 240 - 1 407 331
-- South America: 56 052 817 - 1 287 819
-- European Union: 126 603 619 - 1 048 447
-- United States: 80 102 065 - 980 638
-- Brazil: 29 951 670 - 660 022
-- India: 43 025 775 - 521 181
-- Russia: 17 583 111 - 361 348

SELECT location, total_cases, total_deaths
FROM [dbo].[Covid19]
WHERE date = '2022-03-31'
ORDER BY total_deaths DESC
GO


-- 3.Total deaths, life expectancy, human development index per location
-- The Human Development Index is a statistic composite index of life expectancy, education, and per capita income indicators,
-- which are used to rank countries into four tiers of human development.
-- The Result is:
-- Norway: 2 518 - 82,4 - 0,957
-- Switzerland: 13 564 - 83,78 - 0,955
-- Ireland: 6 753 - 82,3 - 0,955
-- Iceland: 101 - 82,99 - 0,949
-- Hong Kong: 7 825 - 84,86 - 0,949
-- Germany: 129 708 - 81,33 - 0.947
-- Sweden: 18 365 - 82,8 - 0,945

SELECT location, total_deaths, life_expectancy, human_development_index
FROM [dbo].[Covid19]
WHERE date = '2022-03-31' AND human_development_index IS NOT NULL
ORDER BY  human_development_index DESC
GO


-- 4.Total deaths per location, Total deaths in the world and Percent of total deaths per location until 2022-03-31 
-- The Result is:
-- Europe: 1 772 895 - 6 143 147 - 28,85
-- North America: 1 414 214 - 6 143 147 - 23,02
-- Asia: 1 407 331 - 6 143 147 - 22,90
-- South America: 1 287 819 - 6 143 147 - 20,96
-- European Union: 1 048 447 - 6 143 147 - 17,06
-- United States: 980 638 - 6 143 147 - 15,96
-- Brazil: 660 022 - 6 143 147 - 10,74
-- India: 521 181 - 6 143 147 - 8,48
-- Russia: 361 348 - 6 143 147 - 5,88

SELECT location, total_deaths,
total_deaths_world = MAX(total_deaths) Over(),
percent_of_total_deaths = total_deaths / MAX(total_deaths) Over() * 100
FROM [dbo].[Covid19]
WHERE date = '2022-03-31'
ORDER BY percent_of_total_deaths DESC
GO


-- 5.Which are the top 5 locations with the least new cases of Covid-19 on date '2022-03-31'
-- The Result is:
-- Micronesia(country) - 1
-- Saint Helena - 4
-- Marshall Islands - 7
-- Vatican - 29
-- Macao - 82

SELECT location, total_cases,
[Rank by total_case] = DENSE_RANK() OVER(ORDER BY total_cases)
INTO #Total_Cases_per_Location
FROM [dbo].[Covid19]
WHERE date = '2022-03-31'

SELECT location, total_cases
FROM #Total_Cases_per_Location
WHERE [Rank by total_case] <= 5
ORDER BY [Rank by total_case]

DROP TABLE #Total_Cases_per_Location
GO


-- 6.Which are the top 5 locations with the most deaths of Covid-19 until date '2022-03-31'
-- The Result is:
-- World - 6 143 147
-- Upper middle income - 2 488 891
-- High income - 2 310 201
-- Europe - 1 772 895
-- North America - 1 414 214

SELECT location, total_deaths,
[Rank by total_case] = DENSE_RANK() OVER(ORDER BY  total_deaths DESC)
INTO #Total_Deaths_per_Location
FROM [dbo].[Covid19]
WHERE date = '2022-03-31'

SELECT location, total_deaths
FROM #Total_Deaths_per_Location
WHERE [Rank by total_case] <= 5
ORDER BY [Rank by total_case]

DROP TABLE #Total_Deaths_per_Location
GO


-- 7.Which are the locations with zero deaths of Covid-19 until date '2022-03-31'
-- The Result is:
-- Samoa - NULL
-- Vatican - NULL
-- Micronesia (country) - NULL
-- Marshall Islands - NULL
-- Saint Helena - NULL
-- Faikland Islands - NULL
-- Cook Islands - NULL
-- Macao - NULL

WITH CTE
AS
(
SELECT location, total_deaths,
[Rank by total_deaths] = DENSE_RANK() OVER(ORDER BY total_deaths)
FROM [dbo].[Covid19]
WHERE date = '2022-03-31'
)

SELECT CTE.location, CTE.total_deaths
FROM CTE
WHERE CTE.[Rank by total_deaths] = 1
GO


-- 8.Total Deaths by location and Percent of total_deaths in the World
-- The Result is:
-- Europe - 1 772 895 - 28,86%
-- North America - 1 414 214 - 23,02%
-- Asia - 1 407 331 - 22,91%
-- South America - 1 287 819 - 20,96%
-- European Union - 1 048 447 - 17,07%
-- United States - 980 638 - 15,96%
-- Brazil - 660 022 - 10,74%

CREATE FUNCTION dbo.ufnReturnPercentOfTotalDeaths(@New_Deaths INT, @TotalDeaths_WORLD INT)
RETURNS NVARCHAR(8)
AS
	BEGIN
	DECLARE @Percent_of_TotalDeaths DECIMAL(8,2) =  (@New_Deaths * 1.0) / (@TotalDeaths_WORLD * 1.0) * 100
	DECLARE @FinalResult NVARCHAR(8) = Cast(@Percent_of_TotalDeaths AS NVARCHAR) + '%' 
	RETURN @FinalResult
END


DECLARE @total_deaths_WORLD INT = (SELECT total_deaths FROM Covid19 
WHERE date = '2022-03-31' AND location = 'World')

SELECT location, total_deaths,
percent_of_total_deaths = dbo.ufnReturnPercentOfTotalDeaths(total_deaths, @total_deaths_WORLD)
FROM Covid19
WHERE date = '2022-03-31'
ORDER BY total_deaths DESC
GO


-- 9.Which top 10 locations have the most people fully vaccinated until 2022-03-31
-- The Result is:
-- Asia - 3 151 539 386
-- India - 831 238 996
-- Europe - 488 800 282
-- North America - 373 191 530
-- European Union - 326 759 740
-- ...

WITH CTE
AS
(
SELECT location, people_fully_vaccinated,
[rank_people_fully_vaccinated] = DENSE_RANK() OVER(ORDER BY people_fully_vaccinated DESC)
FROM Covid19
WHERE date = '2022-03-31' 
)

SELECT CTE.location, CTE.people_fully_vaccinated
FROM CTE
WHERE CTE.[rank_people_fully_vaccinated] <= 10
GO


-- 10.Which locations have zero people fully vaccinated until 2022-03-31
-- The Result is:
-- Nicaragua
-- Tonga
-- Saint Helena
-- Seychelles
-- Syria
-- Ukraine
-- Vanuatu
-- Iraq
-- Armenia
-- Costa Rica
-- Liberia
-- Brunei
-- Grenada
-- ..
SELECT location, people_fully_vaccinated
FROM Covid19
WHERE date = '2022-03-31'
AND  people_fully_vaccinated IS NULL
GO


-- 11.Create View with Continents, total deaths and total cases until 2022-03-31
-- The Result is:
-- Europe - 1 772 895 - 180 559 221
-- North America - 1 414 214 - 94 614 384
-- Asia - 1 407 331 - 140 133 240
-- South America - 1 287 819 - 56 052 817
-- Africa - 251 953 - 11 558 935
-- Oceania - 8 920 - 5 518 494

CREATE OR ALTER VIEW [Total Deaths and Total Cases per Continent]
AS
SELECT continent, 
[Total deaths] = SUM(total_deaths),
[Total cases] = SUM(total_cases)
FROM Covid19
WHERE date = '2022-03-31' AND continent IS NOT NULL
GROUP BY continent
GO

SELECT * 
FROM [Total Deaths and Total Cases per Continent]
ORDER BY [Total deaths] DESC

-- 12.Create View with people fully vaccinated per continent until 2022-03-31
-- The Result is:
-- Asia - 1 563 968 736
-- South America - 200 510 419
-- Europe - 169 819 686
-- Oceania - 25 297 755
-- Africa - 23 629 867
-- North America - 1 562 707

CREATE OR ALTER VIEW [People fully vaccinated per Continent]
AS
SELECT continent,
[People fully vaccinated] = SUM(people_fully_vaccinated)
FROM Covid19
WHERE date = '2022-03-31' and continent IS NOT NULL
GROUP BY continent
GO

SELECT * 
FROM [People fully vaccinated per Continent]
ORDER BY [People fully vaccinated] DESC


-- 13.Create View with hospitalized patients per countinent until 2022-03-31
-- The Result is:
-- Europe - 63 084 349
-- North America - 37 910 402
-- Asia - 4 439 549
-- Africa - 687 780
-- Oceania - 474 078
-- South America - 327 415

CREATE OR ALTER VIEW [Hospitalized patients]
AS
SELECT continent, 
[hospitalized patients] = SUM(hosp_patients)
FROM Covid19
WHERE continent IS NOT NULL
GROUP BY continent
GO
 
SELECT *
FROM [Hospitalized patients]
ORDER BY [hospitalized patients] DESC


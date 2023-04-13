USE covid_portfolio;

select *
FROM covid_portfolio..covid_deaths
ORDER BY date asc;

-- select *
-- FROM covid_portfolio..covid_vaccinations
-- ORDER BY date asc;

-- Select data that I'm going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_portfolio..covid_deaths
ORDER BY 1,2;

-- Looking at total cases vs Total Deaths
-- Calculating percentage of deaths from confirmed cases
SELECT location, date, total_cases, total_deaths, (1.0 * total_deaths/total_cases) * 100
FROM covid_portfolio..covid_deaths
WHERE location like '%kingdom%'
ORDER BY 1,2;

-- Total cases vs population
SELECT location, date, total_cases, population, (1.0 * total_cases/population) * 100
FROM covid_portfolio..covid_deaths
WHERE location like '%kingdom%'
ORDER BY 1,2;

-- Can group by continent also.
-- Countries with highest infection rate compared to population
SELECT date, location, population, 
MAX(total_cases) AS "highest_infection_count", 
MAX(1.0 * total_cases/population) * 100 AS "Percentage_pop_infected"
FROM covid_portfolio..covid_deaths
-- WHERE location like '%kingdom%'
GROUP BY population, LOCATION, DATE
ORDER BY Percentage_pop_infected DESC;

-- Can group by continent also.
-- Highest death count by location
SELECT LOCATION,
MAX(total_deaths) AS "totaldeath_count", 
MAX(1.0 * total_deaths/population) * 100 AS "Percentage_pop_deaths"
FROM covid_portfolio..covid_deaths
GROUP BY LOCATION
ORDER BY totaldeath_count DESC;

-- Focusing on continent
-- using is null numbers are correct
-- Showing the continents with highest death count

SELECT location,
MAX(total_deaths) AS "totaldeath_count"
FROM covid_portfolio..covid_deaths
WHERE continent is null
GROUP BY location
ORDER BY totaldeath_count DESC;

-- GLOBAL NUMBERS
-- cast converts to datatype

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From covid_deaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- WORKING WITH VACCINATIONS TABLE
-- Joining tables by location and date
select *
FROM covid_vaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date;

-- Total pop vs vaccinations
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(CONVERT(bigint, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date)
AS "rolling_vaccinationcount" -- Converted new_vacc to bigint int overflow error.
FROM covid_deaths cd 
JOIN covid_vaccinations cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2,3;

-- using rolling vaccinations to determine how many people are vaccinated per country
-- CTE version

WITH populationvsvaccination (continent, location, date, population, new_vaccinations, rolling_vaccinationcount)
AS
(
    select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(CONVERT(bigint, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date)
AS "rolling_vaccinationcount" -- Converted new_vacc to bigint int overflow error.
FROM covid_deaths cd 
JOIN covid_vaccinations cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (1.0 * rolling_vaccinationcount/population)
FROM populationvsvaccination

-- TEMP TABLE, create new temporary table
-- DROP TABLE IF exists #Popvaccination_percent;

CREATE TABLE #Popvaccination_percent
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinationcount numeric
)
INSERT INTO #Popvaccination_percent
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(CONVERT(bigint, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date)
AS "rolling_vaccinationcount" -- Converted new_vacc to bigint int overflow error.
FROM covid_deaths cd 
JOIN covid_vaccinations cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2,3

SELECT * FROM #Popvaccination_percent;

-- VIEWS, stores data to be looked at in Tableau
-- Permanent and can be queried
CREATE VIEW Popvaccination_percent AS
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
SUM(CONVERT(bigint, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date)
AS "rolling_vaccinationcount"
FROM covid_deaths cd 
JOIN covid_vaccinations cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
-- ORDER BY 2,3


-- Select existing database
USE CovidProject_1;


--Check that data was imported properly
--SELECT * 
--FROM CovidDeaths
--ORDER BY 3, 4;

--SELECT * 
--FROM CovidVaccinations
--ORDER BY 3, 4;

--EXEC sp_columns CovidDeaths;
--EXEC sp_columns CovidVaccinations;

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


-- Looking at Total Deaths/Cases in each Country
-- DeathRate is percentage of people that died from Covid-19
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathRate
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


-- Looking at a specific country, for example, Canada
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathRate
FROM CovidDeaths
WHERE location LIKE 'Canada'
ORDER BY 1,2;

-- Look at Total Cases/Population in the U.S.
-- CaseRate is percentage of population that has tested positive at some point
SELECT location, date, total_cases, population, (total_cases/population)*100 AS CaseRate
FROM CovidDeaths
WHERE location LIKE 'United States'
ORDER BY 1,2;

-- Looking at Countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS CaseRate
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC;
-- As of 8/15/22, Faeroe Islands have the highest CaseRate



-- Showing Countries with highest death count per population
SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- Investigating Covid across different continents instead of countries


-- Showing the continents with the highest death count per population
SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income' AND location <> 'International'
GROUP BY location
ORDER BY TotalDeathCount DESC;



-- Worldwide statistics

-- Summary by day
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
			SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathRate
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

-- Total overall statistics
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
			SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathRate
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;



-- Looking at Total Vaccination vs Vaccinations

-- Join the two tables

SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
	SUM(CAST(vacc.new_vaccinations as bigint)) OVER (Partition by death.location ORDER BY death.location, death.date) as RollingPeopleVaccinated
FROM CovidDeaths death
JOIN CovidVaccinations vacc 
	ON death.location = vacc.location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL
ORDER BY 2, 3;

-- Use CTE
WITH PopVacc (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
	SUM(CAST(vacc.new_vaccinations as bigint)) OVER (Partition by death.location ORDER BY death.location, death.date) as RollingPeopleVaccinated
FROM CovidDeaths death
JOIN CovidVaccinations vacc 
	ON death.location = vacc.location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/population)*100 FROM PopVacc;


-- TEMP TABLE METHOD

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continet nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
	SUM(CAST(vacc.new_vaccinations as bigint)) OVER (Partition by death.location ORDER BY death.location, death.date) as RollingPeopleVaccinated
FROM CovidDeaths death
JOIN CovidVaccinations vacc 
	ON death.location = vacc.location
	AND death.date = vacc.date

SELECT *, (RollingPeopleVaccinated/population)*100 
FROM #PercentPopulationVaccinated;


-- Creating views to store/explore data later in Tableau
CREATE VIEW PercentPopulationVaccinated AS
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
	SUM(CAST(vacc.new_vaccinations as bigint)) OVER (Partition by death.location ORDER BY death.location, death.date) as RollingPeopleVaccinated
FROM CovidDeaths death
JOIN CovidVaccinations vacc 
	ON death.location = vacc.location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL


CREATE VIEW ContinentStatistics AS
SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income' AND location <> 'International'
GROUP BY location


/*
Final Queries used in Tableau Dashboard
*/


-- 1. 

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as int)) AS total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS DeathRate
FROM CovidDeaths
where continent IS NOT NULL
order by 1,2


-- 2. 

-- We take these out as they are not inluded in the above queries and want to maintain consistency

SELECT location, SUM(CAST(new_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is null 
and location not in ('World', 'European Union', 'International') AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY TotalDeathCount DESC


-- 3. 

SELECT location, population, MAX(total_cases) AS HighestInfectionCount,  MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC



-- 4.


SELECT location, population, date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population, date
ORDER BY PercentPopulationInfected DESC

-- 5.
SELECT CovidDeaths.location, population, MAX(total_cases) AS HighestInfectionCount,  
MAX((total_cases/population))*100 AS PercentPopulationInfected,
MAX((people_vaccinated/population))*100 AS PercentPopulationVaccinated,
MAX((people_fully_vaccinated/population))*100 AS PercentPopulationFullyVaccinated
FROM CovidDeaths
JOIN CovidVaccinations
	ON CovidDeaths.location = CovidVaccinations.location
	AND CovidDeaths.date = CovidVaccinations.date
GROUP BY CovidDeaths.location, population
ORDER BY PercentPopulationInfected DESC



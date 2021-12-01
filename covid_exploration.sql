/* 
COVID-19 Data Exploration
Skills Used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM
	SQL_Practice.dbo.covid_deaths
ORDER BY 3,4 -- order by column 3 and 4 ascending


-- Select Data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM
	SQL_Practice.dbo.covid_deaths
ORDER BY 1, 2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM
	SQL_Practice.dbo.covid_deaths
WHERE LOCATION like '%sing%'
ORDER BY 1, 2

-- Total Cases vs Population
-- Shows what percentage of population infected with covid
SELECT location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
FROM
	SQL_Practice.dbo.covid_deaths
WHERE LOCATION like '%sing%'
ORDER BY 1, 2

-- Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopulationInfected
FROM
	SQL_Practice.dbo.covid_deaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopulationInfected
FROM
	SQL_Practice.dbo.covid_deaths
GROUP BY location, population, date
ORDER BY PercentPopulationInfected DESC


-- BREAKING THINGS DOWN BY CONTINENT
-- Continents with Highest Death Count per Population
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount -- since total_death is originally a nvarchar data type
FROM
	SQL_Practice.dbo.covid_deaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

SELECT continent, SUM(CAST(new_deaths AS INT)) AS TotalDeathCount -- since total_death is originally a nvarchar data type
FROM
	SQL_Practice.dbo.covid_deaths
WHERE continent is not NULL AND location not in ('World', 'European Union', 'International') -- EUropean union is part of europe
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS death_percentage
FROM
	SQL_Practice..covid_deaths
WHERE
	continent is not null -- showing by continent
ORDER BY 1, 2


-- Join both Tables (vaccination and deaths data)
-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one COVID vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --rolling sum within partitioned location by date and location
	--,(RollingPeopleVaccinated/population)*100
FROM
	SQL_Practice..covid_deaths AS dea
JOIN SQL_Practice..covid_vaccination AS vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3

-- USE CTE to perform Calculation on Partition BY in previous query
WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --rolling sum within partitioned location by date and location
	--,(RollingPeopleVaccinated/population)*100
FROM
	SQL_Practice..covid_deaths AS dea
JOIN SQL_Practice..covid_vaccination AS vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not null

)
SELECT *, (RollingPeopleVaccinated/population)*100 
FROM PopvsVac
ORDER BY 2, 3


-- Using TEMP TABLE to perform Calculation on PARTITION BY in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar (255),
	Date datetime,
	Population numeric,
	New_Vaccinations numeric,
	RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --rolling sum within partitioned location by date and location
	--,(RollingPeopleVaccinated/population)*100
FROM
	SQL_Practice..covid_deaths AS dea
JOIN SQL_Practice..covid_vaccination AS vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated/population)*100 
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualzations(Tableau)
USE SQL_Practice
GO
Create View PercentPopulationVaccinated AS 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --rolling sum within partitioned location by date and location
	--,(RollingPeopleVaccinated/population)*100
FROM
	SQL_Practice..covid_deaths AS dea
JOIN SQL_Practice..covid_vaccination AS vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not null



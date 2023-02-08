-- Removing unnecessary data
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccines
--ORDER BY 3,4

-- Select necessary data
SELECT location, date, total_cases, new_cases, total_deaths
FROM PortfolioProject..covidDeaths
ORDER BY 1,2

-- Total Cases vs Total Deaths in Malaysia - %? 
-- Shows likelihood of dying if contracted
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..covidDeaths
WHERE location = 'Malaysia' 
ORDER BY date DESC

-- Looking at Total cases Vs Population
-- Shows % of population that got Covid
SELECT location, date, total_cases, population, (total_deaths/population)*100 AS PopDeathPercentage
FROM PortfolioProject..covidDeaths
WHERE location = 'Malaysia' 
ORDER BY date DESC

-- Country with their highest infection rate / population
SELECT location, population, MAX(total_cases) AS HighestInfection, (MAX(total_cases)/population)*100 AS PopCasePercentage
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
-- HAVING location = 'Malaysia' OR location = 'Singapore'
ORDER BY PopCasePercentage DESC

-- Countries with highest(total) death count / population - needed to cast due to data type nvarchar225
SELECT location, population, MAX(cast(total_deaths as int)) AS TotalDeaths, (MAX(total_deaths)/population)*100 AS DeathsPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
-- HAVING location = 'Malaysia' OR location = 'Singapore'
ORDER BY TotalDeaths DESC

-- Continents with the highest infection rate & death rate - What's the difference btw continent & location - CHECK
SELECT location, MAX(cast(total_cases as int)) AS TotalCase, MAX(cast(total_deaths as int)) AS TotalDeaths 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalCase, TotalDeaths

SELECT continent, MAX(cast(total_cases as int)) AS TotalCase, MAX(cast(total_deaths as int)) AS TotalDeaths 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalCase, TotalDeaths

-- Global daily numbers of cases, deaths, and percentage
SELECT date, SUM(new_cases) AS TotalCase , SUM(CAST(new_deaths as int)) AS TotalDeaths, (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Total case so far globally - Cross checked with google, similar numbers yay!
SELECT SUM(new_cases) AS TotalCase , SUM(CAST(new_deaths as int)) AS TotalDeaths, (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1,2



-- Vaccination numbers & JOINING tables
SELECT *
--SELECT CDEA.continent, CDEA.location, CDEA.date, CDEA.total_cases, CVAC.total_vaccinations
FROM PortfolioProject..CovidDeaths AS CDEA
JOIN PortfolioProject..CovidVaccines AS CVAC
	ON CDEA.location = CVAC.location
	AND CDEA.date = CVAC.date
WHERE CDEA.continent IS NOT NULL
ORDER BY 2,3

-- Total pop & vaccination
SELECT CDEA.continent, CDEA.location, CDEA.date, CDEA.population, CVAC.new_vaccinations,
SUM(CAST(CVAC.new_vaccinations AS bigint)) OVER (PARTITION BY CDEA.location ORDER BY CDEA.location, CDEA.date) AS RollingNosVaccinated
FROM PortfolioProject..CovidDeaths AS CDEA
JOIN PortfolioProject..CovidVaccines AS CVAC
	ON CDEA.location = CVAC.location
	AND CDEA.date = CVAC.date
WHERE CDEA.continent IS NOT NULL
ORDER BY 2,3


-- CREATING A CTE < NOTE: THE NUMBER OF VACCINATION INCLUDES MULTIPLE DOSES. EXPLORE MORE 
WITH TOTALPOPVAC AS (
	SELECT CDEA.continent, CDEA.location, CDEA.date, CDEA.population, CVAC.new_vaccinations,
SUM(CAST(CVAC.new_vaccinations AS bigint)) OVER (PARTITION BY CDEA.location ORDER BY CDEA.location, CDEA.date) AS RollingNosVaccinated
FROM PortfolioProject..CovidDeaths AS CDEA
JOIN PortfolioProject..CovidVaccines AS CVAC
	ON CDEA.location = CVAC.location
	AND CDEA.date = CVAC.date
WHERE CDEA.continent IS NOT NULL
)

SELECT *, (RollingNosVaccinated/population)*100 AS VaccineRatePerPop
FROM TOTALPOPVAC

-- SAME THING, BUT TRYING OUT TEMP TABLE
-- DROP TABLE if exists PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingnosvaccinated numeric
)

INSERT INTO PercentPopulationVaccinated
SELECT CDEA.continent, CDEA.location, CDEA.date, CDEA.population, CVAC.new_vaccinations,
SUM(CAST(CVAC.new_vaccinations AS bigint)) OVER (PARTITION BY CDEA.location ORDER BY CDEA.location, CDEA.date) AS RollingNosVaccinated
FROM PortfolioProject..CovidDeaths AS CDEA
JOIN PortfolioProject..CovidVaccines AS CVAC
	ON CDEA.location = CVAC.location
	AND CDEA.date = CVAC.date
WHERE CDEA.continent IS NOT NULL

SELECT *, (RollingNosVaccinated/population)*100 AS VaccineRatePerPop
FROM PercentPopulationVaccinated

-- Creating view for visualizations
USE PortfolioProject
GO
CREATE VIEW PercentPopulationVaccinatedViz AS
SELECT CDEA.continent, CDEA.location, CDEA.date, CDEA.population, CVAC.new_vaccinations,
SUM(CAST(CVAC.new_vaccinations AS bigint)) OVER (PARTITION BY CDEA.location ORDER BY CDEA.location, CDEA.date) AS RollingNosVaccinated
FROM PortfolioProject..CovidDeaths AS CDEA
JOIN PortfolioProject..CovidVaccines AS CVAC
	ON CDEA.location = CVAC.location
	AND CDEA.date = CVAC.date
WHERE CDEA.continent IS NOT NULL


SELECT *
FROM PercentPopulationVaccinatedViz
SELECT * 
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 3,4

-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, ((total_deaths/total_cases)*100) as DeathPercentage
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Likelihood of Death if contracted COVID in the United States
SELECT location, date, total_cases, total_deaths, ((total_deaths/total_cases)*100) as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

--Looking at what percent of population got COVID in the United States
SELECT location, date, total_cases, population, ((total_cases/population)*100) as PopulationPercent
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

-- Looking at Countries with highest infection rates compared to Population
SELECT location,population,  max(total_cases) as HighestInfectionCount , (max(total_cases/population)*100) as PopulationPercentInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location,population
ORDER BY PopulationPercentInfected desc

-- Looking at the countries with the highest death count per Population
SELECT location,  max(cast(total_deaths as INT)) as DeathCount 
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY DeathCount desc

-- Looking at the countries with the highest death count per Population based on Continents
SELECT continent,  max(cast(total_deaths as INT)) as DeathCount 
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY DeathCount desc

-- Looking at the Global Numbers
SELECT date, SUM(new_cases) as TotalNewCases, SUM(cast(new_deaths as INT)) as TotalNewdeaths, (SUM(cast(new_deaths as INT))/SUM(new_cases)) *100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY DeathPercentage desc

-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3

-- Looking at Total Cumulative Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(int, vac.new_vaccinations)) OVER (Partition By dea.location ORDER BY dea.location, dea.date) as CumulativeVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3


-- Looking at Total number of people vaccinated in a country 
-- USE CTE
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, CumulativeVaccinations)
AS(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(int, vac.new_vaccinations)) OVER (Partition By dea.location ORDER BY dea.location, dea.date) as CumulativeVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
)
SELECT *, (CumulativeVaccinations/Population)*100
FROM PopvsVac

-- TEMP TABLE
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
CumulativeVaccinations numeric
)

INSERT into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(int, vac.new_vaccinations)) OVER (Partition By dea.location ORDER BY dea.location, dea.date) as CumulativeVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
SELECT *, (CumulativeVaccinations/Population)*100 as PopulationVaccinated
FROM #PercentPopulationVaccinated

-- Creating View to store data for later Visualizations

CREATE VIEW PercentPopulationVaccinatedview as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(int, vac.new_vaccinations)) OVER (Partition By dea.location ORDER BY dea.location, dea.date) as CumulativeVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL

SELECT *
FROM PercentPopulationVaccinatedview



--Queries used for Tableau Dashboard

-- 1. Total Cases, Deaths and Percentage of Deaths Globally

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 
order by 1,2

-- 2. Total Deaths per continent
-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe
Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc


-- 3. Percentage of Population Infected based on location

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc


-- 4.  Percentage of Population Infected based on location and Dates

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population, date
order by PercentPopulationInfected desc





Select *
From PortfolioProject..CovidDeaths
Where continent is not NULL
order by 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--order by 3,4

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2

-- looking at Total Cases vs Total Deaths
-- Shows what percentage of population got Covid

Select Location, date, Population, total_cases, total_deaths, (total_cases/population)*100 as PercentagePopulationInfected 
From PortfolioProject..CovidDeaths
--Where location like '%states%'
order by 1,2


--Looking at countries with highest infection rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected 
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by location, population
order by PercentPopulationInfected desc


--Showing countries with highest death count per population

Select Location, MAX(Cast(total_deaths as int)) as TotalDeathCount 
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not NULL
Group by location
order by TotalDeathCount desc

--LET'S BREAK THIS DOWN BY CONTINENT

Select location, MAX(Cast(total_deaths as int)) as TotalDeathCount 
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is NULL
Group by location
order by TotalDeathCount desc


--Global Numbers
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)), SUM(cast(new_deaths as int))/SUM(New_cases)*100 as DeathPercentage 
From PortfolioProject..CovidDeaths 
--Where location like '%states%'
Where continent is not NULL
--Group by date
order by 1,2


--Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/Popolation)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


--CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/Population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac 

--TEMP TABLE


Create Table #PercentagePopulationVaccinated
(
Continent nvarchar(225),
Location nvarchar(225),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPopulationVaccinated numeric
)


Insert into #PercentagePopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/Population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

Select *, (RollingPopulationVaccinated/Population)*100
From #PercentagePopulationVaccinated

--Creating view to store data for later vizualization


USE PortfolioProject;
GO

IF OBJECT_ID('PercentagePopulationVaccinated') IS NOT NULL
    DROP VIEW PercentagePopulationVaccinated;
GO

CREATE VIEW PercentagePopulationVaccinated AS
SELECT 
     dea.continent, dea.location, dea.date, dea.population,
    vac.new_vaccinations, vac.total_vaccinations, vac.people_vaccinated,
    SUM(CONVERT(INT, vac.new_vaccinations)) 
        OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
    (SUM(CONVERT(INT, vac.new_vaccinations)) 
        OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) * 1.0 / dea.population) * 100 AS PercentageVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;



SELECT name, schema_id
FROM sys.views
WHERE name = 'PercentagePopulationVaccinated';

SELECT TOP 18000 * FROM dbo.PercentagePopulationVaccinated;


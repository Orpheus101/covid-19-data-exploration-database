/*

PROJECT: COVID-19 DATA EXPLORATION DATABASE: PortfolioProject TOOLS: Microsoft SQL Server (T-SQL)

PROJECT OVERVIEW: This project explores global COVID-19 data to analyze infection rates, mortality, population impact, and vaccination progress across countries and continents.

KEY ANALYSIS AREAS:

1. Explore and prepare COVID-19 data.
2. Analyze total cases versus total deaths.
3. Calculate infection rates relative to population.
4. Identify countries with the highest infection rates.
5. Compare reported COVID-19 death counts across countries.
6. Analyze reported death counts by continent.
7. Calculate global daily cases, deaths, and death percentages.
8. Analyze cumulative vaccination progress.
9. Use temporary tables and views to support further analysis
   and visualization.

NOTE: This analysis uses reported data. Results depend on the completeness, definitions, and quality of the underlying dataset.

*/

/*
DATA EXPLORATION PURPOSE: Inspect the COVID-19 deaths dataset and review the available records. Filtering out rows without a continent helps focus subsequent queries on country-level records rather than aggregate geographic entries.

*/

SELECT * FROM PortfolioProject..CovidDeaths WHERE continent IS NOT NULL ORDER BY 3, 4;

/* Optional: Inspect the vaccination dataset to understand its structure before joining it with the deaths dataset. */

-- SELECT * -- FROM PortfolioProject..CovidVaccinations -- ORDER BY 3, 4;

/*
SELECT THE DATA REQUIRED FOR ANALYSIS PURPOSE: Retrieve the key fields required for analyzing cases, deaths, dates, and population figures.

*/

SELECT Location, date, total_cases, new_cases, total_deaths, population FROM PortfolioProject..CovidDeaths WHERE continent IS NOT NULL ORDER BY Location, date;

/*
TOTAL CASES VS. TOTAL DEATHS 

BUSINESS QUESTION: What proportion of reported COVID-19 cases resulted in reported deaths?

SCOPE: Morocco.

METRIC: Reported cumulative deaths divided by reported cumulative cases, expressed as a percentage.

NOTE: This is a reported case-fatality percentage, not an individual's probability of dying after infection.

*/

SELECT Location, date, total_cases, total_deaths, ROUND( CAST(total_deaths AS FLOAT) / NULLIF(total_cases, 0) * 100, 2 ) AS DeathPercentage FROM PortfolioProject..CovidDeaths WHERE Location LIKE '%Moroc%' AND continent IS NOT NULL ORDER BY Location, date;

/*
TOTAL CASES VS. POPULATION 

BUSINESS QUESTION: What percentage of Morocco's population had been reported as COVID-19 cases over time?

METRIC: Cumulative reported cases divided by population, expressed as a percentage.

NOTE: This represents reported cumulative cases relative to population. It does not necessarily represent the number of unique people infected.

*/

SELECT Location, date, total_cases, population, ROUND( CAST(total_cases AS FLOAT) / NULLIF(population, 0) * 100, 2 ) AS InfectionPercentage FROM PortfolioProject..CovidDeaths WHERE Location LIKE '%Moroc%' AND continent IS NOT NULL ORDER BY Location, date;

/*
COUNTRIES WITH THE HIGHEST INFECTION RATES 

BUSINESS QUESTION: Which countries recorded the highest cumulative case counts relative to their populations?

METHOD: Group records by country and population, identify the maximum reported total case count, and calculate that count as a percentage of population.

*/

SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, ROUND( MAX(CAST(total_cases AS FLOAT)) / NULLIF(population, 0) * 100, 2 ) AS InfectedPopulationPercentage FROM PortfolioProject..CovidDeaths WHERE continent IS NOT NULL GROUP BY Location, population ORDER BY InfectedPopulationPercentage DESC;

/*
COUNTRIES WITH THE HIGHEST REPORTED COVID-19 DEATH COUNTS 

BUSINESS QUESTION: Which countries recorded the highest cumulative COVID-19 death counts?

METHOD: Convert total_deaths to an integer, then identify the maximum reported cumulative death count for each country.

NOTE: This section ranks absolute death counts, not deaths relative to population.

*/

SELECT Location, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount FROM PortfolioProject..CovidDeaths WHERE continent IS NOT NULL GROUP BY Location ORDER BY HighestDeathCount DESC;

/*
CONTINENT-LEVEL REPORTED DEATH COUNTS 

BUSINESS QUESTION: How do the highest reported cumulative death counts compare across continent-level records?

METHOD: Identify the maximum reported cumulative death count within each continent group.

NOTE: This calculates a maximum, not the sum of deaths across all countries within each continent.

*/

SELECT continent, MAX(CAST(total_deaths AS INT)) AS HighestReportedDeathCount FROM PortfolioProject..CovidDeaths WHERE continent IS NOT NULL GROUP BY continent ORDER BY HighestReportedDeathCount DESC;

/*
GLOBAL DAILY CASES, DEATHS, AND DEATH PERCENTAGE 

BUSINESS QUESTION: How did daily reported COVID-19 cases and deaths change over time?

METHOD: Aggregate new cases and new deaths by date across records with a non-null continent, then calculate daily reported deaths as a percentage of daily reported cases.

CTE: The totals CTE simplifies the aggregation before the final calculation.

INTERPRETATION: This is a daily ratio, not the cumulative case-fatality percentage.

*/

;WITH totals AS ( SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths FROM PortfolioProject..CovidDeaths WHERE continent IS NOT NULL GROUP BY date ) SELECT date, total_cases, total_deaths, ROUND( CAST(total_deaths AS FLOAT) / NULLIF(total_cases, 0) * 100, 2 ) AS DeathPercentage FROM totals ORDER BY date;

/*
CUMULATIVE VACCINATION ANALYSIS 

BUSINESS QUESTION: How did reported vaccination counts accumulate over time within each country, and how do those counts compare with the population?

METHOD: Join the deaths and vaccination datasets by location and date. Use a window function to calculate a running total of new vaccinations for each location.

WINDOW FUNCTION: SUM() OVER (PARTITION BY location ORDER BY date)

NOTE: The running total is based on reported new_vaccinations values. It should not automatically be interpreted as unique individuals vaccinated because reporting definitions and dose counts may differ.

*/

;WITH PopvsVac AS ( SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER ( PARTITION BY dea.location ORDER BY dea.date ROWS UNBOUNDED PRECEDING ) AS RollingPeopleVaccinated FROM PortfolioProject..CovidDeaths AS dea INNER JOIN PortfolioProject..CovidVaccinations AS vac ON dea.location = vac.location AND dea.date = vac.date WHERE dea.continent IS NOT NULL ) SELECT *, ROUND( CAST(RollingPeopleVaccinated AS FLOAT) / NULLIF(population, 0) * 100, 2 ) AS RollingPopVacVsPop FROM PopvsVac ORDER BY location, date;

/*
TEMPORARY TABLE: CUMULATIVE VACCINATION 

ANALYSIS PURPOSE: Store the joined vaccination data and running totals in a temporary table so that the results can be queried repeatedly during further analysis.

BENEFIT: Temporary tables are useful for intermediate calculations, validation, and preparing datasets for subsequent queries.

SCOPE: The #PercentPopulationVaccinated table exists only for the current SQL Server session while it remains available.

*/

DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated ( continent NVARCHAR(255), location NVARCHAR(255), date DATETIME, population NUMERIC, new_vaccinations NUMERIC, RollingPeopleVaccinated NUMERIC );

INSERT INTO #PercentPopulationVaccinated ( continent, location, date, population, new_vaccinations, RollingPeopleVaccinated ) SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER ( PARTITION BY dea.location ORDER BY dea.date ROWS UNBOUNDED PRECEDING ) AS RollingPeopleVaccinated FROM PortfolioProject..CovidDeaths AS dea INNER JOIN PortfolioProject..CovidVaccinations AS vac ON dea.location = vac.location AND dea.date = vac.date WHERE dea.continent IS NOT NULL;

/* Validate the temporary table and calculate cumulative reported vaccinations as a percentage of population. */

SELECT *, ROUND( CAST(RollingPeopleVaccinated AS FLOAT) / NULLIF(population, 0) * 100, 2 ) AS RollingPopVacVsPop FROM #PercentPopulationVaccinated ORDER BY location, date;

/*
CREATE A VIEW FOR VISUALIZATION PURPOSE: Create a reusable database view containing vaccination data and cumulative vaccination calculations for dashboards and reporting.

POTENTIAL USE CASES:

- Power BI dashboards
- Tableau visualizations
- SQL-based reporting
- Further exploratory analysis

NOTE: A view stores the query definition rather than a separate snapshot of its results. The underlying tables must remain accessible.

*/

CREATE VIEW dbo.PercentPopulationVaccinatedView AS SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER ( PARTITION BY dea.location ORDER BY dea.date ROWS UNBOUNDED PRECEDING ) AS RollingPeopleVaccinated FROM PortfolioProject..CovidDeaths AS dea INNER JOIN PortfolioProject..CovidVaccinations AS vac ON dea.location = vac.location AND dea.date = vac.date WHERE dea.continent IS NOT NULL; GO

/* Example: Retrieve data from the view for downstream reporting. */

SELECT * FROM dbo.PercentPopulationVaccinatedView ORDER BY location, date;

# COVID-19 Data Exploration Database

This project analyzes global COVID-19 data using Microsoft SQL Server (T-SQL). It explores infection trends, death counts, vaccination progress, and population impact using the `PortfolioProject` database.

## Project overview

This portfolio project answers important epidemiology and public health questions such as:

- What proportion of reported cases resulted in reported deaths?
- Which countries had the highest infection rates relative to population?
- Which countries had the highest cumulative death counts?
- How do daily global cases and deaths compare over time?
- How have vaccination totals accumulated across countries and dates?

## Database and table structure

This script assumes the following tables exist in the `PortfolioProject` database:

- `dbo.CovidDeaths`
- `dbo.CovidVaccinations`

## Included analysis

- Data inspection and filtering of non-country rows
- Case vs. death analysis
- Infection rate by population
- Highest infection rate countries
- Highest death count countries
- Continent-level death comparisons
- Daily global cases and deaths
- Cumulative vaccination tracking with window functions
- Temporary table creation for intermediate analysis
- View creation for reporting and dashboard use

## SQL file

- `COVID-19-DATA-EXPLORATION-DATABASE.sql`

## How to use

1. Open SQL Server Management Studio (SSMS) or Azure Data Studio.
2. Connect to your SQL Server instance.
3. Ensure the `PortfolioProject` database is available.
4. Run the script in `COVID-19-DATA-EXPLORATION-DATABASE.sql`.

## Notes

This analysis relies on reported public health data. Results depend on the quality, completeness, and definitions used in the source dataset.

/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Looking at total "deaths per case", sorted by columns 1&2, to keep it in chronological order
-- The likelihood of dying if you contract COVID19 in Bulgaria between 2020-03-08 and 2021-04-30

SELECT
  location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deaths_per_case
FROM
  COVID.covid_deaths
Where
  location = "Bulgaria"
ORDER BY
  1, 2;

-- Looking at Total Cases in Population
-- Shows what percentage of the population got COVID 19 between 2020-03-08 and 2021-04-30

SELECT
  location, date, total_cases, population, (total_cases/population)*100 AS total_cases_percentage
FROM
  COVID.covid_deaths
WHERE
  location = "Bulgaria"
ORDER BY
  1, 2;

-- Looking at countries with the highest infection rate per country

SELECT
  location, max(total_cases) AS highest_infection_count, population, max((total_cases/population))*100 AS highest_total_cases
FROM
  COVID.covid_deaths
GROUP BY 
  location, population
ORDER BY
  highest_total_cases desc;

-- Looking at the mortality rate per country as a percentage

SELECT
  location, max(total_deaths) AS max_total_deaths, population, max((total_deaths/population))*100 AS mortality_rate
FROM
  COVID.covid_deaths
GROUP BY 
  location, population
ORDER BY
  mortality_rate desc;

-- Looking at the total death count per country,
-- incl. the mortality_rate on the side for better context

SELECT
  location, max(total_deaths) AS max_total_deaths, population, max((total_deaths/population))*100 AS mortality_rate
FROM
  COVID.covid_deaths
WHERE
  continent is not null
GROUP BY 
  location, population
ORDER BY
  max_total_deaths desc;

-- Looking at the total death count per continent,
-- incl. the mortality_rate on the side for better context

SELECT
  continent, max(total_deaths) AS max_total_deaths, max((total_deaths/population))*100 AS mortality_rate
FROM
  COVID.covid_deaths
WHERE
  continent is not null
GROUP BY 
  continent
ORDER BY
  max_total_deaths desc;

-- GLOBAL NUMBERS
-- "new_cases" and "new_deaths" had to be used instead of their "total" counterparts, as otherwise "Group By Date" won't work properly.
-- the numbers in the end are the same as the um of all new deaths are what 'total_deaths' is based on.

SELECT
  date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS global_deaths_per_case
FROM
  COVID.covid_deaths
WHERE
  continent is not null
GROUP BY
  date
ORDER BY
  1, 2;

-- GLOBAL NUMBERS: total cases, deaths and % of deaths per the number of cases.

SELECT
  SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS global_deaths_per_case
FROM
  COVID.covid_deaths
WHERE
  continent is not null
ORDER BY
  1, 2;

-- Joining the two major tables, so we can properly use them going forwards.

SELECT
  *
FROM
  COVID.covid_deaths AS dea
Join
  COVID.covid_vaccinations AS vac
  on dea.location = vac.location
  and dea.date = vac.date;

-- Looking at the vaccination rates by countries

-- The following CTE is necesarry due to issues surrounding the work of rollout_vaccines with some functions.

WITH PopVsVac
AS
(
SELECT
  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollout_vaccines
FROM
  COVID.covid_deaths AS dea
JOIN
  COVID.covid_vaccinations AS vac
  on dea.location = vac.location
  and dea.date = vac.date
WHERE
  dea.continent is not null
ORDER BY
  2, 3
)
SELECT
  *, (rollout_vaccines/population)*100
FROM
  PopVsVac

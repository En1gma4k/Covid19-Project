
/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM [Covid19 Project]..covid_deaths$
ORDER BY location,date

SELECT * 
FROM [Covid19 Project]..covid_vaccinations$
ORDER BY location,date

--Total Cases vs Total Deaths: To show the mortality rate 

SELECT location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 AS death_percentage
FROM [Covid19 Project]..covid_deaths$
WHERE continent IS NOT NULL
ORDER BY location,date

--Total Case vs Population: To show percent of population that contracted covid

SELECT location,date,total_cases,population,(total_cases/population)*100 AS infection_percentage
FROM [Covid19 Project]..covid_deaths$
WHERE continent IS NOT NULL
ORDER BY location,date

-- Countries with highest infection rate 

SELECT location,population, MAX(total_cases) as total_cases, MAX((total_cases/population))*100 AS total_infected_percentage
FROM [Covid19 Project]..covid_deaths$
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY total_infected_percentage DESC

-- Countries with highest death count compared to its population

SELECT location,population,MAX(CAST(total_deaths AS BIGINT)) as highest_total_deaths, MAX(total_deaths/population)*100 AS total_death_percentage
FROM [Covid19 Project]..covid_deaths$
WHERE continent IS NOT NULL
GROUP  BY location,population
ORDER BY total_death_percentage DESC

--Highest death count by countries

SELECT location, MAX(CAST(total_deaths AS BIGINT)) AS total_death 
FROM [Covid19 Project]..covid_deaths$
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY total_death DESC

-- Total world cases, death & death percentage by date

SELECT date,SUM(new_cases) AS total_world_cases, 
SUM(CAST(new_deaths AS INT)) AS total_world_death,
(SUM(CAST(new_deaths AS INT)))/(SUM(new_cases))*100 AS infected_death_percentage 
--cannot use total_cases & total_deaths becasuse using Group By, Casted new_deaths as int because its a nvar255 char
FROM [Covid19 Project]..covid_deaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date

--Joing Deaths & Vaccination tables 

SELECT* 
FROM [Covid19 Project]..covid_deaths$ CD
JOIN [Covid19 Project]..covid_vaccinations$ CV
     ON CD.location = CV.location
     AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY CD.location,CD.date

--World stats for cases, deaths, total test & vaccination

SELECT SUM(CD.new_cases) AS Total_Cases,
SUM(CAST(CD.new_deaths AS INT)) AS Total_Deaths,
SUM(CAST(CV.new_tests AS BIGINT)) AS Total_Tests,
SUM(CAST(CV.new_vaccinations AS BIGINT)) AS Total_Vaccinations
FROM [Covid19 Project]..covid_deaths$ AS CD
JOIN [Covid19 Project]..covid_vaccinations$ AS CV
     ON CD.location = CV.location
     AND CD.date = CV.date

--Vaccination Cumilative

SELECT location,date, new_vaccinations,people_fully_vaccinated
FROM [Covid19 Project]..covid_vaccinations$
ORDER BY location,date

--Percentage of total people vaccinated

SELECT CD.location,CD.date,CD.population,CV.new_vaccinations,
SUM(CONVERT(BIGINT,CV.new_vaccinations)) OVER(PARTITION BY CD.location ORDER BY CD.location,CD.date) AS vaccination_rolling_count_location
             --partition clause to stop rolling count for each location
FROM [Covid19 Project]..covid_deaths$ CD
JOIN [Covid19 Project]..covid_vaccinations$ CV
      ON CD.date = CV.date
	  AND CD.location = CV.location
ORDER BY location,date

--Percent poppulation vaccinated rolling count
--Using CTE

WITH covid_CTE (location,date,population,new_vaccinations,vaccination_rolling_count_location)
AS
(
SELECT CD.location,CD.date,CD.population,CV.new_vaccinations,
SUM(CONVERT(BIGINT,CV.new_vaccinations)) OVER(PARTITION BY CD.location ORDER BY CD.location,CD.date) AS vaccination_rolling_count_location
             --partition clause to stop rolling count for each location
FROM [Covid19 Project]..covid_deaths$ CD
JOIN [Covid19 Project]..covid_vaccinations$ CV
      ON CD.date = CV.date
	  AND CD.location = CV.location
)
SELECT *, (vaccination_rolling_count_location/population)*100 AS Percent_Population_Vaccinated
FROM covid_CTE
ORDER BY location,date
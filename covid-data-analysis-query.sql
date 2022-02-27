-- Init

Select *
From [covid-deaths]
Where continent is not null
order by 3,4

-- Data selection

Select location, date, total_cases, new_cases, total_deaths, population
From [covid-deaths]
order by 1,2

-- Death by COVID - what are the odds?

Select location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
From [covid-deaths]
-- Where location like '%france'
order by 1,2

-- How many people are infected?

Select location, date, total_cases, new_cases, population, (total_cases/population)*100 as case_percentage
From [covid-deaths]
-- Where location like '%france'
order by 1,2

-- Which country has the highest infection rate?

Select location, population, MAX(total_cases) as highest_infection, MAX((total_cases/population))*100 as infection_percentage
From [covid-deaths]
Group by location, population
order by infection_percentage desc

-- Which country has the highest death rate?

Select location, population, MAX(cast(total_deaths as bigint)) as total_death_count
From [covid-deaths]
Where continent is not null
Group by location, population
order by total_death_count desc

-- Death recap: continent

Select location, MAX(cast(total_deaths as bigint)) as total_death_count
From [covid-deaths]
Where continent is null and location not like '%income' and location not like '%union' and location not like '%world' and location not like '%international'
Group by location
order by total_death_count desc

-- Death recap: financial situation

Select location, MAX(cast(total_deaths as bigint)) as total_death_count
From [covid-deaths]
Where continent is null and location like '%income'
Group by location
order by total_death_count desc

-- Infection recap: financial situation

Select location, MAX(cast(total_cases as bigint)) as total_infection_count
From [covid-deaths]
Where continent is null and location like '%income'
Group by location
order by total_infection_count desc

-- Global recap

Select date, SUM(new_cases) as global_case_count, SUM(cast(new_deaths as bigint)) as global_death_count, SUM(cast(new_deaths as bigint))/SUM(new_cases)*100 as global_death_perc
From [covid-deaths]
Where continent is not null
Group by date
order by 1,2

-- Join tables

Select death.continent, death.location, death.date, death.population, vax.new_vaccinations
, SUM(CONVERT(float, vax.new_vaccinations)) OVER (Partition by death.location Order by death.location
, death.date) as rolling_vax
From [covid-deaths] death
Join [covid-vax] vax
	on death.location = vax.location
	and death.date = vax.date
Where death.continent is not null
order by 2,3;

-- CTE

With PopvsVax (continent, location, date, population, new_vaccinations, rolling_vax)
as
(
Select death.continent, death.location, death.date, death.population, vax.new_vaccinations
, SUM(CONVERT(float, vax.new_vaccinations)) OVER (Partition by death.location Order by death.location
, death.date) as rolling_vax
From [covid-deaths] death
Join [covid-vax] vax
	on death.location = vax.location
	and death.date = vax.date
Where death.continent is not null
)
Select *, (rolling_vax/population)*100 as vax_per_pop
From PopvsVax

-- Temp

Create Table #vaccinations
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_vax numeric
)

Insert into #vaccinations
Select death.continent, death.location, death.date, death.population, vax.new_vaccinations
, SUM(CONVERT(float, vax.new_vaccinations)) OVER (Partition by death.location Order by death.location
, death.date) as rolling_vax
From [covid-deaths] death
Join [covid-vax] vax
	on death.location = vax.location
	and death.date = vax.date
Select *, (rolling_vax/population)*100 as rolling_vax_percentage
From #vaccinations

-- For dataviz

Create View vaccinations as
Select death.continent, death.location, death.date, death.population, vax.new_vaccinations
, SUM(CONVERT(float, vax.new_vaccinations)) OVER (Partition by death.location Order by death.location
, death.date) as rolling_vax
From [covid-deaths] death
Join [covid-vax] vax
	on death.location = vax.location
	and death.date = vax.date
Where death.continent is not null

Select *
From vaccinations
USE db_projeto_covid
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Fonte: https://ourworldindata.org/covid-deaths
-- Descrição: Informações sobre a pandemia da covid-19
------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Visualizando informações gerais sobre a tabela tb_deaths
sp_help tb_deaths

------------------------------------------------------------------/* ALTERAÇÕES */------------------------------------------------------------------------------
-- Alterando formato das colunas. 
-- Foram exportadas como NVARCHAR(proposital), com isso não estava sendo possível realizar a divisão.
-- REF.: 2.Total de casos vs total de mortes
ALTER TABLE TB_DEATHS ALTER COLUMN total_deaths FLOAT
ALTER TABLE TB_DEATHS ALTER COLUMN total_cases FLOAT
ALTER TABLE TB_VACCINATIONS ALTER COLUMN new_vaccinations FLOAT

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.Informções gerais sobre a tb_deaths
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	location, date, total_cases, total_deaths, new_cases, population
FROM TB_DEATHS
ORDER BY 
	location, date
	
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2.Total de casos vs total de mortes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	location, date, total_cases, total_deaths, 
	(total_deaths/total_cases)*100 AS DeathsPercentage 
FROM TB_DEATHS
ORDER BY 
	location, date

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3.Total de casos vs total de mortes nos 'states'
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	location, date, total_cases, total_deaths,
	(total_deaths/total_cases)*100 AS DeathsPercentage 
FROM TB_DEATHS
WHERE
			location LIKE '%STATES%'
AND 	continent IS NOT NULL
ORDER BY 
	location, date
	
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4.Casos totais vs população
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	location, date, population, total_cases, 
	(total_cases/population)*100 AS	CasesPercentage
FROM TB_DEATHS
WHERE
	continent IS NOT NULL
ORDER BY 
	location, date

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 5.Taxa de infecção vs população
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	location, population, 
	MAX(total_cases) AS MaxCases, 
	MAX((total_cases/population))*100 AS	PopulationPercentageInfected
FROM TB_DEATHS
WHERE
	continent IS NOT NULL
GROUP BY 
	location, population
ORDER BY 
	PopulationPercentageInfected DESC
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 6.Paises com maior número de mortes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	RANK () OVER(ORDER BY MAX(total_deaths)DESC) AS [Ranking],
	location, population, 
	MAX(total_deaths)                                                     AS TotalDeaths, 
	MAX(total_deaths/population)*100                          AS DeathsPercentagePopulations
FROM TB_DEATHS
WHERE
	continent IS NOT NULL
GROUP BY 
	location, population

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 7. Continentes com maior número de mortes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	RANK () OVER(ORDER BY MAX(total_deaths)DESC) AS [Ranking], 
	continent, 
	MAX(total_deaths)													   AS TotalDeaths, 
	MAX(total_deaths/population)*100                          AS DeathsPercentagePopulations
FROM TB_DEATHS
WHERE
	continent IS  NOT NULL
GROUP BY 
	continent
ORDER BY MAX(total_deaths) DESC

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 8. Continentes com maior número de mortes por ppopulação
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	RANK () OVER(ORDER BY MAX(total_deaths)DESC) AS [Ranking],
	continent,
	MAX(population)													       AS TotalPopulation , 
	MAX(total_deaths)                                                     AS TotalDeaths
	--MAX(total_deaths/population)*100 AS DeathsPercentagePopulations
FROM TB_DEATHS, SELECT FROM TB_DEATHS
WHERE
	continent IS  NOT NULL
GROUP BY 
	continent
ORDER BY MAX(total_deaths) DESC

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 9. Números globais
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	 date, total_cases, total_deaths,
	ROUND((total_deaths/total_cases)*100,2) AS DeathsPercentage 
FROM TB_DEATHS
WHERE
	continent IS NOT NULL
AND total_cases IS NOT NULL
ORDER BY 
	 date

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 9. Total de casos por pais
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	RANK () OVER(ORDER BY MAX(total_cases)DESC) AS [Ranking],
	location, population, MAX(total_cases)                  AS TotalCasos,
	MAX(total_deaths)                                                  AS TotalDeaths, 
	MAX(total_deaths/population)*100                       AS DeathsPercentagePopulations
FROM TB_DEATHS
WHERE
	continent IS NOT NULL
GROUP BY 
	location, population


	-- DETALHES POR CONTINENTE
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10. %Total Geral mortes e população por continente
------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT 
	continent,
	TotalPopulation,
	TotalDeaths,
	FORMAT(SUM(TotalDeaths)/SUM(SUM(TotalDeaths)) OVER(), 'P') AS TotalGeralDeaths
	--FORMAT(SUM(TotalPopulation)/SUM(SUM(TotalPopulation)) OVER(), 'P') AS TotalGeralPopulation
FROM(
			SELECT 
				continent,
				MAX(population)   AS TotalPopulation , 
				MAX(total_deaths) AS TotalDeaths
			FROM TB_DEATHS
			WHERE continent IS  NOT NULL
			GROUP BY continent) TB
GROUP BY continent, TotalPopulation, TotalDeaths
ORDER BY 3 DESC

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 10. %Total Geral mortes e população por continente
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	 --date,
	 SUM(new_cases)   AS total_cases,
	 SUM(new_deaths) AS total_deaths,
	 NULLIF(SUM(new_deaths),0)/ SUM(CAST(new_cases AS INT))*100 AS deaths_percentage
FROM TB_DEATHS
WHERE
	continent IS NOT NULL
--GROUP BY 
--	date
ORDER BY 
	1,2

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 11. Analisando total populacao vs vacinas
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.date) AS people_vaccinated
FROM TB_DEATHS AS dea
JOIN TB_VACCINATIONS AS vac ON dea.location = vac.location 
												   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 12. Analisando total populacao vs vacinas
------------------------------------------------------------------------------------------------------------------------------------------------------------------------

WITH PopsVac (continent, location, date, population, new_vaccinations,people_vaccinated )
AS (
		SELECT 
			dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
			SUM(vac.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.date) AS people_vaccinated
		FROM TB_DEATHS AS dea
		JOIN TB_VACCINATIONS AS vac ON dea.location = vac.location 
														   AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL
)
SELECT * , (people_vaccinated/population)*100
FROM PopsVac

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 13. Criando tabela temporária
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS #population_vacination

CREATE TABLE #population_vacination (
	continent			     varchar(100),
	location			     varchar(100),
	date					     date,
	population             float,
	new_vaccination    float,
	people_vaccinated float
)

INSERT INTO #population_vacination
	SELECT 
			dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
			SUM(vac.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.date) AS people_vaccinated
		FROM TB_DEATHS AS dea
		JOIN TB_VACCINATIONS AS vac ON dea.location = vac.location 
														   AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL

SELECT * FROM #population_vacination


------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 14. Criando view
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW vw_population_vacination AS 
	SELECT 
			dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
			SUM(vac.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.date) AS people_vaccinated
		FROM TB_DEATHS AS dea
		JOIN TB_VACCINATIONS AS vac ON dea.location = vac.location 
														   AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL

SELECT * FROM vw_population_vacination
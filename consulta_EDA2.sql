-- Análise exploratória dos dados

-- Verificando o nome e o tipo das variáveis
SELECT 
  column_name, 
  data_type 
FROM 
  rj-cetrio.desafio.INFORMATION_SCHEMA.COLUMNS 
WHERE 
  table_name = 'readings_2024_06';

-- Convertendo as variáveis do tipo byte para base64
-- Subconsulta para converter colunas BYTES para Base64
WITH base64_converted AS (
  SELECT
    TO_BASE64(placa) AS placa_base64,
    TO_BASE64(empresa) AS empresa_base64,
    TO_BASE64(tipoveiculo) AS tipoveiculo_base64,
    velocidade,
    TO_BASE64(camera_numero) AS camera_numero_base64,
    camera_latitude,
    camera_longitude,
    datahora,
    datahora_captura
  FROM
    rj-cetrio.desafio.readings_2024_06
)
-- Consulta principal para retornar os dados codificados em Base64
SELECT
  placa_base64 AS placa,
  empresa_base64 AS empresa,
  tipoveiculo_base64 AS tipoveiculo,
  velocidade,
  camera_numero_base64 AS camera_numero,
  camera_latitude,
  camera_longitude,
  datahora,
  datahora_captura
FROM
  base64_converted;

-- Contando o número total de registros na tabela
SELECT COUNT(*) AS total_registros FROM `rj-cetrio.desafio.readings_2024_06`;

-- Verificando a quantidade de registros nulos e inválidos para cada coluna
SELECT
  COUNTIF(placa IS NULL OR LENGTH(placa) = 0) AS num_placa_invalid,
  COUNTIF(empresa IS NULL OR LENGTH(empresa) = 0) AS num_empresa_invalid,
  COUNTIF(tipoveiculo IS NULL OR LENGTH(tipoveiculo) = 0) AS num_tipoveiculo_invalid,
  COUNTIF(velocidade IS NULL OR velocidade < 0) AS num_velocidade_invalid,
  COUNTIF(camera_numero IS NULL OR LENGTH(camera_numero) = 0) AS num_camera_numero_invalid,
  COUNTIF(camera_latitude IS NULL OR camera_latitude NOT BETWEEN -90 AND 90) AS num_camera_latitude_invalid,
  COUNTIF(camera_longitude IS NULL OR camera_longitude NOT BETWEEN -180 AND 180) AS num_camera_longitude_invalid,
  COUNTIF(datahora IS NULL) AS num_datahora_invalid,
  COUNTIF(datahora_captura IS NULL) AS num_datahora_captura_invalid
FROM
  `rj-cetrio.desafio.readings_2024_06`;

-- Resumo estatístico das colunas numéricas
SELECT
  COUNT(*) AS quant_total,
  AVG(velocidade) AS media_velocidade,
  MIN(velocidade) AS min_velocidade,
  MAX(velocidade) AS max_velocidade,
  STDDEV(velocidade) AS desviopadrao_velocidade,
  AVG(camera_latitude) AS media_camera_latitude,
  MIN(camera_latitude) AS min_camera_latitude,
  MAX(camera_latitude) AS max_camera_latitude,
  STDDEV(camera_latitude) AS desviopadrao_camera_latitude,
  AVG(camera_longitude) AS media_camera_longitude,
  MIN(camera_longitude) AS min_camera_longitude,
  MAX(camera_longitude) AS max_camera_longitude,
  STDDEV(camera_longitude) AS desviopadrao_camera_longitude
FROM
  rj-cetrio.desafio.readings_2024_06;

-- Verificando se existe uma correlação entre velocidade e as coordenadas latitude e longitude
SELECT
  CORR(velocidade, camera_latitude) AS corr_velocidade_latitude,
  CORR(velocidade, camera_longitude) AS corr_velocidade_longitude
FROM
  rj-cetrio.desafio.readings_2024_06;

-- Contagem e frequência das variáveis categóricas empresa e placa e calculando a proporção
-- Olhando as empresas
WITH empresa_counts AS (
  SELECT
    TO_BASE64(empresa) AS empresa_base64,
    COUNT(*) AS frequency
  FROM
    `rj-cetrio.desafio.readings_2024_06`
  GROUP BY
    empresa_base64
  ORDER BY
    frequency DESC
),
total_empresas AS (
  SELECT
    COUNT(*) AS total
  FROM
    `rj-cetrio.desafio.readings_2024_06`
),
distinct_plates AS (
  SELECT
    TO_BASE64(empresa) AS empresa_base64,
    COUNT(DISTINCT TO_BASE64(placa)) AS placas_distintas
  FROM
    `rj-cetrio.desafio.readings_2024_06`
  GROUP BY
    empresa_base64
)

SELECT
  ec.empresa_base64,
  ec.frequency,
  ROUND((ec.frequency / te.total) * 100, 2) AS proporcao_registros,
  dp.placas_distintas,
  ROUND((dp.placas_distintas / te.total) * 100, 2) AS proporcao_placas_distintas
FROM
  empresa_counts ec
  CROSS JOIN total_empresas te
  INNER JOIN distinct_plates dp ON ec.empresa_base64 = dp.empresa_base64
ORDER BY
  ec.frequency DESC;

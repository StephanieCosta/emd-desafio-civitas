/*
Estratégia para identificar possíveis placas clonadas
primeira parte: tentar identificar veículos com a mesma placa detectados em locais e horários muito diferentes (indicando a impossibilidade física de ser o mesmo veículo)
*/
WITH base_data AS (
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
    `rj-cetrio.desafio.readings_2024_06`
),

cloned_plates AS (
  SELECT
    t1.placa_base64,
    t1.datahora AS t1_datahora,
    t2.datahora AS t2_datahora,
    t1.camera_latitude AS t1_latitude,
    t1.camera_longitude AS t1_longitude,
    t2.camera_latitude AS t2_latitude,
    t2.camera_longitude AS t2_longitude,
    ST_DISTANCE(ST_GEOGPOINT(t1.camera_longitude, t1.camera_latitude), ST_GEOGPOINT(t2.camera_longitude, t2.camera_latitude)) AS distance_meters,
    ABS(TIMESTAMP_DIFF(t1.datahora, t2.datahora, SECOND)) AS time_diff_seconds,
    'clonada' AS status_clonagem
  FROM
    base_data t1
  JOIN
    base_data t2 ON t1.placa_base64 = t2.placa_base64
                  AND t1.datahora < t2.datahora
  WHERE
    ST_DISTANCE(ST_GEOGPOINT(t1.camera_longitude, t1.camera_latitude), ST_GEOGPOINT(t2.camera_longitude, t2.camera_latitude)) > 1000 -- Distância mínima em metros para considerar clonagem (1000 metros = 1 km)
    AND ABS(TIMESTAMP_DIFF(t1.datahora, t2.datahora, SECOND)) < 3600 -- Tempo máximo em segundos para considerar clonagem (3600 segundos = 1 hora)
),

-- Calculando a proporção de placas clonadas e não clonadas
labeled_data AS (
  SELECT
    IF(cloned_plates.placa_base64 IS NOT NULL, 'clonada', 'não clonada') AS status_clonagem,
    COUNT(*) AS count
  FROM
    cloned_plates
  GROUP BY
    status_clonagem
)

-- Incluindo os dados originais e a informação de clonagem
SELECT
  base_data.*,
  COALESCE(cloned_plates.status_clonagem, 'não clonada') AS status_clonagem
FROM
  base_data
LEFT JOIN
  cloned_plates
ON
  base_data.placa_base64 = cloned_plates.placa_base64
  AND base_data.datahora = cloned_plates.t1_datahora
ORDER BY
  base_data.datahora;

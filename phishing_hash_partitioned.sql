USE TrendPhishing;

-- 1. 테이블이 이미 존재하면 삭제
DROP TABLE IF EXISTS phishing_hash_partitioned;

-- 2. report_id 기준 해시 파티셔닝 테이블 생성
CREATE TABLE phishing_hash_partitioned (
  report_id INT NOT NULL,
  type VARCHAR(20),
  method VARCHAR(20),
  damage_amount INT,
  year INT,
  month INT,
  age INT,
  gender VARCHAR(20),
  region VARCHAR(20),
  phishing_value VARCHAR(50),
  PRIMARY KEY (report_id)
)
PARTITION BY HASH (report_id)
PARTITIONS 8;

INSERT INTO phishing_hash_partitioned
SELECT DISTINCT
  report_id, type, method, damage_amount, year,
  month, age, gender, region, phishing_value
FROM phishing_report;

SELECT SQL_NO_CACHE * 
FROM phishing_hash_partitioned
WHERE year = 2020;

SELECT SQL_NO_CACHE *
FROM phishing_hash_partitioned
WHERE region = '경기도';

SELECT SQL_NO_CACHE year, region, COUNT(*) AS cases, AVG(damage_amount) AS avg_damage
FROM phishing_hash_partitioned
WHERE year >= 2022
  AND damage_amount >= 5000
GROUP BY year, region
ORDER BY year, cases DESC;


SELECT SQL_NO_CACHE
    region,
    COUNT(*) AS case_count,
    SUM(damage_amount) AS total_damage,
    ROUND(AVG(damage_amount), 2) AS avg_damage
FROM phishing_hash_partitioned
WHERE age >= 40
  AND region IN ('서울특별시', '경기도', '인천광역시')
GROUP BY region
ORDER BY total_damage DESC;

SELECT
  TABLE_NAME,
  PARTITION_NAME,
  TABLE_ROWS
FROM INFORMATION_SCHEMA.PARTITIONS
WHERE TABLE_NAME = 'phishing_hash_partitioned';



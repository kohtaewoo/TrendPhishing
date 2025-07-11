-- 1. 간단한 조건 시 성능(range)

SELECT SQL_NO_CACHE * 
FROM phishing_report
WHERE year = 2020;

SELECT SQL_NO_CACHE * 
FROM phishing_list_partitioning
WHERE year = 2020;


-- 2. 간단한 조건 시 성능(list)
-- 비파티셔닝 테이블
SELECT SQL_NO_CACHE * 
FROM phishing_report
WHERE region = '경기도';

SELECT SQL_NO_CACHE * 
FROM phishing_list_partitioning
WHERE region = '경기도';


-- 3. 최근 3년 (2022~2024년) 중 5000만 원 이상 피해 사건만 조회
SELECT SQL_NO_CACHE year, region, COUNT(*) AS cases, AVG(damage_amount) AS avg_damage
FROM phishing_report
WHERE year >= 2022
  AND damage_amount >= 5000
GROUP BY year, region
ORDER BY year, cases DESC;

SELECT SQL_NO_CACHE year, region, COUNT(*) AS cases, AVG(damage_amount) AS avg_damage
FROM phishing_list_partitioning
WHERE year >= 2022
  AND damage_amount >= 5000
GROUP BY year, region
ORDER BY year, cases DESC;


-- 4. 40대 이상이고, 수도권의 피해 금액 합계 및 평균을 지역별로 계산
SELECT SQL_NO_CACHE
    region,
    COUNT(*) AS case_count,
    SUM(damage_amount) AS total_damage,
    ROUND(AVG(damage_amount), 2) AS avg_damage
FROM phishing_report
WHERE age >= 40
  AND region IN ('서울특별시', '경기도', '인천광역시')
GROUP BY region
ORDER BY total_damage DESC;


SELECT SQL_NO_CACHE
    region,
    COUNT(*) AS case_count,
    SUM(damage_amount) AS total_damage,
    ROUND(AVG(damage_amount), 2) AS avg_damage
FROM phishing_list_partitioning
WHERE age >= 40
  AND region IN ('서울특별시', '경기도', '인천광역시')
GROUP BY region
ORDER BY total_damage DESC;








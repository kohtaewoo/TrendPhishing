# 대용량 데이터를 활용한 RDBMS 파티셔닝 프로젝트

대용량 데이터를 처리할 떄 쿼리의 처리 속도에 파티셔닝이 미치는 영향을 분석한 프로젝트입니다.

## 👥 팀 소개
| <img width="150px" src="https://avatars.githubusercontent.com/u/52108628?v=4"/>  | <img width="150px" src="https://avatars.githubusercontent.com/u/45265805?v=4"/> | <img width="150px" src="https://avatars.githubusercontent.com/u/81912226?v=4"> | <img width="150px" src="https://avatars.githubusercontent.com/u/188286798?v=4"> | 
| :---: | :---: | :---: | :---: |
| **고태우**    | **박지원**        | **정서현**        | **황지환**        | 
| [@kohtaewoo](https://github.com/kohtaewoo) | [@bbo9866](https://github.com/bbo9866) | [@hyunn522](https://github.com/hyunn522) | [@jihwan77](https://github.com/jihwan77) |

## 📌 파티셔닝이란?

**파티셔닝**(Partitioning)은 하나의 큰 테이블을 **논리적으로 분할**하여 관리하는 기법으로, 대용량 데이터 환경에서 **성능 향상 및 유지보수 효율성**을 위해 사용됩니다.

### 파티셔닝의 목적

- 📈 **쿼리 처리 속도 개선**: 데이터 `SELECT`, `UPDATE`, `DELETE` 시 `WHERE` 절에 파티션 키가 포함되면, 해당 파티션만 스캔하여 성능이 향상됩니다.
  
- 🛠 **관리 편의성 증가**: 파티션 단위로 데이터 삭제, 백업, 아카이빙이 가능합니다.
  
- 🔁 **병렬 처리 최적화**: 여러 파티션을 병렬로 처리함으로써 처리 효율이 높아집니다.

---

### 파티셔닝 방식

| 유형 | 설명 | 특징 |
| --- | --- | --- |
| **Range Partitioning** | 특정 범위 기준으로 분할 | 시간 흐름 기반 로그/이력에 적합 |
| **List Partitioning** | 특정 값의 목록 기준 분할 | 값의 종류가 명확할 때 적합 |
| **Hash Partitioning** | 해시 값을 기준으로 균등 분할 | 특정 컬럼에 고르게 분산이 필요할 때 |
| **Composite Partitioning** | 여러 기준을 결합해 분할 | 복잡한 조건의 분할이 필요한 경우 |

---

### 적용 전략

이번 프로젝트에서는 **보이스피싱 신고 데이터**를 대상으로 아래와 같은 파티셔닝 전략 적용 및 성능 비교를 진행하였습니다.

#### 1. 📆 **Range 파티셔닝** (`발생 연도` 기준)

- `신고 연도`를 2018~2024년까지를 각 연도별로 파티셔닝
- **시간 흐름에 따라 증가**하는 데이터에 적합

#### 2. 📍 **List 파티셔닝** (`지역` 기준)

- `신고 지역`을 `서울`, `부산`, `경기` 등 주요 지역별로 파티셔닝
- **분포가 균등**한 데이터에 적합

## 📁 데이터 소개

가상의 보이스피싱 신고 데이터를 csv 형태로 50만 건 생성한 후 DBeaver에서 import하여 진행하였습니다.

테이블 구조는 다음과 같습니다.

<img width="751" height="386" alt="image" src="https://github.com/user-attachments/assets/965867e5-87ff-49eb-9d52-5684f8b11deb" />

## ⚙️ 기술 스택

- `MySQL` : v8.0.42

- `Prometheus` : 

- `Grafana` : 

## 💻 실행 플로우

### 1. List Partitioning

다음 쿼리문을 통해 지역에 따라 리스트 파티션을 진행하였습니다.

```sql
CREATE TABLE phishing_range_partitioned(
	report_id int,
	type varchar(20),
	method varchar(20),
	damage_amount int,
	year int,
	month int,
	age int,
	gender varchar(20),
	region varchar(20),
	phishing_value varchar(50),
	primary key (report_id, year)
)
partition by range (year) (

	partition p2018 values less than (2018),
	partition p2019 values less than (2019),
	partition p2020 values less than (2020),
	partition p2021 values less than (2021),
	partition p2022 values less than (2022),
	partition p2023 values less than (2023),
	partition p2024 values less than (2024),
	partition pmax values less than (MAXVALUE)
);

-- 년도별 파티션 테이블 확인
SELECT
  TABLE_NAME,
  PARTITION_NAME,
  TABLE_ROWS
FROM INFORMATION_SCHEMA.PARTITIONS
WHERE TABLE_NAME = 'phishing_range_partitioned';
```

생성된 리스트 파티션을 확인하면 다음과 같다.

<img width="594" height="287" alt="image" src="https://github.com/user-attachments/assets/bf78962c-1713-4c93-b8de-1ca758654dbe" />

---

### 2. Range Partitioning

다음 쿼리문을 통해 연도에 따라 Range Partitioning을 진행하였습니다.

```sql
CREATE TABLE phishing_list_partitioning (
    report_id INT,
    type VARCHAR(20),
    method VARCHAR(20),
    damage_amount INT,
    year INT,
    month INT,
    age INT,
    gender VARCHAR(20),
    region VARCHAR(20),
    phishing_value VARCHAR(50),
    primary key(report_id, region)
)
PARTITION BY LIST COLUMNS (region) (
    PARTITION p_seoul VALUES IN ('서울특별시'),
    PARTITION p_gyeonggi VALUES IN ('경기도'),
    PARTITION p_incheon VALUES IN ('인천광역시'),
    PARTITION p_chungbuk VALUES IN ('충청북도'),
    PARTITION p_chungnam VALUES IN ('충청남도'),
    PARTITION p_jeonbuk VALUES IN ('전라북도'),
    PARTITION p_jeonnam VALUES IN ('전라남도'),
    PARTITION p_gyeongbuk VALUES IN ('경상북도'),
    PARTITION p_gyeongnam VALUES IN ('경상남도'),
    PARTITION p_jeju VALUES IN ('제주특별시')
);

INSERT INTO phishing_list_partitioning
SELECT * FROM phishing_report
WHERE region IN (
    '서울특별시', '경기도', '인천광역시', '충청북도', '충청남도',
    '전라북도', '전라남도', '경상북도', '경상남도', '제주특별시'
);
```

생성된 레인지 파티션을 확인하면 다음과 같습니다.

<img width="616" height="237" alt="image" src="https://github.com/user-attachments/assets/bc2ef57a-ac36-4f94-b55e-dc1da0ae4e4f" />

---

### 3. 파티셔닝 여부에 따른 성능 비교

#### 1. 파티셔닝 기준 칼럼을 조건으로 검색

```sql
-- Range 파티셔닝
-- 파티셔닝 전
SELECT SQL_NO_CACHE * 
FROM phishing_report 
WHERE year = 2020;

-- 파티셔닝 후
SELECT SQL_NO_CACHE * 
FROM phishing_range_partitioned
WHERE year = 2020;
```

<details>
<summary><strong>📌 파티셔닝 전</strong></summary>

<img width="906" height="262" alt="Image" src="https://github.com/user-attachments/assets/4f7632a2-a684-4afb-b9cf-20a2487db18c" />

⏱ 실행 시간: **1.731초**

</details>

<details>
<summary><strong>📌 Range 파티셔닝 후</strong></summary>

<img width="925" height="239" alt="Image" src="https://github.com/user-attachments/assets/91096db0-4bc6-46ca-aace-760db8fef92c" />

⏱ 실행 시간: **0.739초**

</details>

<details>
<summary><strong>📌 Hash 파티셔닝 후</strong></summary>

<img width="962" height="264" alt="Image" src="https://github.com/user-attachments/assets/d44394a3-fcf7-4330-9969-a3b4f35f9827" />

⏱ 실행 시간: **1.052초**

</details>

---

#### 2. 지역(region) 기준으로 검색 (List 파티셔닝 vs Hash)

```sql
-- List 파티셔닝
-- 파티셔닝 전
SELECT SQL_NO_CACHE * 
FROM phishing_report
WHERE region = '경기도';

-- 파티셔닝 후
SELECT SQL_NO_CACHE *
FROM list_partitioned2
WHERE region = '경기도';
```

<details>
<summary><strong>📌 파티셔닝 전</strong></summary>

<img width="988" height="265" alt="Image" src="https://github.com/user-attachments/assets/4548624d-3358-4345-af68-34a6fd91bccf" />

⏱ 실행 시간: **3.805초**

</details>

<details>
<summary><strong>📌 List 파티셔닝 후</strong></summary>

<img width="995" height="265" alt="Image" src="https://github.com/user-attachments/assets/585bfbc7-1b3f-486e-ace5-90d675a8f9eb" />

⏱ 실행 시간: **1.645초**

</details>

<details>
<summary><strong>📌 Hash 파티셔닝 후</strong></summary>

<img width="964" height="238" alt="Image" src="https://github.com/user-attachments/assets/76df522d-cc9b-42f5-9872-d042396bd693" />

⏱ 실행 시간: **1.782초**

</details>

---

#### 3. 최근 3년(2022~2024), 피해금액 5000만 원 이상 필터

```sql
SELECT SQL_NO_CACHE year, region, COUNT(*) AS cases, AVG(damage_amount) AS avg_damage
FROM phishing_report
WHERE year >= 2022 AND damage_amount >= 5000
GROUP BY year, region
ORDER BY year, cases DESC;
```

<details>
<summary><strong>📌 파티셔닝 전</strong></summary>

<img width="1061" height="239" alt="Image" src="https://github.com/user-attachments/assets/52618a40-db48-4b75-8a3b-05f4776ebfd9" />

⏱ 실행 시간: **2.337초**

</details>

<details>
<summary><strong>📌 Range 파티셔닝 후</strong></summary>

<img width="1162" height="246" alt="Image" src="https://github.com/user-attachments/assets/ab6a5d0a-4535-41dc-8348-45560b9dc5b6" />

⏱ 실행 시간: **0.583초**

</details>

<details>
<summary><strong>📌 List 파티셔닝 후</strong></summary>

<img width="987" height="263" alt="Image" src="https://github.com/user-attachments/assets/8da00332-16f3-4b08-b733-f12308b63188" />

⏱ 실행 시간: **0.886초**

</details>

<details>
<summary><strong>📌 Hash 파티셔닝 후</strong></summary>

<img width="971" height="241" alt="Image" src="https://github.com/user-attachments/assets/9b700f55-513d-4c21-b690-a41c2b66e9d0" />

⏱ 실행 시간: **0.479초**

</details>

---

#### 4. 40대 이상 수도권 대상, 피해 합계/평균 집계

```sql
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
```

<details>
<summary><strong>📌 파티셔닝 전</strong></summary>

<img width="1064" height="211" alt="Image" src="https://github.com/user-attachments/assets/f1fc7e70-9ee9-455e-82b6-70a9982ba70c" />

⏱ 실행 시간: **2.183초**

</details>

<details>
<summary><strong>📌 Range 파티셔닝 후</strong></summary>

<img width="1060" height="237" alt="Image" src="https://github.com/user-attachments/assets/634bc6de-f65f-4b38-8a80-af48e4cff044" />

⏱ 실행 시간: **2.029초**

</details>

<details>
<summary><strong>📌 List 파티셔닝 후</strong></summary>

<img width="983" height="270" alt="Image" src="https://github.com/user-attachments/assets/8e1e5486-a61d-44a6-837b-e8119346614d" />

⏱ 실행 시간: **0.710초**

</details>

<details>
<summary><strong>📌 Hash 파티셔닝 후</strong></summary>

<img width="962" height="234" alt="Image" src="https://github.com/user-attachments/assets/e89bab80-739a-4feb-9cb3-41a15697d130" />

⏱ 실행 시간: **0.880초**

</details>

---

#### 5. AND 조건: 파티셔닝 칼럼 2개 결합

```sql
SELECT *
FROM phishing_report
WHERE year = 2020
  AND region IN ('서울특별시', '경기도');
```

✅ 이 경우는 `year`(RANGE) + `region`(LIST)의 **교집합 조건**을 사용하기 때문에,  
단일 파티션 조건일 때보다 큰 성능 차이가 나지 않음.

→ 두 개 이상의 파티션 키를 쓰는 경우, **서로의 파티션 범위를 먼저 탐색한 뒤 조합**을 찾는 방식이라  
**Range와 List의 성능 차이가 줄어드는 것**이 특징이다.


## 💡 인사이트



## 🚀 트러블슈팅

3. SELECT 쿼리 캐싱 현상

문제 : `SELECT`문을 반복 실행하면 동일한 쿼리에 대해 **쿼리 캐시(Query Cache)**가 적용되어 실행 시간이 실제 시간보다 적게 걸리는 현상

해결책 : **`SQL_NO_CACHE`** 키워드를 사용하여 쿼리 캐싱 없이 실행 가능

```sql
SELECT *  
FROM phishing_list_partitioned
WHERE region = '서울특별시';
```

위 쿼리를 예시로 들자면, `SQL_NO_CACHE` 키워드를 추가하지 않으면 실행 시간이 점차 줄어들어 5번째 실행 시 0.645초가 기록되었다. 반면 `SQL_NO_CACHE` 키워드를 추가하면 모든 실행에서 약 1.14초대로 기록되었다. 


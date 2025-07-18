# 대용량 데이터를 활용한 RDBMS 파티셔닝 프로젝트

> **가상의 보이스피싱 신고 데이터를 활용한** 파티셔닝 전략에 따른 대용량 데이터의 쿼리 실행 속도 분석을 위한 프로젝트입니다.

## 👥 팀 소개
| <img width="150px" src="https://avatars.githubusercontent.com/u/52108628?v=4"/>  | <img width="150px" src="https://avatars.githubusercontent.com/u/45265805?v=4"/> | <img width="150px" src="https://avatars.githubusercontent.com/u/81912226?v=4"> | <img width="150px" src="https://avatars.githubusercontent.com/u/188286798?v=4"> | 
| :---: | :---: | :---: | :---: |
| **고태우**    | **박지원**        | **정서현**        | **황지환**        | 
| [@kohtaewoo](https://github.com/kohtaewoo) | [@bbo9866](https://github.com/bbo9866) | [@hyunn522](https://github.com/hyunn522) | [@jihwan77](https://github.com/jihwan77) |

<br/> 

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

#### 3. 🧮 Hash 파티셔닝 (`id` 기준)

- 파티션 키를 균등하게 분산하여 데이터 쏠림 없이 저장 가능

- **특정 기준으로 나누기 모호**한 데이터에 적합

## 📁 데이터 소개

가상의 보이스피싱 신고 데이터를 csv 형태로 50만 건 생성한 후 DBeaver에서 import하여 진행하였습니다.

테이블 구조는 다음과 같습니다.

<img width="751" height="386" alt="image" src="https://github.com/user-attachments/assets/965867e5-87ff-49eb-9d52-5684f8b11deb" />

## ⚙️ 기술 스택

- `MySQL` : v8.0.42

- `Prometheus`
 	- v2.48.0
    
  	- 매트릭 정보를 수집하여 쿼리 결과만이 아닌 쿼리 속도나 연결 수 네트워크 사용량, 자원 사용량 등의 더 자세한 정보를 시각화하기 위해 사용

- `Grafana`
  	- v12.0.2
  	  
  	- mysql에서의 쿼리 결과물을 시각화 하기 위해 사용

## 💻 실행 플로우

### 1. List Partitioning

다음 쿼리문을 통해 지역에 따라 리스트 파티션을 진행하였습니다.

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

생성된 리스트 파티션을 확인하면 다음과 같습니다.

<img width="594" height="287" alt="image" src="https://github.com/user-attachments/assets/bf78962c-1713-4c93-b8de-1ca758654dbe" />

---

### 2. Range Partitioning

다음 쿼리문을 통해 연도에 따라 Range Partitioning을 진행하였습니다.

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

생성된 레인지 파티션을 확인하면 다음과 같습니다.

<img width="616" height="237" alt="image" src="https://github.com/user-attachments/assets/bc2ef57a-ac36-4f94-b55e-dc1da0ae4e4f" />

---

### 3. Hash Partitioning

다음 쿼리문을 통해 report_id에 따라 해쉬 파티션을 진행하였습니다.

```sql
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

-- 년도별 파티션 테이블 확인
SELECT
  TABLE_NAME,
  PARTITION_NAME,
  TABLE_ROWS
FROM INFORMATION_SCHEMA.PARTITIONS
WHERE TABLE_NAME = 'phishing_range_partitioned';
```

생성된 해쉬 파티션을 확인하면 다음과 같습니다.

<img width="558" height="229" alt="Image" src="https://github.com/user-attachments/assets/2d46b862-6c2b-4f80-9c7b-352c0134c31e" />

---

### 4. 파티셔닝 여부에 따른 성능 비교

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

<details>
<summary><strong>최근 3년 (2022~2024년) 중 5000만 원 이상 피해 사건만 시각화</strong></summary>

<img width="751" height="372" alt="Image" src="https://github.com/user-attachments/assets/091c92e9-9b14-48de-81e0-9741f602645f" />

<img width="1067" height="357" alt="Image" src="https://github.com/user-attachments/assets/c15538cc-511c-4a32-a437-d0cc7757a2a3" />

<img width="1069" height="359" alt="Image" src="https://github.com/user-attachments/assets/14121b9a-82fc-4170-8863-0ddd672e0fbd" />

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

<details>
<summary><strong>40대 이상이고, 수도권의 피해 금액 합계 및 평균을 지역별 시각화</strong></summary>

<img width="1119" height="511" alt="Image" src="https://github.com/user-attachments/assets/47874256-25a2-4791-9ca4-8a0202a2ad51" />

<img width="1092" height="385" alt="Image" src="https://github.com/user-attachments/assets/dfaaab2f-5371-4529-9fe8-ccfd8162ef7b" />

<img width="1099" height="393" alt="Image" src="https://github.com/user-attachments/assets/e2b67061-fd09-435e-83a8-2ed9a909b815" />

</details>

---

#### 5. AND 조건: 파티셔닝 칼럼 2개 결합

```sql
SELECT *
FROM phishing_report
WHERE year = 2020
  AND region IN ('서울특별시', '경기도');
```

`year`(RANGE) + `region`(LIST)의 **교집합 조건**을 사용하기 때문에, 단일 파티션 조건일 때보다 큰 성능 차이가 나지 않습니다.

→ 두 개 이상의 파티션 키를 쓰는 경우, **서로의 파티션 범위를 먼저 탐색한 뒤 조합**을 찾는 방식이라 **Range와 List의 성능 차이가 줄어드는 것**

## 💡 인사이트

1. 분석 목적에 따라 파티셔닝 전략이 달라야 함
   
2. 테이블 용량이 커질수록 파티셔닝 효과가 두드러짐
   
3. 쿼리 성능은 **조건에 파티션 키가 포함될 때**만 향상됨
   
4. Grafana만으로는 커넥션 및 트랜잭션 상태, 쿼리 속도를 수집하지 못함

## 🚀 트러블슈팅

### 파티셔닝

1. **MySQL에서 연관 관계의 테이블 2개에 대해 파티셔닝 불가능**

- 문제 : 참조 무결성 유지 로직이 파티셔닝 엔진과 충돌하기 때문에 여러 테이블들에 대해 파티셔닝 불가능. 연관 관계에 있는 테이블에 대해서 전체 테이블 단위로 외래키 검증이 수행되어야 합니다.

	그러나 MySQL의 파티셔닝 엔진은 각 파티션을 독립적으로 관리하므로 외래키 제약 조건을 지원할 수 없습니다.

- 해결책 : 기존 테이블을 2개에서 1개로 통합

2. **이미 생성된 테이블에 대해 파티션 추가 불가**

- 문제 : CREATE로 생성한 테이블에 대해 ALTER로 파티션 추가 불가

- 원인 : MySQL의 RANGE, LIST 파티셔닝은 정적 방식으로 이루어집니다. 따라서 파티셔닝 후 동적으로 파티션을 추가할 수 없습니다.

- 해결책 : 파티셔닝 테이블 생성 시 파티셔닝을 함께 수행하고 원본 테이블에서 데이터 복사

3. **SELECT 쿼리 캐싱 현상**

- 문제 : `SELECT`문을 반복 실행하면 동일한 쿼리에 대해 **쿼리 캐시**가 적용되어 실행 시간이 실제 시간보다 적게 걸리는 현상

- 해결책 : **`SQL_NO_CACHE`** 키워드를 사용하여 쿼리 캐싱 없이 실행 가능

```sql
SELECT *  
FROM phishing_list_partitioned
WHERE region = '서울특별시';
```

위 쿼리를 예시로 들자면, `SQL_NO_CACHE` 키워드를 추가하지 않으면 실행 시간이 점차 줄어들어 5번째 실행 시 0.645초가 기록되었습니다. 반면 `SQL_NO_CACHE` 키워드를 추가하면 모든 실행에서 약 1.14초대로 기록되었습니다. 

### Promethemus 연동

- 원인 : `mysqld_exporter` 실행 시 다음 오류 발생:
    
    ```
    failed to validate config" section=client err="no user specified in section or parent"
    Error parsing host config" file=.my.cnf err="no configuration found"
    
    ```
    
    서비스가 `Active: failed (Result: exit-code)`로 구동되지 않습니다.

- 해결책 :
  	### **`EnvironmentFile` 방식**

	**설정 경로:**
	
	```bash
	/etc/default/mysqld_exporter
	```
	
	**수정 내용:**
	
	```bash
	DATA_SOURCE_NAME="exporter:MyStrongPassword@(localhost:3306)/"
	```
	
	- `MyStrongPassword` = MySQL에 생성한 exporter 계정의 비밀번호
	
	```bash
	sudo chmod 600 /etc/default/mysqld_exporter
	```
	
	**systemd 서비스 예시:**
	
	```bash
	[Unit]
	Description=Prometheus MySQL Exporter
	After=network.target
	
	[Service]
	User=mysqld_exporter
	EnvironmentFile=/etc/default/mysqld_exporter
	ExecStart=/usr/local/bin/mysqld_exporter
	
	[Install]
	WantedBy=default.target
	```
	
	**서비스 재시작:**

 	```bash
	sudo systemctl daemon-reload
	sudo systemctl restart mysqld_exporter
	sudo systemctl status mysqld_exporter
	```

	<details><summary>모니터링 아키텍처 구조</summary>
	
	```bash
	[MySQL Server]
	   │
	   │ (MySQL 프로세스)
	   │
	[mysqld_exporter]
	   │
	   │ (Metrics HTTP Endpoint :9104)
	   │
	[Prometheus]
	   │
	   │ (scrape: 5초마다 수집)
	   │
	[Grafana]
	```
	
	구현한 모니터링 아키텍처 구조
	
	```
	[MySQL Server]
	   ▲
	   │ (쿼리 실행: SELECT ...)
	   ▼
	[Grafana]
	```

	<img width="1867" height="1012" alt="image" src="https://github.com/user-attachments/assets/c66c10b1-9baa-4a9f-ae64-2c7b7981a333" />

	</details>

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

- 📈 **조회 속도 개선**: WHERE 절에 파티션 키가 포함되면, 해당 파티션만 스캔하여 성능이 향상됩니다.
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

이번 프로젝트에서는 **보이스피싱 신고 데이터**를 대상으로 아래와 같은 파티셔닝 전략을 실험하였습니다.

#### 1. 📆 **Range 파티셔닝** (`발생 연도` 기준)

- `발생일자`의 연도를 기준으로 2020~2024년까지 범위로 나누어 파티셔닝
- 시간 흐름에 따라 자연스럽게 증가하는 데이터에는 **가장 적합**
- 쿼리 성능 개선 효과도 실제로 확인할 수 있었음

#### 2. 📍 **List 파티셔닝** (`지역` 기준)

- `서울`, `부산`, `대전`, `경기` 등 주요 지역별로 분할
- **단점**: 데이터가 특정 지역에 쏠릴 경우, 파티션 간 불균형이 발생
- 실험 결과, 전체 쿼리 성능에는 오히려 불리한 영향도 있을 수 있음
    
    → 📌 **데이터 분포가 균등할 때 더 적합한 방식**이라는 점을 확인함

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

### 2. Range Partitioning

다음 쿼리문을 통해 연도에 따라 Range Partitioning을 진행하였습니다.

```
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

### 3. 파티셔닝 여부에 따른 성능 비교

## 💡 인사이트


## 🚀 트러블슈팅


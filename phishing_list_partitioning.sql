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
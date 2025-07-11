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


insert into phishing_range_partitioned
select * from phishing_report;
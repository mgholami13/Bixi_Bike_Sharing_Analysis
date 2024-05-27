/*
Bixi Project Deliverable 1
By: Majid Gholami
Date: 2023_04_17
BrainStation
*/

USE bixi;

-- Q1. Using the correct SQL queries, calculate and interpret the following:
-- 1.1. The total number of trips for the year of 2016
SELECT 
    COUNT(*) AS Total_trips_2016
FROM
    trips
WHERE 
	YEAR(start_date) = 2016;
    
-- 1.2. The total number of trips for the year of 2017
SELECT 
    COUNT(*) AS Total_trips_2017
FROM
    trips
WHERE 
	YEAR(start_date) = 2017;

-- 1.3. The total number of trips for the year of 2016 broken down by month
SELECT 
    MONTHNAME(start_date) AS Month_,
    COUNT(*) AS Number_Trips
FROM
    trips
WHERE
    YEAR(start_date) = 2016
GROUP BY MONTH(start_date);

-- 1.4. The total number of trips for the year of 2017 broken down by month
SELECT 
    MONTHNAME(start_date) AS Month_,
    COUNT(*) AS Number_Trips
FROM
    trips
WHERE
    YEAR(start_date) = 2017
GROUP BY MONTH(start_date);

-- 1.5. The average number of trips a day for each year-month combination in the dataset
SELECT 
    YEAR(start_date) AS Year_,
    MONTHNAME(start_date) AS Month_,
    (COUNT(DISTINCT DATE(start_date))) AS Number_Days,
	COUNT(*) / (COUNT(DISTINCT DATE(start_date))) AS Avg_Trips_Per_Day
FROM
    trips
GROUP BY YEAR(start_date), MONTH(start_date);

-- 1.6. Save your query results from the previous question (Q1.5) by creating a table called working_table1.
DROP TABLE IF EXISTS working_table1;
CREATE TABLE working_table1 AS
SELECT 
    YEAR(start_date) AS Year_,
    MONTHNAME(start_date) AS Month_,
    (COUNT(DISTINCT DATE(start_date))) AS Number_Days,
	COUNT(*) / (COUNT(DISTINCT DATE(start_date))) AS Avg_Trips_Per_Day
FROM
    trips
GROUP BY YEAR(start_date), MONTH(start_date);

-- Q2. Unsurprisingly, the number of trips varies greatly throughout the year. How about membership status? 
-- Should we expect members and non-members to behave differently? To start investigating that, calculate:

-- 2.1. The total number of trips in the year 2017 broken down by membership status (member/non-member)
SELECT 
    is_member AS Member_status, COUNT(*) AS Total_trips
FROM
    trips
WHERE
    (YEAR(start_date) = 2017)
GROUP BY is_member;

-- 2.2. The percentage of total trips by members for the year 2017 broken down by month
SELECT 
    MONTHNAME(start_date) AS Month_,
    COUNT(*) AS Trips_All,
    SUM(is_member) AS Trips_Members,
    ROUND(100 * AVG(is_member), 1) AS Percentage_MembersRatio
FROM
    trips
WHERE
    YEAR(start_date) = 2017
GROUP BY
    MONTHNAME(start_date)
ORDER BY
    MONTH(start_date);
    

  
-- Q3. Use the above queries to answer the questions below.
-- 3.1. At which time(s) of the year is the demand for Bixi bikes at its peak?
SELECT 
    Members.Year_,
    Members.Month_,
    Members.Total_Number_Trips AS Trips_Members,
    Total.Total_Number_Trips AS Trips_All,
    ROUND(100 * (Members.Total_Number_Trips / Total.Total_Number_Trips), 1) AS Percentage_MembersRatio
FROM
    (SELECT 
        YEAR(start_date) AS Year_, MONTHNAME(start_date) AS Month_,
            COUNT(*) AS Total_Number_Trips
    FROM
        trips
    WHERE
        (is_member = 1)
    GROUP BY YEAR(start_date), MONTHNAME(start_date)) AS Members
INNER JOIN
    (SELECT 
        YEAR(start_date) AS Year_, MONTHNAME(start_date) AS Month_, COUNT(*) AS Total_Number_Trips
    FROM
        trips
    GROUP BY YEAR(start_date), MONTHNAME(start_date)) AS Total 
    ON (Members.Month_ = Total.Month_) AND (Members.Year_ = Total.Year_)
    ORDER BY Year_ DESC, Trips_All DESC;
    
-- 3.2. If you were to offer non-members a special promotion in an attempt to convert them to members, when would you do it? 
-- Describe the promotion and explain the motivation and your reasoning behind it. 

/*
Q4. It is clear now that time of year and membership status are intertwined and influence greatly how people use Bixi bikes. 
Next, let's investigate how people use individual stations, and explore station popularity.
*/

-- 4.1. What are the names of the 5 most popular starting stations? Determine the answer without using a subquery
SELECT 
    s.code AS Station_code, 
    s.name AS Station_name, 
    COUNT(*) AS Number_starts
FROM
    trips AS t
INNER JOIN
    stations AS s ON s.code = t.start_station_code
GROUP BY s.code
ORDER BY Number_starts DESC
LIMIT 5; 

-- 4.2. Solve the same question as Q4.1, but now use a subquery. Is there a difference in query run time between 4.1 and 4.2? Why or why not?
SELECT     
	s.code AS Station_code, 
    s.name AS Station_name,  
    (
    SELECT COUNT(*)
    FROM trips
    WHERE start_station_code = s.code
	) as Number_starts
FROM stations as s
ORDER BY Number_starts DESC
LIMIT 5;

/*
Yes, there is a difference in query run time between 4.1 and 4.2:
4.1. JOIN: 		6.110 sec
4.2. Subquery: 	3.140 sec
Using subquery: This approach can be more efficient than a join, because it only needs to filter the "trips" table by the "start_station_code" for each station
				in the "stations" table, count the number of trips, and return the top 5 stations with the highest number of starts.
Using JOIN: 	This involves combining the "stations" and "trips" tables using a common column (in this case, the station code). Then, the GROUP BY operation 
				groups the results by station code and counts the number of trips for each station which can be computationally expensive. 
*/ 

-- Q5. If we break up the hours of the day as follows:

SELECT COUNT(start_station_code) AS Frequency,
	CASE
       WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "morning"
       WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "afternoon"
       WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "evening"
       ELSE "night"
END AS "time_of_day"
FROM trips
GROUP BY time_of_day;

SELECT COUNT(end_station_code) AS Frequency,
	CASE
       WHEN HOUR(end_date) BETWEEN 7 AND 11 THEN "morning"
       WHEN HOUR(end_date) BETWEEN 12 AND 16 THEN "afternoon"
       WHEN HOUR(end_date) BETWEEN 17 AND 21 THEN "evening"
       ELSE "night"
END AS "time_of_day"
FROM trips
GROUP BY time_of_day;

-- 5.1. How is the number of starts and ends distributed for the station Mackay / de Maisonneuve throughout the day?
SELECT 
	CASE
       WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "morning"
       WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "afternoon"
       WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "evening"
       ELSE "night"
END AS "time_of_day",
COUNT(start_station_code) AS Frequency, start_station_code
FROM trips
WHERE trips.start_station_code = (SELECT code FROM stations WHERE name = 'Mackay / de Maisonneuve') 
GROUP BY time_of_day
ORDER BY FIELD(time_of_day,"morning","afternoon","evening","night");

-- 5.2. Explain and interpret your results from above. Why do you think these patterns in Bixi usage occur for this station? Put forth a hypothesis and justify your rationale.
/*
The pattern of Bixi usage at the Mackay / de Maisonneuve station suggests that it is primarily used by people commuting to and from work or school since it is near Concordia University
 buildings and libraries. The usage is highest in the afternoon and evening, which is when people are likely to be heading home from work or school. The high usage in the morning also 
 suggests that people are using Bixi bikes to get to their place of work or school. The usage drops off at night, which is likely due to people being less likely to use Bixi bikes for 
 leisure purposes during this time. 
*/

/*
Q6. List all stations for which at least 10% of trips are round trips. Round trips are those that start and end in the same station. 
This time we will only consider stations with at least 500 starting trips. (Please include answers for all steps outlined here)
*/
-- 6.1. First, write a query that counts the number of starting trips per station.

SELECT 
    start_station_code, COUNT(*) AS Number_trips
FROM
    trips
GROUP BY start_station_code
ORDER BY Number_trips DESC;

-- 6.2. Second, write a query that counts, for each station, the number of round trips
SELECT 
    start_station_code,
    end_station_code,
    COUNT(*) AS Number_roundtrips
FROM
    trips
WHERE
    start_station_code = end_station_code
GROUP BY start_station_code
ORDER BY Number_roundtrips DESC;

-- 6.3. Combine the above queries and calculate the fraction of round trips to the total number of starting trips for each station
SELECT 
    start_station_code,
	COUNT(*) AS Number_trips,
    SUM(IF(start_station_code = end_station_code, 1, 0)) AS Number_roundtrips,
    ROUND(100 * SUM(IF(start_station_code = end_station_code, 1, 0)) / COUNT(*), 1) AS Percentage_roundtrip_share
FROM
    trips
GROUP BY start_station_code
ORDER BY Percentage_roundtrip_share DESC
LIMIT 50;


-- 6.4. Filter down to stations with at least 500 trips originating from them and having at least 10% of their trips as round trips
SELECT 
    t1.start_station_code,
    t2.end_station_code,
    t1.Number_trips,
    t2.Number_roundtrips,
    ROUND(100 * t2.Number_roundtrips / t1.Number_trips,1) AS Percentage_roundtrip_share
FROM
    (SELECT 
        start_station_code, COUNT(*) AS Number_trips
    FROM
        trips
    GROUP BY start_station_code) AS t1
INNER JOIN
    (SELECT 
        start_station_code,
		end_station_code,
        COUNT(*) AS Number_roundtrips
    FROM
        trips
    WHERE
        start_station_code = end_station_code
    GROUP BY start_station_code) AS t2 ON t1.start_station_code = t2.start_station_code
WHERE (number_trips >=500) AND (t2.Number_roundtrips/t1.Number_trips >= 0.10) 
ORDER BY Percentage_roundtrip_share DESC
limit 50;


-- 6. Where would you expect to find stations with a high fraction of round trips? Describe why and justify your reasoning
SELECT round_stations.start_station_code AS Code_RoundStation, 
		s.name, 
        s.latitude, 
        s.longitude
FROM  
(SELECT 
    t1.start_station_code,
    t2.end_station_code,
    t1.Number_trips,
    t2.Number_roundtrips,
    ROUND(100 * t2.Number_roundtrips / t1.Number_trips,1) AS Percentage_roundtrip_share
FROM
    (SELECT 
        start_station_code, COUNT(*) AS Number_trips
    FROM
        trips
    GROUP BY start_station_code) AS t1
INNER JOIN
    (SELECT 
        start_station_code,
		end_station_code,
        COUNT(*) AS Number_roundtrips
    FROM
        trips
    WHERE
        start_station_code = end_station_code
    GROUP BY start_station_code) AS t2 ON t1.start_station_code = t2.start_station_code
WHERE (number_trips >=500) AND (t2.Number_roundtrips/t1.Number_trips >= 0.10) 
ORDER BY Percentage_roundtrip_share DESC) AS round_stations
JOIN stations AS s ON s.code = round_stations.start_station_code;

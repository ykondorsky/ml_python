-- 
-- Description of BD, tasks and queries:
-- https://docs.google.com/document/d/1hNg5qcr5mgXYd_kW-UA5GuYvq-uMlbIqQNxGKyH4hrY/edit?usp=sharing
--

-- 1
SELECT	city, COUNT(city) 
FROM		airports
GROUP BY	city
HAVING	COUNT(city) > 1

-- 2
SELECT 	DISTINCT departure_airport_name
FROM		routes r
WHERE 	aircraft_code = (SELECT	aircraft_code 
			 		FROM		aircrafts a
			 		WHERE		a.range = (SELECT MAX(a.range) FROM aircrafts a)) 

-- 3
SELECT	flight_no, 
		(actual_departure-scheduled_departure) AS delay
FROM 		flights
WHERE		actual_departure IS NOT NULL -- WHERE status = 'Arrived' OR status = 'Departed'
ORDER BY	(actual_departure-scheduled_departure) DESC 
LIMIT		10

-- 4
SELECT	COUNT(*)
FROM 		boarding_passes bp
RIGHT JOIN	tickets t
ON 		t.ticket_no = bp.ticket_no
WHERE		bp.ticket_no IS NULL

-- 5
SELECT	f_reg.flight_id, 
		total_seats.cnt-f_reg.cnt as free_cnt, 
		ROUND((total_seats.cnt-f_reg.cnt)*100.0/total_seats.cnt) as percentage
FROM		(SELECT	f.flight_id, f.aircraft_code, reg.cnt
	 	FROM		flights f
	 	JOIN		(SELECT	flight_id, 
						COUNT(*) as cnt
				FROM 		boarding_passes
				GROUP BY 	flight_id) reg
	 	ON	 	reg.flight_id = f.flight_id) f_reg
		JOIN		(SELECT   	aircraft_code, 
				 		COUNT(*) as cnt
				FROM  	seats
				GROUP BY 	aircraft_code) total_seats
		ON 		total_seats.aircraft_code = f_reg.aircraft_code
		

-- 6 
SELECT	f.flight_id, 
		f.actual_departure, 
		f.departure_airport, 
		reg.cnt,
		SUM(reg.cnt) OVER 
			(PARTITION BY departure_airport, date_trunc('day', f.actual_departure) 
			 ORDER BY actual_departure) AS cum_sum
FROM		flights f
JOIN		(SELECT   	flight_id, 
				COUNT(*) AS cnt
	 	FROM 	  	boarding_passes
	 	GROUP BY 	flight_id) reg
ON	 	reg.flight_id = f.flight_id
WHERE		actual_departure IS NOT NULL

-- 7
SELECT	af.aircraft_code, 
	  	ROUND(af.cnt*100.0/(SELECT count(*) from flights)) as percentage
FROM		(SELECT   aircraft_code, 
	  	COUNT(*) cnt
	  	FROM 	   flights
	  	GROUP BY aircraft_code) af
ORDER BY  	percentage DESC

-- 8
WITH 
business AS 
		(SELECT  	flight_id, fare_conditions, MIN(amount) as business_min
		FROM 		ticket_flights
		WHERE		fare_conditions = 'Business'
		GROUP BY 	flight_id, fare_conditions),
economy  AS 
		(SELECT  	flight_id, fare_conditions, MAX(amount) as economy_max
		FROM 		ticket_flights
		WHERE		fare_conditions = 'Economy'
		GROUP BY 	flight_id, fare_conditions)
SELECT	COUNT(*) 
FROM		business b JOIN economy e on e.flight_id = b.flight_id
WHERE		business_min < economy_max

-- 9
SELECT		e.departure_city, e.arrival_city
FROM		(SELECT   	r1.departure_city, r2.arrival_city 
	 	FROM 	    	routes r1 
	 	CROSS JOIN	routes r2
	 	EXCEPT
	 	SELECT		departure_city, arrival_city 
	 	FROM 	    	routes) e
WHERE		e.departure_city <> e.arrival_city
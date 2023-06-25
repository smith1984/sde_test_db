-- Удалить таблицу results если существует
DROP TABLE IF EXISTS results;

-- Создать таблицу results c атрибутами id (INT), response (TEXT),
CREATE TABLE results
(
    id          INT,
    response    TEXT
);


-- 1.	Вывести максимальное количество человек в одном бронировании
INSERT INTO results
SELECT 1 AS id, COUNT(1) AS response
FROM tickets t
GROUP BY t.book_ref
ORDER BY COUNT(1) Desc
    LIMIT 1;


-- 2.	Вывести количество бронирований с количеством людей больше среднего значения людей на одно бронирование
INSERT INTO results
SELECT 2 AS id, COUNT(*) AS response
FROM (
         SELECT t.book_ref, COUNT(1) AS passengers_count
         FROM tickets t
         GROUP BY t.book_ref
         HAVING COUNT(1) > (
             SELECT AVG(passengers_count)
             FROM (
                      SELECT t1.book_ref, COUNT(1) AS passengers_count
                      FROM tickets t1
                      GROUP BY t1.book_ref
                  ) AS avg_passengers_count
         )
     ) AS bookings_count;


-- 3.	Вывести количество бронирований, у которых состав пассажиров повторялся два и более раза, среди бронирований
-- с максимальным количеством людей (п.1)?
INSERT INTO results
SELECT 3 AS id, COUNT(*) AS response FROM (
                                              WITH max_pass_count AS (
                                                  SELECT MAX(pass_count) AS max_pass_count
                                                  FROM (
                                                           SELECT t1.book_ref, COUNT(*) AS pass_count
                                                           FROM tickets t1
                                                           GROUP BY t1.book_ref
                                                       ) AS pass_count
                                              )
                                              SELECT t.book_ref, COUNT(1) AS pass_count
                                              FROM tickets t
                                              GROUP BY t.book_ref
                                              HAVING COUNT(1) = (SELECT max_pass_count FROM max_pass_count)
                                                 AND t.book_ref IN (SELECT book_ref
                                                                    FROM tickets t3
                                                                    WHERE t3.passenger_id IN (SELECT passenger_id AS pass_id_repeat
                                                                                              FROM (
                                                                                                       SELECT passenger_id, COUNT(passenger_id)
                                                                                                       FROM tickets t2
                                                                                                       GROUP BY t2.passenger_id
                                                                                                       HAVING COUNT(t2.passenger_id) >= 2
                                                                                                   ) AS pass_id_count))
                                          ) AS book_count;


-- 4.	Вывести номера брони и контактную информацию по пассажирам в брони (passenger_id, passenger_name, contact_data)
-- с количеством людей в брони = 3
WITH book_pass_count_3 AS (
    SELECT t1.book_ref
    FROM tickets t1
    GROUP BY t1.book_ref
    HAVING COUNT(passenger_id) = 3
)
INSERT INTO results
SELECT 4 AS id, book_ref || '|' || passenger_id || '|' || passenger_name || '|' || contact_data AS response
FROM (
         SELECT t.book_ref, t.passenger_id, t.passenger_name, t.contact_data
         FROM tickets t
         WHERE t.book_ref IN (SELECT book_ref FROM book_pass_count_3)
         ORDER BY t.book_ref, t.passenger_id, t.passenger_name, t.contact_data) AS contact_data_for_book;


-- 5.	Вывести максимальное количество перелётов на бронь
INSERT INTO results
SELECT 5 AS id, COUNT(DISTINCT tf.flight_id) AS response
FROM tickets t
         LEFT JOIN ticket_flights tf on t.ticket_no = tf.ticket_no
GROUP BY t.book_ref
ORDER BY COUNT(DISTINCT tf.flight_id) desc
    LIMIT 1;


-- 6.	Вывести максимальное количество перелётов на пассажира в одной брони
INSERT INTO results
SELECT 6 AS id, COUNT(DISTINCT tf.flight_id) AS response
FROM tickets t
         LEFT JOIN ticket_flights tf on t.ticket_no = tf.ticket_no
GROUP BY t.book_ref, t.passenger_id
ORDER BY COUNT(DISTINCT tf.flight_id) desc
    LIMIT 1;


-- 7.	Вывести максимальное количество перелётов на пассажира
INSERT INTO results
SELECT 7 AS id, COUNT(DISTINCT tf.flight_id) AS response
FROM tickets t
         LEFT JOIN ticket_flights tf on t.ticket_no = tf.ticket_no
GROUP BY t.passenger_id
ORDER BY COUNT(DISTINCT tf.flight_id) desc
    LIMIT 1;


-- 8.	Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data)
-- и общие траты на билеты, для пассажира потратившему минимальное количество денег на перелеты
WITH min_sum_amount AS (
    SELECT SUM(tf1.amount) as min_sum_amount
    FROM tickets t1
             LEFT JOIN ticket_flights tf1 on t1.ticket_no = tf1.ticket_no
    GROUP BY t1.passenger_id
    ORDER BY min_sum_amount
    LIMIT 1
    )
INSERT INTO results
SELECT 8 AS id, t.passenger_id || '|' || t.passenger_name || '|' || t.contact_data || '|' || SUM(tf.amount) AS response
FROM tickets t
         LEFT JOIN ticket_flights tf on t.ticket_no = tf.ticket_no
GROUP BY t.passenger_id, t.passenger_name, t.contact_data
HAVING SUM(tf.amount) = (SELECT * FROM min_sum_amount)
ORDER BY t.passenger_id, t.passenger_name, t.contact_data, SUM(tf.amount);


-- 9.	Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data)
-- и общее время в полётах, для пассажира, который провёл максимальное время в полётах

WITH min_sum_actual_duration AS (
    SELECT SUM(f.actual_duration)
    FROM tickets t
             LEFT JOIN ticket_flights tf on t.ticket_no = tf.ticket_no
             LEFT JOIN flights_v f on tf.flight_id = f.flight_id
    WHERE f.status = 'Arrived'
    GROUP BY t.passenger_id
    ORDER BY SUM(f.actual_duration) DESC
    LIMIT 1
    )
INSERT INTO results
SELECT 9 AS id, t.passenger_id || '|' || t.passenger_name || '|' || t.contact_data || '|' || SUM(f.actual_duration) AS response
FROM tickets t
         LEFT JOIN ticket_flights tf on t.ticket_no = tf.ticket_no
         LEFT JOIN flights_v f on tf.flight_id = f.flight_id
WHERE f.status = 'Arrived'
GROUP BY t.passenger_id, t.passenger_name, t.contact_data
HAVING SUM(f.actual_duration) = (SELECT * FROM min_sum_actual_duration)
ORDER BY t.passenger_id, t.passenger_name, t.contact_data, SUM(f.actual_duration);


-- 10.	Вывести город(а) с количеством аэропортов больше одного
INSERT INTO results
SELECT 10 AS id, a.city AS response
FROM airports a
GROUP BY a.city
HAVING COUNT(a.airport_code) > 1
ORDER BY a.city;


-- 11.	Вывести город(а), у которого самое меньшее количество городов прямого сообщения
WITH min_arrival_city AS (
    SELECT count(r.arrival_city)
    FROM routes r
    GROUP BY r.departure_city
    ORDER BY count(r.arrival_city)
    LIMIT 1
    )
INSERT INTO results
SELECT 11 AS id, r.departure_city AS response
FROM routes r
GROUP BY r.departure_city
HAVING count(r.arrival_city) = (SELECT * FROM min_arrival_city)
ORDER BY departure_city;


-- 12.	Вывести пары городов, у которых нет прямых сообщений исключив реверсные дубликаты
WITH not_direct AS (
    SELECT Distinct f1.departure_city, f2.arrival_city
    FROM routes f1
             CROSS JOIN routes f2
    EXCEPT
    SELECT Distinct f2.departure_city, f2.arrival_city
    FROM routes f2
    ORDER BY departure_city, arrival_city
),
     all_columns AS (
         SELECT n.departure_city, n.arrival_city
         FROM not_direct n
         WHERE n.departure_city != n.arrival_city
    )
INSERT INTO results
SELECT 12 AS id, departure_city || '|' || arrival_city AS response
FROM all_columns l
WHERE NOT EXISTS(
        SELECT *
        from all_columns r
        WHERE r.departure_city = l.arrival_city
          AND r.arrival_city = l.departure_city
          AND r.departure_city < r.arrival_city
    )
ORDER BY departure_city, arrival_city;


-- 13.	Вывести города, до которых нельзя добраться без пересадок из Москвы?
INSERT INTO results
SELECT DISTINCT 13 AS id, r.departure_city AS response
FROM routes r
WHERE r.departure_city NOT IN (SELECT arrival_city FROM routes r1 where r1.departure_city = 'Москва')
  AND departure_city <> 'Москва'
ORDER BY r.departure_city;


-- 14.	Вывести модель самолета, который выполнил больше всего рейсов
WITH air_code AS (
    SELECT f.aircraft_code, count(1)
    FROM flights f
    WHERE status = 'Arrived'
    GROUP BY f.aircraft_code
    ORDER BY count(1) DESC
    LIMIT 1
    )
INSERT INTO results
SELECT 14 AS id, a.model AS response
FROM aircrafts a
WHERE a.aircraft_code = (SELECT a.aircraft_code FROM air_code a);


-- 15.	Вывести модель самолета, который перевез больше всего пассажиров
WITH air_code AS (
    SELECT f.aircraft_code, count(1)
    FROM flights f
             LEFT JOIN ticket_flights tf on f.flight_id = tf.flight_id
    WHERE status = 'Arrived'
    GROUP BY f.aircraft_code
    ORDER BY count(1) DESC
    LIMIT 1
    )
INSERT INTO results
SELECT 15 AS id, a.model AS response
FROM aircrafts a
WHERE a.aircraft_code = (SELECT a.aircraft_code FROM air_code a);


-- 16.	Вывести отклонение в минутах суммы запланированного времени перелета от фактического по всем перелётам
INSERT INTO results
SELECT 16 AS id, (EXTRACT (EPOCH FROM SUM(actual_duration) - SUM(scheduled_duration)::interval)/ 60)::int AS response
FROM flights_v
WHERE status = 'Arrived';


-- 17.	Вывести города, в которые осуществлялся перелёт из Санкт-Петербурга 2016-09-13
INSERT INTO results
SELECT 17 AS id, f.arrival_city AS response
FROM flights_v f
WHERE f.departure_city = 'Санкт-Петербург'
  AND f.status in ('Arrived', 'Departed')
  AND f.actual_departure::date = '2017-08-11'::date
ORDER BY f.arrival_city;


-- 18.	Вывести перелёт(ы) с максимальной стоимостью всех билетов
WITH max_sum_amount AS (
    SELECT SUM(tf.amount) as max_amount
    FROM ticket_flights tf
    GROUP BY tf.flight_id
    ORDER BY SUM(tf.amount) DESC
    LIMIT 1
    ),
    flight_id_with_max_amount AS (
SELECT DISTINCT t.flight_id
FROM ticket_flights t
GROUP BY t.flight_id
HAVING SUM(t.amount) = (SELECT max_amount FROM max_sum_amount)
    )
INSERT INTO results
SELECT 18 AS id, flight_id AS response
FROM flight_id_with_max_amount
ORDER BY flight_id;


-- 19.	Выбрать дни в которых было осуществлено минимальное количество перелётов
WITH min_flight AS (
    SELECT count(1) AS min_count
    FROM flights_v f
    WHERE f.status in ('Arrived', 'Departed')
    GROUP BY f.actual_departure::date
ORDER BY count(1)
    LIMIT 1
    ),
    days_with_min_flight AS (
SELECT f.actual_departure::date AS day_min_flight
FROM flights_v f
WHERE f.status in ('Arrived', 'Departed')
GROUP BY f.actual_departure::date
HAVING count(1) = (SELECT min_count FROM min_flight)
    )
INSERT INTO results
SELECT 19 AS id, day_min_flight AS response
FROM days_with_min_flight
ORDER BY day_min_flight;

-- 20.	Вывести среднее количество вылетов в день из Москвы за 08 месяц 2017 года
WITH avg_from_moscow AS (
    SELECT count(f.flight_id) AS flight_id_count
    FROM flights_v f
    WHERE  f.departure_city = 'Москва'
      AND f.status IN ('Arrived', 'Departed')
      AND date_trunc('month', f.actual_departure)::date = '2017-08-01'::date
GROUP BY date_trunc('day', f.actual_departure)
    )
INSERT INTO results
SELECT 20 as id, round(avg(flight_id_count)) AS response
FROM avg_from_moscow;


-- 21.	Вывести топ 5 городов у которых среднее время перелета до пункта назначения больше 3 часов
WITH top_avg_time_duration AS (
    SELECT f.departure_city, avg(actual_duration) AS avg_time_duration
    FROM flights_v f
    WHERE f.status IN ('Arrived')
    GROUP BY f.departure_city
    HAVING avg(actual_duration) > '0 years 0 mons 0 days 3 hours 00 mins 0.0 secs'
    ORDER BY avg_time_duration DESC
    LIMIT 5
    )
INSERT INTO results
SELECT 21 as id, departure_city AS response
FROM top_avg_time_duration
ORDER BY departure_city;
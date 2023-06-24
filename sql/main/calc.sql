CREATE TABLE if not exists results(id int, response text);

--1.	Вывести максимальное количество человек в одном бронировании
insert into results
select 1, max(cnt_tickets) from
              (select book_ref, count(ticket_no) as cnt_tickets,
                      count(passenger_id) as cnt_pass from tickets
                  group by book_ref) a;

--2.	Вывести количество бронирований с количеством людей больше среднего значения людей на одно бронирование
with avg_pass as
(select avg(cnt_pass)  as avg_cnt_pass from
         (select book_ref,  count(passenger_id) as cnt_pass from tickets
         group by book_ref) b)
insert into results select 2,count(distinct c.book_ref) from
    (select a.book_ref,  count(a.passenger_id) as cnt_pass from tickets a
    group by a.book_ref
    having count(a.passenger_id)>(select avg_pass.avg_cnt_pass from avg_pass)
    ) c;

--3.	Вывести количество бронирований, у которых состав пассажиров повторялся два и более раза, среди бронирований с максимальным количеством людей (п.1)?
insert into results
select 3, count(distinct a.book_ref) from tickets a
inner join
(select book_ref,
count(agg_id)  cnt_agg_id
from
(select a.book_ref, string_agg(DISTINCT passenger_id, ',' ORDER BY passenger_id) as agg_id from tickets a
         inner join
     (select book_ref, count(passenger_id)
      from tickets
      group by book_ref
      having count(passenger_id)=5) b on a.book_ref=b.book_ref
group by a.book_ref) a
group by book_ref
having count(agg_id)>1) b on a.book_ref=b.book_ref;

--4.	Вывести номера брони и контактную информацию по пассажирам в брони (passenger_id, passenger_name, contact_data) с количеством людей в брони = 3
insert into results
select 4,book_ref||'|'||
             string_agg(passenger_id||'|'||passenger_name||'|'||contact_data, '|' ORDER BY passenger_id||'|'||passenger_name||'|'||contact_data)
from
(select distinct a.book_ref,passenger_id, passenger_name,contact_data from tickets a
left join
    (select book_ref,
            count(passenger_id) as cnt_pass from tickets
     group by book_ref) b on a.book_ref=b.book_ref
where cnt_pass=3
    order by a.book_ref,a.passenger_id, a.passenger_name,a.contact_data
    ) a
group by book_ref
order by book_ref;

--5.	Вывести максимальное количество перелётов на бронь
insert into results
select 5 , max(flights)
from (	SELECT  t.book_ref, count(f.flight_id) flights
          FROM tickets t inner join ticket_flights tf on t.ticket_no = tf.ticket_no
                         inner join flights f on tf.flight_id = f.flight_id
          where f.status in ('Departed', 'Arrived', 'On Time')
          group by t.book_ref) a;

--6.	Вывести максимальное количество перелётов на пассажира в одной брони
insert into results
select 6, max(flights) from
    (select a.book_ref, a.passenger_id, count(distinct b.flight_id) flights from tickets a
     inner join ticket_flights b on a.ticket_no=b.ticket_no
     inner join flights c on b.flight_id = c.flight_id
     where c.status in ('Departed', 'Arrived', 'On Time')
     group by a.book_ref, a.passenger_id) a;

--7.	Вывести максимальное количество перелётов на пассажира
insert into results
select 7, max(flights) from
    (select a.passenger_id, count(distinct flight_id) flights from tickets a
     inner join ticket_flights b on a.ticket_no=b.ticket_no
     inner join flights c on b.flight_id = c.flight_id
     where c.status in ('Departed', 'Arrived', 'On Time')
     group by a.passenger_id) a;

--8.	Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) и общие траты на билеты, для пассажира потратившему минимальное количество денег на перелеты
insert into results
select distinct 8, passenger_id||'|'||passenger_name||'|'||contact_data||'|'||amount_total from
(select a.passenger_id,a.passenger_name,a.contact_data, amount_total,
        DENSE_RANK() over (order by amount_total asc) as rn
 from
     (select a.passenger_id,a.passenger_name,a.contact_data,
     sum(b.amount) amount_total
     from tickets a
     inner join ticket_flights b on a.ticket_no=b.ticket_no
     group by a.passenger_id,a.passenger_name,a.contact_data) a
    order by a.passenger_id,a.passenger_name,a.contact_data) a where a.rn=1;

--9.	Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) и общее время в полётах, для пассажира, который провёл максимальное время в полётах
insert into results
SELECT 9 id, concat_ws('|', passenger_id, passenger_name, contact_data, sum_min) p
FROM (
         SELECT t.passenger_id
              , t.passenger_name
              , t.contact_data
              , SUM(f.actual_duration) sum_min
              , RANK() OVER (ORDER BY SUM(f.actual_duration) DESC) rn
         FROM tickets t
                  inner join ticket_flights tf ON t.ticket_no = tf.ticket_no
                  inner join flights_v f ON tf.flight_id = f.flight_id
         WHERE f.status = 'Arrived'
         GROUP BY t.passenger_id, t.passenger_name, t.contact_data
         ORDER BY sum_min DESC
     ) a
WHERE rn = 1;

--10.	Вывести город(а) с количеством аэропортов больше одного
insert into results
select 10 id, city
from (
         select city, count(airport_code)  mair
         from(		SELECT airport_code, x.ru city
                       FROM bookings.airports_data
                         ,json_to_record(city::json) x (ru text)) ac
         group by city
         having count(airport_code) > 1 ) totair;

--11.	Вывести город(а), у которого самое меньшее количество городов прямого сообщения
insert into results
SELECT 11 id, departure_city
FROM (
         SELECT COUNT(DISTINCT arrival_city) c
              , departure_city
              , RANK() OVER (ORDER BY COUNT(DISTINCT arrival_city)) rn
         FROM bookings.routes
         GROUP BY departure_city
     ) a
WHERE rn = 1;

--12.	Вывести пары городов, у которых нет прямых сообщений исключив реверсные дубликаты
insert into results
SELECT 12  id, concat(c1, '|', c2) p
FROM (
         SELECT dep.city c1, arr.city c2
         FROM bookings.airports dep
            , bookings.airports arr
         WHERE dep.city != Arr.city
             EXCEPT
         SELECT dep.city c1, arr.city c2
         FROM bookings.flights f
            , bookings.airports dep
            , bookings.airports arr
         WHERE f.departure_airport = dep.airport_code
           AND f.arrival_airport = arr.airport_code
     ) t
WHERE c1 < c2;

--13.	Вывести города, до которых нельзя добраться без пересадок из Москвы?
insert into results
SELECT DISTINCT 13 id, arrival_city
FROM bookings.routes br
WHERE arrival_city NOT IN (
    SELECT arrival_city
    FROM bookings.routes br2
    WHERE br2.departure_city = 'Москва')
  AND arrival_city != 'Москва';


--14.	Вывести модель самолета, который выполнил больше всего рейсов
insert into results
with airc as (	SELECT modair, count(flight_id) cfli
                  FROM bookings.flights bf left join (SELECT aircraft_code, x.ru modair
                                                      FROM bookings.aircrafts_data
                                                         ,json_to_record(model::json) x (ru text)) bac on bf.aircraft_code = bac.aircraft_code
                  where actual_departure is not null
                  group by modair )
select 14 id, modair
from airc
where cfli = (select max(cfli) from airc);


--15.	Вывести модель самолета, который перевез больше всего пассажиров
insert into results
with tc as (SELECT modair, count(passenger_id) cpid
            FROM bookings.tickets bt 	left join bookings.ticket_flights btf on bt.ticket_no = btf.ticket_no
                                        left join bookings.flights bf on btf.flight_id = bf.flight_id
                                        left join (SELECT aircraft_code, x.ru modair
                                                   FROM bookings.aircrafts_data
                                                      ,json_to_record(model::json) x (ru text)) bac on bf.aircraft_code = bac.aircraft_code
            where actual_departure is not null
            group by modair)
select 15 id, modair
from tc
where cpid = (select max(cpid) from tc);


--16.	Вывести отклонение в минутах суммы запланированного времени перелета от фактического по всем перелётам
insert into results
SELECT 16 id, abs(extract(epoch from sum(scheduled_duration) - sum(actual_duration)) / 60)::int  d
FROM bookings.flights_v
WHERE status = 'Arrived';


--17.	Вывести города, в которые осуществлялся перелёт из Санкт-Петербурга 2017-08-11 - поменял дату, иначе пусто
insert into results
select distinct 17, city_ar
FROM bookings.tickets bt 	left join bookings.ticket_flights btf on bt.ticket_no = btf.ticket_no
                            left join bookings.flights bf on btf.flight_id = bf.flight_id
                            left join 	(SELECT airport_code, x.ru city_dep
                                          FROM bookings.airports_data
                                             ,json_to_record(city::json) x (ru text)) badep on bf.departure_airport = badep.airport_code
                            left join 	(SELECT airport_code, x.ru city_ar
                                          FROM bookings.airports_data
                                             ,json_to_record(city::json) x (ru text)) badar on bf.arrival_airport = badar.airport_code
where 	cast(actual_departure as date) = '2017-08-11'
  and	city_dep = 'Санкт-Петербург';

--18.	Вывести перелёт(ы) с максимальной стоимостью всех билетов
insert into results
with tfli as (	select btf.flight_id , sum(amount) samount
                  FROM bookings.ticket_flights btf left join bookings.flights bf on btf.flight_id = bf.flight_id
                  where actual_departure is not null
                  group by btf.flight_id)
select 18 id, flight_id
from tfli
where samount = (select max(samount) from tfli);

--19.	Выбрать дни в которых было осуществлено минимальное количество перелётов
insert into results
with gdte as (	select dte, count(flight_no) cfl
                  from (	select flight_no, cast(actual_departure as date) as dte
                            FROM bookings.flights
                            where actual_departure is not null) fldt
                  group by dte)
select 19 id, dte
from gdte
where cfl = (select min(cfl) from gdte);


--20.	Вывести среднее количество вылетов в день из Москвы за 08 месяц 2017 года - поменял дату, иначе null
insert into results
select 20 id, avg(cfl)
from (	select dte, count(flight_no) cfl
          from (  select cast(actual_departure as date) dte, flight_no
                  FROM bookings.flights bf left join 	(	SELECT airport_code, x.ru city_dep
                                                             FROM bookings.airports_data
                                                                ,json_to_record(city::json) x (ru text)) badep on bf.departure_airport = badep.airport_code
                  where 	actual_departure is not null
                    and cast(actual_departure as date) between  '2017-08-01' and '2017-08-31'
                    and  city_dep = 'Москва') dtfl
          group by dte) dtcfl;


--21.	Вывести топ 5 городов у которых среднее время перелета до пункта назначения больше 3 часов
insert into results
select 21 id, city_dep
from (	select city_dep, avg(tm) mimut
          from (  select city_dep, (actual_arrival - actual_departure) tm
                  FROM bookings.flights bf left join 	(	SELECT airport_code, x.ru city_dep
                                                             FROM bookings.airports_data
                                                                ,json_to_record(city::json) x (ru text)) badep on bf.departure_airport = badep.airport_code
                  where 	actual_departure is not null) dtfl
          group by city_dep
          having avg(tm) > '03:00:00'
          order by mimut desc
          limit 5) g;

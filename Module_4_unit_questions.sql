/*Задание 4.1*/
/*База данных содержит список аэропортов практически всех крупных городов России. В большинстве городов есть только один аэропорт. Исключение составляет:*/
SELECT a.city ,
       count(a.airport_code) cnt -- да, количество необязательно, но я слишком любопытен :)
FROM dst_project.airports a
GROUP BY a.city
HAVING count(a.airport_code) != 1;

/*Задание 4.2*/
/*Вопрос 1. Таблица рейсов содержит всю информацию о прошлых, текущих и запланированных рейсах. Сколько всего статусов для рейсов определено в таблице?*/
SELECT count(DISTINCT f.status) cnt
FROM dst_project.flights f;
/*Вопрос 2. Какое количество самолетов находятся в воздухе на момент среза в базе (статус рейса «самолёт уже вылетел и находится в воздухе»).*/
SELECT count(f.flight_id) cnt
FROM dst_project.flights f
WHERE f.status = 'Departed';
/*Вопрос 3. Места определяют схему салона каждой модели. Сколько мест имеет самолет модели Boeing 777-300?*/
SELECT count(s.seat_no) cnt -- но 402 места - это 777-300ER, что всё таки немножко другой самолёт.
FROM dst_project.aircrafts a
JOIN dst_project.seats s ON s.aircraft_code = a.aircraft_code
WHERE a.model = 'Boeing 777-300';
/*Вопрос 4. Сколько состоявшихся (фактических) рейсов было совершено между 1 апреля 2017 года и 1 сентября 2017 года?*/
SELECT count(f.flight_id) cnt
FROM dst_project.flights f
WHERE f.status = 'Arrived'
  AND f.actual_arrival BETWEEN to_date('01.04.2017', 'DD.MM.YYYY') AND to_date('01.09.2017', 'DD.MM.YYYY')-1/86400;
/*
 * 1. Тут, скорее, "завершено", а не "совершено". А то существует 6 рейсов, вылетевших в марте "and f.actual_departure < to_date('01.04.2017','DD.MM.YYYY')"
 * 2. Да, визуально лучше было бы to_date('31.08.2017 23:59:59', 'DD.MM.YYYY HH24:MI:SS'), но я слишком привык иметь дело с датами как датами - и отнять секунду от правой границы периода мне быстрее и легче :)
*/

/*Задание 4.3*/
/*Вопрос 1. Сколько всего рейсов было отменено по данным базы?*/
SELECT count(f.flight_id) cnt
FROM dst_project.flights f
WHERE f.status = 'Cancelled';
/*Вопрос 2. Сколько самолетов моделей типа Boeing, Sukhoi Superjet, Airbus находится в базе авиаперевозок?*/
SELECT regexp_replace(a.model, '(.*)(Boeing|Sukhoi Superjet|Airbus)(.*)', '\2') aircraft_model ,
       count(a.aircraft_code) cnt
FROM dst_project.aircrafts a
WHERE a.model SIMILAR TO '%(Boeing|Sukhoi Superjet|Airbus)%';
/*Вопрос 3. В какой части (частях) света находится больше аэропортов?*/
SELECT regexp_matches(a.timezone, '[^/]+') w_part ,
       count(a.airport_code) cnt
FROM dst_project.airports a
GROUP BY regexp_matches(a.timezone, '[^/]+')
ORDER BY 2 DESC;
/*Вопрос 4. У какого рейса была самая большая задержка прибытия за все время сбора данных? Введите id рейса (flight_id).*/
SELECT f.flight_id
FROM dst_project.flights f
WHERE f.status = 'Arrived'
ORDER BY f.actual_arrival - f.scheduled_arrival DESC
LIMIT 1;

/*Задание 4.4*/
/*Вопрос 1. Когда был запланирован самый первый вылет, сохраненный в базе данных?*/
SELECT to_char(f.scheduled_departure, 'DD.MM.YYYY') min_shed_dep
FROM dst_project.flights f
ORDER BY f.scheduled_departure
LIMIT 1;
/*Вопрос 2. Сколько минут составляет запланированное время полета в самом длительном рейсе?*/
SELECT extract(HOUR
               FROM (f.scheduled_arrival - f.scheduled_departure)) * 60 + extract(MINUTE
                                                                                  FROM (f.scheduled_arrival - f.scheduled_departure)) longest_flight
FROM dst_project.flights f
WHERE f.status = 'Arrived'
ORDER BY f.actual_arrival - f.actual_departure DESC
LIMIT 1;
/*Вопрос 3. Между какими аэропортами пролегает самый длительный по времени запланированный рейс?*/
SELECT f.departure_airport || ' - ' || f.arrival_airport route
FROM dst_project.flights f
ORDER BY f.scheduled_arrival - f.scheduled_departure DESC
LIMIT 1;
/*Вопрос 4. Сколько составляет средняя дальность полета среди всех самолетов в минутах? Секунды округляются в меньшую сторону (отбрасываются до минут).*/
SELECT floor(avg(extract(HOUR
                         FROM (f.actual_arrival - f.actual_departure)) * 60 + extract(MINUTE
                                                                                      FROM (f.actual_arrival - f.actual_departure)))) avg_flight
FROM dst_project.flights f
WHERE f.status = 'Arrived';

/*Задание 4.5*/
/*Вопрос 1. Мест какого класса у SU9 больше всего?*/
SELECT s.fare_conditions ,
       count(s.seat_no) cnt
FROM dst_project.seats s
WHERE s.aircraft_code = 'SU9'
GROUP BY s.fare_conditions
ORDER BY 2 DESC
LIMIT 1;
/*Вопрос 2. Какую самую минимальную стоимость составило бронирование за всю историю?*/
SELECT min(b.total_amount) min_amount
FROM dst_project.bookings b;
/*Вопрос 3. Какой номер места был у пассажира с id = 4313 788533?*/
SELECT bp.seat_no
FROM dst_project.tickets t
JOIN dst_project.ticket_flights tf ON tf.ticket_no = t.ticket_no
JOIN dst_project.boarding_passes bp ON (bp.ticket_no = tf.ticket_no
                                        AND bp.flight_id = tf.flight_id)
WHERE t.passenger_id = '4313 788533';

/*Задание 5.1*/
/*Вопрос 1. Анапа — курортный город на юге России. Сколько рейсов прибыло в Анапу за 2017 год?*/
SELECT count(f.flight_id) cnt
FROM dst_project.airports a
JOIN dst_project.flights f ON f.arrival_airport = a.airport_code
WHERE a.city = 'Anapa'
  AND extract(YEAR
              FROM f.actual_arrival) = 2017;
/*Вопрос 2. Сколько рейсов из Анапы вылетело зимой 2017 года?*/
SELECT count(f.flight_id) cnt
FROM dst_project.airports a
JOIN dst_project.flights f ON f.departure_airport = a.airport_code
WHERE a.city = 'Anapa'
  AND extract(YEAR
              FROM f.actual_departure) = 2017
  AND extract(MONTH
              FROM f.actual_departure) in (1,
                                           2,
                                           12);
/*Вопрос 3. Посчитайте количество отмененных рейсов из Анапы за все время.*/
SELECT count(f.flight_id) cnt
FROM dst_project.airports a
JOIN dst_project.flights f ON f.departure_airport = a.airport_code
WHERE a.city = 'Anapa'
  AND f.status = 'Cancelled';
/*Вопрос 4. Сколько рейсов из Анапы не летают в Москву?*/
SELECT count(f.flight_id) cnt
FROM dst_project.airports a
JOIN dst_project.flights f ON f.departure_airport = a.airport_code
WHERE a.city = 'Anapa'
  AND f.arrival_airport not in
    (SELECT aa.airport_code
     FROM dst_project.airports aa
     WHERE aa.city = 'Moscow' );
/*Вопрос 5. Какая модель самолета летящего на рейсах из Анапы имеет больше всего мест?*/
WITH ac_list AS
  (SELECT a.model ,
          a.aircraft_code ,
          count(s.seat_no) cnt_seats
   FROM dst_project.aircrafts a
   JOIN dst_project.seats s ON s.aircraft_code = a.aircraft_code
   GROUP BY a.model ,
            a.aircraft_code)
SELECT al.model
FROM dst_project.airports a
JOIN dst_project.flights f ON f.departure_airport = a.airport_code
JOIN ac_list al ON al.aircraft_code = f.aircraft_code
WHERE a.city = 'Anapa'
ORDER BY al.cnt_seats DESC
LIMIT 1;
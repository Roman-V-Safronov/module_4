WITH base_routes AS
  (SELECT DISTINCT f.departure_airport ,
                   f.arrival_airport
   FROM dst_project.airports a1
   JOIN dst_project.flights f ON f.departure_airport = a1.airport_code
   JOIN dst_project.airports a2 ON a2.airport_code = f.arrival_airport
   WHERE a1.city = 'Anapa'
     AND extract(MONTH
                 FROM f.scheduled_departure) in (1,
                                                 2,
                                                 12)
     AND f.status != 'Cancelled' ),
     routes AS
  (SELECT br.departure_airport ,
          br.arrival_airport ,
          a1.city departure_city ,
          a2.city arrival_city ,
          acos(sin(a1.latitude*pi()/180)*sin(a2.latitude*pi()/180) + cos(a1.latitude*pi()/180)*cos(a2.latitude*pi()/180)*cos(abs(a2.longitude-a1.longitude)*pi()/180)) * (6372795+10000) / 1000 route_length
   FROM base_routes br
   JOIN dst_project.airports a1 ON a1.airport_code = br.departure_airport
   JOIN dst_project.airports a2 ON a2.airport_code = br.arrival_airport),
     base_crafts AS
  (SELECT DISTINCT f.aircraft_code
   FROM dst_project.airports a1
   JOIN dst_project.flights f ON f.departure_airport = a1.airport_code
   WHERE a1.city = 'Anapa'
     AND extract(MONTH
                 FROM f.scheduled_departure) in (1,
                                                 2,
                                                 12)
     AND f.status != 'Cancelled' ),
     crafts AS
  (SELECT a.aircraft_code ,
          a.model ,
          a.range ,
          39/1.25 /*средняя стоимость керосина на начало 2017 года (примерная, р/кг) и перевод в литры*/ cost_r_l ,
                                                                                                         (CASE a.aircraft_code
                                                                                                              WHEN 'SU9' THEN 1864./830.*1.25
                                                                                                              WHEN '733' THEN 2600./807.
                                                                                                              ELSE 0.
                                                                                                          END) fuel_l_km ,
                                                                                                         (CASE a.aircraft_code
                                                                                                              WHEN 'SU9' THEN 15805
                                                                                                              WHEN '733' THEN 20102
                                                                                                              ELSE 0
                                                                                                          END) fuel_tank_l ,
                                                                                                         sum(CASE s.fare_conditions
                                                                                                                 WHEN 'Economy' THEN 1
                                                                                                                 ELSE 0
                                                                                                             END) seats_economy --, sum(case s.fare_conditions when 'Comfort' then 1 else 0 end) seats_comfort
 ,
                                                                                                         sum(CASE s.fare_conditions
                                                                                                                 WHEN 'Business' THEN 1
                                                                                                                 ELSE 0
                                                                                                             END) seats_business
   FROM base_crafts bc
   JOIN dst_project.aircrafts a ON a.aircraft_code = bc.aircraft_code
   JOIN dst_project.seats s ON s.aircraft_code = a.aircraft_code
   GROUP BY a.aircraft_code ,
            a.model ,
            a.range),
     ticket AS
  (SELECT tf.flight_id ,
          sum(CASE tf.fare_conditions
                  WHEN 'Economy' THEN 1
                  ELSE 0
              END) cnt_economy ,
          avg(CASE tf.fare_conditions
                  WHEN 'Economy' THEN tf.amount
                  ELSE 0
              END) avg_economy ,
          sum(CASE tf.fare_conditions
                  WHEN 'Economy' THEN tf.amount
                  ELSE 0
              END) pay_economy ,
          sum(CASE tf.fare_conditions
                  WHEN 'Business' THEN 1
                  ELSE 0
              END) cnt_business ,
          avg(CASE tf.fare_conditions
                  WHEN 'Business' THEN tf.amount
                  ELSE 0
              END) avg_business ,
          sum(CASE tf.fare_conditions
                  WHEN 'Business' THEN tf.amount
                  ELSE 0
              END) pay_business
   FROM dst_project.airports a1
   JOIN dst_project.flights f ON f.departure_airport = a1.airport_code
   JOIN dst_project.ticket_flights tf ON tf.flight_id = f.flight_id
   WHERE a1.city = 'Anapa'
     AND extract(MONTH
                 FROM f.scheduled_departure) in (1,
                                                 2,
                                                 12)
     AND f.status != 'Cancelled'
   GROUP BY tf.flight_id)
SELECT f.flight_id ,
       extract(hours
               FROM (f.actual_arrival - f.actual_departure)) * 60 + extract(MINUTE
                                                                            FROM (f.actual_arrival - f.actual_departure)) flight_time ,
       r.route_length ,
       r.departure_city ,
       r.arrival_city ,
       c.model ,
       c.range ,
       c.fuel_l_km ,
       c.fuel_tank_l ,
       r.route_length * c.fuel_l_km * c.cost_r_l fuel_r_plan ,
       t.cnt_economy ,
       c.seats_economy ,
       t.pay_economy ,
       t.pay_economy / t.cnt_economy * c.seats_economy plan_economy ,
       t.cnt_business ,
       c.seats_business ,
       t.pay_business ,
       t.pay_business / t.cnt_business * c.seats_business plan_business
FROM dst_project.airports a1
JOIN dst_project.flights f ON f.departure_airport = a1.airport_code
JOIN routes r ON (r.departure_airport = f.departure_airport
                  AND r.arrival_airport = f.arrival_airport)
JOIN crafts c ON c.aircraft_code = f.aircraft_code
JOIN ticket t ON t.flight_id = f.flight_id
WHERE a1.city = 'Anapa'
  AND extract(MONTH
              FROM f.scheduled_departure) in (1,
                                              2,
                                              12)
  AND f.status != 'Cancelled'
ORDER BY f.actual_departure
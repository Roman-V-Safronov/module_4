with 
  base_routes as (
    select distinct
           f.departure_airport
         , f.arrival_airport
    from   dst_project.airports a1
    join   dst_project.flights f on f.departure_airport = a1.airport_code
    join   dst_project.airports a2 on a2.airport_code = f.arrival_airport
    where  a1.city = 'Anapa'
    and    extract(month from f.scheduled_departure) in (1, 2, 12)
    and    f.status != 'Cancelled'
  ) ,
  routes as (
    select br.departure_airport
         , br.arrival_airport
         , a1.city departure_city
         , a2.city arrival_city
         , acos(sin(a1.latitude*pi()/180)*sin(a2.latitude*pi()/180) + cos(a1.latitude*pi()/180)*cos(a2.latitude*pi()/180)*cos(abs(a2.longitude-a1.longitude)*pi()/180)) * (6372795+10000) / 1000 route_length
    from   base_routes br
    join   dst_project.airports a1 on a1.airport_code = br.departure_airport
    join   dst_project.airports a2 on a2.airport_code = br.arrival_airport
  ) ,
  base_crafts as (
    select distinct
           f.aircraft_code
    from   dst_project.airports a1
    join   dst_project.flights f on f.departure_airport = a1.airport_code
    where  a1.city = 'Anapa'
    and    extract(month from f.scheduled_departure) in (1, 2, 12)
    and    f.status != 'Cancelled'
  ) ,
  crafts as (
    select a.aircraft_code
         , a.model
         , a.range
         , 39/1.25 /*средняя стоимость керосина на начало 2017 года (примерная, р/кг) и перевод в литры*/ cost_r_l
         , (case a.aircraft_code when 'SU9' then 1864./830.*1.25 when '733' then 2600./807. else 0. end) fuel_l_km
         , (case a.aircraft_code when 'SU9' then 15805 when '733' then 20102 else 0 end) fuel_tank_l
         , sum(case s.fare_conditions when 'Economy' then 1 else 0 end) seats_economy
         --, sum(case s.fare_conditions when 'Comfort' then 1 else 0 end) seats_comfort
         , sum(case s.fare_conditions when 'Business' then 1 else 0 end) seats_business
    from   base_crafts bc
    join   dst_project.aircrafts a on a.aircraft_code = bc.aircraft_code
    join   dst_project.seats s on s.aircraft_code = a.aircraft_code
    group by a.aircraft_code
           , a.model
           , a.range
  ) ,
  ticket as (
    select tf.flight_id
         , sum(case tf.fare_conditions when 'Economy' then 1 else 0 end) cnt_economy
         , avg(case tf.fare_conditions when 'Economy' then tf.amount else 0 end) avg_economy
         , sum(case tf.fare_conditions when 'Economy' then tf.amount else 0 end) pay_economy
         , sum(case tf.fare_conditions when 'Business' then 1 else 0 end) cnt_business
         , avg(case tf.fare_conditions when 'Business' then tf.amount else 0 end) avg_business
         , sum(case tf.fare_conditions when 'Business' then tf.amount else 0 end) pay_business
    from   dst_project.airports a1
    join   dst_project.flights f on f.departure_airport = a1.airport_code
    join   dst_project.ticket_flights tf on tf.flight_id = f.flight_id
    where  a1.city = 'Anapa'
    and    extract(month from f.scheduled_departure) in (1, 2, 12)
    and    f.status != 'Cancelled'
    group by tf.flight_id
  )
select f.flight_id
     , extract(hours from (f.actual_arrival - f.actual_departure)) * 60 + extract(minute from (f.actual_arrival - f.actual_departure)) flight_time
     , r.route_length
     , r.departure_city
     , r.arrival_city
     , c.model
     , c.range
     , c.fuel_l_km
     , c.fuel_tank_l
     , r.route_length * c.fuel_l_km * c.cost_r_l fuel_r_plan
     , t.cnt_economy
     , c.seats_economy
     , t.pay_economy
     , t.pay_economy / t.cnt_economy * c.seats_economy plan_economy
     , t.cnt_business
     , c.seats_business
     , t.pay_business
     , t.pay_business / t.cnt_business * c.seats_business plan_business
from   dst_project.airports a1
join   dst_project.flights f on f.departure_airport = a1.airport_code
join   routes r on (r.departure_airport = f.departure_airport and r.arrival_airport = f.arrival_airport)
join   crafts c on c.aircraft_code = f.aircraft_code
join   ticket t on t.flight_id = f.flight_id
where  a1.city = 'Anapa'
and    extract(month from f.scheduled_departure) in (1, 2, 12)
and    f.status != 'Cancelled'
order by f.actual_departure
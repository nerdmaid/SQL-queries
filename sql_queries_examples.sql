1. В таблице trips содержатся поездки таксопарка ООО 'КЕХ Ромашка'. Для каждой поездки указаны client_id и driver_id,
которые являются внешними ключами на таблицу users (поле user_id).
В поле status могут содержаться значения ('completed', 'cancelled_by_driver', 'cancelled_by_client').
Таблица users содержит всех пользователей таксопарка (и клиентов и водителей).
В поле role указана их роль в таксопарке, а в поле banned их статус блокировки.
Напишите запрос, который найдет коэффициент отмены в промежутке между 2020-02-01 и 2020-02-03.
Коэффициент отмены - отношение отмененных поездок к общему количеству поездок.
Учитывать нужно только незаблокированных пользователей (незаблокированы должны быть и клиент и водитель).
Ограничения: запрещено использовать HAVING, JOIN, связанные подзапросы (обращение в подзапросе к таблицам из внешнего запроса), LIMIT, UNION, UNION ALL, VALUES.

SELECT trips.request_at, 
	TRUNCATE(
		SUM(CASE WHEN trips.status != 'completed' THEN 1 ELSE 0 END) / COUNT(*), 2
		) as cancel_rate
FROM 
	trips, users
    WHERE trips.client_id NOT IN (SELECT user_id FROM users WHERE banned = '1')
    AND trips.driver_id NOT IN (SELECT user_id FROM users WHERE banned = '1')
	AND (trips.request_at BETWEEN '2020-02-01' AND '2020-02-03')
GROUP BY trips.request_at

2. Дана таблички с транзакциями пользователей.
CREATE TABLE transactions (
	id int,
	user_id int4,
	amount int4,
	dtime timestamp
);
Нужно найти наибольшее число транзакций, которые сделал юзер за 30 суток (max_count_30_day).
Можно считать, что у одного юзера нет 2 транзакция на один timestamp (timestamp = дата+время). 
Ограничения: запрещено использовать LIMIT, UNION, UNION ALL, VALUES, IN

WITH t3 AS(
      SELECT user_id, COUNT(*) AS cnt
      FROM transactions t1
JOIN transactions t2 USING (user_id)
      WHERE t2.dtime >= t1.dtime AND  t2.dtime <  (t1.dtime + INTERVAL 30 day)
      GROUP BY t1.id,user_id
      )
SELECT user_id, MAX(cnt) AS max_count_30_day
      FROM t3
GROUP BY user_id
ORDER BY user_id

3. -- d7_buyer(id int, name text, surname text, last_action_date date);
-- d7_seller(id int, name text, surname text, last_action_date date);
-- d7_manager(id int, name text, last_action_date date);
-- d7_user(id serial, role text, registration_date date)
Посчитайте количество пользователей в разрезе квартала регистрации и месяца. 
Подведите подытог по каждому разрезу  и общий подытог, отсортируйте по первой и второй колонке.
Формат ответа 'q', 'm', 'cntd_users'

SELECT QUARTER(registration_date) as q, MONTH(registration_date) as m, COUNT(DISTINCT id) as cntd_users
      FROM d7_user
GROUP BY QUARTER(registration_date), MONTH(registration_date) WITH ROLLUP
ORDER BY 1,2

4. -- d8_scores (event_date, category, subcategory, value)
Для дат с 2021-01-19 по 2021-01-21 выведите среднее значение value за предыдущие два дня для каждой подкатегории категории A
Например, для даты 2021-01-19 вычисление среднего должно происходить по датам 2021-01-17, 2021-01-18.

WITH cte AS
      (SELECT *, AVG(value) OVER
      (
      PARTITION BY subcategory ORDER BY event_date RANGE BETWEEN INTERVAL 2 day PRECEDING AND interval 1 day PRECEDING
      ) AS last_2d_avg
      FROM d8_scores
      WHERE category = 'A')
SELECT * FROM cte
      WHERE (event_date BETWEEN '2021-01-19' AND '2021-01-21') 
      AND (category = 'A')
ORDER BY 1,2,3

5. -- create table d9_datamarts (dm varchar(64), calc_time int);
-- create table d9_dag (src varchar(64), tgt varchar(4));
 
Даны расчеты табличек в хранилище данных.
d9_datamarts - хранит название таблички и время в минутах которое необходимо для ее заполнения
d9_dag - хранит последовательность, в которой нужно заполнять таблички в виде пар.
Нужно вывести цепочку табличек которая заполняется дольше всего.
Цепочка состоит из названий таблиц, разделенных символами ' -> '

WITH recursive path(pth,prev,time) AS 
      (
   	 SELECT d1.src AS pth, 
      d1.src AS prev, 
      d2.calc_time FROM 
      d9_dag d1 JOIN d9_datamarts d2 
      ON d1.src = d2.dm
    	UNION ALL
    		SELECT CONCAT(path.pth,' -> ',dg.tgt), 
      dg.tgt, 
      path.time + dm.calc_time
    	FROM path
    		JOIN d9_dag dg 
      ON path.prev = dg.src
    		JOIN d9_datamarts dm 
      ON dg.tgt = dm.dm
      )
SELECT DISTINCT pth AS calc_path, time AS calc_time
      FROM path
WHERE time = (SELECT MAX(time) FROM path)

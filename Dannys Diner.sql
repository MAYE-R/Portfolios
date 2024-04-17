CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
--Case Study Questions
--1. What is the total amount each customer spent at the restaurant?

SELECT 
	sales.customer_id,
	SUM(mu.price) AS total_sales
FROM
	sales
		JOIN menu AS mu
	ON sales.product_id = mu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id ASC;


--2. How many days has each customer visited the restaurant?
SELECT
	customer_id,
	COUNT(DISTINCT order_date)
FROM
	sales
GROUP BY customer_id
ORDER BY customer_id;


--3. What was the first item from the menu purchased by each customer?
WITH cte_rank AS (
	SELECT
		customer_id,
		order_date,
		product_id,
		DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date ASC)
			AS purchase_number
	FROM
		sales
				)
SELECT
	cte.customer_id,
	cte.order_date,
	mu.product_name
FROM
	cte_rank AS cte
		JOIN menu AS mu
	ON cte.product_id = mu.product_id
WHERE
	purchase_number = 1
ORDER BY customer_id;


--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
	mu.product_name,
	COUNT(s.product_id) AS purchase_count
FROM
	sales AS s
		JOIN menu AS mu
	ON s.product_id = mu.product_id
GROUP BY mu.product_name
ORDER BY purchase_count DESC;


--5. Which item was the most popular for each customer?
WITH cte AS (
	SELECT
		s.customer_id,
		mu.product_name,
		COUNT(*) as total_orders,
		RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS p_rank
	FROM
		sales AS s
			JOIN menu AS mu
		ON s.product_id = mu.product_id
	GROUP BY s.customer_id, mu.product_name
			)
SELECT
	customer_id,
	product_name,
	total_orders
FROM
	cte
WHERE
	p_rank = 1;

--6. Which item was purchased first by the customer after they became a member?
WITH cte AS (
	SELECT
		mm.customer_id,
		mu.product_name,
		RANK() OVER(PARTITION BY mm.customer_id ORDER BY order_date ASC) AS r_date
	FROM
		members AS mm
			LEFT JOIN sales AS s
		ON mm.customer_id = s.customer_id
			JOIN menu AS mu
		ON s.product_id = mu.product_id
	WHERE
		s.order_date >= mm.join_date
			)
SELECT
	customer_id,
	product_name
FROM cte
WHERE
	r_date = 1;

--7. Which item was purchased just before the customer becamse a member?
WITH cte AS (
	SELECT
		mm.customer_id,
		mu.product_name,
		RANK() OVER(PARTITION BY mm.customer_id ORDER BY order_date ASC) AS r_date
	FROM
		members AS mm
			LEFT JOIN sales AS s
		ON mm.customer_id = s.customer_id
			JOIN menu AS mu
		ON s.product_id = mu.product_id
	WHERE
		s.order_date < mm.join_date
			)
SELECT
	customer_id,
	product_name
FROM cte
WHERE
	r_date = 1;

--8. What is the total items and amount spent for each member before they became a member?
SELECT
	s.customer_id,
	SUM(mu.price)
FROM
	members AS mm
		LEFT JOIN sales AS s
	ON s.customer_id = mm.customer_id
		JOIN menu AS mu
	ON s.product_id = mu.product_id
WHERE
	s.order_date < mm.join_date
GROUP BY s.customer_id;

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier. How many points would each customer have?
WITH cte_points AS (
	SELECT
		*,
		CASE
			WHEN product_id = '1' THEN price * 20 ELSE price * 10 END AS reward_points
	FROM
		menu
					)
SELECT
	s.customer_id,
	SUM(cte.reward_points) AS reward_points
FROM
	sales AS s
		JOIN cte_points AS cte
	ON s.product_id = cte.product_id
GROUP BY s.customer_id
ORDER BY reward_points DESC;

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH cte AS (
	SELECT
		s.customer_id,
		s.order_date,
		CASE
			WHEN s.order_date - mm.join_date BETWEEN 0 AND 7 OR mu.product_id = '1' THEN mu.price * 20
			ELSE mu.price * 10 END AS  r_points
	FROM
		members AS mm
			RIGHT JOIN sales AS s
		ON mm.customer_id = s.customer_id
			JOIN menu AS mu
		ON s.product_id = mu.product_id
				)
SELECT
	customer_id,
	SUM(r_points) AS reward_points
FROM
	cte
WHERE
	customer_id IN ('A','B')
	AND EXTRACT (MONTH FROM order_date) = 1
GROUP BY customer_id;

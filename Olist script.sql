--Olist store data set
--

--Sales are being tagged once the payment has been made and recorded.
SELECT
	SUM(payment.payment_value)
FROM
	payment
		JOIN orders
	ON payment.order_id = orders.order_id;
	
--Counting all orders with payment.
SELECT
	COUNT(DISTINCT payment.order_id)
FROM
	payment
		JOIN orders
	ON payment.order_id = orders.order_id;

--Getting the canceled divided by the total of orders
SELECT
	ROUND(COUNT(DISTINCT payment.order_id)::NUMERIC / 
		(SELECT
				COUNT(orders.order_id)::NUMERIC
		 FROM
				orders) * 100,2) AS successful_order
FROM
	payment
		JOIN orders
	ON payment.order_id = orders.order_id
WHERE
	orders.order_status = 'canceled';
	
--Total sales divided by orders with payment
SELECT
	ROUND(SUM(payment.payment_value)/
	COUNT(DISTINCT orders.order_id),2) AS avg_order_value
FROM
	orders
		JOIN payment
	ON orders.order_id = payment.order_id;

--Average review score
SELECT
	ROUND(AVG(review_score),2)
FROM
	reviews;

--Top 5 highest-selling categories based on payment order_id
SELECT
	products.product_category_name,
	COUNT(DISTINCT payment.order_id) AS order_count
FROM
	payment
		JOIN order_items
	ON payment.order_id = order_items.order_id
		JOIN products
	ON order_items.product_id = products.product_id
GROUP BY products.product_category_name
ORDER BY order_count DESC
LIMIT 5;

--bottom 5 lowest-selling categories baseed on payment order_id
SELECT
	products.product_category_name,
	COUNT(DISTINCT payment.order_id) AS order_count
FROM
	payment
		JOIN order_items
	ON payment.order_id = order_items.order_id
		JOIN products
	ON order_items.product_id = products.product_id
GROUP BY products.product_category_name
ORDER BY order_count ASC
LIMIT 5;

--Top 5 cities and states with the highest sales
--Based on payment transaction

SELECT
	CONCAT(customers.customer_city, ', ', customers.customer_state)
		AS city_state,
	SUM(payment.payment_value) AS total_sales
FROM
	payment
		JOIN orders
	ON orders.order_id = payment.order_id
		JOIN customers
	ON orders.customer_id = customers.customer_id
GROUP BY city_state
ORDER BY total_sales DESC
LIMIT 5;

--Breaking down the order status from highest to lowest
SELECT
	order_status,
	COUNT(order_id) AS order_count
FROM
	orders
GROUP BY order_status
ORDER BY order_count DESC;

--Seller_id was used since the seller_name isn't part of the dataset.
--Orders fulfilled are being tagged as delivered and shipped.
SELECT
	seller.seller_id,
	COUNT(orders.order_id) AS order_fulfilled
FROM
	seller
		JOIN order_items
	ON seller.seller_id = order_items.seller_id
		JOIN orders
	ON order_items.order_id = orders.order_id
WHERE
	orders.order_status IN ('delivered', 'shipped')
GROUP BY seller.seller_id
ORDER BY order_fulfilled DESC
LIMIT 5;

--Filtering the order status to canceled
SELECT
	CONCAT(customers.customer_city,', ',customers.customer_state) AS city_state,
	COUNT(orders.order_id) AS canceled_count
FROM
	orders
		JOIN customers
	ON orders.customer_id = customers.customer_id
WHERE
	orders.order_status = 'canceled'
GROUP BY city_state
ORDER BY canceled_count DESC
LIMIT 3;

--Orders per month trend
SELECT
	to_char(order_purchase_timestamp,'Month') AS per_month,
	COUNT(orders.order_id)
FROM
	orders
GROUP BY per_month
ORDER BY per_month DESC;

--Orders per day trend
SELECT
	to_char(order_purchase_timestamp,'day') AS per_day,
	COUNT(orders.order_id)
FROM
	orders
GROUP BY per_day
ORDER BY per_day DESC;
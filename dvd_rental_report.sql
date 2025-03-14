-- School project. Set of queries to explore the PostgreSQL DVD Rental Database. Used to generate a business report detailing the most loyal customers and information about their purchases and spending totals.
-- Contains a detailed table and a summary table, a function to return the detailed table, a trigger to update the summary table based on changes in the detailed table, and a stored procedure to refresh the tables weekly.

-- Overview of how many purchases each customer has made
SELECT * FROM payment
ORDER BY customer_id;

-- Verifying the correct count for total purchases made by customer_id
SELECT customer_id, COUNT(customer_id)
FROM payment
WHERE customer_id = 1
GROUP BY customer_id;

-- Query to return raw data needed for the detailed section of the report
SELECT payment.customer_id, customer.first_name, customer.last_name, customer.email, payment.amount FROM payment
LEFT JOIN customer ON payment.customer_id = customer.customer_id
GROUP BY payment.customer_id, customer.first_name, customer.last_name, customer.email, payment.amount;

-- (Detailed table) Query to return the names, email addresses, total purchases, and total amount spent on DVDs for each customer
-- Ordered by the customers with the highest total amount spent
SELECT customer.first_name, customer.last_name, customer.email, COUNT(payment.customer_id) AS total_purchases, SUM(payment.amount) AS total_amount FROM payment
LEFT JOIN customer ON payment.customer_id = customer.customer_id
GROUP BY customer.first_name, customer.last_name, customer.email
ORDER BY total_amount DESC;

DROP FUNCTION customer_total();

-- Function that contains the detailed table query
CREATE OR REPLACE FUNCTION customer_total()
RETURNS TABLE (
	first_name VARCHAR(45), 
	last_name VARCHAR(45), 
	email VARCHAR(50),
	total_purchases SMALLINT,
	total_amount DECIMAL(5,2)
	) AS $$
BEGIN
	RETURN QUERY
	SELECT customer.first_name, customer.last_name, customer.email, CAST(COUNT(payment.customer_id) AS SMALLINT), SUM(payment.amount) AS total_amount
	FROM payment
	LEFT JOIN customer ON payment.customer_id = customer.customer_id
	GROUP BY customer.first_name, customer.last_name, customer.email
	ORDER BY total_amount DESC;
END; $$
LANGUAGE PLPGSQL;

-- Detailed table returned from function
SELECT * FROM customer_total();

-- (Summary table) Average of the total purchases and total spending by the top 100 customers
SELECT CAST(AVG(total_purchases) AS SMALLINT) AS top_purchases_average, CAST(AVG(total_amount) AS DECIMAL(5,2)) AS top_spend_average 
FROM (
	SELECT total_purchases, total_amount
	FROM customer_total()
	ORDER BY total_amount DESC
	LIMIT 100
);

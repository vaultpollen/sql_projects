-- School project. Set of queries to explore the PostgreSQL DVD Rental Database. Used to generate a business report detailing the most loyal customers and information about their purchases and spending totals.
-- Contains a detailed table and a summary table, a function to create the detailed table from a transformation on raw data from the database, a trigger to update the summary table based on changes in the detailed table, and a stored procedure to refresh the tables.

/* Overview of how many purchases each customer has made
SELECT * FROM payment
ORDER BY customer_id; */

/* Verifying the correct count for total purchases made by customer_id
SELECT customer_id, COUNT(customer_id)
FROM payment
WHERE customer_id = 1
GROUP BY customer_id; */

--Query to return raw data needed for the detailed section of the report
SELECT payment.customer_id, customer.first_name, customer.last_name, customer.email, payment.amount FROM payment
LEFT JOIN customer ON payment.customer_id = customer.customer_id
GROUP BY payment.customer_id, customer.first_name, customer.last_name, customer.email, payment.amount;

/* (Detailed table) Query to return the names, email addresses, total purchases, and total amount spent on DVDs for each customer
Ordered by the customers with the highest total amount spent
SELECT customer.first_name, customer.last_name, customer.email, COUNT(payment.customer_id) AS total_purchases, SUM(payment.amount) AS total_amount FROM payment
LEFT JOIN customer ON payment.customer_id = customer.customer_id
GROUP BY customer.first_name, customer.last_name, customer.email
ORDER BY total_amount DESC; */

DROP FUNCTION customer_total();

-- (A4) Function to perform data transformation for the detailed table
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

-- Function test
SELECT * FROM customer_total();

-- Drop tables
DROP TABLE detailed_table;
DROP TABLE summary_table;

-- (C) Create detailed and summary tables
CREATE TABLE detailed_table (
	first_name VARCHAR(45), 
	last_name VARCHAR(45), 
	email VARCHAR(50),
	total_purchases SMALLINT,
	total_amount DECIMAL(5,2)
);

CREATE TABLE summary_table (
	top_purchases_average SMALLINT,
	top_spend_average DECIMAL(5,2)
);

-- Check tables
SELECT * FROM detailed_table;
SELECT * FROM summary_table;

-- Trigger to refresh summary table based on detailed table updates
CREATE OR REPLACE FUNCTION trigger_function()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
DELETE FROM summary_table;
INSERT INTO summary_table
SELECT CAST(AVG(total_purchases) AS SMALLINT) AS top_purchases_average, CAST(AVG(total_amount) AS DECIMAL(5,2)) AS top_spend_average 
FROM (
	SELECT total_purchases, total_amount
	FROM detailed_table
	ORDER BY total_amount DESC
	LIMIT 100
);
RETURN NEW;
END;
$$;

CREATE TRIGGER table_update
AFTER INSERT ON detailed_table
FOR EACH STATEMENT
EXECUTE PROCEDURE trigger_function();

-- (D) Extract raw data into detailed table
INSERT INTO detailed_table
SELECT * FROM customer_total();

-- Confirm summary table update based on detailed table update
SELECT * FROM detailed_table;
SELECT * FROM summary_table;

-- (E) Confirm summary table update based on new data entered into detailed table
INSERT INTO detailed_table
VALUES ('Test', 'Name', 'testemail@email.com', 1, 500);

-- Show updated tables
SELECT * FROM detailed_table
ORDER BY total_amount DESC;
SELECT * FROM summary_table;

-- (F) Stored procedure to refresh detailed and summary tables
CREATE OR REPLACE PROCEDURE refresh_tables()
LANGUAGE PLPGSQL
AS $$
BEGIN
DELETE FROM detailed_table;
DELETE FROM summary_table;

INSERT INTO detailed_table
SELECT * FROM customer_total();
RETURN;
END; $$;

CALL refresh_tables()

-- Show updated tables
SELECT * FROM detailed_table;
SELECT * FROM summary_table;

-- Show updated tables
SELECT * FROM detailed_table;
SELECT * FROM summary_table;

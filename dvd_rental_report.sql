-- Summarized here is a report that will be used to determine the top 10 customers of a DVD rental store based on their highest spending month, ranking them by the largest total amount spent in any single month. The purpose of this report is to provide actionable insights for a customer loyalty program that can be tailored based on the months in which the customers tend to spend the most.

--Raw data needed for the detailed section of the report
SELECT payment.customer_id, customer.first_name, customer.last_name, customer.email, payment.amount, payment.payment_date FROM payment
LEFT JOIN customer ON payment.customer_id = customer.customer_id
GROUP BY payment.customer_id, customer.first_name, customer.last_name, customer.email, payment.amount, payment.payment_date;

DROP FUNCTION date_convert();

-- User defined function to perform data transformation (changing the payment date from YYYY-MM-DD HH:MM:SS to display only the month as text)
CREATE OR REPLACE FUNCTION date_convert(dt TIMESTAMP)
RETURNS TEXT AS $$
DECLARE
payment_month TEXT;
BEGIN
	payment_month := TO_CHAR(dt, 'FMMonth');
	RETURN payment_month;
END; $$
LANGUAGE PLPGSQL;

-- Function test
SELECT date_convert(payment_date) FROM payment;

-- Drop tables
DROP TABLE detailed_table;
DROP TABLE summary_table;

-- Create detailed and summary tables
CREATE TABLE detailed_table (
	first_name VARCHAR(45), 
	last_name VARCHAR(45), 
	email VARCHAR(50),
	amount DECIMAL(5,2),
	payment_month VARCHAR
);

CREATE TABLE summary_table (
	first_name VARCHAR(45),
	last_name VARCHAR(45),
	email VARCHAR(50),
	total_amount DECIMAL(5,2),
	highest_spending_month VARCHAR
);

-- Check tables
SELECT * FROM detailed_table;
SELECT * FROM summary_table;

-- Trigger to refresh summary table based on detailed table updates, aggregate data from the detailed table to provide the correct data for the summary table
CREATE OR REPLACE FUNCTION trigger_function()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
	DELETE FROM summary_table;
	INSERT INTO summary_table(first_name, last_name, email, total_amount, highest_spending_month)
	WITH ranked_totals AS (
		SELECT first_name, last_name, email, payment_month, sum(amount) AS total_amount,
		RANK() OVER (PARTITION BY first_name, last_name, email ORDER BY SUM(amount) DESC) as final_rank
		FROM detailed_table
		GROUP BY first_name, last_name, email, payment_month
	)
	SELECT first_name, last_name, email, total_amount, payment_month
	FROM ranked_totals
	WHERE final_rank = 1
	ORDER BY total_amount DESC
	LIMIT 10;
	RETURN NEW;
END;
$$;

CREATE TRIGGER table_update
AFTER INSERT ON detailed_table
FOR EACH STATEMENT
EXECUTE PROCEDURE trigger_function();

-- Extract raw data into detailed table
INSERT INTO detailed_table(first_name, last_name, email, amount, payment_month)
SELECT customer.first_name, customer.last_name, customer.email, payment.amount, date_convert(payment.payment_date)
FROM payment
LEFT JOIN customer ON payment.customer_id = customer.customer_id;

-- Confirm summary table update based on detailed table update
SELECT * FROM detailed_table;
SELECT * FROM summary_table ORDER BY total_amount DESC;

-- Confirm summary table update based on new data entered into detailed table
INSERT INTO detailed_table
VALUES ('Test', 'Name', 'testemail@email.com', 199.99, 'December');

-- Show updated tables
SELECT * FROM detailed_table
ORDER BY amount DESC;
SELECT * FROM summary_table
ORDER BY total_amount DESC;

-- Stored procedure to refresh detailed and summary tables
CREATE OR REPLACE PROCEDURE refresh_tables()
LANGUAGE PLPGSQL
AS $$
BEGIN
DELETE FROM detailed_table;
DELETE FROM summary_table;
INSERT INTO detailed_table(first_name, last_name, email, amount, payment_month)
SELECT customer.first_name, customer.last_name, customer.email, payment.amount, date_convert(payment.payment_date)
FROM payment
LEFT JOIN customer ON payment.customer_id = customer.customer_id;
RETURN;
END; $$;

CALL refresh_tables()

-- Show updated tables
SELECT * FROM detailed_table
ORDER BY amount DESC;
SELECT * FROM summary_table
ORDER BY total_amount DESC;

-- Show updated tables
SELECT * FROM detailed_table;
SELECT * FROM summary_table;

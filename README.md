# sql_projects
Collection of data exploration projects

dvd_rental_report.sql - A school project used to answer a business question for a theoretical DVD rental business. Explores the PostgreSQL DVD Rental Database to examine the most loyal customers by number of   
purchases made and total amount spent. Contains two data transformation tables with differing granularities: a detailed table with customer information, total purchases by customer, and total amount spent by customer, and a summary table that contains the average purchases made by the top 100 customers and the total amount spent by the top 100 customers. Contains a function that can be used to produce the detailed table, a trigger that updates the summary table based on changes made in the detailed table, and a stored procedure to refresh the data in the detailed and summary tables. 

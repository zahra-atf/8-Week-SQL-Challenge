----------------------------------
-- CASE STUDY #1: DANNY'S DINER --
----------------------------------
-- Tool used: MySQL

CREATE SCHEMA dannys_diner;

CREATE TABLE sales (
    customer_id VARCHAR(1),
    order_date DATE,
    product_id INTEGER
);

INSERT INTO sales
    (customer_id, order_date, product_id)
VALUES
    ('A', '2021-01-01', 1),
    ('A', '2021-01-01', 2),
    ('A', '2021-01-07', 2),
    ('A', '2021-01-10', 3),
    ('A', '2021-01-11', 3),
    ('A', '2021-01-11', 3),
    ('B', '2021-01-01', 2),
    ('B', '2021-01-02', 2),
    ('B', '2021-01-04', 1),
    ('B', '2021-01-11', 1),
    ('B', '2021-01-16', 3),
    ('B', '2021-02-01', 3),
    ('C', '2021-01-01', 3),
    ('C', '2021-01-01', 3),
    ('C', '2021-01-07', 3);
 
CREATE TABLE menu (
    product_id INTEGER,
    product_name VARCHAR(5),
    price INTEGER
);

INSERT INTO menu
    (product_id, product_name, price)
VALUES
    (1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);
  
CREATE TABLE members (
    customer_id VARCHAR(1),
    join_date DATE
);

INSERT INTO members
    (customer_id, join_date)
VALUES
    ('A', '2021-01-07'),
    ('B', '2021-01-09');

SELECT * 
FROM sales; 

SELECT * 
FROM menu;

SELECT * 
FROM members;

--------------------------
-- QUESTIONS --
--------------------------

/* 1. What is the total amount each customer spent at the restaurant? */

SELECT sales.customer_id, SUM(price) AS total_purchase
FROM sales
JOIN menu
USING (product_id)
GROUP BY sales.customer_id
;


/* 2. How many days has each customer visited the restaurant? */

SELECT sales.customer_id, COUNT(distinct(order_date)) AS total_visit
FROM sales
GROUP BY sales.customer_id;


/* 3. What was the first item from the menu purchased by each customer? */

-- Disable ONLY_FULL_GROUP_BY mode
SET sql_mode = ''

SELECT sales.customer_id, MIN(sales.order_date) AS first_purchased, menu.product_name 
FROM sales
INNER JOIN menu ON sales.product_id = menu.product_id 
GROUP BY customer_id;


/* 4. What is the most purchased item on the menu and how many times was it purchased by 
all customers? */

SELECT product_name, COUNT(sales.product_id) AS most_purchased_count
FROM sales
JOIN menu USING (product_id)
GROUP BY sales.product_id
ORDER BY most_purchased_count DESC
LIMIT 1;


/* 5. Which item was the most popular for each customer? */

SELECT customer_id, product_name
FROM 
    (SELECT customer_id, product_name, COUNT(menu.product_id),
    rank() over (PARTITION BY customer_id ORDER BY COUNT(sales.customer_id) DESC) AS `rank`  
    FROM sales
    JOIN menu USING (product_id)
    GROUP BY customer_id,product_id) temp
WHERE `rank` = 1;


/* 6. Which item was purchased first by the customer after they became a member? */

SELECT DISTINCT(customer_id), product_name 
FROM
    (SELECT customer_id, order_date, product_id, rank() over (PARTITION BY customer_id ORDER BY order_date ASC) AS `rank` 
    FROM sales 
    JOIN members USING (customer_id)
    where members.join_date < sales.order_date) temp
JOIN menu USING (product_id)
WHERE `rank` = 1;


/* 7. Which item was purchased just before the customer became a member? */

SELECT DISTINCT(customer_id), product_name 
FROM
    (SELECT customer_id, order_date, product_id, rank() over (PARTITION BY customer_id ORDER BY order_date ASC) AS `rank` 
    FROM sales 
    JOIN members USING (customer_id)
    where members.join_date > sales.order_date) temp
JOIN menu USING (product_id)
WHERE `rank` = 1;


/* 8. What is the total items and amount spent for each member before they became a member? */

SELECT sales.customer_id, COUNT(sales.product_id) AS total_items, SUM(menu.price) AS amount
FROM sales
JOIN menu USING(product_id)
JOIN members USING(customer_id)
WHERE sales.order_date < members.join_date
GROUP BY customer_id;


/* 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier-how many points would each customer have? */

SELECT customer_id, 
    SUM(
        CASE 
        WHEN sales.product_id = 1 THEN menu.price*20
        ELSE menu.price*10
        END) AS points
FROM sales
JOIN menu USING (product_id)
GROUP BY customer_id;


/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on
all items, not just sushi - how many points do customer A and B have at the end of January? */


WITH points_cte AS (
   SELECT *,
   DATE_ADD(join_date,INTERVAL 6 DAY) AS valid_date
   FROM members)

    SELECT p.customer_id,
    SUM(CASE
        WHEN menu.product_name = 'sushi' THEN 20*menu.price
        WHEN sales.order_date BETWEEN p.join_date AND p.valid_date THEN 20*menu.price
        ELSE 10*menu.price
        END) AS total_points
    FROM points_cte AS p
    JOIN sales
    ON p.customer_id = sales.customer_id
    JOIN menu 
    ON sales.product_id = menu.product_id
    WHERE sales.order_date < '2021-01-31'
    GROUP BY p.customer_id;

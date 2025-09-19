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

--What is the total amount each customer spent at the restaurant?

with cte as(select * from sales natural join menu)
select customer_id,sum(price) as total 
from cte 
group by customer_id;


--How many days has each customer visited the restaurant?

with cte as(select * from sales natural join menu)
select customer_id,count(*) as total_days from (select distinct customer_id,order_date 
from cte) as x
group by customer_id; 


--What was the first item from the menu purchased by each customer?
select customer_id,product_name from (select *,
dense_rank() over(partition by customer_id order by order_date) as rn
from sales 
natural join menu) as x
where rn=1;

--What is the most purchased item on the menu and how many times was it purchased by all customers?
with cte as(select product_id,count(*) as total
from sales
group by product_id)

select product_name
from cte natural join menu
order by total desc
limit 1
;

--Which item was the most popular for each customer?

select customer_id,product_name from (select *,
dense_rank() over(partition by customer_id order by total desc ) as rn
from (select customer_id,product_name,count(*)  as total from sales natural join menu
group by customer_id,product_name) as x) as y 
where rn=1;


--Which item was purchased first by the customer after they became a member?
select customer_id, product_name
from (
    select s.customer_id,
           s.order_date,
           m.product_name,
           dense_rank() over (
               partition by s.customer_id 
               order by s.order_date
           ) as rn
    from sales s
    join menu m 
      on s.product_id = m.product_id
    join members me 
      on s.customer_id = me.customer_id
    where s.order_date >= me.join_date
) as t
where rn = 1;


--Which item was purchased just before the customer became a member?
select customer_id,product_name
from 
(select *,
dense_rank() over(partition by customer_id order by order_date desc) as rn 
from sales natural join members
where order_date <join_date) as x  natural join menu 
where rn=1;

--What is the total items and amount spent for each member before they became a member?
with cte as(select customer_id,product_id,order_date from sales natural join members
where join_date >order_date)

select customer_id,count(*) as total_items,sum(price) as amount
from (select * from cte natural join menu) as x
group by customer_id;

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select customer_id,sum(points) as total_points
from (select customer_id,
case when product_name = 'sushi' then price*20
else price*10 end as points
from sales natural join menu) as x
group by customer_id;

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--not just sushi - how many points do customer A and B have at the end of January?

select customer_id,sum(points) as total
from (select customer_id,
case
when product_name ='sushi' or order_date between join_date and join_date + Interval '6 days' then price*20
else price*10 end as points
from sales 
natural join
members
natural join 
menu
where order_date <='2021-01-31') as x
group by customer_id;








































  


 






  
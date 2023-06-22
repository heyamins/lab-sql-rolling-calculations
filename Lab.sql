/*
Retained customers every month.
*/

-- Get number of monthly active customers.
with cte_active_users as (
select customer_id, convert(rental_date, date) as Activity_date,
	date_format(convert(rental_date, date), '%m') as Activity_month,
    date_format(convert(rental_date, date), '%y') as Activity_year
    from sakila.rental
    )
    select Activity_year, Activity_month, count(distinct customer_id) as Active_Users
    from cte_active_users
    group by Activity_year, Activity_month;
    
-- Active users in the previous month.
with cte_active_users as (
	select customer_id, convert(rental_date, date) as Activity_date,
	date_format(convert(rental_date, date), '%m') as Activity_month,
    date_format(convert(rental_date, date), '%y') as Activity_year
    from sakila.rental
    ),
    cte_pre_month as (
    select Activity_year, Activity_month, count(distinct customer_id) as Active_Users
    from cte_active_users
    group by Activity_year, Activity_month 
    )
select Activity_year, Activity_month, Active_Users, 
lag(Active_Users) over (order by Activity_year, Activity_month) as Last_Month
from cte_pre_month;

-- Percentage change in the number of active customers. --> will finish 6/23 
/*
with cte_active_users as (
	select customer_id, convert(rental_date, date) as Activity_date,
	date_format(convert(rental_date, date), '%m') as Activity_month,
    date_format(convert(rental_date, date), '%y') as Activity_year
    from sakila.rental
    ),
    cte_pre_month as (
    select Activity_year, Activity_month, count(distinct customer_id) as Active_Users
    from cte_active_users
    group by Activity_year, Activity_month 
    ),
    cte_Percent_change as (
    select Activity_year, Activity_month, Active_Users, 
	lag(Active_Users) over (order by Activity_year, Activity_month) as Last_Month
	from cte_pre_month
    )
select *, Active_Users-Last_Month as difference, concat(round((Active_Users - Last_Month) / Active_Users * 100), "%") percentage 
from cte_Percent_change;

-- Retained customers every month.


-- step 1: get the unique active users per month
with cte_transactions as (
	select account_id, convert(date, date) as Activity_date,
		date_format(convert(date,date), '%m') as Activity_Month,
		date_format(convert(date,date), '%Y') as Activity_year
	from bank.trans
)
select distinct 
	account_id as Active_id, 
	Activity_year, 
	Activity_month
from cte_transactions
order by Active_id, Activity_year, Activity_month;

-- step 2: self join to find recurrent customers (users that made a transfer this month and also last month)
with cte_transactions as (
	select account_id, convert(date, date) as Activity_date,
		date_format(convert(date,date), '%m') as Activity_Month,
		date_format(convert(date,date), '%Y') as Activity_year
	from bank.trans
), recurrent_transactions as (
	select distinct 
		account_id as Active_id, 
		Activity_year, 
		Activity_month
	from cte_transactions
	order by Active_id, Activity_year, Activity_month
)
select rec1.Active_id, rec1.Activity_year, rec1.Activity_month, rec2.Activity_month as Previous_month
from recurrent_transactions rec1
join recurrent_transactions rec2
	on rec1.Activity_year = rec2.Activity_year -- To match the similar years. It is not perfect, is we wanted to make sure that, for example, Dez/1994 would connect with Jan/1995, we would have to do something like: case when rec1.Activity_month = 1 then rec1.Activity_year + 1 else rec1.Activity_year end
	and rec1.Activity_month = rec2.Activity_month+1 -- To match current month with previous month. It is not perfect, if you want to connect Dezember with January we would need something like this: case when rec2.Activity_month+1 = 13 then 12 else rec2.Activity_month+1 end;
	and rec1.Active_id = rec2.Active_id -- To get recurrent users.
order by rec1.Active_id, rec1.Activity_year, rec1.Activity_month;
*/
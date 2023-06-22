-- Rolling Calculations

-- Rolling sum of the amount transfered in transactions per account:
select account_id, date, amount,
	sum(amount) over (partition by account_id order by date) -- order by account_id, date -- partition by account_id
from bank.trans;


-- Rolling Calculations with LAG()

select trans_id, account_id, date, balance, lag(balance) over () -- partition by account_id order by date
from trans;

-- Return the difference between the amount of monthly active users and the active users from the previous month:
-- monthly active users - previous month active users

-- step 1: get the monthly active users:
with cte_transactions as (
	select account_id, convert(date, date) as Activity_date,
		date_format(convert(date,date), '%m') as Activity_Month,
		date_format(convert(date,date), '%Y') as Activity_year
	from bank.trans
)
select Activity_year, Activity_Month, count(distinct account_id) as Active_users
from cte_transactions
group by Activity_year, Activity_Month;

-- step 2: get the active users from previous month as a column:
with cte_transactions as (
	select account_id, convert(date, date) as Activity_date,
		date_format(convert(date,date), '%m') as Activity_Month,
		date_format(convert(date,date), '%Y') as Activity_year
	from bank.trans
), cte_active_users as (
	select Activity_year, Activity_Month, count(distinct account_id) as Active_users
	from cte_transactions
	group by Activity_year, Activity_Month
)
select Activity_year, Activity_month, Active_users, 
   lag(Active_users) over (order by Activity_year, Activity_Month) as Last_month
from cte_active_users;

-- step 3: get the difference between active users and active users from previous month:
with cte_transactions as (
	select account_id, convert(date, date) as Activity_date,
		date_format(convert(date,date), '%m') as Activity_Month,
		date_format(convert(date,date), '%Y') as Activity_year
	from bank.trans
), cte_active_users as (
	select Activity_year, Activity_Month, count(distinct account_id) as Active_users
	from cte_transactions
	group by Activity_year, Activity_Month
), cte_active_users_prev as (
	select Activity_year, Activity_month, Active_users, 
	   lag(Active_users) over (order by Activity_year, Activity_Month) as Last_month
	from cte_active_users)
select *,
	(Active_users - Last_month) as Difference,
    concat(round((Active_users - Last_month)/Active_users*100), "%") as Percent_Difference
from cte_active_users_prev;


-- Rolling Calculations with Self Joins

-- Return the recurrent clients (clients that made transactions at least 2 subsequent months):

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

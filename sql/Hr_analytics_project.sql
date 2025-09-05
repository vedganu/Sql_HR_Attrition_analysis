create table HrAtrition (
    Age INT,
    Attrition TEXT,
    BusinessTravel TEXT,
    DailyRate INT,
    Department TEXT,
    DistanceFromHome INT,
    Education INT,
    EducationField TEXT,
    EmployeeCount TEXT,  -- Duplicate column name handled
    EmployeeNumber TEXT,
    EnvironmentSatisfaction INT,
    Gender TEXT,
    HourlyRate INT,
    JobInvolvement INT,
    JobLevel INT,
    JobRole TEXT,
    JobSatisfaction INT,
    MaritalStatus TEXT,
    MonthlyIncome NUMERIC(12,2),
    MonthlyRate INT,
    NumCompaniesWorked INT,
    Over18 TEXT,
    OverTime TEXT,
    PercentSalaryHike INT,
    PerformanceRating INT,
    RelationshipSatisfaction INT,
    StandardHours INT,
    StockOptionLevel INT,
    TotalWorkingYears INT,
    TrainingTimesLastYear INT,
    WorkLifeBalance INT,
    YearsAtCompany INT,
    YearsInCurrentRole INT,
    YearsSinceLastPromotion INT,
    YearsWithCurrManager INT
);

/* Hr suspects that missing values and inconsistent format are hiding the
 * real drivers of attrition . before analysis , we must clean and validate data */


 -- Overviewing data  

select * from  HrAtrition ;

select count(*) as TotalRows from HrAtrition; -- 1,470 
select count(*) filter (where Employee)

-- i am overlook missing values in some importan columns
select 
	count(*) filter (where Age is null) as NullAge,
	count(*) filter (where Attrition is null) as NullAttrition,
	count(*) filter (where EmployeeNumber is null) as NullEmplyeeNumber,
	count(*) filter (where MonthlyIncome is null ) as NullMonthlyIncome
 from HrAtrition;


-- Counting employees per department
select Department, count(*) as EmployeeCount 
from HrAtrition 
group by Department 
order by EmployeeCount  desc; -- R&D 961 ,sales-446 ,Hr 63 

-- now i am overlook Attrition to see which department and roles are most affected by attrition
-- sales and r and d roles are losing talent fast .
-- we need to tackle problem 

select  Department, count(*)as total_employee,
count(*) as total_count ,
count(case when Attrition = 'Yes' then 1 end)as yes_count,
count(case when Attrition = 'No' then 1 end ) as no_count,
round(100.0 * count(*) filter (where Attrition = 'Yes')/count(*),2) as Attrition_rate
from HrAtrition 
group by Department
order by Attrition_rate desc;

select Department, min(MonthlyIncome),max(MonthlyIncome) ,
round(avg(MonthlyIncome),2) as AVgIncome
from HrAtrition
group by Department;


-- i want to see attrtion by department and job role ( top 5 riskiest)
with RoleRates as (
select Department,JobRole,
count(*) as Headcount,
count(*) filter (where Attrition = 'Yes') as "Attritions",
100 *count(*) filter (where Attrition ='Yes')/nullif(count(*),0) as AttrRate
from  HrAtrition
group by Department,JobRole)
select * from RoleRates 
order by AttrRate desc, Headcount desc 
limit 5;


select min(age), max(age) from HrAtrition
;

/* Now i am try to understanding how long an employee has been at the 
 * company  */
-- Average years at company
select round(avg(YearsAtCompany),2) as AvgYears
from HrAtrition ;

-- Attrition by tenure bracket
select 
	case 
		when YearsAtCompany <3 then '0-2 Years'
		when YearsAtCompany between 3 and 5 then '3-5 Years'
		when YearsAtCompany between 5 and 10 then '6-10 Years'
		else '10+ Years'
		end as TenureGroup,
		count(*)filter (where Attrition ='Yes') as AttritionCount
		from HrAtrition 
		group by TenureGroup 
		order by TenureGroup;
	
	
                                                                                              
-- Some top contributors are quitting despite good pay and ratings .Why?
select EmployeeNumber, Department,MonthlyIncome, PerformanceRating,
	dense_rank() over (partition by Department order by MonthlyIncome desc) as IncomeRank
	from HrAtrition 
	where Attrition = 'Yes';
 


/*
i am here interesting to that compensation linked to attrition 8*/
with income_ranked as (
  select *,
         ntile(4) over (order by MonthlyIncome) as income_quartile
  from HrAtrition
  where MonthlyIncome is not null
)
select income_quartile,
       count(*) AS n,
      round(100.0 * avg((Attrition = 'Yes')::int), 2) AS attrition_pct
from income_ranked
group by income_quartile
order by income_quartile;


--Lower income quartiles often show higher attrition—suggesting pay dissatisfaction or lack of career pathing.


--Are we losing top performers
select  PerformanceRating,
       count(*) AS total,
       sum((Attrition = 'Yes')::int) AS attritions,
       round(100.0 * AVG((Attrition = 'Yes')::int), 2) AS attrition_pct
from HrAtrition
group by  PerformanceRating
order by attrition_pct desc;


-- Further processing we neeed to export data in csv file to pandas


-- create the databases
CREATE DATABASE project;
CREATE DATABASE employee;

-- create a table for employee records in employee database
CREATE TABLE employee.employee_records_table
(
	EMP_ID varchar(4) PRIMARY KEY,
    FIRST_NAME varchar(30),
    LAST_NAME varchar(30),
    GENDER varchar(1),
    ROLE varchar(100),
    DEPT varchar(30),
    EXP int,
    COUNTRY varchar(20),
    CONTINENT varchar(30),
    SALARY int,
    EMP_RATING int,
    MANAGER_ID varchar(4)
);

-- create the two tables in the Project database
CREATE TABLE project.Data_Science_Team
(
	EMP_ID varchar(4) PRIMARY KEY,
	FIRST_NAME varchar(50),
	LAST_NAME varchar(50),
	GENDER varchar(1),
	ROLE varchar(100),
	DEPT varchar(15),
	EXP int,
	COUNTRY varchar(20),
	CONTINENT varchar(30),
	FOREIGN KEY (EMP_ID) REFERENCES employee.employee_records_table(EMP_ID)
);

CREATE TABLE project.Project_Table
(
	PROJ_ID varchar(4),
    PROJ_NAME varchar(100),
    DOMAIN varchar(20),
    START_DATE DATE,
    CLOSURE_DATE DATE,
    DEV_QTR varchar(2),
    STATUS varchar(15)
);

-- insert data into the project database
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/proj_table.csv"
INTO TABLE project.project_table
FIELDS TERMINATED BY ',' 
LINES terminated by '\n'
IGNORE 1 LINES;
SELECT * FROM project_table;

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/data_science_team.csv"
INTO TABLE project.data_science_team
FIELDS TERMINATED BY ',' 
LINES terminated by '\n'
IGNORE 1 LINES;
SELECT * FROM  data_science_team;
 
 -- insert data into the employee database
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/emp_record_table.csv"
INTO TABLE employee.employee_records_table
FIELDS TERMINATED BY ',' 
LINES terminated by '\n'
IGNORE 1 LINES;
SELECT * FROM employee_records_table;

SELECT EMP_ID, FIRST_NAME, LAST_NAME, GENDER, DEPT
FROM employee.employee_records_table;

SELECT EMP_ID, FIRST_NAME, LAST_NAME, GENDER, DEPT, EMP_RATING
FROM employee.employee_records_table
WHERE EMP_RATING < 2 
OR EMP_RATING > 4
OR (EMP_RATING >= 2 AND EMP_RATING <= 4); -- This will return all rows since every EMP_RATING condition is met

-- Concat all Finance dept members names
SELECT CONCAT(FIRST_NAME,' ', LAST_NAME) AS NAME 
FROM employee.employee_records_table
WHERE DEPT = 'FINANCE' ; 

-- list the employees (managers) who have someone reporting to them. Also, show the number of reporters, including the President
SELECT E.EMP_ID, E.FIRST_NAME, E.LAST_NAME, E.ROLE, COUNT(DISTINCT R.EMP_ID) AS NUMBER_OF_REPORTERS
FROM employee.employee_records_table E
LEFT JOIN employee.employee_records_table R ON E.EMP_ID = R.MANAGER_ID
GROUP BY E.EMP_ID, E.FIRST_NAME, E.LAST_NAME, E.ROLE
HAVING COUNT(DISTINCT R.EMP_ID) > 0; -- filter out employees with no subordinates

-- list  all the employees from the healthcare and finance department using UNION
SELECT * 
FROM employee.employee_records_table WHERE (DEPT = 'FINANCE')
UNION
SELECT * 
FROM employee.employee_records_table WHERE (DEPT = 'HEALTHCARE');

-- list down employee details including the max EMP_RATING rating for each Department, grouped by Department
SELECT EMP_ID, First_name, Last_name, Role, DEPT, Emp_rating, 
	 MAX(EMP_RATING) OVER (partition by DEPT) AS MAX_DEPT_RATING
FROM employee.employee_records_table
GROUP BY DEPT, EMP_ID, FIRST_NAME, LAST_NAME, ROLE, EMP_RATING;

--  calculate the minimum and the maximum salary of the employees in each role
SELECT Role, 
	   MIN(Salary) AS MIN_SALARY,
       MAX(Salary) AS MAX_SALARY
FROM employee.employee_records_table
GROUP BY Role;

-- assign a rank to each employee based on experience
SELECT
    EMP_ID,
    FIRST_NAME,
    LAST_NAME,
    EXP,
    RANK() OVER (ORDER BY EXP DESC) AS Employee_Ranking
FROM employee.employee_records_table; -- most experience = rank 1

-- Write a query to create a view that displays employees in countries whose salary is more than six thousand
SELECT EMP_ID, FIRST_NAME, LAST_NAME, SALARY, COUNTRY
FROM employee.employee_records_table
WHERE Salary > 6000
order by COUNTRY, SALARY desc;

-- Write a nested query to find employees with experience of more than ten years
SELECT EMP_ID, FIRST_NAME, LAST_NAME, EXP
FROM employee.employee_records_table
WHERE EXP > (
	SELECT 10);

-- Write a query to create a stored procedure to retrieve the details of the employees whose experience is more than three years
DELIMITER //
CREATE PROCEDURE ThreePlusYearsExp()
BEGIN
    SELECT EMP_ID, FIRST_NAME, LAST_NAME, exp
    FROM employee.employee_records_table
    WHERE exp > 3;
END //
DELIMITER ;
CALL ThreePlusYearsExp;

-- Query using stored functions in the project table to check whether the -
-- job profile assigned to each employee in the data science team matches the organization’s set standard
DELIMITER $$  
CREATE FUNCTION Employee_Profile(exp int)   
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
	DECLARE job_profile VARCHAR(50);
    IF exp <= 2 THEN 
		SET job_profile =  'JUNIOR DATA SCIENTIST';
	ELSEIF exp > 2 AND exp <= 5 THEN
        SET job_profile = 'ASSOCIATE DATA SCIENTIST';
    ELSEIF exp > 5 AND exp <= 10 THEN
        SET job_profile = 'SENIOR DATA SCIENTIST';
    ELSEIF exp > 10 AND exp <= 12 THEN
        SET job_profile = 'LEAD DATA SCIENTIST';
    ELSE
        SET job_profile = 'MANAGER';
    END IF;
    RETURN job_profile;
END$$
DELIMITER ;
-- Create an instance. In this case 8 years, which will return SENIOR DATA SCIENTIST
SET @job_profile = Employee_Profile(8);    
select @job_profile as Job_profile;

-- Create an index to improve the cost and performance of the query to find the employee -
-- whose FIRST_NAME is ‘Eric’ in the employee table after checking the execution plan.
CREATE INDEX employee_index
ON employee.employee_records_table (FIRST_NAME);
EXPLAIN SELECT * FROM employee.employee_records_table WHERE FIRST_NAME = 'Eric';
select * from employee_records_table;

-- calculate the bonus for all the employees, based on their ratings and salaries (Use the formula: 5% of salary * employee rating).
SELECT CONCAT(FIRST_NAME,' ',LAST_NAME) as NAME, EMP_RATING, salary, (salary*.05)*(EMP_RATING) as BONUS
FROM employee.employee_records_table;

-- calculate the average salary distribution based on the continent and country. 
SELECT COUNTRY, CONTINENT, CAST(AVG(SALARY) AS DECIMAL(10,2)) AS AVERAGE_SALARY -- AS DECIMAL to round to two decimal places
FROM employee.employee_records_table
group by COUNTRY, CONTINENT;

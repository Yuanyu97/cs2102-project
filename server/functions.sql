CREATE OR REPLACE PROCEDURE add_employee (
    emp_name TEXT,
    emp_home_address TEXT,
    emp_contact_number TEXT,
    emp_email_address TEXT,
    emp_join_date DATE,
    emp_category TEXT,
    emp_monthly_salary NUMERIC DEFAULT NULL,
    emp_hourly_rate NUMERIC DEFAULT NULL,
    emp_course_areas TEXT[] DEFAULT '{}'
) AS $$
DECLARE
    emp_id INTEGER;
    emp_course_area TEXT;
BEGIN
    IF (emp_category = 'administrator' AND array_length(emp_course_areas, 1) > 0) THEN
        RAISE EXCEPTION 'administrator should not have any course areas';
    END IF;

    IF (emp_monthly_salary IS NULL AND emp_hourly_rate IS NULL) THEN
        RAISE EXCEPTION 'hourly rate and monthly salary cannot be both NULL';
    END IF;

    IF (emp_monthly_salary IS NOT NULL AND emp_hourly_rate IS NOT NULL) THEN
        RAISE EXCEPTION 'hourly rate and monthly salary cannot be both NOT NULL';
    END IF;

    -- full time emp
    IF (emp_monthly_salary IS NOT NULL) THEN 
        IF (emp_category = 'manager') THEN
            INSERT INTO Employees(name, address, phone, email, join_date) VALUES (emp_name, emp_home_address, 
            emp_contact_number, emp_email_address, emp_join_date) RETURNING eid into emp_id;
            INSERT INTO Full_Time_Emp(eid, monthly_salary) VALUES(emp_id, emp_monthly_salary);
            INSERT INTO Managers(mid) VALUES(emp_id);
            FOREACH emp_course_area IN ARRAY emp_course_areas 
            LOOP
                INSERT INTO Course_areas(area_name, mid) VALUES(emp_course_area, emp_id);
            END LOOP;
        ELSIF (emp_category = 'administrator') THEN
            INSERT INTO Employees(name, address, phone, email, join_date) VALUES (emp_name, emp_home_address,
            emp_contact_number, emp_email_address, emp_join_date) RETURNING eid into emp_id;
            INSERT INTO Full_Time_Emp(eid, monthly_salary) VALUES(emp_id, emp_monthly_salary);
            INSERT INTO Administrators(aid) VALUES(emp_id);
        ELSIF (emp_category = 'instructor') THEN 
            INSERT INTO Employees(name, address, phone, email, join_date) VALUES (emp_name, emp_home_address,
            emp_contact_number, emp_email_address, emp_join_date) RETURNING eid into emp_id;
            INSERT INTO Full_Time_Emp(eid, monthly_salary) VALUES(emp_id, emp_monthly_salary);
            FOREACH emp_course_area in ARRAY emp_course_areas
            LOOP
                INSERT INTO Full_Time_Instructor(ftid, area_name) VALUES(emp_id, emp_course_area);
            END LOOP;
        END IF;
    -- part time emp
    ELSE 
        IF (emp_category = 'manager') THEN
            RAISE EXCEPTION 'a manager is not a part time employee';
        ELSIF (emp_category = 'administrator') THEN
            RAISE EXCEPTION 'an administrator is not a part time employee';
        ELSE 
            INSERT INTO Employees(name, address, phone, email, join_date) VALUES (emp_name, emp_home_address,
            emp_contact_number, emp_email_address, emp_join_date) RETURNING eid into emp_id;
            INSERT INTO Part_Time_Emp(eid, hourly_rate) VALUES(emp_id, emp_hourly_rate);
            FOREACH emp_course_area in ARRAY emp_course_areas
            LOOP
                INSERT INTO Part_Time_Instructor(ftid, area_name) VALUES(emp_id, emp_course_area);
            END LOOP;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE remove_employee (
    emp_id INTEGER,
    emp_depart_date DATE
) AS $$
    WITH SessionsAndInstructors AS (
        SELECT iid , s_date FROM Sessions S INNER JOIN (
            SELECT iid, sid FROM Conducts
        ) AS C ON C.sid = S.sid
    )
    UPDATE Employees 
    SET depart_date = emp_depart_date
    WHERE eid = emp_id AND emp_id NOT IN (
        SELECT DISTINCT mid FROM Course_areas
        WHERE mid = emp_id
        UNION
        SELECT DISTINCT iid FROM SessionsAndInstructors
        WHERE s_date > emp_depart_date
        AND iid = emp_id
        UNION 
        SELECT DISTINCT aid FROM Offerings
        WHERE registration_deadline > emp_depart_date
        AND aid = emp_id
    );
$$ LANGUAGE SQL;

CREATE OR REPLACE PROCEDURE add_customer (
    cname TEXT,
    cust_home_address TEXT,
    cust_contact_number TEXT,
    cust_email_address TEXT,
    cust_credit_card_number TEXT,
    cust_credit_card_expiry_date DATE,
    cust_credit_card_cvv CHAR(3)
) AS $$
BEGIN
    INSERT INTO Credit_cards(credit_card_number, cvv, expiry_date, from_date) VALUES(cust_credit_card_number,
    cust_credit_card_cvv, cust_credit_card_expiry_date, CURRENT_DATE);
    INSERT INTO Customers(credit_card_number, name, address, email, phone) VALUES(cust_credit_card_number,
     cname, cust_home_address, cust_email_address, cust_contact_number);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE update_credit_card (
    cid INTEGER,
    new_credit_card_number TEXT,
    new_credit_card_expiry_date DATE,
    new_credit_card_cvv CHAR(3)
) AS $$
DECLARE 
    old_credit_card_number TEXT;
BEGIN
    SELECT credit_card_number INTO old_credit_card_number FROM Customers WHERE cid = cust_id;
    UPDATE Credit_cards
    SET credit_card_number = new_credit_card_number,
        cvv = new_credit_card_cvv,
        expiry_date = new_credit_card_expiry_date
    WHERE credit_card_number = old_credit_card_number;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE add_course (
    course_title TEXT,
    course_description TEXT,
    course_area_name TEXT,
    course_duration INTEGER
) AS $$
    INSERT INTO Courses(title, duration, description, area_name) VALUES(course_title, course_duration,
    course_description, course_area_name);
$$ LANGUAGE SQL;

CREATE OR REPLACE PROCEDURE add_course_package(
package_name TEXT,
num_free_registrations INTEGER,
sale_start_date DATE,
sale_end_date DATE,
price FLOAT) AS $$
INSERT INTO Course_packages (package_name, num_free_registrations, sale_start_date, sale_end_date, price)
VALUES(package_name, num_free_registrations, sale_start_date, sale_end_date, price);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_available_course_packages()
RETURNS TABLE (
package_name TEXT,
num_free_sessions INT,
end_date DATE,
price FLOAT) AS $$
SELECT package_name, num_free_registrations, sale_end_date, price
FROM Course_packages
WHERE sale_end_date >= CURRENT_DATE AND sale_start_date <= CURRENT_DATE;
$$ LANGUAGE SQL;

CREATE OR REPLACE PROCEDURE buy_course_package(
_cust_id INTEGER,
_package_id INTEGER) AS $$
DECLARE
sale_start_date DATE;
sale_end_date DATE;
BEGIN
SELECT Course_packages.sale_start_date, Course_packages.sale_end_date into sale_start_date, sale_end_date FROM Course_packages WHERE Course_packages.package_id = _package_id;
IF (sale_end_date >= CURRENT_DATE AND sale_start_date <= CURRENT_DATE) THEN
INSERT INTO Buys(buy_date, cust_id, package_id) VALUES(CURRENT_DATE, _cust_id,  _package_id);
ELSE
RAISE EXCEPTION 'Course Package is not on sale';
END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_available_course_offerings()
RETURNS TABLE (
course_title TEXT,
course_area TEXT,
start_date DATE,
end_date DATE,
registration_deadline DATE,
course_fees FLOAT,
number_of_remaining_seats INTEGER) AS $$
with num_registrations_for_each_session as (
SELECT COUNT(Registers.cust_id) as num_registrations, Sessions.course_id, Sessions.launch_date
FROM Sessions LEFT JOIN Registers ON Sessions.sid = Registers.sid
GROUP BY Sessions.course_id, Sessions.launch_date),
offerings_join_courses as (
SELECT Offerings.course_id, Offerings.launch_date, Courses.title as course_title, Courses.area_name as course_area, Offerings.start_date, Offerings.end_date, Offerings.registration_deadline, Offerings.fees as course_fees, Offerings.seating_capacity
FROM Offerings INNER JOIN Courses ON Offerings.course_id = Courses.course_id)
SELECT course_title, course_area, start_date, end_date, registration_deadline, course_fees, seating_capacity - num_registrations as number_of_remaining_seats
FROM offerings_join_courses LEFT JOIN num_registrations_for_each_session
ON offerings_join_courses.course_id = num_registrations_for_each_session.course_id AND offerings_join_courses.launch_date = num_registrations_for_each_session.launch_date
WHERE registration_deadline >= CURRENT_DATE;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_available_course_sessions(_offering_id INTEGER)
RETURNS TABLE (
session_date DATE,
start_hour INTEGER,
instructor_name TEXT,
remaining_seats INTEGER) AS $$
DECLARE
c_id INTEGER;
l_date DATE;
BEGIN
SELECT course_id, launch_date INTO c_id, l_date
FROM Offerings
WHERE Offerings.offering_id = _offering_id;
RETURN QUERY
with instructor_name_mapping AS (
SELECT DISTINCT Instructors.iid, Employees.name
FROM Instructors LEFT JOIN Employees ON Instructors.iid = Employees.eid
),
sessions_instructors_table AS (
SELECT instructor_name_mapping.name, Conducts.sid, Conducts.course_id, Rooms.seating_capacity, Sessions.start_time, Sessions.s_date
FROM Conducts LEFT JOIN instructor_name_mapping ON Conducts.iid = instructor_name_mapping.iid LEFT JOIN Rooms ON Conducts.rid = Rooms.rid LEFT JOIN Sessions ON Conducts.sid = Sessions.sid AND Sessions.course_id = Conducts.course_id
WHERE Conducts.course_id = c_id AND Conducts.launch_date = l_date
),
num_registrations_for_each_session as (
SELECT COUNT(Registers.cust_id) as num_registrations, Sessions.course_id, Sessions.sid
FROM Sessions LEFT JOIN Registers ON Sessions.sid = Registers.sid
GROUP BY Sessions.course_id, Sessions.sid
)
SELECT sessions_instructors_table.s_date as session_date, sessions_instructors_table.start_time as start_hour, sessions_instructors_table.name as instructor_name, (sessions_instructors_table.seating_capacity - num_registrations)::int as remaining_seats
FROM sessions_instructors_table LEFT JOIN num_registrations_for_each_session ON sessions_instructors_table.course_id = num_registrations_for_each_session.course_id AND sessions_instructors_table.sid = num_registrations_for_each_session.sid
ORDER BY sessions_instructors_table.s_date, sessions_instructors_table.start_time;
END;
$$ LANGUAGE plpgsql;
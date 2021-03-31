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
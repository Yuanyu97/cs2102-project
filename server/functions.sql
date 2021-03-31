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
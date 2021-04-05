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
        SELECT iid , s_date FROM Sessions S INNER JOIN Conducts C on C.sid = S.sid and S.course_id = C.course_id and C.launch_date = S.launch_date
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

CREATE OR REPLACE FUNCTION find_instructors (
    cid INTEGER,
    session_start_date DATE,
    session_start_hour INTEGER
) RETURNS TABLE(inst_id INTEGER, inst_name TEXT) AS $$
DECLARE 
    session_end_hour INTEGER;
    course_duration INTEGER;
    num_sessions_offered INTEGER;
    session_duration INTEGER;
    offering_launch_date DATE;
    r RECORD;
BEGIN
    -- how to get session duration?
    -- course duration / number of sessions in offering
    -- how to get course duration? Course.duration
    -- how to get number of sessions in offering? given: cid, session_start_date
    -- find session launch date in Sessions
    -- use Sessions - group by course_id and launch_date 
    -- Count rows
    SELECT launch_date INTO offering_launch_date FROM Sessions
    WHERE course_id = cid AND s_date = session_start_date AND start_time = session_start_hour
    LIMIT 1;

    SELECT duration INTO course_duration FROM Courses WHERE course_id = cid;

    SELECT COUNT(*) INTO num_sessions_offered FROM Sessions
    WHERE course_id = cid AND launch_date = offering_launch_date;

    session_duration := course_duration / num_sessions_offered;

    session_end_hour := session_start_hour + session_duration;

    RETURN QUERY
    WITH SpecializingInstructors AS (
        SELECT DISTINCT ftid AS iid
        FROM Full_Time_Instructor FT
        WHERE EXISTS (
            SELECT 1
            FROM Courses C
            WHERE C.course_id = cid AND C.area_name = FT.area_name
        )
        UNION
        SELECT DISTINCT ptid AS iid
        FROM Part_Time_Instructor PT
        WHERE EXISTS (
            SELECT 1
            FROM Courses C
            WHERE C.course_id = cid AND C.area_name = PT.area_name
        )
        UNION
        SELECT DISTINCT iid
        FROM Instructors I
        WHERE EXISTS (
            SELECT 1
            FROM Courses C
            WHERE C.course_id = cid AND C.area_name = I.area_name
        )
    ),
    MaxHoursQuotaReachedInstructors AS (
        SELECT DISTINCT iid 
        FROM Conducts C INNER JOIN Sessions S ON S.sid = C.sid AND S.course_id = C.course_id
        GROUP BY iid 
        HAVING SUM(end_time - start_time) >= 30
        EXCEPT
        SELECT ftid
        FROM Full_Time_Instructor
    ),
    -- must course_id same as cid?
    -- no, the instructor just has to specialize in that area
    TimeNotAvailableInstructors AS (
        SELECT DISTINCT iid
        FROM Conducts C INNER JOIN Sessions S ON S.sid = C.sid AND S.course_id = C.course_id
        WHERE session_start_date = s_date AND NOT (session_start_hour > end_time OR session_end_hour < start_time)
    ),
    AvailableInstructors AS (
        SELECT iid FROM SpecializingInstructors EXCEPT SELECT iid FROM MaxHoursQuotaReachedInstructors EXCEPT 
        SELECT iid FROM TimeNotAvailableInstructors
    )
    SELECT eid, name 
    FROM AvailableInstructors INNER JOIN Employees ON iid = eid;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_available_instructors(
    cid INTEGER,
    course_start_date DATE,
    course_end_date DATE
) RETURNS TABLE(emp_id INTEGER, emp_name TEXT, emp_total_hours INTEGER, emp_avail_day DATE, emp_avail_hours INT[]) AS $$
DECLARE
    r RECORD;
    date_diff INTEGER;
    counter_date INTEGER;
    counter_hours INTEGER;
    current_date DATE;
    avail_hours INTEGER[];
BEGIN
    CREATE OR REPLACE VIEW SpecializingInstructors AS (
        SELECT DISTINCT ftid AS iid
        FROM Full_Time_Instructor FT
        WHERE EXISTS (
            SELECT 1
            FROM Courses C
            WHERE cid = C.course_id AND C.area_name = FT.area_name
        )
        UNION
        SELECT DISTINCT ptid AS iid
        FROM Part_Time_Instructor PT
        WHERE EXISTS (
            SELECT 1
            FROM Courses C
            WHERE cid = C.course_id  AND C.area_name = PT.area_name
        )
        UNION
        SELECT DISTINCT iid
        FROM Instructors I
        WHERE EXISTS (
            SELECT 1
            FROM Courses C
            WHERE cid = C.course_id AND C.area_name = I.area_name
        )
    );
    CREATE OR REPLACE VIEW ConductsAndSessions AS (
        SELECT C.sid, C.course_id, s_date, start_time, end_time, iid
        FROM Conducts C INNER JOIN Sessions S ON C.sid = S.sid AND C.course_id = S.course_id
        ORDER BY iid, s_date
    );
    CREATE OR REPLACE VIEW InstructorsWhoTeachThisMonth AS (
        SELECT iid, start_time, end_time
        FROM ConductsAndSessions
        WHERE EXTRACT(MONTH FROM s_date) = EXTRACT(MONTH FROM CURRENT_DATE)
    );
    CREATE OR REPLACE VIEW InstructorsWhoDoesNotTeachThisMonth AS (
        SELECT iid, 0 AS teaching_hours
        FROM (SELECT iid FROM SpecializingInstructors EXCEPT SELECT iid FROM InstructorsWhoTeachThisMonth) AS X
    );
    CREATE OR REPLACE VIEW InstructorsHoursOfTheMonth AS (
        SELECT iid, SUM(end_time - start_time) AS teaching_hours
        FROM InstructorsWhoTeachThisMonth
        GROUP BY iid
        UNION
        SELECT iid, teaching_hours
        FROM InstructorsWhoDoesNotTeachThisMonth
    );

    date_diff := course_end_date - course_start_date;   
    FOR r in 
        SELECT DISTINCT ftid AS iid
        FROM Full_Time_Instructor FT
        WHERE EXISTS (
            SELECT 1
            FROM Courses C
            WHERE C.course_id = cid AND C.area_name = FT.area_name
        )
        UNION
        SELECT DISTINCT ptid AS iid
        FROM Part_Time_Instructor PT
        WHERE EXISTS (
            SELECT 1
            FROM Courses C
            WHERE C.course_id = cid AND C.area_name = PT.area_name
        )
        UNION
        SELECT DISTINCT iid
        FROM Instructors I
        WHERE EXISTS (
            SELECT 1
            FROM Courses C
            WHERE C.course_id = cid AND C.area_name = I.area_name
        )
    LOOP
        --FETCH curs INTO r;
        --EXIT WHEN NOT FOUND;
        current_date := course_start_date;
        FOR counter_date IN 1..date_diff
        LOOP
            avail_hours := "{}";
            FOR counter_hours in 9..17 
            LOOP
                CONTINUE WHEN counter_hours = 12 OR counter_hours = 13 OR 
                    EXISTS(
                        SELECT 1 
                        FROM ConductsAndSessions C
                        WHERE r.iid = C.iid AND C.s_date = current_date AND C.start_time <= counter_hours AND counter_hours <= C.end_time
                    );
                avail_hours := ARRAY_APPEND(avail_hours, counter_hours);
            END LOOP;
            RETURN QUERY
            SELECT r.iid, (SELECT name FROM Employees WHERE eid = r.iid), 
                (SELECT teaching_hours FROM InstructorsHoursOfTheMonth WHERE iid = r.iid), current_date, avail_hours;
        END LOOP;
        current_date := current_date + 1;
    END LOOP; 
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION find_rooms (
    session_date DATE,
    session_start_hour INTEGER,
    session_duration INTEGER
) RETURNS TABLE(room_id INTEGER) AS $$
    WITH NotAvailableRooms AS (
        SELECT rid
        FROM Sessions NATURAL JOIN Conducts 
        WHERE s_date = session_date AND 
              ((start_time < session_start_hour AND  session_start_hour < end_time)
              OR 
               (start_time < session_start_hour + session_duration AND session_start_hour + session_duration < end_time)
              )
    )
    SELECT rid FROM Rooms
    EXCEPT 
    SELECT rid FROM NotAvailableRooms;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_available_rooms(
start_date DATE,
end_date DATE
) RETURNS TABLE (
    r_id INTEGER,
    r_capacity INTEGER,
    day DATE,
    hours INT[]
) AS $$
DECLARE
    curs refcursor;
    r RECORD;
    curr_date DATE := start_date;
    start_hour_1 INTEGER := 9;
    start_hour_2 INTEGER := 14;
    arr INT[];
    start_hour INTEGER;
    end_hour INTEGER;
BEGIN
    CREATE TEMPORARY TABLE output_table(
        r_id INTEGER,
        r_capacity INTEGER,
        day DATE,
        hours INT[]
    );
LOOP
    OPEN curs FOR SELECT Rooms.rid, COALESCE(Rooms.seating_capacity - X.num_registrations - X.num_redeems, Rooms.seating_capacity - X.num_registrations, Rooms.seating_capacity - X.num_redeems, Rooms.seating_capacity) as r_capacity, X.sid, X.course_id, X.launch_date
    FROM Rooms 
    LEFT JOIN (
        SELECT COUNT(Registers.cust_id) as num_registrations, COUNT(Redeems.cust_id) as num_redeems, Conducts.sid, Conducts.course_id, Conducts.launch_date, Conducts.rid
        FROM Conducts NATURAL JOIN Sessions LEFT JOIN Registers ON Conducts.sid = Registers.sid AND Conducts.launch_date = Registers.launch_date AND Conducts.course_id = Registers.course_id LEFT JOIN Redeems ON Conducts.sid = Redeems.sid AND Conducts.launch_date = Redeems.launch_date AND Conducts.course_id = Redeems.course_id
        WHERE Sessions.s_date = curr_date
        GROUP BY Conducts.course_id, Conducts.launch_date, Conducts.sid) AS X 
        ON Rooms.rid = X.rid;
    LOOP
        FETCH curs INTO r;
        EXIT WHEN NOT FOUND;
            LOOP
                IF (r.r_capacity = 0) THEN
                    EXIT;
                END IF;
                SELECT start_time, end_time INTO start_hour, end_hour FROM Sessions WHERE Sessions.sid = r.sid AND Sessions.course_id = r.course_id AND Sessions.launch_date = r.launch_date;
                IF (start_hour IS NULL AND end_hour IS NULL) THEN
                    arr := array_cat(arr, ARRAY[9, 10, 11]);
                    EXIT;
                END IF;
                IF (start_hour_1 < start_hour OR start_hour_1 > end_hour) THEN
                    arr := array_append(arr, start_hour_1);
                END IF;
                start_hour_1 := start_hour_1 + 1;
                IF (start_hour_1 > 11) THEN
                    start_hour_1 := 9;
                    EXIT;
                END IF;
            END LOOP;
            LOOP
                IF (r.r_capacity = 0) THEN
                    EXIT;
                END IF;
                SELECT start_time, end_time INTO start_hour, end_hour FROM Sessions WHERE Sessions.sid = r.sid AND Sessions.course_id = r.course_id AND Sessions.launch_date = r.launch_date;
                IF (start_hour IS NULL AND end_hour IS NULL) THEN
                    arr := array_cat(arr, ARRAY[14, 15, 16, 17, 18]);
                    EXIT;
                END IF;
                IF (start_hour_2 < start_hour OR start_hour_2 > end_hour) THEN
                    arr := array_append(arr, start_hour_2);
                END IF;
                start_hour_2 := start_hour_2 + 1;
                IF (start_hour_2 > 18) THEN
                    start_hour_2 := 14;
                    EXIT;
                END IF;
            END LOOP;
            INSERT INTO output_table VALUES(r.rid, r.r_capacity, curr_date, arr);
            arr := NULL;
    END LOOP;
    CLOSE curs;
    curr_date := curr_date + 1;
    EXIT WHEN curr_date > end_date;
END LOOP;
    RETURN QUERY
    SELECT * FROM output_table ORDER BY r_id, day;
    DROP TABLE output_table;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE add_course_offering(
	c_id INTEGER,
	c_fees NUMERIC,
	l_Date DATE,
	reg_deadline DATE,
	target INTEGER,
	a_id INTEGER,
	arr session_array[]
) AS $$
DECLARE
	seating_capacity INTEGER = 0;
	temp_seating_capacity INTEGER;
	i session_array;
    instructor_id INTEGER;
    c_duration INTEGER;
    r_id INTEGER;
    c_area TEXT;
    sess_id INTEGER = 0;
BEGIN
	FOREACH i IN ARRAY arr --finding num_sess and total seating capacity
	LOOP
		SELECT Rooms.seating_capacity INTO temp_seating_capacity FROM Rooms WHERE i.rid = Rooms.rid; 
		seating_capacity := seating_capacity + temp_seating_capacity;
	END LOOP;
	IF (seating_capacity < target) THEN
		RAISE EXCEPTION 'Total seating capacity % must be greater or equal to target num reg', seating_capacity;
	END IF;
    SELECT duration, area_name INTO c_duration, c_area FROM Courses WHERE Courses.course_id = c_id;
    INSERT INTO Offerings (course_id, launch_date, target_number_registrations, registration_deadline, fees, aid) VALUES (c_id, l_date, target, reg_deadline, c_fees, a_id);
    FOREACH i IN ARRAY arr
    LOOP --checking if each session can be assigned an instructor, or is the room available
        sess_id := sess_id + 1;
        INSERT INTO Sessions (sid, s_date, start_time, end_time, course_id, launch_date, rid) VALUES(sess_id, i.s_date, i.s_start, i.s_start + c_duration, c_id, l_date, i.rid);
        RAISE NOTICE 'sid: %', sess_id;
        SELECT inst_id INTO instructor_id FROM find_instructors(c_id, i.s_date, i.s_start) LIMIT 1;
        IF (instructor_id IS NULL) THEN
            DELETE FROM Offerings WHERE Offerings.launch_Date= l_date AND Offerings.course_id = c_id;
            RAISE EXCEPTION 'No instructor available to teach session where session date is %, session time is %', i.s_date, i.s_start;
        END IF;
        SELECT room_id INTO r_id FROM find_rooms(i.s_date, i.s_start, c_duration) WHERE room_id = i.rid;
        IF (r_id IS NULL) THEN
            DELETE FROM Offerings WHERE Offerings.launch_Date= l_date AND Offerings.course_id = c_id;
            RAISE EXCEPTION 'Room % is not avaiable for session', i.rid;
        ELSE
            INSERT INTO Conducts (iid, area_name, sid, launch_date, course_id, rid) VALUES (instructor_id, c_area, sess_id, l_date, c_id, r_id);
            instructor_id := NULL;
            r_id := NULL;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE add_course_package(
package_name TEXT,
num_free_registrations INTEGER,
sale_start_date DATE,
sale_end_date DATE,
price NUMERIC) AS $$
INSERT INTO Course_packages (package_name, num_free_registrations, sale_start_date, sale_end_date, price)
VALUES(package_name, num_free_registrations, sale_start_date, sale_end_date, price);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_available_course_packages()
RETURNS TABLE (
package_name TEXT,
num_free_sessions INT,
end_date DATE,
price NUMERIC) AS $$
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


CREATE OR REPLACE FUNCTION get_my_course_package(
    c_id INTEGER
) RETURNS TABLE (
    j JSON 
) AS $$
DECLARE
    arr redeemed_session[];
    val redeemed_session;
    curs1 refcursor;
    curs2 refcursor;
    r1 RECORD;
    r2 RECORD;
    p_id INTEGER;
    p_name TEXT;
    p_date DATE;
    p_price NUMERIC;
    p_not_redeemed INTEGER;
    num_rows INTEGER;
BEGIN
    CREATE TEMPORARY TABLE output_table(
        package_name TEXT,
        purchase_date DATE,
        price_of_package NUMERIC,
        num_sessions_not_redeemed INTEGER,
        redeemed_sessions_info redeemed_session[]
    );

    OPEN curs1 FOR SELECT Buys.package_id, Course_packages.package_name, Buys.buy_date, Course_packages.price, Buys.num_remaining_redemptions, Courses.title, Sessions.s_date, Sessions.start_time FROM 
        Buys LEFT JOIN Redeems ON Buys.buy_date = Redeems.buy_date AND Buys.cust_id = Redeems.cust_id AND Buys.package_id = Redeems.package_id LEFT JOIN Sessions ON Redeems.sid = Sessions.sid AND Redeems.course_id = Sessions.course_id AND Redeems.launch_date = Sessions.launch_date LEFT JOIN Courses ON Sessions.course_id = Courses.course_id LEFT JOIN Course_packages ON Buys.package_id = Course_packages.package_id
        WHERE Buys.cust_id = c_id AND num_remaining_redemptions > 0 
        ORDER BY Buys.package_id, Sessions.s_date, Sessions.start_time;

    OPEN curs2 FOR SELECT Buys.package_id, Course_packages.package_name, Buys.buy_date, Course_packages.price, Buys.num_remaining_redemptions, Courses.title, Sessions.s_date, Sessions.start_time FROM 
        Buys LEFT JOIN Redeems ON Buys.buy_date = Redeems.buy_date AND Buys.cust_id = Redeems.cust_id AND Buys.package_id = Redeems.package_id LEFT JOIN Sessions ON Redeems.sid = Sessions.sid AND Redeems.course_id = Sessions.course_id AND Redeems.launch_date = Sessions.launch_date LEFT JOIN Courses ON Sessions.course_id = Courses.course_id LEFT JOIN Course_packages ON Buys.package_id = Course_packages.package_id
        WHERE Buys.cust_id = c_id AND num_remaining_redemptions = 0 AND redeem_date <= Sessions.s_date - 7
        ORDER BY Buys.package_id, Sessions.s_date, Sessions.start_time;
    LOOP
        FETCH curs1 INTO r1;
        EXIT WHEN NOT FOUND;
        p_id := r1.package_id;
        p_name := r1.package_name;
        p_date := r1.buy_date;
        p_price := r1.price;
        p_not_redeemed := r1.num_remaining_redemptions;
        IF (r1.s_date IS NOT NULL) THEN
            val.c_name := r1.title;
            val.sess_date := r1.s_date;
            val.s_hour := r1.start_time;
            arr := array_append(arr, val);
        END IF;
    END LOOP;
    IF (p_id IS NOT NULL) THEN
        INSERT INTO output_table VALUES (p_name, p_date, p_price, p_not_redeemed, arr);
        p_id := NULL;
        p_name := NULL;
        p_date := NULL;
        p_price := NULL;
        p_not_redeemed := NULL;
    END IF;
    CLOSE curs1;
    LOOP
        FETCH curs2 INTO r2;
        EXIT WHEN NOT FOUND;
        p_id := r2.package_id;
        p_name := r2.package_name;
        p_date := r2.buy_date;
        p_price := r2.price;
        p_not_redeemed := r2.num_remaining_redemptions;
        IF (r2.s_date IS NOT NULL) THEN
            val.c_name := r1.title;
            val.sess_date := r1.s_date;
            val.s_hour := r1.start_time;
            arr := array_append(arr, val);
        END IF;
    END LOOP;
    IF (p_id IS NOT NULL) THEN
        INSERT INTO output_table VALUES (p_name, p_date, p_price, p_not_redeemed, arr);
    END IF;
    CLOSE curs2;
    SELECT COUNT(package_name) INTO num_rows FROM output_table;
    IF (num_rows = 0) THEN
        RAISE EXCEPTION 'Customer % has no active or partially active packages', c_id;
    END IF;
    RETURN QUERY
    SELECT row_to_json(a) FROM (SELECT * FROM output_table) a; 
    DROP TABLE output_table;
END;
$$ LANGUAGE plpgsql;

-- CREATE OR REPLACE FUNCTION get_my_course_package(
--     c_id INTEGER
-- ) RETURNS TABLE (
--     j JSON --package name, purchase date, price of package, number of free sessions included in the package, 
--     -- number of sessions that have not been redeemed, 
--     -- and information for each redeemed session (course name, session date, session start hour)
-- ) AS $$
-- DECLARE
--     arr redeemed_session;
--     curs refcursor;
--     r RECORD;
--     p_id INTEGER;
--     p_name TEXT;
--     p_date DATE;
--     p_price NUMERIC;
--     p_not_redeemed INTEGER;
-- BEGIN
--     CREATE TEMPORARY TABLE output_table(
--         package_name TEXT,
--         purchase_date DATE,
--         price_of_package NUMERIC,
--         num_sessions_not_redeemed INTEGER,
--         redeemed_sessions_info redeemed_session[]
--     );
--     RETURN QUERY
--     with active_course_packages AS (
--         SELECT Buys.package_id, Course_packages.package_name, Buys.buy_date, Course_packages.price, Buys.num_remaining_redemptions, Courses.title, Sessions.s_date, Sessions.start_time FROM 
--         Buys LEFT JOIN Redeems ON Buys.buy_date = Redeems.buy_date AND Buys.cust_id = Redeems.cust_id AND Buys.package_id = Redeems.package_id LEFT JOIN Sessions ON Redeems.sid = Sessions.sid AND Redeems.course_id = Sessions.course_id AND Redeems.launch_date = Sessions.launch_date LEFT JOIN Courses ON Sessions.course_id = Courses.course_id LEFT JOIN Course_packages ON Buys.package_id = Course_packages.package_id
--         WHERE cust_id = c_id AND num_remaining_redemptions > 0 
--         ORDER BY Buys.package_id, Sessions.s_date, Sessions.start_time
--     ),
--     partially_active_pacakges AS (
--         SELECT Buys.package_id, Course_packages.package_name, Buys.buy_date, Course_packages.price, Buys.num_remaining_redemptions, Courses.title, Sessions.s_date, Sessions.start_time FROM 
--         Buys LEFT JOIN Redeems ON Buys.buy_date = Redeems.buy_date AND Buys.cust_id = Redeems.cust_id AND Buys.package_id = Redeems.package_id LEFT JOIN Sessions ON Redeems.sid = Sessions.sid AND Redeems.course_id = Sessions.course_id AND Redeems.launch_date = Sessions.launch_date LEFT JOIN Courses ON Sessions.course_id = Courses.course_id LEFT JOIN Course_packages ON Buys.package_id = Course_packages.package_id
--         WHERE cust_id = c_id AND num_remaining_redemptions = 0 AND redeem_date <= Sessions.s_date - 7
--         ORDER BY Buys.package_id, Sessions.s_date, Sessions.start_time
--     )
--     OPEN curs FOR active_course_packages;
--     LOOP
--         FETCH curs INTO r;
--         EXIT WHEN NOT FOUND;
--         IF (p_id NOT NULL AND r.package_id <> p_id) THEN --diff package
--             INSERT INTO output_table VALUES (p_name, p_date, p_price, p_not_redeemed, arr); --insert prev info
--             p_id := r.package_id;
--             p_name := r.package_name;
--             p_date := r.buy_date;
--             p_price := r.price;
--             p_not_redeemed := r.num_remaining_redemptions;
--             arr := NULL;
--             IF (r.s_date IS NOT NULL) THEN
--                 arr := array_append(arr, redeemed_session(r.title, r.s_date, r.start_time));
--             END IF;
--         END IF;
--         IF (p_id NOT NULL AND r.package_id = p_id) THEN --same package
--             IF (r.s_date IS NOT NULL) THEN
--                 arr := array_append(arr, redeemed_session(r.title, r.s_date, r.start_time));
--             END IF;
--         END IF;
--         IF (p_id IS NULL) THEN --first package
--             p_id := r.package_id;
--             p_name := r.package_name;
--             p_date := r.buy_date;
--             p_price := r.price;
--             p_not_redeemed := r.num_remaining_redemptions;
--             IF (r.s_date IS NOT NULL) THEN
--                 arr := array_append(arr, redeemed_session(r.title, r.s_date, r.start_time));
--             END IF;
--         END IF;
--     END LOOP;
--     IF (p_id IS NOT NULL) THEN --add last element
--         INSERT INTO output_table VALUES (p_name, p_date, p_price, p_not_redeemed, arr);
--             p_id := NULL;
--             p_name := NULL;
--             p_date := NULL;
--             p_price := NULL;
--             p_not_redeemed := NULL;
--             arr := NULL;
--     END IF;
--     CLOSE curs;
--     OPEN curs FOR partially_active_pacakges
--     LOOP
--         FETCH curs INTO r;
--         EXIT WHEN NOT FOUND;
        
--     END LOOP;
--     CLOSE curs;
--     RETURN QUERY
--     SELECT row_to_json(a) FROM (SELECT * FROM output_table) a; 
-- END;
-- $$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_available_course_offerings()
RETURNS TABLE (
course_title TEXT,
course_area TEXT,
start_date DATE,
end_date DATE,
registration_deadline DATE,
course_fees NUMERIC,
number_of_remaining_seats INTEGER) AS $$
SELECT Courses.title, Courses.area_name, Offerings.start_date, Offerings.end_date, Offerings.registration_deadline, Offerings.fees, Offerings.seating_capacity
FROM Offerings LEFT JOIN Courses ON Offerings.course_id = Courses.course_id
WHERE Offerings.registration_deadline >= CURRENT_DATE AND Offerings.seating_capacity > 0;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_available_course_sessions(_course_id INTEGER, _launch_date DATE)
RETURNS TABLE (
session_date DATE,
start_hour INTEGER,
instructor_name TEXT,
remaining_seats INTEGER) AS $$
BEGIN
RETURN QUERY
with instructor_name_mapping AS (
SELECT DISTINCT Instructors.iid, Employees.name
FROM Instructors LEFT JOIN Employees ON Instructors.iid = Employees.eid
),
offering_sessions_table AS (
    SELECT Sessions.sid, Sessions.start_time, Sessions.s_date FROM Sessions WHERE Sessions.launch_date = _launch_date AND Sessions.course_id = _course_id
),
sessions_instructors_table AS (
    SELECT instructor_name_mapping.name, Conducts.sid, Conducts.course_id, Rooms.seating_capacity, offering_sessions_table.start_time, offering_sessions_table.s_date
    FROM Conducts LEFT JOIN instructor_name_mapping ON Conducts.iid = instructor_name_mapping.iid LEFT JOIN Rooms ON Conducts.rid = Rooms.rid INNER JOIN offering_sessions_table ON Conducts.sid = offering_sessions_table.sid AND Conducts.course_id = offering_sessions_table.course_id 
),
num_registrations_for_each_session AS (
    SELECT COUNT(Registers.cust_id) AS num_reg, offering_sessions_table.sid
    FROM offering_sessions_table LEFT JOIN Registers ON offering_sessions_table.sid = Registers.sid
    WHERE Registers.course_id = _course_id AND Registers.launch_date = _launch_date 
    GROUP BY offering_sessions_table.sid
),
num_redemptions_for_each_session AS (
    SELECT COUNT(Redeems.cust_id) AS num_red, offering_sessions_table.sid
    FROM offering_sessions_table LEFT JOIN Redeems ON offering_sessions_table.sid = Redeems.sid
    WHERE Redeems.course_id = _course_id AND Redeems.launch_date = _launch_date 
    GROUP BY offering_sessions_table.sid
)
SELECT sessions_instructors_table.s_date, sessions_instructors_table.start_time, sessions_instructors_table.name, COALESCE(sessions_instructors_table.seating_capacity - num_reg - num_red, sessions_instructors_table.seating_capacity - num_reg, sessions_instructors_table.seating_capacity - num_red, sessions_instructors_table.seating_capacity)
FROM sessions_instructors_table LEFT JOIN num_registrations_for_each_session ON sessions_instructors_table.sid = num_registrations_for_each_session.sid LEFT JOIN num_redemptions_for_each_session ON sessions_instructors_table.sid = num_redemptions_for_each_session.sid
WHERE COALESCE(sessions_instructors_table.seating_capacity - num_reg - num_red, sessions_instructors_table.seating_capacity - num_reg, sessions_instructors_table.seating_capacity - num_red, sessions_instructors_table.seating_capacity) > 0
ORDER BY sessions_instructors_table.s_date, sessions_instructors_table.start_time;
END;
$$ LANGUAGE plpgsql;


/** 17: Register for session
Note:
- credit_card registrations are not explicity recorded. 
Testing done:
NEGATIVE:
[?] Course pacakge not active
[?] Session does not exist
[?] Payment method does not exist
[?] Customer id does not exit
[?] Course offering does not exist
POSITIVE:
[G] Redemption registration
[G] Credit card registration
**/
CREATE OR REPLACE PROCEDURE register_session(
    target_cid INTEGER, 
    offering_course_id INTEGER,
    offering_launch_date DATE,
    target_sid INTEGER,
    payment_method TEXT
) AS $$
DECLARE
offering_registration_deadline DATE;
offering_start_date DATE;
offering_end_date DATE;
target_package_id INTEGER;
target_package_buy_date DATE;
BEGIN

SELECT Offerings.registration_deadline, Offerings.start_date, Offerings.end_date
INTO offering_registration_deadline, offering_start_date, offering_end_date
FROM Offerings
where Offerings.course_id = offering_course_id AND Offerings.launch_date = offering_launch_date; 

-- VALIDATION
IF (payment_method NOT in ('credit_card', 'redemption')) THEN
RAISE EXCEPTION 'Payment method must be credit_card or redemption only';
END IF;

-- process redemption transaction
IF (payment_method = 'redemption') THEN 
    SELECT Buys.package_id, Buys.buy_date
    INTO target_package_id, target_package_buy_date
    FROM Buys
    WHERE Buys.cust_id = target_cid AND num_remaining_redemptions > 0;

    -- if no such packaage then raise exception
    IF (target_package_id IS NULL AND target_package_buy_date IS NULL) THEN
        RAISE EXCEPTION 'Customer does not have a active course package to redeem from';
    END IF;

    INSERT INTO Redeems (package_id, buy_date, sid, launch_date, course_id, redeem_date, cust_id) 
    VALUES(target_package_id, target_package_buy_date, target_sid, offering_launch_date, offering_course_id, CURRENT_DATE, target_cid);

    UPDATE Buys
    SET num_remaining_redemptions = Buys.num_remaining_redemptions - 1
    WHERE 
        Buys.cust_id = target_cid AND 
        Buys.package_id = target_package_id AND 
        Buys.buy_date = target_package_buy_date;
END IF;


-- insert into registration table
INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) 
VALUES (target_sid, offering_launch_date, offering_course_id, CURRENT_DATE, target_cid);

END;
$$ LANGUAGE plpgsql;

/** 18: Get all customer registrations
-- only return active registration sessions
-- sorted in ascending order of session date and session start hour
Testing done:
NEGATIVE:
[?] 
POSITIVE:
[?] Get all active registration and sorted in order
**/
CREATE OR REPLACE FUNCTION get_my_registrations(
    target_cid INTEGER
) RETURNS TABLE (
    course_title TEXT, -- Courses (course title)
    fees NUMERIC, -- Offerings
    s_date DATE, -- Sessions
    start_time INTEGER, -- Sessions
    session_duration INTEGER, -- Sessions
    instructor_name TEXT -- Employees table
) AS $$
BEGIN

RETURN QUERY
SELECT distinct Courses.title as course_title, Offerings.fees as fees, Sessions.s_date as s_date,
Sessions.start_time as start_time, Courses.duration as session_duration, Employees.name as instructor_name
FROM Courses, Offerings, Sessions, Employees, Registers, Conducts
WHERE 
Employees.eid = Conducts.iid AND
Conducts.course_id = Sessions.course_id AND
Conducts.launch_date = Sessions.launch_date AND
Courses.course_id = Offerings.course_id AND
Sessions.s_date > current_date AND
Sessions.course_id = Offerings.course_id AND
Sessions.launch_date = Offerings.launch_date AND
Registers.course_id = Sessions.course_id AND
Registers.launch_date = Sessions.launch_date AND
Registers.sid = Sessions.sid AND
Registers.cust_id = target_cid
ORDER BY Sessions.s_date, Sessions.start_time;

END;
$$ LANGUAGE plpgsql;

/** 19: Customer request to change registed course session to another session
NEGATIVE:
[?] Customer does not exist
[?] Session does not exist
[?] Customer previously not registered to course with another session
POSITIVE:
[G] Update course session correctly
**/
CREATE OR REPLACE PROCEDURE update_course_session(
    target_cid INTEGER,
    target_course_id INTEGER,
    target_offering_launch_date DATE,
    new_sid INTEGER
) AS $$
DECLARE
target_session_start_date DATE;
BEGIN

-- VALIDATION
-- Customer registered to some session previously
IF (NOT EXISTS 
    (SELECT 1 from Registers WHERE 
        Registers.cust_id = target_cid AND
        Registers.launch_date = target_offering_launch_date AND
        Registers.course_id = target_course_id)) THEN
            RAISE EXCEPTION 'Customer % previously has not registered for a session under course offering %, with launch date: %'
                , new_sid, target_course_id, target_offering_launch_date;
END IF;

-- Target session exists
IF (NOT EXISTS 
    (SELECT 1 from Sessions WHERE 
        Sessions.sid = new_sid AND 
        Sessions.launch_date = target_offering_launch_date AND
        Sessions.course_id = target_course_id)) THEN
            RAISE EXCEPTION 'Target session % does not exist for course offering %, with launch date: %'
                , new_sid, target_course_id, target_offering_launch_date;
END IF;

SELECT Sessions.s_date into target_session_start_date
from Sessions
where Sessions.sid = new_sid AND 
    Sessions.launch_date = target_offering_launch_date AND
    Sessions.course_id = target_course_id;

-- Target session should not have started
IF (target_session_start_date < CURRENT_DATE) THEN
    RAISE EXCEPTION 'Target session %, is in the past', new_sid;
END IF;

-- Target session has spare seats to be done as a trigger

UPDATE Registers
SET sid = new_sid,
registration_date = CURRENT_DATE
WHERE Registers.launch_date = target_offering_launch_date AND
Registers.course_id = target_course_id AND
Registers.cust_id = target_cid;

END;
$$ LANGUAGE plpgsql;
-- -- check new session_id exists
-- -- check cid currently registered in
-- -- update Registers table sid to new 

/** 20: cancel / refund registration
NEGATIVE:
[?] Customer does not exist
[?] Customer has not registered for target offering
POSITIVE:
[G] No refund
[G] Refund credit card payment
[G] Refund redemption 
**/
-- if request is valid: process the request with necessary update
CREATE OR REPLACE PROCEDURE cancel_registration (
    target_cid INTEGER,
    target_course_id INTEGER,
    target_offering_launch_date DATE
) AS $$
DECLARE
target_sid INTEGER;
target_session_s_date DATE;
target_course_fees NUMERIC;
is_redemption_payment BOOLEAN DEFAULT FALSE;
target_package_id INTEGER;
target_package_buy_date DATE;
BEGIN

SELECT fees INTO target_course_fees
FROM Offerings
WHERE Offerings.course_id =  target_course_id AND Offerings.launch_Date = target_offering_launch_date;

-- VALIDATION
-- Check cid is indeed registered
IF (NOT EXISTS (
    SELECT 1 
    FROM Registers
    WHERE 
        Registers.launch_date = target_offering_launch_date AND
        Registers.course_id = target_course_id AND
        Registers.cust_id = target_cid
)) THEN
    RAISE EXCEPTION 'Customer %, is not registered for course: %, with launch date: %', target_cid, target_course_id, target_offering_launch_date;
END IF;

SELECT Registers.sid INTO target_sid
FROM Registers
WHERE 
    Registers.launch_date = target_offering_launch_date AND
    Registers.course_id = target_course_id AND
    Registers.cust_id = target_cid;

SELECT Sessions.s_date into target_session_s_date
FROM Sessions
WHERE 
    Sessions.launch_date = target_offering_launch_date AND
    Sessions.course_id = target_course_id AND
    Sessions.sid = target_sid;

-- check if is redeem or credit card
IF (EXISTS (
    SELECT 1 
    FROM Redeems
    WHERE 
        Redeems.launch_date = target_offering_launch_date AND
        Redeems.course_id = target_course_id AND
        Redeems.cust_id = target_cid AND
        Redeems.sid = target_sid
)) THEN
    is_redemption_payment := TRUE;
END IF;

-- check current date is 7 days before registered session
IF ((target_session_s_date - CURRENT_DATE) < 7) THEN
    INSERT INTO Cancels (cancel_date, cust_id, sid, launch_date, course_id)
    VALUES (CURRENT_DATE, target_cid, target_sid, target_offering_launch_date, target_course_id);
ELSE
-- process actual refund
    IF (is_redemption_payment) THEN
        SELECT Buys.package_id, Buys.buy_date
        INTO target_package_id, target_package_buy_date
        FROM Buys
        WHERE Buys.cust_id = target_cid
        ORDER BY buy_date
        LIMIT 1;

        UPDATE Buys
        SET num_remaining_redemptions = Buys.num_remaining_redemptions + 1
        WHERE 
            Buys.cust_id = target_cid AND 
            Buys.package_id = target_package_id AND 
            Buys.buy_date = target_package_buy_date;

        INSERT INTO Cancels (cancel_date, cust_id, sid, launch_date, course_id, package_credit)
        VALUES (CURRENT_DATE, target_cid, target_sid, target_offering_launch_date, target_course_id, 1);
    ELSE
        INSERT INTO Cancels (cancel_date, cust_id, sid, launch_date, course_id, refund_amt)
        VALUES (CURRENT_DATE, target_cid, target_sid, target_offering_launch_date, target_course_id, 0.9 * target_course_fees);
    END IF;
END IF;

-- remove from registers table
DELETE FROM Registers 
WHERE 
    Registers.launch_date = target_offering_launch_date AND
    Registers.course_id = target_course_id AND
    Registers.cust_id = target_cid AND 
    Registers.sid = target_sid;

END;
$$ LANGUAGE plpgsql;
-- -- check mapping exists
-- -- remove all registers rows with cid = cid 
-- -- soft delete?

/** 21: Change instructor for a course session
Testing done:
NEGATIVE:
[?] target course session has started
[G] Instructor does not teach course area
[?] Instrucotr does not exist
POSITIVE:
[G] Standard update
**/
CREATE OR REPLACE PROCEDURE update_instructor (
    target_course_id INTEGER,
    target_offering_launch_date DATE,
    target_sid INTEGER,
    new_iid INTEGER -- Conducts
) AS $$
DECLARE
session_start_date DATE;
BEGIN

SELECT s_date INTO session_start_date
FROM Sessions
WHERE Sessions.sid = target_sid AND Sessions.course_id = target_course_id AND Sessions.launch_date = target_offering_launch_date;

IF (session_start_date < CURRENT_DATE) THEN 
RAISE EXCEPTION 'Course session has started';
END IF;

UPDATE Conducts
SET iid = new_iid
WHERE Conducts.course_id = target_course_id AND Conducts.sid = target_sid AND Conducts.launch_date = target_offering_launch_date;
END;
$$ LANGUAGE plpgsql;

/** 22: change room for a course session
TODO:
- Check room capacity limitations [if relevant]

Testing done:
NEGATIVE:
[?] 
POSITIVE:
[G] Standard update
**/
CREATE OR REPLACE PROCEDURE update_room (
    target_course_id INTEGER,
    target_offering_launch_date DATE,
    target_sid INTEGER,
    new_rid INTEGER
) AS $$
DECLARE
session_start_date DATE;
BEGIN

-- get session_start_id
SELECT s_date INTO session_start_date
FROM Sessions
WHERE Sessions.sid = target_sid AND Sessions.course_id = target_course_id AND Sessions.launch_date = target_offering_launch_date;

-- check course session has not started
IF (session_start_date < CURRENT_DATE) THEN 
RAISE EXCEPTION 'Course session has started';
END IF;

-- actual update
UPDATE Sessions
SET rid = new_rid
WHERE Sessions.course_id = target_course_id AND Sessions.sid = target_sid AND Sessions.launch_date = target_offering_launch_date;

UPDATE Conducts
SET rid = new_rid
WHERE Conducts.course_id = target_course_id AND Conducts.sid = target_sid AND Conducts.launch_date = target_offering_launch_date;

END;
$$ LANGUAGE plpgsql;

/** 23: remove course session
Testing done:
NEGATIVE:
[?] session has already started
[G] session has at least one customer registered already
[G] session is only session in course offering
POSITIVE:
[G] Standard removal
**/
CREATE OR REPLACE PROCEDURE remove_session(
    target_course_id INTEGER,
    target_offering_launch_date DATE,
    target_sid INTEGER
) AS $$
DECLARE
session_start_date DATE;
num_registered_to_session INTEGER;
BEGIN

-- get session_start_id
SELECT s_date INTO session_start_date
FROM Sessions
WHERE Sessions.sid = target_sid AND Sessions.course_id = target_course_id AND Sessions.launch_date = target_offering_launch_date;

-- VALIDATION
-- check course session has not started
IF (session_start_date < CURRENT_DATE) THEN 
RAISE EXCEPTION 'Course session has started';
END IF;

-- check nobody registered
IF (EXISTS (
    SELECT 1 FROM Registers 
    WHERE 
        Registers.course_id = target_course_id AND
        Registers.sid = target_sid AND
        Registers.launch_date = target_offering_launch_date
    )) THEN 
RAISE EXCEPTION 'There is at least one customer registered for session. Thus, removal of target session is invalid';
END IF;

-- check if session is only one for couse_offering
IF ((SELECT count(*) FROM Sessions 
        WHERE 
            Sessions.sid = target_sid AND
            Sessions.course_id = target_course_id AND
            Sessions.launch_date = target_offering_launch_date) = 1
    ) THEN 
RAISE EXCEPTION 'Only session is course offering. Thus, removal of target session is invalid';
END IF;

-- actual deletion
DELETE FROM Sessions
WHERE Sessions.course_id = target_course_id AND Sessions.sid = target_sid AND Sessions.launch_date = target_offering_launch_date;

DELETE FROM Conducts
WHERE Conducts.course_id = target_course_id AND Conducts.sid = target_sid AND launch_date = target_offering_launch_date;

END;
$$ LANGUAGE plpgsql;
-- -- check request valid: sid,  exists in Sessions / Conducts
-- -- check: if >=1 registration for session cannot remove!!
-- -- allow seating capacity of course offering to
-- -- fall below course offering target number of reigstrations

/** 24: Add a new session to course offering
Changes:
- Change end date calculation to count from Courses.duration

Testing done:
NEGATIVE:
[G] instructor specialisation mismatch with course area
[G] start_day not within 10 days of registration deadline
[?] same day and time 
[?] invalid start hour
POSITIVE:
[G] Standard insertion
**/ 
CREATE OR REPLACE PROCEDURE add_session (
    offering_course_id INTEGER,
    offering_launch_date DATE,
    new_sid INTEGER,
    s_date DATE,
    start_hour INTEGER,
    iid INTEGER,
    rid INTEGER
) AS $$
DECLARE
offering_registration_deadline DATE;
offering_start_date DATE;
offering_end_date DATE;
course_area_name TEXT;
offering_duration INTEGER;
BEGIN

-- check start_hour is valid number

-- chekc No two sessions for the same course offering can be conducted on the same day and at the same time

-- get registration deadline
SELECT Offerings.registration_deadline, Offerings.start_date, Offerings.end_date
INTO offering_registration_deadline, offering_start_date, offering_end_date
FROM Offerings
where Offerings.launch_date = offering_launch_date AND Offerings.course_id = offering_course_id;

SELECT Courses.area_name, Courses.duration 
INTO course_area_name, offering_duration
FROM Courses
WHERE Courses.course_id = offering_course_id;

IF (offering_registration_deadline < CURRENT_DATE) THEN
RAISE EXCEPTION 'Specified course offering registration deadline has passed';
END IF;

-- insert into sessions here
INSERT INTO Sessions(sid, s_date, start_time, end_time, course_id, launch_date, rid) 
    VALUES(new_sid, s_date, start_hour, start_hour + offering_duration, offering_course_id, offering_launch_date,rid);

INSERT INTO Conducts(iid, area_name, sid, course_id, rid) 
    VALUES (iid, course_area_name, new_sid, offering_course_id, rid);

END;
$$ LANGUAGE plpgsql;




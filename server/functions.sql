DROP FUNCTION IF EXISTS
add_employee, remove_employee, add_customer, update_credit_card, add_course,
find_instructors, get_available_instructors, find_rooms, get_available_rooms, add_course_offering,
add_course_package, get_available_course_packages, buy_course_package, get_my_course_package, get_available_course_offerings,
get_available_course_sessions, register_session, get_my_registrations, update_course_session, cancel_registration,
update_instructor, update_room, remove_session, add_session, pay_salary,
promote_courses, top_packages, popular_courses, view_summary_report, view_manager_report,
get_work_days, get_work_hours;

--helper function
create or replace function get_redeem_fees(in target_package_id integer, out redeem_fee numeric)
returns numeric as $$

declare

begin
 select price/num_free_registrations as redeem
 from Course_packages
 where Course_packages.package_id = target_package_id
 into redeem_fee;

end;
$$ language plpgsql;

--helper function
create or replace function get_total_net_registration_fees(in target_launch_date date, target_course_id integer, out total numeric)
returns numeric as $$

declare
registration_fee INTEGER;
redeem_fee INTEGER;
begin
-- register fees:register join session join offering get fees 
-- for each redeem fees: redeems join course_packages, get course_packages.price/course_packages.num_free_registrations
SELECT sum(X.fees) FROM 
 (select fees, course_id, launch_date
 from (Sessions natural join Offerings) 
 natural join Registers
   where Course_id = target_course_id
 and launch_date = target_launch_date) as x
 group by Course_id, launch_date
 into registration_fee;
 
 select sum(redeem)
from (select get_redeem_fees(package_id) as redeem, * 
 from redeems
 where course_id = target_course_id
 and launch_date = target_launch_date) as Y
 group by Course_id, launch_date
 into redeem_fee;

total := registration_fee + redeem_fee;

end;
$$ language plpgsql;

--helper function
create or replace function get_work_hours(in eid integer, in curr_month integer, in curr_year integer, out total integer)
returns integer as $$
-- find eid occurrence in conducts table, (as iid)
-- for each sid (under that iid), check sessions table to take end_time - start_time for duration
declare
	curs1 cursor FOR (
		select sid, start_time, end_time
		from sessions
		where exists (
			select sid
			from conducts	
			where sid = eid
		)
        and extract('month' from s_date) = curr_month
        and extract('year' from s_date) = curr_year
     
	);
	r record;
	start integer;
	end1 integer;
	diff integer;

begin
	total := 0;
	open curs1;
	
	loop
		fetch curs1 into r;
		exit when not found;
		start := r.start_time;
		end1 := r.end_time;
		diff := end1 - start;
		total := total + diff;

	end loop;
	close curs1;
end;
$$ language plpgsql;

--helper function
create or replace function get_work_days(in eid1 integer, in curr_month integer, in curr_year integer, out total integer)
returns integer as $$
-- find eid occurrence in employees table (as eid)
-- first work day = 1, unless join date within month of payment
-- last work day = num of days in the month (if depart_date = null) unless,
--  case 1: departed date is within month of payment (ie recently departed)
--  case 2: departed date is in previous month (ie no longer need to pay)
declare
 first integer;
 last integer;
 join_month integer;
 join_year integer;
 depart_month integer;
 depart_year integer;

begin
 select extract('month' from employees.join_date) into join_month from employees where employees.eid =  eid1;
 select extract('month' from employees.depart_date) into depart_month from employees where employees.eid =  eid1;
 select extract('year' from employees.join_date) into join_year from employees where employees.eid = eid1;
 select extract('year' from employees.depart_date) into depart_year from employees where employees.eid = eid1;
 
 
 total := 0;
 if (join_month = curr_month AND join_year = curr_year) then
  -- first work day within month of payment
  select extract('day' from employees.join_date) into first from employees where employees.eid =   eid1;
 else
  first := 1;
 end if;

 if (depart_month IS NULL) then
  -- has not departed
  select extract('day' from (date_trunc('month', CONCAT(curr_year, '-', curr_month, '-01')::date) + interval '1 month' - interval '1    day')) into last;
 elsif (depart_month = curr_month AND depart_year = curr_year) then
  -- departed this month
  select extract('day' from employees.depart_date) into last from employees where employees.eid =   eid1;
 elsif (depart_month <> curr_month OR (depart_month = curr_month AND depart_year <> curr_year)) then
  -- departed before this month
    total := null;
    return;
  return;
 end if;
 
 total := last - first + 1;

end;
$$ language plpgsql;

--Function 1
CREATE OR REPLACE PROCEDURE add_employee (
    emp_name TEXT,
    emp_home_address TEXT,
    emp_contact_number TEXT,
    emp_email_address TEXT,
    emp_monthly_salary NUMERIC DEFAULT NULL,
    emp_hourly_rate NUMERIC DEFAULT NULL,
    emp_join_date DATE DEFAULT CURRENT_DATE,
    emp_category TEXT DEFAULT NULL,
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
        RAISE EXCEPTION 'Hourly rate and monthly salary cannot be both NULL';
    END IF;

    IF (emp_monthly_salary IS NOT NULL AND emp_hourly_rate IS NOT NULL) THEN
        RAISE EXCEPTION 'Please provide only monthly salary OR hourly salary.';
    END IF;

    IF (emp_category NOT IN ('administrator', 'manager', 'instructor')) THEN
        RAISE EXCEPTION 'Employee category must be one of administrator, manager or instructor';
    END IF;

    FOREACH emp_course_area IN ARRAY emp_course_areas
    LOOP 
        IF emp_category = 'manager' AND EXISTS(
                SELECT 1 FROM Course_areas 
                WHERE area_name = emp_course_area
        ) THEN 
            RAISE EXCEPTION 'course area already managed by someone';
        END IF;
    END LOOP;

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
                INSERT INTO Instructors(Iid, area_name) VALUES(emp_id, emp_course_area);
                INSERT INTO full_time_instructors(ftid, area_name) VALUES(emp_id, emp_course_area);
            END LOOP;
        END IF;
    -- part time emp
    ELSE 
        IF (emp_category = 'manager') THEN
            RAISE EXCEPTION 'A manager is not a part time employee. Please provide monthly salary only.';
        ELSIF (emp_category = 'administrator') THEN
            RAISE EXCEPTION 'An administrator is not a part time employee. Please provide monthly salary only.';
        ELSIF (emp_category = 'instructor') THEN
            INSERT INTO Employees(name, address, phone, email, join_date) VALUES (emp_name, emp_home_address,
            emp_contact_number, emp_email_address, emp_join_date) RETURNING eid into emp_id;
            INSERT INTO Part_Time_Emp(eid, hourly_rate) VALUES(emp_id, emp_hourly_rate);
            FOREACH emp_course_area in ARRAY emp_course_areas
            LOOP
                INSERT INTO Instructors(iid, course_area) VALUES(emp_id, emp_course_area);
                INSERT INTO Part_Time_Instructors(ptid, course_area) VALUES(emp_id, emp_course_area);
            END LOOP;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

--Function 2
CREATE OR REPLACE PROCEDURE remove_employee (
    emp_id INTEGER,
    emp_depart_date DATE
) AS $$
DECLARE 
    check_null_depart_date DATE;
BEGIN
    SELECT depart_date INTO check_null_depart_date
    FROM Employees
    WHERE emp_id = emp_id;
    IF check_null_depart_date IS NOT NULL THEN
        RAISE EXCEPTION 'cannot fire an employee who is leaving soon';
    ELSIF emp_id IN (
        SELECT DISTINCT mid FROM Course_areas
    ) THEN 
        RAISE EXCEPTION 'cannot fire a manager who manages some areas, who u want to manage the area?';
    ELSIF emp_id IN (
        SELECT DISTINCT aid FROM Offerings
        WHERE registration_deadline > emp_depart_date
    ) THEN 
        RAISE EXCEPTION 'cannot fire an admin who handles some course area with registration date after depart date' ;
    ELSIF emp_id IN (
        WITH SessionsAndInstructors AS (
        SELECT iid , s_date FROM Sessions S INNER JOIN Conducts C on C.sid = S.sid and S.course_id = C.course_id and C.launch_date = S.launch_date
        )
        SELECT DISTINCT iid FROM SessionsAndInstructors
        WHERE s_date > emp_depart_date
    ) THEN 
        RAISE EXCEPTION 'cannot fire an instructor who teaches some session that starts after depart date' ;
    ELSE
        UPDATE Employees 
        SET depart_date = emp_depart_date
        WHERE eid = emp_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

--Function 3
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

--Function 4
CREATE OR REPLACE PROCEDURE update_credit_card (
    cid INTEGER,
    new_credit_card_number TEXT,
    new_credit_card_expiry_date DATE,
    new_credit_card_cvv CHAR(3)
) AS $$
DECLARE 
    old_credit_card_number TEXT;
BEGIN
    IF new_credit_card_expiry_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'cannot set a credit card that has already expired';
    END IF;
    SELECT credit_card_number INTO old_credit_card_number FROM Customers WHERE cid = cust_id;
    UPDATE Credit_cards
    SET credit_card_number = new_credit_card_number,
        cvv = new_credit_card_cvv,
        expiry_date = new_credit_card_expiry_date
    WHERE credit_card_number = old_credit_card_number;
END;
$$ LANGUAGE plpgsql;

--Function 5
CREATE OR REPLACE PROCEDURE add_course (
    course_title TEXT,
    course_description TEXT,
    course_area_name TEXT,
    course_duration INTEGER
) AS $$
    INSERT INTO Courses(title, duration, description, area_name) VALUES(course_title, course_duration,
    course_description, course_area_name);
$$ LANGUAGE SQL;

--Function 6
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
    IF cid NOT IN (
        SELECT course_id 
        FROM Courses
    ) THEN
        RAISE EXCEPTION 'No such course offered.';
    END IF;
    SELECT launch_date INTO offering_launch_date FROM Sessions
    WHERE course_id = cid AND s_date = session_start_date AND start_time = session_start_hour
    LIMIT 1;

    SELECT duration INTO course_duration FROM Courses WHERE course_id = cid;

    SELECT COUNT(*) INTO num_sessions_offered FROM Sessions
    WHERE course_id = cid AND launch_date = offering_launch_date;

    session_duration := course_duration;

    session_end_hour := session_start_hour + session_duration;

    RETURN QUERY
    WITH SpecializingInstructors AS (
        SELECT DISTINCT ftid AS iid
        FROM full_time_instructors FT
        WHERE EXISTS (
            SELECT 1
            FROM Courses C
            WHERE C.course_id = cid AND C.area_name = FT.area_name
        )
        UNION
        SELECT DISTINCT ptid AS iid
        FROM Part_Time_Instructors PT
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
        FROM full_time_instructors
    ),
    -- must course_id same as cid?
    -- no, the instructor just has to specialize in that area
    TimeNotAvailableInstructors AS (
        SELECT DISTINCT iid
        FROM Conducts C INNER JOIN Sessions S ON S.sid = C.sid AND S.course_id = C.course_id
        WHERE session_start_date = s_date AND ((start_time - 1 <= session_start_hour AND  session_start_hour <= end_time) OR (start_time - 1 <= session_end_hour AND  session_end_hour <= end_time))
        UNION 
        SELECT DISTINCT eid
        FROM Employees
        WHERE depart_date < session_start_date
    ),
    AvailableInstructors AS (
        (SELECT iid FROM SpecializingInstructors EXCEPT SELECT iid FROM MaxHoursQuotaReachedInstructors) EXCEPT 
        SELECT iid FROM TimeNotAvailableInstructors
    )
    SELECT eid, name 
    FROM AvailableInstructors INNER JOIN Employees ON iid = eid;
END;
$$ LANGUAGE plpgsql;

--Function 7
CREATE OR REPLACE FUNCTION get_available_instructors (
    cid INTEGER,
    course_start_date DATE,
    course_end_date DATE
) RETURNS TABLE (
    emp_id INTEGER,
    emp_name TEXT,
    emp_total_teaching_hours_for_current_month BIGINT,
    emp_avail_day DATE,
    emp_avail_hours INTEGER[]
) AS $$
DECLARE
    r RECORD;
    date_diff INTEGER;
    counter_date INTEGER;
    counter_hours INTEGER;
    current_date DATE;
    avail_hours INTEGER[];
BEGIN
    date_diff := course_end_date - course_start_date; 
    FOR r IN WITH SpecializingInstructors AS (
        SELECT DISTINCT ftid AS iid
            FROM full_time_instructors FT
            WHERE EXISTS (
                SELECT 1
                FROM Courses C
                WHERE C.course_id = cid AND C.area_name = FT.area_name
            )
            UNION
            SELECT DISTINCT ptid AS iid
            FROM Part_Time_Instructors PT
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
            EXCEPT 
            (SELECT DISTINCT iid 
            FROM Conducts C INNER JOIN Sessions S ON S.sid = C.sid AND S.course_id = C.course_id
            GROUP BY iid 
            HAVING SUM(end_time - start_time) >= 30
            EXCEPT
            SELECT ftid
            FROM full_time_instructors)
        ),
        ConductsAndSessions AS (
            SELECT C.sid, C.course_id, s_date, start_time, end_time, iid
            FROM Conducts C INNER JOIN Sessions S ON C.sid = S.sid AND C.course_id = S.course_id
            ORDER BY iid, s_date
        ),
        InstructorsWhoTeachThisMonth AS (
            SELECT iid, start_time, end_time
            FROM ConductsAndSessions
            WHERE EXTRACT(MONTH FROM s_date) = EXTRACT(MONTH FROM CURRENT_DATE)
        ),
        InstructorsWhoDoesNotTeachThisMonth AS (
        SELECT iid, 0 AS teaching_hours
        FROM (SELECT iid FROM SpecializingInstructors EXCEPT SELECT iid FROM InstructorsWhoTeachThisMonth) AS X
        ),
        InstructorsHoursOfTheMonth AS (
            SELECT iid, SUM(end_time - start_time) AS teaching_hours
            FROM InstructorsWhoTeachThisMonth
            GROUP BY iid
            UNION
            SELECT iid, teaching_hours
            FROM InstructorsWhoDoesNotTeachThisMonth
        )
        SELECT iid, name
        FROM 
            (SpecializingInstructors INNER JOIN Employees ON iid = eid) AS X
    LOOP
        FOR counter_date IN 0..date_diff
        LOOP
            CONTINUE WHEN course_start_date + counter_date > (SELECT depart_date FROM Employees WHERE eid = r.iid);
            avail_hours := ARRAY[]::INTEGER[];
            FOR counter_hours in 9..17
            LOOP
                CONTINUE WHEN counter_hours = 12 OR counter_hours = 13 OR 
                    EXISTS(
                        SELECT 1 
                        FROM (
                                SELECT C.sid, C.course_id, s_date, start_time, end_time, iid
                                FROM Conducts C INNER JOIN Sessions S ON C.sid = S.sid AND C.course_id = S.course_id
                                ORDER BY iid, s_date) as Y
                        WHERE r.iid = Y.iid AND Y.s_date = course_start_date + counter_date AND (Y.start_time - 1 <= counter_hours AND counter_hours < Y.end_time + 1) 
                    );
                avail_hours := ARRAY_APPEND(avail_hours, counter_hours);
            END LOOP;
            RETURN QUERY
            SELECT r.iid, r.name, (
                SELECT teaching_hours 
                FROM 
                    (
                        SELECT iid, SUM(end_time - start_time) AS teaching_hours
                        FROM (
                            SELECT iid, start_time, end_time
                            FROM (
                                SELECT C.sid, C.course_id, s_date, start_time, end_time, iid
                                FROM Conducts C INNER JOIN Sessions S ON C.sid = S.sid AND C.course_id = S.course_id
                                ORDER BY iid, s_date
                            ) AS ConductsAndSessions
                            WHERE EXTRACT(MONTH FROM s_date) = EXTRACT(MONTH FROM CURRENT_DATE)
                        ) AS InstructorsWhoTeachThisMonth
                        GROUP BY iid
                        UNION
                        SELECT iid, teaching_hours
                        FROM (
                            SELECT iid, 0 AS teaching_hours
                            FROM (
                                SELECT iid 
                                FROM (
                                    SELECT DISTINCT ftid AS iid
                                    FROM full_time_instructors FT
                                    WHERE EXISTS (
                                        SELECT 1
                                        FROM Courses C
                                        WHERE C.course_id = cid AND C.area_name = FT.area_name
                                    )
                                    UNION
                                    SELECT DISTINCT ptid AS iid
                                    FROM Part_Time_Instructors PT
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
                                ) AS SpecializingInstructors2
                                EXCEPT 
                                SELECT iid 
                                FROM (
                                    SELECT iid, start_time, end_time
                                    FROM (
                                        SELECT C.sid, C.course_id, s_date, start_time, end_time, iid
                                        FROM Conducts C INNER JOIN Sessions S ON C.sid = S.sid AND C.course_id = S.course_id
                                        ORDER BY iid, s_date
                                    ) AS ConductsAndSessions
                                    WHERE EXTRACT(MONTH FROM s_date) = EXTRACT(MONTH FROM CURRENT_DATE)
                                ) AS InstructorsWhoTeachThisMonth2
                            ) AS X
                        ) AS InstructorsWhoDoesNotTeachThisMonth
                    ) AS InstructorsHoursOfTheMonth
                WHERE iid = r.iid), course_start_date + counter_date, avail_hours;
            --current_date := current_date + 1;
        END LOOP; 
    END LOOP;
END;
$$ LANGUAGE plpgsql;

--Function 8
CREATE OR REPLACE FUNCTION find_rooms (
    session_date DATE,
    session_start_hour INTEGER,
    session_duration INTEGER
) RETURNS TABLE(room_id INTEGER) AS $$
    WITH NotAvailableRooms AS (
        SELECT rid
        FROM Sessions NATURAL JOIN Conducts 
        WHERE s_date = session_date AND 
            (session_start_hour < Sessions.end_time AND Sessions.start_time < (session_start_hour + session_duration))
    )
    SELECT rid FROM Rooms
    EXCEPT 
    SELECT rid FROM NotAvailableRooms;
$$ LANGUAGE SQL;

--Function 9
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
    arr INT[];
    num_rooms INTEGER;
    curr_room_cap INTEGER;
BEGIN
    CREATE TEMPORARY TABLE output_table(
        r_id INTEGER,
        r_capacity INTEGER,
        day DATE,
        hours INT[]
    );
    SELECT COUNT(Rooms.rid) INTO num_rooms FROM Rooms;
    LOOP --loop on date change
        FOR room_id IN 1..num_rooms LOOP --room loop
            arr :=  array_cat(arr, ARRAY[9, 10, 11, 14, 15, 16, 17]);
            SELECT seating_capacity INTO curr_room_cap FROM Rooms WHERE rid = room_id;
            OPEN curs FOR SELECT Conducts.rid, Sessions.s_date, Sessions.start_time, Sessions.end_time, COUNT(registers_redeems_view.cust_id) as num_reg_red
                FROM Sessions 
                NATURAL JOIN Conducts
                LEFT JOIN registers_redeems_view  
                ON registers_redeems_view.sid = Sessions.sid AND registers_redeems_view.course_id = Sessions.course_id AND registers_redeems_view.launch_date = Sessions.launch_date
                WHERE Sessions.s_date = curr_date AND Conducts.rid = room_id
                GROUP BY Conducts.rid, Sessions.s_date, Sessions.start_time, Sessions.end_time
                ORDER BY Sessions.s_date;   
            LOOP --curs
                FETCH curs INTO r;
                IF (NOT FOUND) THEN
                    INSERT INTO output_table VALUES(room_id, curr_room_cap, curr_date, arr);
                    EXIT;
                END IF;
                curr_room_cap := curr_room_cap - r.num_reg_red;
                FOR hour IN r.start_time..r.end_time - 1 LOOP --hour loop
                    arr := array_remove(arr,hour);
                END LOOP; --end hour loop
            END LOOP; --end curs loop
            CLOSE curs;
            arr := NULL;
        END LOOP; -- end room loop
        curr_date := curr_date + 1;
        EXIT WHEN curr_date > end_date;
    END LOOP; --end date loop
    RETURN QUERY
    SELECT * FROM output_table ORDER BY r_id, day;
    DROP TABLE output_table;
END;
$$ LANGUAGE plpgsql;

--Function 10
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
        -- RAISE NOTICE 'launch_date: %, course_id: %, s_date: %, s_start: %', l_date, c_id, i.s_date, i.s_start;
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
            INSERT INTO Sessions (sid, s_date, start_time, end_time, course_id, launch_date) VALUES(sess_id, i.s_date, i.s_start, i.s_start + c_duration, c_id, l_date);
            INSERT INTO Conducts (iid, area_name, sid, launch_date, course_id, rid) VALUES (instructor_id, c_area, sess_id, l_date, c_id, r_id);
            instructor_id := NULL;
            r_id := NULL;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

--Function 11
CREATE OR REPLACE PROCEDURE add_course_package(
package_name TEXT,
num_free_registrations INTEGER,
sale_start_date DATE,
sale_end_date DATE,
price NUMERIC) AS $$
INSERT INTO Course_packages (package_name, num_free_registrations, sale_start_date, sale_end_date, price)
VALUES(package_name, num_free_registrations, sale_start_date, sale_end_date, price);
$$ LANGUAGE SQL;

--Function 12
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

--Function 13
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

--Function 14
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
        Buys NATURAL LEFT JOIN Redeems NATURAL LEFT JOIN Sessions LEFT JOIN Courses ON Sessions.course_id = Courses.course_id NATURAL LEFT JOIN Course_packages
        WHERE Buys.cust_id = c_id AND num_remaining_redemptions > 0 
        ORDER BY Buys.package_id, Sessions.s_date, Sessions.start_time;

    OPEN curs2 FOR SELECT Buys.package_id, Course_packages.package_name, Buys.buy_date, Course_packages.price, Buys.num_remaining_redemptions, Courses.title, Sessions.s_date, Sessions.start_time FROM 
        Buys NATURAL LEFT JOIN Redeems NATURAL LEFT JOIN Sessions LEFT JOIN Courses ON Sessions.course_id = Courses.course_id NATURAL LEFT JOIN Course_packages
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

--Function 15
CREATE OR REPLACE FUNCTION get_available_course_offerings()
RETURNS TABLE (
    course_title TEXT,
    course_area TEXT,
    start_date DATE,
    end_date DATE,
    registration_deadline DATE,
    course_fees NUMERIC,
    number_of_remaining_seats INTEGER
) AS $$
SELECT Courses.title, Courses.area_name, Offerings.start_date, Offerings.end_date, Offerings.registration_deadline, Offerings.fees, Offerings.seating_capacity
FROM Offerings LEFT JOIN Courses ON Offerings.course_id = Courses.course_id
WHERE Offerings.registration_deadline >= CURRENT_DATE AND Offerings.seating_capacity > 0
ORDER BY Offerings.registration_deadline, Courses.title;
$$ LANGUAGE SQL;

--Function 16
CREATE OR REPLACE FUNCTION get_available_course_sessions(_course_id INTEGER, _launch_date DATE)
RETURNS TABLE (
    session_date DATE,
    start_hour INTEGER,
    instructor_name TEXT,
    remaining_seats INTEGER
) AS $$
DECLARE
    reg_deadline DATE;
BEGIN
SELECT registration_deadline INTO reg_deadline 
FROM Offerings 
WHERE Offerings.course_id = _course_id AND Offerings.launch_date = _launch_date;
IF (reg_deadline < CURRENT_DATE) THEN
    RAISE EXCEPTION 'Past course offering registration deadline %', reg_deadline;
END IF;
RETURN QUERY
with instructor_name_mapping AS (
    SELECT DISTINCT Instructors.iid, Employees.name
    FROM Instructors LEFT JOIN Employees ON Instructors.iid = Employees.eid
),
offering_sessions_instructor_table AS (
    SELECT instructor_name_mapping.name, Sessions.sid, Sessions.start_time, Sessions.s_date, Sessions.course_id, Sessions.launch_date, Rooms.seating_capacity 
    FROM Sessions NATURAL JOIN Conducts LEFT JOIN instructor_name_mapping ON Conducts.iid = instructor_name_mapping.iid LEFT JOIN Rooms ON Conducts.rid = Rooms.rid
    WHERE Sessions.launch_date = _launch_date AND Sessions.course_id = _course_id
),
num_registrations_for_each_session AS (
    SELECT COUNT(Registers.cust_id) AS num_reg, offering_sessions_instructor_table.sid, offering_sessions_instructor_table.course_id, offering_sessions_instructor_table.launch_date
    FROM Registers NATURAL LEFT JOIN offering_sessions_instructor_table
    WHERE Registers.course_id = _course_id AND Registers.launch_date = _launch_date 
    GROUP BY offering_sessions_instructor_table.sid, offering_sessions_instructor_table.course_id, offering_sessions_instructor_table.launch_date
),
num_redemptions_for_each_session AS (
    SELECT COUNT(Redeems.cust_id) AS num_red, offering_sessions_instructor_table.sid, offering_sessions_instructor_table.course_id, offering_sessions_instructor_table.launch_date
    FROM Redeems NATURAL LEFT JOIN offering_sessions_instructor_table
    WHERE Redeems.course_id = _course_id AND Redeems.launch_date = _launch_date 
    GROUP BY offering_sessions_instructor_table.sid, offering_sessions_instructor_table.course_id, offering_sessions_instructor_table.launch_date
)
SELECT offering_sessions_instructor_table.s_date, offering_sessions_instructor_table.start_time, offering_sessions_instructor_table.name, COALESCE(offering_sessions_instructor_table.seating_capacity - num_reg - num_red, offering_sessions_instructor_table.seating_capacity - num_reg, offering_sessions_instructor_table.seating_capacity - num_red, offering_sessions_instructor_table.seating_capacity)::int
FROM offering_sessions_instructor_table NATURAL LEFT JOIN num_registrations_for_each_session NATURAL LEFT JOIN num_redemptions_for_each_session 
WHERE COALESCE(offering_sessions_instructor_table.seating_capacity  - num_reg - num_red, offering_sessions_instructor_table.seating_capacity  - num_reg, offering_sessions_instructor_table.seating_capacity  - num_red, offering_sessions_instructor_table.seating_capacity) > 0
ORDER BY offering_sessions_instructor_table.s_date, offering_sessions_instructor_table.start_time;
END;
$$ LANGUAGE plpgsql;

--Function 17
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

    -- reduction of num_remaining_buys is in trigger: after_insert_redeems
ELSE
    -- insert into registration table
    INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) 
    VALUES (target_sid, offering_launch_date, offering_course_id, CURRENT_DATE, target_cid);

END IF;

END;
$$ LANGUAGE plpgsql;

--Function 18
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
FROM Courses, Offerings, Sessions, Employees, registers_redeems_view, Conducts
WHERE 
Employees.eid = Conducts.iid AND
Conducts.sid = Sessions.sid AND
Conducts.course_id = Sessions.course_id AND
Conducts.launch_date = Sessions.launch_date AND
Courses.course_id = Offerings.course_id AND
Sessions.s_date >= current_date AND
Sessions.course_id = Offerings.course_id AND
Sessions.launch_date = Offerings.launch_date AND
registers_redeems_view.course_id = Sessions.course_id AND
registers_redeems_view.launch_date = Sessions.launch_date AND
registers_redeems_view.sid = Sessions.sid AND
registers_redeems_view.cust_id = target_cid
ORDER BY Sessions.s_date, Sessions.start_time;

END;
$$ LANGUAGE plpgsql;

--Function 19
CREATE OR REPLACE PROCEDURE update_course_session(
    target_cid INTEGER,
    target_course_id INTEGER,
    target_offering_launch_date DATE,
    new_sid INTEGER
) AS $$
DECLARE
target_session_start_date DATE;
is_redemption_payment BOOLEAN DEFAULT FALSE;
old_sid INTEGER;
BEGIN

-- VALIDATION
-- Customer registered to some session previously
IF (NOT EXISTS 
    (SELECT 1 from registers_redeems_view WHERE 
        registers_redeems_view.cust_id = target_cid AND
        registers_redeems_view.launch_date = target_offering_launch_date AND
        registers_redeems_view.course_id = target_course_id)) THEN
            RAISE EXCEPTION 'Customer % previously has not registered for a session under course offering %, with launch date: %'
                , target_cid, target_course_id, target_offering_launch_date;
END IF;

-- Target session exists
IF (NOT EXISTS 
    (SELECT 1 from Sessions WHERE 
        Sessions.sid = new_sid AND 
        Sessions.launch_date = target_offering_launch_date AND
        Sessions.course_id = target_course_id)) THEN
            RAISE EXCEPTION 'Target session % does not exist for course offering %, with launch date: %'
                , target_cid, target_course_id, target_offering_launch_date;
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

SELECT registers_redeems_view.sid INTO old_sid
FROM registers_redeems_view
WHERE 
    registers_redeems_view.cust_id = target_cid AND
    registers_redeems_view.launch_date = target_offering_launch_date AND
    registers_redeems_view.course_id = target_course_id;

IF (EXISTS (
    SELECT 1
    FROM Redeems
    WHERE 
    Redeems.launch_date = target_offering_launch_date AND
    Redeems.course_id = target_course_id AND
    Redeems.cust_id = target_cid AND
    Redeems.sid = old_sid
)) THEN 
    is_redemption_payment := TRUE;
END IF;

-- update Registers / Redeems accordingly
IF (is_redemption_payment) THEN 
    UPDATE Redeems
    SET sid = new_sid,
    redeem_date = CURRENT_DATE
    WHERE Redeems.launch_date = target_offering_launch_date AND
    Redeems.course_id = target_course_id AND
    Redeems.cust_id = target_cid AND
    Redeems.sid = old_sid;
ELSE 
    UPDATE Registers
    SET sid = new_sid,
    registration_date = CURRENT_DATE
    WHERE Registers.launch_date = target_offering_launch_date AND
    Registers.course_id = target_course_id AND
    Registers.cust_id = target_cid AND
    Registers.sid = old_sid;
END IF;

END;
$$ LANGUAGE plpgsql;

--Function 20
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
-- Check cid is indeed registered / redeems for course session
IF (NOT EXISTS (
    SELECT 1 
    FROM registers_redeems_view
    WHERE 
        registers_redeems_view.launch_date = target_offering_launch_date AND
        registers_redeems_view.course_id = target_course_id AND
        registers_redeems_view.cust_id = target_cid
)) THEN
    RAISE EXCEPTION 'Customer %, is not registered for course: %, with launch date: %', target_cid, target_course_id, target_offering_launch_date;
END IF;

SELECT registers_redeems_view.sid INTO target_sid
FROM registers_redeems_view
WHERE 
    registers_redeems_view.launch_date = target_offering_launch_date AND
    registers_redeems_view.course_id = target_course_id AND
    registers_redeems_view.cust_id = target_cid;

SELECT Sessions.s_date into target_session_s_date
FROM Sessions
WHERE 
    Sessions.launch_date = target_offering_launch_date AND
    Sessions.course_id = target_course_id AND
    Sessions.sid = target_sid;

-- if session_s_date already in the past cannot cancel!
IF (target_session_s_date < current_date) THEN
    RAISE EXCEPTION 'Session was in the past: %. Cannot be cancelled', target_session_s_date;
END IF;

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

IF (is_redemption_payment) THEN
    IF ((target_session_s_date - CURRENT_DATE) < 7) THEN
        INSERT INTO Cancels (cancel_date, cust_id, sid, launch_date, course_id)
        VALUES (CURRENT_DATE, target_cid, target_sid, target_offering_launch_date, target_course_id);
    ELSE
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
    END IF;

    -- remove from redeems table
    DELETE FROM Redeems 
    WHERE 
        Redeems.launch_date = target_offering_launch_date AND
        Redeems.course_id = target_course_id AND
        Redeems.cust_id = target_cid AND 
        Redeems.sid = target_sid AND
        Redeems.package_id = target_package_id AND
        Redeems.buy_date = target_package_buy_date;
ELSE
    -- credit-card payment
    IF ((target_session_s_date - CURRENT_DATE) < 7) THEN
        INSERT INTO Cancels (cancel_date, cust_id, sid, launch_date, course_id)
        VALUES (CURRENT_DATE, target_cid, target_sid, target_offering_launch_date, target_course_id);
    ELSE
        INSERT INTO Cancels (cancel_date, cust_id, sid, launch_date, course_id, refund_amt)
        VALUES (CURRENT_DATE, target_cid, target_sid, target_offering_launch_date, target_course_id, 0.9 * target_course_fees);
    END IF;

    -- remove from registers table
    DELETE FROM Registers 
    WHERE 
        Registers.launch_date = target_offering_launch_date AND
        Registers.course_id = target_course_id AND
        Registers.cust_id = target_cid AND 
        Registers.sid = target_sid;
END IF;

END;
$$ LANGUAGE plpgsql;

--Function 21
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

-- check new instructor has not been fired and
IF (EXISTS (
    SELECT 1 
    FROM Employees
    WHERE Employees.eid = new_iid 
    AND depart_date IS NOT NULL 
    AND depart_date < session_start_date
)) THEN
    RAISE EXCEPTION 'Target instructor has departed before session start date';
END IF;

IF (session_start_date < CURRENT_DATE) THEN 
    RAISE EXCEPTION 'Course session has started';
END IF;

UPDATE Conducts
SET iid = new_iid
WHERE Conducts.course_id = target_course_id AND Conducts.sid = target_sid AND Conducts.launch_date = target_offering_launch_date;
END;
$$ LANGUAGE plpgsql;

--Function 22
CREATE OR REPLACE PROCEDURE update_room (
    target_course_id INTEGER,
    target_offering_launch_date DATE,
    target_sid INTEGER,
    new_rid INTEGER
) AS $$
DECLARE
session_start_date DATE;
no_of_registrations INTEGER;
target_seating_capacity INTEGER;
BEGIN

-- check room exists
IF NOT EXISTS ((
    SELECT 1 
    FROM Rooms
    WHERE rid = new_rid
)) THEN 
    RAISE EXCEPTION 'Target room id: %, does not exist in databse', new_rid;
END IF;

-- check conducts exists
IF NOT EXISTS ((
    SELECT 1 
    FROM Conducts
    WHERE Conducts.sid = target_sid AND Conducts.course_id = target_course_id AND Conducts.launch_date = target_offering_launch_date
)) THEN 
    RAISE EXCEPTION 'Target session, does not exist in databse. CourseId %, lanchdate %, sid %', target_course_id, target_offering_launch_date, target_sid;
END IF;

-- get session_start_id
SELECT s_date INTO session_start_date
FROM Sessions
WHERE Sessions.sid = target_sid AND Sessions.course_id = target_course_id AND Sessions.launch_date = target_offering_launch_date;

-- check course session has not started
IF (session_start_date < CURRENT_DATE) THEN 
RAISE EXCEPTION 'Course session has started';
END IF;


SELECT COUNT(*) INTO no_of_registrations
FROM Sessions
WHERE Sessions.sid = target_sid AND Sessions.launch_date = target_offering_launch_date AND Sessions.course_id = target_course_id;

SELECT seating_capacity INTO target_seating_capacity
FROM Rooms
WHERE Rooms.rid = new_rid;

IF (no_of_registrations > target_seating_capacity) THEN
    RAISE EXCEPTION 'Target room does not have enough seating capacity. Total registerd: %. Seating capacity: %', no_of_registrations, target_seating_capacity;
END IF;

-- actual update
UPDATE Conducts
SET rid = new_rid
WHERE Conducts.course_id = target_course_id AND Conducts.sid = target_sid AND Conducts.launch_date = target_offering_launch_date;

END;
$$ LANGUAGE plpgsql;

--Function 23
CREATE OR REPLACE PROCEDURE remove_session(
    target_course_id INTEGER,
    target_offering_launch_date DATE,
    target_sid INTEGER
) AS $$
DECLARE
session_start_date DATE;
num_registered_to_session INTEGER;
BEGIN

IF (NOT EXISTS (
    SELECT 1 
    FROM Sessions
    WHERE Sessions.sid = target_sid AND Sessions.course_id = target_course_id AND Sessions.launch_date = target_offering_launch_date
)) THEN 
    RAISE EXCEPTION 'Course session does not exist';
END IF;

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
    SELECT 1 FROM registers_redeems_view 
    WHERE 
        registers_redeems_view.course_id = target_course_id AND
        registers_redeems_view.sid = target_sid AND
        registers_redeems_view.launch_date = target_offering_launch_date
    )) THEN 
    RAISE EXCEPTION 'There is at least one customer registered for session. Thus, removal of target session is invalid';
END IF;

-- check if session is only one for couse_offering
IF ((SELECT count(*) FROM Sessions 
        WHERE 
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

--Function 24
CREATE OR REPLACE PROCEDURE add_session (
    offering_course_id INTEGER,
    offering_launch_date DATE,
    new_sid INTEGER,
    s_date DATE,
    start_hour INTEGER,
    target_iid INTEGER,
    rid INTEGER
) AS $$
DECLARE
offering_registration_deadline DATE;
offering_start_date DATE;
offering_end_date DATE;
course_area_name TEXT;
offering_duration INTEGER;
BEGIN

-- check No two sessions for the same course offering can be conducted on the same day and at the same time

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

IF (EXISTS (
    SELECT 1 
    FROM Employees
    WHERE Employees.eid = target_iid 
    AND depart_date IS NOT NULL 
    AND depart_date < s_date
)) THEN
    RAISE EXCEPTION 'Target instructor has departed before session start date';
END IF;

-- insert into sessions here
INSERT INTO Sessions(sid, s_date, start_time, end_time, course_id, launch_date)
    VALUES(new_sid, s_date, start_hour, start_hour + offering_duration, offering_course_id, offering_launch_date);

INSERT INTO Conducts(iid, area_name, sid, course_id, launch_date, rid) 
    VALUES (target_iid, course_area_name, new_sid, offering_course_id, offering_launch_date, rid);

END;
$$ LANGUAGE plpgsql;

--function 25
create or replace function pay_salary ()
returns table (
eid integer,
name text,
status text,
num_work_days integer,
num_work_hours integer,
hourly_rate numeric,
monthly_salary numeric,
amount numeric) AS $$

declare
	curs cursor FOR (select * from employees order by eid asc);
	r record;
	num_days integer;
	num_hours integer;
    max_days integer;
	is_parttime boolean default FALSE;
	is_fulltime boolean default FALSE;
    curr_month integer;
    curr_year integer;
begin
    select extract('month' from current_date) into curr_month;
    select extract('year' from current_date) into curr_year;


	open curs;
	loop
		fetch curs into r;
		exit when not found;
		eid := r.eid;
		name := r.name;
		select exists (select 1 from part_time_emp P where P.eid = r.eid) into is_parttime;

		select exists (select 1 from full_time_emp F where F.eid = r.eid) into is_fulltime;
		
		if (is_parttime = TRUE) then
		-- is a part_time_emp, calculate using hourly rate
			status := 'part-time';
			num_work_days := null;
			monthly_salary := null;
			num_work_hours := get_work_hours(eid, curr_month, curr_year);
			select P.hourly_rate from part_time_emp P where P.eid = r.eid into hourly_rate;
			amount := num_work_hours * hourly_rate;
			
			if (amount is not null) then
			insert into pay_slips_for(eid, payment_date, num_work_hours, num_work_days, amount)
				values (eid, current_date, num_work_hours, null, amount);
			
			return next;
			end if;
			
			

		elsif (is_fulltime = TRUE) then
		-- is a full_time_emp, calculate using monthly salary
			status := 'full-time';
			num_work_hours := null;
			hourly_rate := null;
			num_work_days := get_work_days(eid, curr_month, curr_year);
			select P.monthly_salary from full_time_emp P where P.eid = r.eid into monthly_salary;

            select extract('day' from (date_trunc('month', current_date) + interval '1 month' - interval '1    day')) into max_days;
			amount := num_work_days * monthly_salary / max_days;

			if (amount is not null) then
			insert into pay_slips_for(eid, payment_date, num_work_hours, num_work_days, amount)
				values (eid, current_date, null, num_work_days, amount);
			return next;
			end if;	
			
		end if;
	end loop;
	close curs;
end;
$$ language plpgsql;

--function 26
create or replace function promote_courses()
returns table (
target_cust_id integer,
target_cust_name text,
target_area_name text,
target_course_id integer,
target_title text,
target_launch_date date,
target_registration_deadline date,
target_fees numeric
) as $$
begin
    return query
    select * from promote_courses_helper()
    order by target_cust_id asc, target_registration_deadline asc;
end;
$$ language plpgsql;


create or replace function promote_courses_helper()
returns table (
target_cust_id integer,
target_cust_name text,
target_area_name text,
target_course_id integer,
target_title text,
target_launch_date date,
target_registration_deadline date,
target_fees numeric
) as $$

declare
	curs refcursor;
	curs1 refcursor;
	curs2 refcursor;
	r record;
	r1 record;
	r2 record;
	is_empty boolean default false;
	is_empty1 boolean default false;
begin
	curs := 'curs_name1';
	curs1 := 'curs_name2';
	curs2 := 'curs_name3';
	--find all inactive customers (customers - those that registered within 6 mth)
	open curs for select cust_id
	from customers
	except (select cust_id
		from registers
		where registration_date > (current_date - interval '6 months')
	)
	order by cust_id asc;

	-- for each customer, find course area A that they are interested in
	loop
		fetch curs into r;
		exit when not found;
		
		target_cust_id := r.cust_id;
		select name
		from customers
		where cust_id = r.cust_id
		into target_cust_name;
		
-- find all course areas A that they are interested in (can return 3, 2 ,1 or all)
		
		with interested_table as (select registers_redeems_view.course_id
		from registers_redeems_view 
		where registers_redeems_view.cust_id = r.cust_id
		order by registration_date desc
		limit 3)
		
		select not exists (select 1 from interested_table) into is_empty;
		
		if (is_empty = FALSE) then
			open curs1 for (select registers_redeems_view.course_id
							from registers_redeems_view 
							where registers_redeems_view.cust_id = r.cust_id
							order by registration_date desc
							limit 3);
		elsif (is_empty = TRUE) then
			open curs1 for select course_id from courses;
		end if;

		loop
			fetch curs1 into r1;
			exit when not found;
		
			select area_name
			from Courses
			where Courses.course_id = r1.course_id
			into target_area_name;
			
			target_course_id := r1.course_id;
			
			select title
			from Courses
			where Courses.course_id = r1.course_id
			into target_title;
		
			with offering_table as (select course_id, launch_date, registration_deadline, fees
			from offerings
			where offerings.course_id = r1.course_id
			and launch_date <= current_date
			and current_date <= registration_deadline)

			select not exists (select 1 from offering_table) into is_empty1;
		
			if (is_empty1 = FALSE) then 
				open curs2 for (select course_id, launch_date, registration_deadline, fees
								from offerings
								where offerings.course_id = r1.course_id
								and launch_date <= current_date
								and current_date <= registration_deadline
                                order by registration_deadline);
				
				loop
					fetch curs2 into r2;
					exit when not found;
					
					target_launch_date := r2.launch_date;
					target_registration_deadline := r2.registration_deadline;
					target_fees := r2.fees;
					
					return next;
					
				end loop;
				close curs2;
			end if;
			
		end loop;
		close curs1;
		
	end loop;

close curs;

end;
$$ language plpgsql;

--function 27
create or replace function top_packages(in n integer)
returns table (
package_id integer,
num_free_registrations integer,
price numeric,
sale_start_date date,
sale_end_date date,
num_sold bigint
) as $$

declare

begin
return query
	with cte as (select course_packages.package_id, 
		course_packages.num_free_registrations, 
		course_packages.price, 
		course_packages.sale_start_date, 
		course_packages.sale_end_date, 
		c.num_sold,
		rank() over (
			order by c.num_sold desc
		) as rankING
	from course_packages join 
		(select buys.package_id, count(*) as num_sold from buys group by buys.package_id) as c
	on course_packages.package_id = c.package_id
	order by num_sold desc, price desc)
	
	select cte.package_id,
		cte.num_free_registrations,
		cte.price,
		cte.sale_start_date,
		cte.sale_end_date,
		cte.num_sold
	from cte
	where cte.ranking <= n;

	-- maybe can use rank() function to deal w the tiebreaker cases? couldnt test it, 
	
end;
$$ language plpgsql;

--function 28
CREATE OR REPLACE FUNCTION popular_courses() RETURNS TABLE (
    cid INTEGER,
    course_title TEXT,
    course_area TEXT,
    num_of_offerings_this_year BIGINT,
    num_registrations_for_latest_offering_this_year INTEGER
) AS $$
DECLARE
    r1 RECORD;
    r2 RECORD;
    last_num INTEGER;
    flag BOOLEAN;
BEGIN 
    CREATE TEMPORARY TABLE OutputTable(
        course_id INTEGER,
        course_title TEXT,
        course_area TEXT,
        num_of_offerings_this_year BIGINT,
        num_registrations_for_latest_offering_this_year INTEGER
    );
    FOR r1 IN WITH CoursesWithMoreThanOneOfferings AS ( --looping through courses
        SELECT course_id, COUNT(course_id) AS num_offerings
        FROM Offerings
        WHERE EXTRACT(YEAR FROM launch_date) = EXTRACT(YEAR FROM CURRENT_DATE)
        GROUP BY course_id
        HAVING COUNT(launch_date) >= 2
    ) SELECT course_id, num_offerings FROM CoursesWithMoreThanOneOfferings
    LOOP
        flag := TRUE;
        last_num := -1;
        FOR r2 IN WITH CoursesWithMoreThanOneOfferings AS ( 
            SELECT course_id, COUNT(course_id) AS num_offerings
            FROM Offerings
            WHERE EXTRACT(YEAR FROM launch_date) = EXTRACT(YEAR FROM CURRENT_DATE)
            GROUP BY course_id
            HAVING COUNT(launch_date) >= 2
        ), NumRegistrationsForExistOfferings AS (
            SELECT course_id, launch_date, COUNT(cust_id) AS num_registers
            FROM registers_redeems_view
            WHERE course_id IN (
                select course_id FROM CoursesWithMoreThanOneOfferings
                )
            GROUP BY course_id, launch_date
        ), 
        NumRegistrationsForEachOfferings AS (
            SELECT course_id, launch_date, num_registers
            FROM NumRegistrationsForExistOfferings
            UNION
            (SELECT course_id, launch_date, 0 as num_registers
            FROM Offerings
            WHERE course_id IN (SELECT course_id FROM CoursesWithMoreThanOneOfferings) AND (course_id, launch_date)
            NOT IN (SELECT course_id, launch_date FROM NumRegistrationsForExistOfferings)
            )
            ORDER BY course_id, launch_date
        ) SELECT course_id, launch_date, num_registers FROM NumRegistrationsForEachOfferings WHERE course_id = r1.course_id
        LOOP
            CONTINUE WHEN NOT flag;
            IF r2.num_registers <= last_num THEN
                flag := FALSE;
            END IF;
            last_num := r2.num_registers;
        END LOOP;
        IF flag THEN
            INSERT INTO OutputTable VALUES ( 
                r1.course_id, 
                (SELECT title FROM Courses WHERE course_id = r1.course_id), 
                (SELECT area_name FROM Courses WHERE course_id = r1.course_id),
                r1.num_offerings,
                last_num
            );
        END IF;
    END LOOP;
    RETURN QUERY
    SELECT * FROM OutputTable 
    ORDER BY num_registrations_for_latest_offering_this_year DESC, course_id ASC;
    DROP TABLE OutputTable;
END;
$$ LANGUAGE plpgsql;

-- function 29
create or replace function view_summary_report (in n integer)
returns table (
summary_month integer,
summary_year integer,
total_salary integer,
-- for total salary, from pay_slips_for, group by payment_date's month/year and sum() pay_slips_for's amount
total_sales integer,
-- for total sales, from course_packages and buys, join on package_id, group by buy_date's month/year and sum() course_package's price
total_registration_fees integer,
-- for total registration, from registers join sessions join offerings, group by registration_date's month/year and sum() offering's fee
total_refunded_fees integer,
-- for total refunded, from cancels, group by cancel_date's month/year and sum() refund_amt
total_redemptions integer
-- for total redemptions, from redeems, group by redeem_date's month/year and count(*)
) as $$

declare
	start integer;
	curr_month integer;
	curr_year integer;
	
begin
	start := 1;
	curr_month := extract('month' from current_date) + 1;
	curr_year := extract('year' from current_date);

	loop
		exit when n = 0;
		raise notice 'start:%', start;
		curr_month := curr_month - start;
				raise notice 'cur_month:%	', curr_month;
		if (curr_month = 0) then
		--jan minus 1 month is december of previous year
			raise notice 'inside loop';
			curr_month := 12;
			curr_year := curr_year - 1;
		end if;
		summary_month := curr_month;
		summary_year := curr_year;
		
		--total salary
		select G.sum
		from 	(select extract('month' from payment_date) as pay_month, 
				extract('year' from payment_date) as pay_year, 
				sum(amount) as sum
			from pay_slips_for
			group by 1,2) as G
		where G.pay_month = curr_month
		and G.pay_year = curr_year
		into total_salary;
		
		--total sales
		select B.sum
		from	(select extract('month' from Buys.buy_date) as buy_month,
				extract('year' from Buys.buy_date) as buy_year,
				sum(Course_packages.price) as sum
			from Buys join Course_packages
			on Buys.package_id = Course_packages.package_id
			group by 1,2) as B
		where B.buy_month = curr_month
		and B.buy_year = curr_year
		into total_sales;
		
		--total registration fees
		select R.sum
		from	(select extract('month' from Registers.registration_date) as reg_month,
				extract('year' from Registers.registration_date) as reg_year,
				sum(Offerings.fees) as sum
			from (Sessions natural join Offerings) 
			natural join Registers
			group by 1,2) as R
		where R.reg_month = curr_month
		and R.reg_year = curr_year
		into total_registration_fees;

		--total refunded fees
		select C.sum
		from	(select extract('month' from Cancels.cancel_date) as cancel_month,
				extract('year' from Cancels.cancel_date) as cancel_year,
				sum(Cancels.refund_amt) as sum
			from Cancels
			group by 1,2) as C
		where C.cancel_month = curr_month
		and C.cancel_year = curr_year
		into total_refunded_fees;

		--total redemptions

		select T.sum
		from	(select extract('month' from Redeems.redeem_date) as redeem_month,
				extract('year' from Redeems.redeem_date) as redeem_year,
				count(*) as sum
			from Redeems
			group by 1,2) as T
		where T.redeem_month = curr_month
		AND T.redeem_year = curr_year
		into total_redemptions;
		
		n:= n - 1;
		return next;


		
	end loop;
	


end;
$$ language plpgsql;

--function 30
create or replace function view_manager_report()
returns table (
manager_name text,
-- output is sorted by manager_name asc
num_course_areas bigint,
-- from course_areas table, group by mid and count(*)
num_course_offerings numeric,
-- for each course_area (curs in course_areas table), group by course_area and date, 
total_reg_fees numeric,

top_offering_title text[]
) as $$

declare

begin

RETURN QUERY
with table_one as (SELECT Table1.mid, Table1.name, Table1.num_course_areas, Table2.course_id, COALESCE(Table2.num_offerings, 0) as num_offerings, Table2.launch_date FROM
(SELECT Managers.mid, Employees.name, COUNT(DISTINCT area_name) as num_course_areas
 FROM Managers INNER JOIN employees on mid = eid
 LEFT JOIN Course_areas ON Managers.mid = Course_areas.mid
 GROUP BY Managers.mid, Employees.name) AS Table1
 LEFT JOIN
(SELECT Managers.mid, Courses.course_id, COUNT(Offerings.course_id) as num_offerings, Offerings.launch_date
FROM Managers LEFT JOIN Course_areas ON Managers.mid = Course_areas.mid LEFT JOIN Courses ON Course_areas.area_name = Courses.area_name LEFT JOIN Offerings ON Courses.course_id = Offerings.course_id
WHERE EXTRACT('year' FROM Offerings.end_date) = EXTRACT('year' FROM CURRENT_DATE)
GROUP BY Managers.mid, Courses.course_id, Offerings.launch_date) AS Table2
ON Table1.mid = Table2.mid)


,table_two as (select *, get_total_net_registration_fees(launch_date, course_id) as total_fees
from table_one)


,table_three as(select mid as mid_max, max(total_fees) as fees_max, sum(num_offerings) as num_c_offerings
from table_two
group by mid)

,table_four as (select *
from table_two cross join table_three
where mid = mid_max
and total_fees is not distinct from fees_max)

select table_four.name, table_four.num_course_areas, num_c_offerings, table_four.total_fees, array_agg(C.title) as "title(s)"
from table_four left outer join (select course_id, title from courses) as C
on table_four.course_id = C.course_id
group by table_four.name, table_four.num_course_areas, num_c_offerings, table_four.total_fees;

end;
$$ language plpgsql;

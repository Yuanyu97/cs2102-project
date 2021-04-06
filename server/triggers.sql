CREATE OR REPLACE FUNCTION before_insert_update_conducts() RETURNS TRIGGER AS $$
DECLARE
    r_capacity INTEGER;
    o_capacity INTEGER;
    course_area TEXT;
BEGIN
    SELECT area_name INTO course_area FROM Courses WHERE Courses.course_id = NEW.course_id;
    IF (course_area <> NEW.area_name) THEN
      RAISE EXCEPTION 'Instructor specializing area not the same as session course area';
    END IF;
    SELECT seating_capacity INTO r_capacity FROM Rooms WHERE Rooms.rid = NEW.rid;
    SELECT seating_capacity INTO o_capacity FROM Offerings WHERE Offerings.course_id = NEW.course_id AND Offerings.launch_date = NEW.launch_date;
    UPDATE Offerings SET seating_capacity = o_capacity + r_capacity WHERE Offerings.course_id = NEW.course_id AND Offerings.launch_date = NEW.launch_date;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_update_conducts_trigger
BEFORE INSERT OR UPDATE ON Conducts
FOR EACH ROW EXECUTE FUNCTION before_insert_update_conducts();
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION before_insert_buys() RETURNS TRIGGER AS $$
DECLARE
  num_remaining_redemptions INTEGER;
  sale_start DATE;
  sale_end DATE;
BEGIN
  SELECT sale_start_date, sale_end_date INTO sale_start, sale_end FROM Course_packages WHERE Course_packages.package_id = NEW.package_id;
  IF (NEW.buy_date < sale_start OR NEW.buy_date > sale_end) THEN
    RAISE EXCEPTION 'Unable to purchase course package. % buy date not within % and %', NEW.buy_date, sale_start_date, sale_end_date;
  END IF;
  SELECT num_free_registrations INTO num_remaining_redemptions FROM Course_packages WHERE Course_packages.package_id = NEW.package_id;
  NEW.num_remaining_redemptions = num_remaining_redemptions;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_buys_trigger
BEFORE INSERT ON Buys
FOR EACH ROW EXECUTE FUNCTION before_insert_buys();
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION before_insert_offering() RETURNS TRIGGER AS $$
DECLARE
  days_diff INTEGER;
BEGIN
  SELECT (NEW.start_date - NEW.registration_deadline) INTO days_diff;
  IF (days_diff >= 10) THEN
    RETURN NEW;
  ELSE
    RAISE EXCEPTION 'registration deadline for a course offering must be at least 10 days before its start date';
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_offering_trigger
BEFORE INSERT ON Offerings
FOR EACH ROW EXECUTE FUNCTION before_insert_offering();
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION before_update_or_insert_session() RETURNS TRIGGER AS $$
DECLARE
  day_of_week INTEGER;
  earliest_start_date DATE;
  latest_start_date DATE;
  s_capacity INTEGER;
  old_capacity INTEGER;
  num_hours INTEGER;
  sess_count INTEGER;
BEGIN
  SELECT extract(
    isodow FROM NEW.s_date
    ) INTO day_of_week;
  IF (day_of_week IN (6, 7)) THEN --check if session start date is a weekend
    RAISE EXCEPTION 'Day % is not a weekday', NEW.s_date;
  END IF;
  SELECT duration INTO num_hours FROM Courses WHERE Courses.course_id = NEW.course_id;
  NEW.end_time := NEW.start_time + num_hours; 
  SELECT COUNT(DISTINCT sid) INTO sess_count
  FROM Sessions
  WHERE Sessions.course_id = NEW.course_id AND Sessions.launch_date = NEW.launch_date AND Sessions.s_date = NEW.s_date AND ((NEW.start_time >= Sessions.start_time AND NEW.start_time <= Sessions.end_time) OR (NEW.end_time >= Sessions.start_time AND NEW.end_time <= Sessions.end_time) OR (NEW.start_time <= Sessions.start_time AND NEW.end_time >= Sessions.end_time));   
  IF (sess_count <> 0) THEN --check overlapping sessions in same course offering
    RAISE EXCEPTION 'Overlapping sessions in same course offering: Start date: %, Start time: %, End Time: %', NEW.s_date, NEW.start_time, NEW.end_time;
  END IF;
  SELECT start_date, end_Date INTO earliest_start_date, latest_start_date FROM Offerings WHERE Offerings.course_id = NEW.course_id AND Offerings.launch_date = NEW.launch_date;
  IF (NEW.s_date < earliest_start_date OR earliest_start_date IS NULL) THEN --setting start date
    UPDATE Offerings SET start_date = NEW.s_date WHERE Offerings.course_id = NEW.course_id AND Offerings.launch_date = NEW.launch_date;
  END IF;
  IF (NEW.s_date > latest_start_date OR latest_start_date IS NULL) THEN --setting end date
    UPDATE Offerings SET end_date = NEW.s_date WHERE Offerings.course_id = NEW.course_id AND Offerings.launch_date = NEW.launch_date;
  END IF; 
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_update_or_insert_session_trigger
BEFORE INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION before_update_or_insert_session();
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION before_insert_redeems() RETURNS TRIGGER AS $$
DECLARE
  num_redemptions_left INTEGER;
  sess_total_capacity INTEGER;
  num_red INTEGER;
  num_reg INTEGER;
BEGIN
  SELECT num_remaining_redemptions INTO num_redemptions_left FROM Buys WHERE Buys.cust_id = NEW.cust_id AND Buys.buy_date = NEW.buy_date AND Buys.package_id = NEW.package_id;
  IF (num_redemptions_left = 0) THEN
    RAISE EXCEPTION 'Failed to redeem due to insufficient remaining redemptions with redemption info: Cust id %, Package id: %, Buy Date: %', NEW.cust_id, NEW.package_id, NEW.buy_date;
  END IF;
  SELECT Rooms.seating_capacity INTO sess_total_capacity
  FROM Conducts LEFT JOIN Rooms ON Conducts.rid = Rooms.rid
  WHERE Conducts.sid = NEW.sid AND Conducts.course_id = NEW.course_id AND Conducts.launch_date = NEW.launch_date
  LIMIT 1;

  SELECT COUNT(Registers.cust_id) INTO num_reg 
  FROM Registers
  WHERE Registers.sid = NEW.sid AND Registers.course_id = NEW.sid AND Registers.launch_date = NEW.launch_date;

  SELECT COUNT(Redeems.cust_id)INTO num_red
  FROM Redeems
  WHERE Redeems.sid = NEW.sid AND Redeems.course_id = NEW.sid AND Redeems.launch_date = NEW.launch_date;

  IF (sess_total_capacity - num_reg - num_red = 0) THEN
    RAISE EXCEPTION 'Could not redeem session. Max capacity reached';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_redeems_trigger 
BEFORE INSERT ON Redeems
FOR EACH ROW EXECUTE FUNCTION before_insert_redeems();
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION after_insert_redeems() RETURNS TRIGGER AS $$
DECLARE
  current_remaining_seats_offering INTEGER;
  current_remaining_redemptions INTEGER;
BEGIN

  SELECT seating_capacity INTO current_remaining_seats_offering FROM Offerings
  WHERE Offerings.course_id = NEW.course_id AND Offerings.launch_date = NEW.launch_date;

  UPDATE Offerings SET seating_capacity = current_remaining_seats_offering - 1 
  WHERE Offerings.course_id = NEW.course_id AND Offerings.launch_date = NEW.launch_date;

  SELECT num_remaining_redemptions INTO current_remaining_redemptions FROM Buys 
  WHERE Buys.buy_date = NEW.buy_date AND Buys.cust_id = NEW.cust_id AND Buys.package_id = NEW.package_id;

  UPDATE Buys 
  SET num_remaining_redemptions = current_remaining_redemptions - 1 
  WHERE Buys.buy_date = NEW.buy_date AND Buys.cust_id = NEW.cust_id AND Buys.package_id = NEW.package_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_insert_redeems_trigger 
AFTER INSERT ON Redeems
FOR EACH ROW EXECUTE FUNCTION after_insert_redeems();
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION before_insert_registers() RETURNS TRIGGER AS $$
DECLARE
  sess_total_capacity INTEGER;
  num_red INTEGER;
  num_reg INTEGER;
BEGIN
  SELECT Rooms.seating_capacity INTO sess_total_capacity
  FROM Conducts LEFT JOIN Rooms ON Conducts.rid = Rooms.rid
  WHERE Conducts.sid = NEW.sid AND Conducts.course_id = NEW.course_id AND Conducts.launch_date = NEW.launch_date
  LIMIT 1;

  SELECT COUNT(Registers.cust_id) INTO num_reg 
  FROM Registers
  WHERE Registers.sid = NEW.sid AND Registers.course_id = NEW.sid AND Registers.launch_date = NEW.launch_date;

  SELECT COUNT(Redeems.cust_id)INTO num_red
  FROM Redeems
  WHERE Redeems.sid = NEW.sid AND Redeems.course_id = NEW.sid AND Redeems.launch_date = NEW.launch_date;

  IF (sess_total_capacity - num_reg - num_red = 0) THEN
    RAISE EXCEPTION 'Could not register session. Max capacity reached';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_registers_trigger 
BEFORE INSERT ON Registers
FOR EACH ROW EXECUTE FUNCTION before_insert_registers();
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION after_insert_registers() RETURNS TRIGGER AS $$
DECLARE
  current_remaining_seats_offering INTEGER;
  current_remaining_redemptions INTEGER;
BEGIN

  SELECT seating_capacity INTO current_remaining_seats_offering FROM Offerings
  WHERE Offerings.course_id = NEW.course_id AND Offerings.launch_date = NEW.launch_date;

  UPDATE Offerings SET seating_capacity = current_remaining_seats_offering - 1 
  WHERE Offerings.course_id = NEW.course_id AND Offerings.launch_date = NEW.launch_date;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_insert_registers_trigger 
AFTER INSERT ON Registers
FOR EACH ROW EXECUTE FUNCTION after_insert_registers();
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION register_at_most_one_session_before_deadline() RETURNS TRIGGER AS $$
DECLARE
    session_registration_deadline DATE;
BEGIN
    SELECT registration_deadline INTO session_registration_deadline 
    FROM (
        SELECT registration_deadline
        FROM Registers R INNER JOIN Offerings O ON R.launch_date = O.launch_date AND R.course_id = O.course_id
        WHERE R.course_id = NEW.course_id AND R.sid = NEW.sid AND R.launch_date = NEW.launch_date
    ) AS X;
    IF (NEW.registration_date > session_registration_deadline) OR EXISTS(
        SELECT 1
        FROM Registers 
        WHERE cust_id = NEW.cust_id
    ) THEN RETURN NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER register_at_most_one_session_before_deadline_trigger
BEFORE INSERT ON Registers
FOR EACH ROW EXECUTE FUNCTION register_at_most_one_session_before_deadline();
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION instructor_teach_one_course_session_at_any_hour() RETURNS TRIGGER AS $$
DECLARE
    session_date DATE;
    session_start_time INTEGER;
    session_end_time INTEGER;
BEGIN
    SELECT s_date, start_time, end_time INTO session_date, session_start_time, session_end_time
    FROM (
        SELECT s_date, start_time, end_time
        FROM Sessions S INNER JOIN Conducts C ON S.sid = C.sid AND S.course_id = C.course_id
        WHERE S.sid = NEW.sid AND S.course_id = NEW.course_id
    ) AS CS;
    IF EXISTS (
        SELECT 1 
        FROM (Sessions S INNER JOIN Conducts C ON S.sid = C.sid AND S.course_id = C.course_id) AS X
        where X.s_date = session_date AND X.iid = NEW.iid AND (session_end_time <= X.start_time OR X.end_time <= session_start_time)
    ) THEN RETURN NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER instructor_teach_one_course_session_at_any_hour_trigger
BEFORE INSERT OR UPDATE ON Conducts
FOR EACH ROW EXECUTE FUNCTION instructor_teach_one_course_session_at_any_hour();
---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION one_session_at_all_time_per_room() RETURNS TRIGGER AS $$
DECLARE
    session_date DATE;
    session_start_time INTEGER;
    session_end_time INTEGER;
BEGIN
    -- get the start time and end time. room id access from NEW.rid
    SELECT s_date, start_time, end_time INTO session_date, session_start_time, session_end_time 
    FROM (
        SELECT s_date, start_time, end_time
        FROM Sessions S INNER JOIN Conducts C ON S.sid = C.sid AND S.course_id = C.course_id
        WHERE S.sid = NEW.sid AND S.course_id = NEW.course_id
    ) AS CS;
    IF EXISTS(
        SELECT 1 
        FROM (Sessions S INNER JOIN Conducts C ON S.sid = C.sid AND S.course_id = C.course_id) AS X
        WHERE X.rid = NEW.rid AND X.s_date = session_date AND (session_end_time <= X.start_time OR X.end_time <= session_start_time)
    ) THEN RETURN NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER one_session_at_all_time_per_room_trigger
BEFORE INSERT OR UPDATE ON Conducts
FOR EACH ROW EXECUTE FUNCTION one_session_at_all_time_per_room();
---------------------------------------------------------------------------------



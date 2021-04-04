CREATE OR REPLACE FUNCTION before_insert_update_conducts() RETURNS TRIGGER AS $$
DECLARE
    room_id INTEGER;
    course_area TEXT;
BEGIN
    SELECT area_name INTO course_area FROM Courses WHERE Courses.course_id = NEW.course_id;
    SELECT rid INTO room_id FROM Sessions WHERE Sessions.sid = NEW.sid AND Sessions.course_id = NEW.course_id;
    IF (course_area <> NEW.area_name) THEN
      RAISE EXCEPTION 'Instructor specializing area not the same as session course area';
    ELSE
      NEW.rid = room_id;
      RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_update_conducts_trigger
BEFORE INSERT OR UPDATE ON Conducts
FOR EACH ROW EXECUTE FUNCTION before_insert_update_conducts();


CREATE OR REPLACE FUNCTION before_insert_buys() RETURNS TRIGGER AS $$
DECLARE
  num_remaining_redemptions INTEGER;
BEGIN
  SELECT num_free_registrations INTO num_remaining_redemptions FROM Course_packages WHERE Course_packages.package_id = NEW.package_id;
  NEW.num_remaining_redemptions = num_remaining_redemptions;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER buys_trigger
BEFORE INSERT ON Buys
FOR EACH ROW EXECUTE FUNCTION before_insert_buys();

CREATE OR REPLACE FUNCTION before_insert_offering() RETURNS TRIGGER AS $$
DECLARE
  days_diff INTEGER;
BEGIN
  SELECT (NEW.start_date - OLD.registration_deadline) INTO days_diff;
  IF (days_diff >= 10) THEN
    RETURN NEW;
  ELSE
    RAISE EXCEPTION 'registration deadline for a course offering must be at least 10 days before its start date';
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER offerings_trigger
BEFORE UPDATE ON Offerings
FOR EACH ROW EXECUTE FUNCTION before_insert_offering();

CREATE OR REPLACE FUNCTION before_insert_session() RETURNS TRIGGER AS $$
DECLARE
  earliest_start_date DATE;
  latest_start_date DATE;
  s_capacity INTEGER;
  old_capacity INTEGER;
BEGIN
  SELECT start_date, end_Date INTO earliest_start_date, latest_start_date FROM Offerings WHERE Offerings.course_id = NEW.course_id AND Offerings.launch_date = NEW.launch_date;
  IF (NEW.s_date < earliest_start_date OR earliest_start_date IS NULL) THEN
    UPDATE Offerings SET start_date = NEW.s_date WHERE Offerings.course_id = NEW.course_id AND Offerings.launch_date = NEW.launch_date;
  END IF;
  IF (NEW.s_date > latest_start_date OR latest_start_date IS NULL) THEN
    UPDATE Offerings SET end_date = NEW.s_date WHERE Offerings.course_id = NEW.course_id AND Offerings.launch_date = NEW.launch_date;
  END IF;
  SELECT seating_capacity INTO s_capacity FROM Rooms WHERE NEW.rid = Rooms.rid;
  SELECT seating_capacity INTO old_capacity FROM Offerings WHERE Offerings.course_id = NEW.course_id AND Offerings.launch_date = NEW.launch_date;
  UPDATE Offerings SET seating_capacity = s_capacity + old_capacity WHERE Offerings.course_id = NEW.course_id AND Offerings.launch_date = NEW.launch_date;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_session 
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION before_insert_session();

-- CREATE OR REPLACE FUNCTION before_update_conducts() RETURNS TRIGGER AS $$
-- DECLARE

-- BEGIN
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER before_update_conducts
-- BEFORE UPDATE ON Conducts
-- FOR EACH ROW EXECUTE FUNCTION before_update_conducts();

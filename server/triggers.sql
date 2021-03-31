CREATE OR REPLACE FUNCTION before_insert_conducts() RETURNS TRIGGER AS $$
DECLARE
    capacity INTEGER;
BEGIN
    SELECT seating_capacity into capacity FROM Rooms WHERE Rooms.rid = NEW.rid;
    NEW.seating_capacity = capacity;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION before_insert_offerings() RETURNS TRIGGER AS $$
DECLARE
  capacity INTEGER;
BEGIN
  SELECT SUM(seating_capacity) INTO capacity FROM Conducts WHERE Conducts.course_id = NEW.course_id;
  NEW.seating_capacity = capacity;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER offerings_trigger
BEFORE INSERT ON Offerings
FOR EACH ROW EXECUTE FUNCTION before_insert_offerings();

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
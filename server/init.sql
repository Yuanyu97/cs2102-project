drop table if exists Rooms, Customers, Credit_cards, Course_packages, Buys,
 Employees, Part_Time_Emp, Full_Time_Emp, Instructors, Part_Time_Instructors,
 Full_Time_Instructors, Managers, Administrators, Course_areas, Courses, Offerings,
 Sessions, Cancels, Registers, Redeems, Pay_slips_for cascade; 

-- checked
CREATE TABLE Rooms (
  rid SERIAL PRIMARY KEY,
  location text,
  seating_capacity integer
);

-- checked
CREATE TABLE Credit_cards ( 
  credit_card_number text PRIMARY KEY,
  CVV CHAR(3) NOT NULL,
  expiry_date DATE NOT NULL,
  from_date DATE,
  check (from_date < expiry_date)
  -- combined with Owns table (Key + Total Participation Constrainteger)
  -- SET TRIGGER: Every customer must own at least one credit card (when inserting new customer)
);

-- checked
CREATE TABLE Customers (
  cust_id SERIAL PRIMARY KEY,
  credit_card_number TEXT NOT NULL UNIQUE,
  name text NOT NULL,
  address text,
  email text,
  phone text,
  FOREIGN KEY (credit_card_number) references Credit_cards ON UPDATE CASCADE
);

-- checked
CREATE TABLE Course_packages (
  package_id SERIAL PRIMARY KEY, 
  sale_start_date DATE NOT NULL,
  sale_end_date DATE NOT NULL,
  num_free_registrations integer,
  package_name text,
  price NUMERIC NOT NULL,
  check (sale_start_date <= sale_end_date)
);

-- checked (CHECK PRIMARY KEY!!)
CREATE TABLE Buys (
  buy_date DATE,
  cust_id INTEGER,
  num_remaining_redemptions integer,
  package_id integer REFERENCES Course_packages,
  FOREIGN KEY (cust_id) 
    REFERENCES Customers,
  PRIMARY KEY (buy_date, cust_id, package_id)
);

-- check (double confirm can null all)
-- soft delete by adding depart_date
CREATE TABLE Employees (
  eid SERIAL PRIMARY KEY,
  name text,
  address text,
  phone text,
  email text,
  join_date DATE,
  depart_date DATE DEFAULT NULL,
  check (join_date <= depart_date)
  -- SET TRIGGER: Every Employee is either a Part_Time_Emp or Full_Time_Emp but not both
);

-- checked
CREATE TABLE Part_Time_Emp (
  eid integer PRIMARY KEY REFERENCES Employees
    ON DELETE CASCADE,
  hourly_rate NUMERIC
    constraint positive_hourly_rate check (hourly_rate >= 0)
);

-- checked
CREATE TABLE Full_Time_Emp (
  eid integer PRIMARY KEY REFERENCES Employees
    ON DELETE CASCADE,
  monthly_salary NUMERIC
    constraint positive_monthly_salary check (monthly_salary >= 0)
  -- SET TRIGGER: Every Full_Time_Emp is either a Full_Time_Instructor or Managers or Administrators but not all
);

-- checked
CREATE TABLE Managers (
  mid integer PRIMARY KEY REFERENCES Full_Time_Emp
  ON DELETE CASCADE
);

-- checked
CREATE TABLE Administrators(
  aid integer PRIMARY KEY REFERENCES Full_Time_Emp
  ON DELETE CASCADE
);

-- checked
CREATE TABLE Course_areas ( 
  area_name text PRIMARY KEY,
  mid integer NOT NULL REFERENCES Managers(mid)
  -- Combined with Manages table (Key + Total participation constrainteger)
);

-- checked
-- consider how diff part-time & full-time for add_employee function
CREATE TABLE Instructors (
  iid integer REFERENCES Employees
    ON DELETE CASCADE,
  area_name text REFERENCES Course_areas,
  PRIMARY KEY(iid, area_name)
);

-- checked
CREATE TABLE Part_Time_Instructors (
  ptid integer REFERENCES Part_Time_Emp
    ON DELETE CASCADE,
  area_name TEXT,
  FOREIGN KEY (ptid, area_name) 
    REFERENCES Instructors
    ON DELETE CASCADE,
  PRIMARY KEY (ptid, area_name)
);

-- checked
CREATE TABLE Full_Time_Instructors (
  ftid integer REFERENCES Full_Time_Emp
    ON DELETE CASCADE,
  area_name TEXT, 
  FOREIGN KEY (ftid, area_name) 
    REFERENCES Instructors
    ON DELETE CASCADE,
  PRIMARY KEY (ftid, area_name)
);

-- checked
CREATE TABLE Courses (
  course_id SERIAL PRIMARY KEY,
  title text NOT NULL,
  duration integer NOT NULL,
  description text,
  area_name text NOT NULL REFERENCES Course_areas,
  check (duration <= 4)
);

-- checked
CREATE TABLE Offerings (
  course_id integer REFERENCES Courses ON DELETE CASCADE,
  launch_date DATE,
  start_date DATE,
  end_date DATE,
  target_number_registrations integer DEFAULT 0,
  seating_capacity integer,
  registration_deadline DATE,
  fees NUMERIC,
  aid integer NOT NULL REFERENCES Administrators,
  PRIMARY KEY(course_id, launch_date),
  check((start_date <= end_date) AND (registration_deadline <= start_date) AND (registration_deadline >= launch_date))
  -- Combined with Has table (WEAK ENTITIY OF COURSE)
  -- Combined with Handles table (Key + Total Participation Constrainteger)
  -- SET A TRIGGER: Every offering has at least 1 session
  -- SET A TRIGGER: seating_capacity = sum of session capacity
);

-- checked SUSS day, hour spoil. ER no good
CREATE TABLE Sessions (/*WEAK ENTITIY OF OFFERING*/
  sid INTEGER,
  s_date DATE,
  start_time integer, 
  end_time integer,
  course_id integer,
  launch_date DATE,
  PRIMARY KEY(sid, course_id, launch_date),
  FOREIGN KEY (course_id, launch_date) REFERENCES Offerings(course_id, launch_date)
    ON DELETE CASCADE,
  check (((start_time IN (9, 10, 11) AND end_time IN (10, 11, 12)) OR (start_time IN (14, 15, 16, 17) AND end_time IN (15, 16, 17, 18))) 
    AND start_time < end_time)
  -- Combined with Consists table (WEAK ENTITIY OF OFFERING)
  -- Combined with Conducts table (Key + Total Participation Constrainteger)
);

CREATE TABLE Conducts (
  iid INTEGER,
  area_name TEXT,
  rid INTEGER NOT NULL,
  sid INTEGER,
  launch_date DATE,
  course_id INTEGER,
  UNIQUE(sid, course_id, launch_date),
  FOREIGN KEY (iid, area_name) REFERENCES Instructors,
  FOREIGN KEY (rid) REFERENCES Rooms,
  FOREIGN KEY (sid, course_id, launch_date) REFERENCES Sessions
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  PRIMARY KEY (iid, area_name, rid, sid, course_id, launch_date)
);

-- checked (what is package_credit??)
CREATE TABLE Cancels (
  cancel_date DATE,
  cust_id integer REFERENCES Customers,
  sid integer,
  launch_date DATE,
  course_id integer,
  refund_amt NUMERIC,
  package_credit integer,
  PRIMARY KEY(cancel_date, cust_id, sid, course_id),
  FOREIGN KEY (sid, course_id, launch_Date) references Sessions
  -- Trigger: compute package_credit from Buys.num_remaining_redemptions
);

-- checked G
CREATE TABLE Registers (
  sid integer,
  launch_date DATE,
  course_id integer,
  registration_date DATE,
  cust_id INTEGER,
  PRIMARY KEY(registration_date, cust_id, sid, course_id, launch_date),
  FOREIGN KEY (cust_id) REFERENCES Customers,
  FOREIGN KEY (sid, course_id, launch_date) references Sessions
);

-- checked
CREATE TABLE Redeems (
  -- redeems own attributes
  redeem_date DATE,
  -- buy stuff
  buy_date DATE,
  cust_id INTEGER,
  package_id integer,
  -- session stuff
  sid integer,
  course_id integer,
  launch_date DATE,
  FOREIGN KEY (sid, course_id, launch_date)  REFERENCES Sessions,
  FOREIGN KEY (buy_date, cust_id, package_id) REFERENCES Buys,
  PRIMARY KEY (redeem_date, buy_date, cust_id, package_id, sid, course_id, launch_date),
  check (redeem_date >= buy_date)
);

-- checked
/*WEAK ENTITY OF EMPLOYEES, combined with For*/
CREATE TABLE Pay_slips_for (
  eid integer NOT NULL REFERENCES Employees ON DELETE CASCADE,
  payment_date DATE,
  num_work_hours integer,
  num_work_days integer,
  amount NUMERIC,
  PRIMARY KEY (eid, payment_date)
);


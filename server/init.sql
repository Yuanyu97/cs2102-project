drop table if exists Rooms, Customers, Credit_cards, Course_packages, Buys,
 Employees, Part_Time_Emp, Full_Time_Emp, Instructors, Part_Time_Instructor,
 Full_Time_Instructor, Managers, Administrators, Course_areas, Courses, Offerings,
 Sessions, Cancels, Registers, Redeems, Pay_slips_for, Specializes cascade; 

-- checked
CREATE TABLE Rooms (
  rid SERIAL PRIMARY KEY,
  location text,
  seating_capacity integer
);

-- checked
CREATE TABLE Customers (
  cust_id SERIAL PRIMARY KEY,
  name text,
  address text,
  email text,
  phone text
);

-- checked
CREATE TABLE Credit_cards ( 
  credit_card_number text PRIMARY KEY,
  CVV CHAR(3) NOT NULL,
  owned_by integer NOT NULL,
  expiry_date DATE NOT NULL,
  from_date DATE,
  FOREIGN KEY (owned_by) REFERENCES Customers(cust_id)
  -- combined with Owns table (Key + Total Participation Constrainteger)
  -- SET TRIGGER: Every customer must own at least one credit card (when inserting new customer)
);

-- checked
CREATE TABLE Course_packages (
  package_id SERIAL PRIMARY KEY, 
  sale_start_date DATE NOT NULL,
  sale_end_date DATE NOT NULL,
  num_free_registrations integer,
  package_name text,
  price FLOAT NOT NULL
);

-- checked (CHECK PRIMARY KEY!!)
CREATE TABLE Buys (
  buy_date DATE,
  credit_card_number text,
  num_remaining_redemptions integer,
  package_id integer REFERENCES Course_packages,
  FOREIGN KEY (credit_card_number) 
    REFERENCES Credit_cards,
  PRIMARY KEY (buy_date, credit_card_number, package_id)
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
  depart_date DATE
  -- SET TRIGGER: Every Employee is either a Part_Time_Emp or Full_Time_Emp but not both
);

-- checked
CREATE TABLE Part_Time_Emp (
  eid integer PRIMARY KEY REFERENCES Employees,
  hourly_rate NUMERIC
    constraint positive_hourly_rate check (hourly_rate >= 0)
);

-- checked
CREATE TABLE Full_Time_Emp (
  eid integer PRIMARY KEY REFERENCES Employees,
  monthly_salary NUMERIC
    constraint positive_monthly_salary check (monthly_salary >= 0)
  -- SET TRIGGER: Every Full_Time_Emp is either a Full_Time_Instructor or Managers or Administrators but not all
);

-- checked
-- consider how diff part-time & full-time for add_employee function
CREATE TABLE Instructors (
  iid integer PRIMARY KEY REFERENCES Employees
);

-- checked
CREATE TABLE Part_Time_Instructor (
  ptid integer PRIMARY KEY 
    REFERENCES Part_Time_Emp 
    REFERENCES Instructors
    ON DELETE CASCADE
);

-- checked
CREATE TABLE Full_Time_Instructor (
  ftid integer PRIMARY KEY 
    REFERENCES Full_Time_Emp 
    REFERENCES Instructors 
    ON DELETE CASCADE
);

-- checked
CREATE TABLE Managers (
  mid integer PRIMARY KEY REFERENCES Full_Time_Emp
);

-- checked
CREATE TABLE Administrators(
  aid integer PRIMARY KEY REFERENCES Full_Time_Emp
);

-- checked
CREATE TABLE Course_areas ( 
  area_name text PRIMARY KEY,
  mid integer NOT NULL REFERENCES Managers(mid)
  -- Combined with Manages table (Key + Total participation constrainteger)
);

-- checked
CREATE TABLE Courses (
  course_id SERIAL PRIMARY KEY,
  title text,
  duration integer,
  description text,
  area_name text NOT NULL REFERENCES Course_areas
);



-- checked
CREATE TABLE Offerings (
  course_id integer REFERENCES Courses ON DELETE CASCADE,
  launch_date DATE,
  start_date DATE,
  end_date DATE,
  target_number_registrations integer,
  seating_capacity integer,
  registration_deadline DATE,
  fees FLOAT,
  aid integer NOT NULL REFERENCES Administrators,
  PRIMARY KEY(course_id, launch_date)
  -- Combined with Has table (WEAK ENTITIY OF COURSE)
  -- Combined with Handles table (Key + Total Participation Constrainteger)
  -- SET A TRIGGER: Every offering has at least 1 session
);

-- checked SUSS day, hour spoil. ER no good
CREATE TABLE Sessions (/*WEAK ENTITIY OF OFFERING*/
  sid serial,
  s_date DATE,
  -- integer for start hours only 9,10,11,14,15,16,17
  start_time integer,
  -- integer for end hours 
  end_time integer,
  -- computed at runtime
  course_id integer,
  launch_date DATE,
  rid integer NOT NULL REFERENCES Rooms,
  iid integer NOT NULL REFERENCES Instructors,
  PRIMARY KEY(sid, course_id, launch_date),
  FOREIGN KEY (course_id, launch_date) references Offerings
    ON DELETE CASCADE
  -- Combined with Consists table (WEAK ENTITIY OF OFFERING)
  -- Combined with Conducts table (Key + Total Participation Constrainteger)
);

-- checked (what is package_credit??)
CREATE TABLE Cancels (
  cancel_date DATE,
  cust_id integer REFERENCES Customers,
  sid integer,
  course_id integer,
  launch_date DATE,
  refund_amt FLOAT,
  package_credit integer,
  PRIMARY KEY(cancel_date, cust_id, sid, course_id, launch_date),
  FOREIGN KEY (sid, course_id, launch_date) references Sessions
  -- Trigger: compute package_credit from Buys.num_remaining_redemptions
);

-- checked G
CREATE TABLE Registers (
  sid integer,
  course_id integer,
  launch_date DATE,
  registration_date DATE,
  credit_card_number text,
  PRIMARY KEY(registration_date, credit_card_number, sid, course_id, launch_date),
  FOREIGN KEY (credit_card_number) REFERENCES Credit_cards,
  FOREIGN KEY (sid, course_id, launch_date) references Sessions
);

-- checked
CREATE TABLE Redeems (
  -- redeems own attributes
  redeem_date DATE,
  -- buy stuff
  buy_date DATE,
  credit_card_number text,
  package_id integer,
  -- session stuff
  sid integer,
  course_id integer,
  launch_date DATE,
  FOREIGN KEY (sid, course_id, launch_date)  REFERENCES Sessions,
  FOREIGN KEY (buy_date, credit_card_number, package_id) REFERENCES Buys,
  PRIMARY KEY (redeem_date, buy_date, credit_card_number, package_id, sid, course_id, launch_date)
);

-- checked
/*WEAK ENTITY OF EMPLOYEES, combined with For*/
CREATE TABLE Pay_slips_for (
  eid integer NOT NULL REFERENCES Employees ON DELETE CASCADE,
  payment_date DATE,
  num_work_hours integer,
  num_work_days integer,
  amount FLOAT,
  PRIMARY KEY (eid, payment_date)
);

-- checked
CREATE TABLE Specializes (
  area_name text REFERENCES Course_areas,
  iid integer REFERENCES Instructors
  -- SET TRIGGER: Every Instructor must specialize in at least 1 area.
);

/**
  - Check how auto generate all ID for all tables
  - If Owns merge into Credit_cards, Buys / Registers / Redeems how reference properly?
**/


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

INSERT INTO Rooms(location, seating_capacity) VALUES('Bishan', 10);
INSERT INTO Rooms(location, seating_capacity) VALUES('Serangoon', 5);
INSERT INTO Rooms(location, seating_capacity) VALUES('Punggol', 20);
INSERT INTO Rooms(location, seating_capacity) VALUES('Whompoa', 17);
INSERT INTO Rooms(location, seating_capacity) VALUES('Lorong Chuan', 30);
INSERT INTO Rooms(location, seating_capacity) VALUES('Tenteram', 13);
INSERT INTO Rooms(location, seating_capacity) VALUES('Ang Mo Kio', 50);

-- checked
CREATE TABLE Customers (
  cust_id SERIAL PRIMARY KEY,
  name text,
  address text,
  email text,
  phone text
);

INSERT INTO Customers(name, address, email, phone) VALUES('Freddy', 'Bishan St 11', 'f@yahoo.com', '81234567');
INSERT INTO Customers(name, address, email, phone) VALUES('Wei Boon', 'KR Hall', 'W@gmail.com', '89876543');
INSERT INTO Customers(name, address, email, phone) VALUES('Weng Fai', 'Sheares Juzz', 'weng@yahoo.com', '91234567');
INSERT INTO Customers(name, address, email, phone) VALUES('Dian Hao', 'Best Chai', 'd@outlook.com', '69696969');
INSERT INTO Customers(name, address, email, phone) VALUES('Johnny Sins', 'USA', 'ph@onz.com', '61234567');

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

INSERT INTO Credit_cards VALUES('4628 4500 1234 5678', '123', 1, '2021-03-29', '2020-03-29');
INSERT INTO Credit_cards VALUES('4628 4500 9876 5432', '345', 2, '2021-02-15', '2019-07-15');
INSERT INTO Credit_cards VALUES('4628 4500 8593 8572', '678', 3, '2021-01-05', '2010-05-28');
INSERT INTO Credit_cards VALUES('4628 4500 6969 6969', '901', 4, '2017-12-31', '2025-11-09');
INSERT INTO Credit_cards VALUES('4628 4500 5893 9724', '619', 5, '2021-09-08', '2030-02-10');

-- checked
CREATE TABLE Course_packages (
  package_id SERIAL PRIMARY KEY, 
  sale_start_date DATE NOT NULL,
  sale_end_date DATE NOT NULL,
  num_free_registrations integer,
  package_name text,
  price FLOAT NOT NULL
);

INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-03-30', '2021-04-26', 10, 'Free Udemy Course', 69.99);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-04-15', '2021-06-30', 25, 'React Course', 29.90);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2022-08-24', '2022-09-15', 50, 'Ruby Course', 10.90);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-06-30', '2021-09-26', 35, 'Rest API Course', 8.88);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-07-24', '2021-11-22', 10, 'Java Course', 109.99);

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

INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Freddy', 'Bishan St 11', '81234567', 'f@yahoo.com', '1997-04-26', null);
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Wei Boon', 'KR Hall', '89876543', 'W@gmail.com', '2000-07-21', '2020-12-31');
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Weng Fai', 'Sheares Juzz', '91234567', 'weng@yahoo.com', '2010-02-21', '2011-11-26');
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Dian Hao', 'Best Chai', '69696969', 'd@outlook.com', '2010-06-24', null);
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Johnny Sins', 'USA', '61234567', 'ph@onz.com', '2021-03-29', '2030-07-02');

-- checked
CREATE TABLE Part_Time_Emp (
  eid integer PRIMARY KEY REFERENCES Employees,
  hourly_rate NUMERIC
    constraint positive_hourly_rate check (hourly_rate >= 0)
);

INSERT INTO Part_Time_Emp VALUES(1, 80);
INSERT INTO Part_Time_Emp VALUES(2, 100);

-- checked
CREATE TABLE Full_Time_Emp (
  eid integer PRIMARY KEY REFERENCES Employees,
  monthly_salary NUMERIC
    constraint positive_monthly_salary check (monthly_salary >= 0)
  -- SET TRIGGER: Every Full_Time_Emp is either a Full_Time_Instructor or Managers or Administrators but not all
);

INSERT INTO Full_Time_Emp VALUES(3, 6000);
INSERT INTO Full_Time_Emp VALUES(4, 5050);
INSERT INTO Full_Time_Emp VALUES(5, 10000);

-- checked
-- consider how diff part-time & full-time for add_employee function
CREATE TABLE Instructors (
  iid integer PRIMARY KEY REFERENCES Employees
);

INSERT INTO Instructors VALUES(3);
INSERT INTO Instructors VALUES(4);
INSERT INTO Instructors VALUES(5);

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
INSERT INTO Managers VALUES(3);
INSERT INTO Managers VALUES(4);
INSERT INTO Managers VALUES(5);

-- checked
CREATE TABLE Administrators(
  aid integer PRIMARY KEY REFERENCES Full_Time_Emp
);

INSERT INTO Administrators VALUES(3);
INSERT INTO Administrators VALUES(4);
INSERT INTO Administrators VALUES(5);

-- checked
CREATE TABLE Course_areas ( 
  area_name text PRIMARY KEY,
  mid integer NOT NULL REFERENCES Managers(mid)
  -- Combined with Manages table (Key + Total participation constrainteger)
);

INSERT INTO Course_areas VALUES('Java', 3);
INSERT INTO Course_areas VALUES('Python', 4);

-- checked
CREATE TABLE Courses (
  course_id SERIAL PRIMARY KEY,
  title text,
  duration integer,
  description text,
  area_name text NOT NULL REFERENCES Course_areas
);

INSERT INTO Courses(title, duration, description, area_name) VALUES('Java Bootcamp', 30, 'Java for beginners', 'Java');
INSERT INTO Courses(title, duration, description, area_name) VALUES('Hackwagon', 15, 'Python for newbies', 'Python');

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

INSERT INTO Offerings VALUES (1, '2020-04-04', '2020-05-05', '2020-06-30', 60, 100, '2020-04-10', 99.99, 3);
INSERT INTO Offerings VALUES (2, '2019-04-04', '2019-05-05', '2019-06-30', 100, 90, '2019-04-10', 59.99, 4);

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

INSERT INTO Sessions(s_date, start_time, end_time, course_id, launch_date, rid, iid) VALUES('2020-05-07', 4, 5, 1, '2020-04-04', 1, 3);
INSERT INTO Sessions(s_date, start_time, end_time, course_id, launch_date, rid, iid) VALUES('2020-11-23', 9, 11, 2, '2019-04-04', 3, 4);

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

INSERT INTO Specializes VALUES('Java', 3);
INSERT INTO Specializes VALUES('Python', 5);

/**
  - Check how auto generate all ID for all tables
  - If Owns merge into Credit_cards, Buys / Registers / Redeems how reference properly?
**/


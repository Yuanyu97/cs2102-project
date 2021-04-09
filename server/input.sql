CREATE OR REPLACE PROCEDURE add_course_offering_input(
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
        SELECT inst_id INTO instructor_id FROM find_instructors(c_id, i.s_date, i.s_start) ORDER BY RANDOM() LIMIT 1;
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

CREATE OR REPLACE PROCEDURE buy_course_package_input(
_cust_id INTEGER,
_package_id INTEGER,
_purchase_date DATE) AS $$
DECLARE
sale_start_date DATE;
sale_end_date DATE;
BEGIN
SELECT Course_packages.sale_start_date, Course_packages.sale_end_date into sale_start_date, sale_end_date FROM Course_packages WHERE Course_packages.package_id = _package_id;
IF (sale_end_date >= _purchase_date AND sale_start_date <= _purchase_date) THEN
INSERT INTO Buys(buy_date, cust_id, package_id) VALUES(_purchase_date, _cust_id,  _package_id);
ELSE
RAISE EXCEPTION 'Course Package is not on sale';
END IF;
END;
$$ LANGUAGE plpgsql;

create or replace function pay_salary_with_date (in input_month integer, in input_year integer)
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
    curr_month := input_month;
    curr_year := input_year;


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
			
			if (amount is not null AND amount > 0) then
			insert into pay_slips_for(eid, payment_date, num_work_hours, num_work_days, amount)
				values (eid, CONCAT(curr_year, '-', curr_month, '-01')::date, num_work_hours, null, amount);
			
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
				values (eid, CONCAT(curr_year, '-', curr_month, '-01')::date, null, num_work_days, amount);
			return next;
			end if;	
			
		end if;
	end loop;
	close curs;
end;
$$ language plpgsql;

INSERT INTO Rooms(location, seating_capacity) VALUES('Com2 #02-02', 10);
INSERT INTO Rooms(location, seating_capacity) VALUES('Biz Auditorium #01-01', 5);
INSERT INTO Rooms(location, seating_capacity) VALUES('Com2 #01-15', 20);
INSERT INTO Rooms(location, seating_capacity) VALUES('Com1 #02-26', 17);
INSERT INTO Rooms(location, seating_capacity) VALUES('Com1 #02-16', 30);
INSERT INTO Rooms(location, seating_capacity) VALUES('Biz Lecture Room 1 #03-10', 13);
INSERT INTO Rooms(location, seating_capacity) VALUES('Biz Lecture Room 2 #03-15', 50);
INSERT INTO Rooms(location, seating_capacity) VALUES('AR6 #03-20', 1);
INSERT INTO Rooms(location, seating_capacity) VALUES('I3 #01-02', 5);
INSERT INTO Rooms(location, seating_capacity) VALUES('I3 #01-20', 15);

INSERT INTO Credit_cards VALUES('4628 4500 1234 5678', '123', '2021-03-29', '2020-03-29');
INSERT INTO Credit_cards VALUES('4628 4500 9876 5432', '345', '2021-02-15', '2019-07-15');
INSERT INTO Credit_cards VALUES('4628 4500 8593 8572', '678', '2021-01-05', '2010-05-28');
INSERT INTO Credit_cards VALUES('4628 4500 6969 6969', '901', '2025-12-31', '2015-11-09');
INSERT INTO Credit_cards VALUES('4628 4500 5893 9721', '523', '2030-09-08', '2021-02-10');
INSERT INTO Credit_cards VALUES('4628 4500 5893 9722', '827', '2030-09-08', '2021-02-10');
INSERT INTO Credit_cards VALUES('4628 4500 5893 9723', '422', '2030-09-08', '2021-02-10');
INSERT INTO Credit_cards VALUES('4628 4500 5893 9724', '331', '2030-09-08', '2021-02-10');
INSERT INTO Credit_cards VALUES('4628 4500 5893 9725', '938', '2030-09-08', '2021-02-10');
INSERT INTO Credit_cards VALUES('4628 4500 5893 9726', '742', '2030-09-08', '2021-02-10');
INSERT INTO Credit_cards VALUES('4628 4500 5893 9727', '413', '2030-09-08', '2021-02-10');

INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Freddy', '4628 4500 1234 5678', 'Bishan St 11', 'f@yahoo.com', '81234567');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Wei Boon', '4628 4500 9876 5432', 'KR Hall', 'W@gmail.com', '89876543');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Weng Fai', '4628 4500 8593 8572', 'Sheares Hall', 'weng@yahoo.com', '91234567');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Dian Hao', '4628 4500 6969 6969', 'Eusoff Hall', 'd@outlook.com', '69696969');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Johnny Tan', '4628 4500 5893 9721', 'Raffles Hall', 'jt@gmail.com', '61234567');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Harrold Tan', '4628 4500 5893 9722', 'Temasek Hall', 'hart@outlook.com', '61234567');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Ng Jun Wei', '4628 4500 5893 9723', 'PGP Hall', 'njw@yahoo.com', '61234567');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Seng Rong Liang', '4628 4500 5893 9724', 'RVRC', 'ronglaingseng@outlook.com', '61234567');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Lee Sheng Siong', '4628 4500 5893 9725', 'UTR', 'sslee@karhart.com', '61234567');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Peggy Tan', '4628 4500 5893 9726', 'Tembusu', 'peggytan@gmail.com', '61234567');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Demacia Wong', '4628 4500 5893 9727', 'CAPT', 'demwong@lomotif.com', '61234567');

INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2019-03-20', '2021-04-20', 10, 'Free Udemy Course', 69.99);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2019-04-15', '2021-06-30', 25, 'React Course', 29.90);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2019-02-24', '2022-04-18', 50, 'Ruby Course', 10.90);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2019-06-30', '2022-09-26', 35, 'Rest API Course', 8.88);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2019-01-24', '2021-11-22', 10, 'Java Course', 109.99);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2019-09-20', '2021-10-11', 55, 'Excel VBA', 109.99);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2019-02-15', '2021-07-03', 15, 'Intro To Pysch', 19.99);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2019-03-11', '2022-04-14', 40, 'Ethics In Computing', 20.80);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2019-07-01', '2023-08-22', 45, 'Competitive Programming', 49.99);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2019-03-29', '2021-04-15', 69, 'Nano Technology', 55.55);

INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Jerry Bom', 'Bishan St 11', '81234567', 'f@yahoo.com', '1997-04-26', null);
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Yup Ying Hao', 'KR Hall', '89876543', 'W@gmail.com', '2000-07-21', '2020-12-31');
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Cassandra Tan', 'Sheares', '91234567', 'weng@yahoo.com', '2010-02-21', '2011-11-26');
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Wallie Stucke', 'Eusoff', '69696969', 'd@outlook.com', '2010-06-24', null);
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Blinni Alner', 'USA', '61234567', 'ph@onz.com', '2021-03-29', '2030-07-02');
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Adan Poytheras', 'Tanjong Pagar', '10281028', 'yuihatano@sex.com', '2021-04-01', null);
insert into Employees (name, address, phone, email, join_date) values ('Chelsey Geelan', '3919 Ridgeway Circle', '3427402435', 'wstucke0@xing.com', '2020-04-07');
insert into Employees (name, address, phone, email, join_date) values ('Dorene Lippo', '4901 Weeping Birch Plaza', '3821234580', 'balner1@java.com', '2020-09-22');
insert into Employees (name, address, phone, email, join_date) values ('Ardene Thresh', '66064 Sunfield Hill', '7723260537', 'apoytheras2@arstechnica.com', '2020-12-30');
insert into Employees (name, address, phone, email, join_date) values ('Grenville Farr', '1866 Pennsylvania Lane', '8148663320', 'cgeelan3@latimes.com', '2020-05-17'); --10
insert into Employees (name, address, phone, email, join_date) values ('Adelheid Loveman', '74261 Troy Lane', '7247372538', 'dlippo4@bravesites.com', '2020-10-27');
insert into Employees (name, address, phone, email, join_date) values ('Rosemaria Theobold', '2365 Roxbury Way', '4604275872', 'rtheobold8@people.com.cn', '2020-12-17');
insert into Employees (name, address, phone, email, join_date) values ('Tedda Skipping', '4592 Killdeer Trail', '5449966596', 'tskipping9@ucla.edu', '2021-01-27');
insert into Employees (name, address, phone, email, join_date) values ('Marabel Hansmann', '2338 Marcy Lane', '5317142317', 'mhansmanna@ucoz.com', '2020-10-04');
insert into Employees (name, address, phone, email, join_date) values ('Breena Iley', '5 Quincy Lane', '1896013463', 'bileyb@seesaa.net', '2021-03-27');
insert into Employees (name, address, phone, email, join_date) values ('Thom Mattin', '366 Meadow Valley Avenue', '8313278653', 'tmattinc@mail.ru', '2020-10-30');
insert into Employees (name, address, phone, email, join_date) values ('Zulema Oliver-Paull', '097 Vermont Way', '6545095288', 'zoliverpaulld@discuz.net', '2021-01-02');
insert into Employees (name, address, phone, email, join_date) values ('Jandy Shapero', '93 Mesta Way', '6723948427', 'jshaperoe@4shared.com', '2021-03-05');
insert into Employees (name, address, phone, email, join_date) values ('Karie Grundy', '56 Warrior Hill', '9673703163', 'kgrundyf@g.co', '2020-07-29');
insert into Employees (name, address, phone, email, join_date) values ('Saxon Hassewell', '05530 Oneill Hill', '5578698639', 'shassewellg@hubpages.com', '2020-04-23');
insert into Employees (name, address, phone, email, join_date) values ('Keelby Le Marchand', '2 Merchant Plaza', '4297692589', 'kleh@yelp.com', '2020-09-26');
insert into Employees (name, address, phone, email, join_date) values ('Vinny Kopje', '592 Blue Bill Park Trail', '1334387991', 'vkopjei@uiuc.edu', '2021-01-27');
insert into Employees (name, address, phone, email, join_date) values ('Vincent Dukelow', '992 Ilene Circle', '4054958997', 'vdukelowj@accuweather.com', '2020-10-05');
insert into Employees (name, address, phone, email, join_date) values ('Waylon Mapp', '1 Cody Hill', '4758128710', 'wmappk@earthlink.net', '2020-06-10');
insert into Employees (name, address, phone, email, join_date) values ('Gwenore Lymbourne', '91883 Buena Vista Hill', '7502213400', 'glymbournel@ocn.ne.jp', '2021-01-16');
insert into Employees (name, address, phone, email, join_date) values ('Ewell Matthisson', '21104 Bunker Hill Center', '9043067021', 'ematthissonm@youku.com', '2020-12-12');
insert into Employees (name, address, phone, email, join_date) values ('Flint Draycott', '689 Buena Vista Trail', '9718911854', 'fdraycottn@rambler.ru', '2020-05-29');
insert into Employees (name, address, phone, email, join_date) values ('Gerti Rossbrooke', '914 Basil Hill', '7778600022', 'grossbrookeo@globo.com', '2021-03-17');
insert into Employees (name, address, phone, email, join_date) values ('Remington Caddell', '1231 Texas Lane', '8083521636', 'rcaddellp@utexas.edu', '2020-05-01');
insert into Employees (name, address, phone, email, join_date) values ('Rachele Twinning', '2 Tennyson Crossing', '7283868404', 'rtwinningq@usda.gov', '2020-12-12');
insert into Employees (name, address, phone, email, join_date) values ('Gianna Mattsson', '5628 New Castle Lane', '1384854627', 'gmattssonr@nature.com', '2020-10-24');
insert into Employees (name, address, phone, email, join_date) values ('Jen Novotni', '90222 Shasta Road', '7449999952', 'jnovotnis@cnn.com', '2020-09-21');
insert into Employees (name, address, phone, email, join_date) values ('Theodore Talkington', '32 Petterle Terrace', '5257958973', 'ttalkingtont@opera.com', '2020-06-27');
insert into Employees (name, address, phone, email, join_date) values ('Allister Butting', '8011 Buell Circle', '2174109842', 'abuttingu@51.la', '2021-01-08');
insert into Employees (name, address, phone, email, join_date) values ('Gerladina Lorait', '97731 Portage Road', '6122395454', 'gloraitv@google.pl', '2020-09-14');
insert into Employees (name, address, phone, email, join_date) values ('Creight Yukhtin', '5590 Mariners Cove Plaza', '8303241085', 'cyukhtinw@unblog.fr', '2020-05-13');
insert into Employees (name, address, phone, email, join_date) values ('Derek Frichley', '94 Evergreen Plaza', '1392398626', 'dfrichleyx@army.mil', '2020-10-31');
insert into Employees (name, address, phone, email, join_date) values ('Frank Haskett', '1039 Rigney Pass', '1388722837', 'fhasketty@sitemeter.com', '2020-08-01');
insert into Employees (name, address, phone, email, join_date) values ('Dame Hamnett', '59858 Daystar Way', '2737752185', 'dhamnettz@skyrock.com', '2020-07-07');
insert into Employees (name, address, phone, email, join_date) values ('Norma Leal', '4 Jenna Parkway', '4431153666', 'nleal10@icq.com', '2020-08-29');


INSERT INTO Part_Time_Emp VALUES(1, 80);
INSERT INTO Part_Time_Emp VALUES(2, 100);
INSERT INTO Part_Time_Emp VALUES(3, 49.99);
INSERT INTO Part_Time_Emp VALUES(4, 20.15);
INSERT INTO Part_Time_Emp VALUES(5, 45.45);
INSERT INTO Part_Time_Emp VALUES(6, 69.69);
INSERT INTO Part_Time_Emp VALUES(7, 75.05);
INSERT INTO Part_Time_Emp VALUES(8, 200);
INSERT INTO Part_Time_Emp VALUES(9, 30.50);
INSERT INTO Part_Time_Emp VALUES(10, 80.90);

INSERT INTO Full_Time_Emp VALUES(11, 6000);
INSERT INTO Full_Time_Emp VALUES(12, 5050);
INSERT INTO Full_Time_Emp VALUES(13, 10000);
INSERT INTO Full_Time_Emp VALUES(14, 20000);
INSERT INTO Full_Time_Emp VALUES(15, 4500);
INSERT INTO Full_Time_Emp VALUES(16, 1500);
INSERT INTO Full_Time_Emp VALUES(17, 2500);
INSERT INTO Full_Time_Emp VALUES(18, 3000);
INSERT INTO Full_Time_Emp VALUES(19, 4100);
INSERT INTO Full_Time_Emp VALUES(20, 10100);
INSERT INTO Full_Time_Emp VALUES(21, 3100);
INSERT INTO Full_Time_Emp VALUES(22, 4300);
INSERT INTO Full_Time_Emp VALUES(23, 8000);
INSERT INTO Full_Time_Emp VALUES(24, 9050);
INSERT INTO Full_Time_Emp VALUES(25, 900);
INSERT INTO Full_Time_Emp VALUES(26, 800);
INSERT INTO Full_Time_Emp VALUES(27, 1100);
INSERT INTO Full_Time_Emp VALUES(28, 2100);
INSERT INTO Full_Time_Emp VALUES(29, 3800);
INSERT INTO Full_Time_Emp VALUES(30, 5210);
INSERT INTO Full_Time_Emp VALUES(31, 7300);
INSERT INTO Full_Time_Emp VALUES(32, 6530);
INSERT INTO Full_Time_Emp VALUES(33, 7000);
INSERT INTO Full_Time_Emp VALUES(34, 7220);
INSERT INTO Full_Time_Emp VALUES(35, 20000);
INSERT INTO Full_Time_Emp VALUES(36, 3710);
INSERT INTO Full_Time_Emp VALUES(37, 6340);
INSERT INTO Full_Time_Emp VALUES(38, 8120);
INSERT INTO Full_Time_Emp VALUES(39, 4240);
INSERT INTO Full_Time_Emp VALUES(40, 6110);

INSERT INTO Managers VALUES(11);
INSERT INTO Managers VALUES(12);
INSERT INTO Managers VALUES(13);
INSERT INTO Managers VALUES(14);
INSERT INTO Managers VALUES(15);
INSERT INTO Managers VALUES(16);
INSERT INTO Managers VALUES(17);
INSERT INTO Managers VALUES(18);
INSERT INTO Managers VALUES(19);
INSERT INTO Managers VALUES(20);


INSERT INTO Administrators VALUES(21);
INSERT INTO Administrators VALUES(22);
INSERT INTO Administrators VALUES(23);
INSERT INTO Administrators VALUES(24);
INSERT INTO Administrators VALUES(25);
INSERT INTO Administrators VALUES(26);
INSERT INTO Administrators VALUES(27);
INSERT INTO Administrators VALUES(28);
INSERT INTO Administrators VALUES(29);
INSERT INTO Administrators VALUES(30);

INSERT INTO Course_areas VALUES('Python', 11);
INSERT INTO Course_areas VALUES('Java', 11);
INSERT INTO Course_areas VALUES('R', 12);
INSERT INTO Course_areas VALUES('C++', 14);
INSERT INTO Course_areas VALUES('C', 14);
INSERT INTO Course_areas VALUES('Javascript', 15);
INSERT INTO Course_areas VALUES('Tableau', 16);
INSERT INTO Course_areas VALUES('Golang', 18);
INSERT INTO Course_areas VALUES('SQL', 19);
INSERT INTO Course_areas VALUES('CSS', 20);

INSERT INTO Instructors VALUES(1, 'Python');
INSERT INTO Instructors VALUES(2, 'Java');
INSERT INTO Instructors VALUES(3, 'Python');
INSERT INTO Instructors VALUES(4, 'C++');
INSERT INTO Instructors VALUES(5, 'C');
INSERT INTO Instructors VALUES(6, 'Java');
INSERT INTO Instructors VALUES(7, 'Tableau');
INSERT INTO Instructors VALUES(8, 'C');
INSERT INTO Instructors VALUES(9, 'Tableau');
INSERT INTO Instructors VALUES(10, 'C++');

INSERT INTO Instructors VALUES(31, 'Python');
INSERT INTO Instructors VALUES(32, 'Java');
INSERT INTO Instructors VALUES(33, 'Python');
INSERT INTO Instructors VALUES(34, 'C++');
INSERT INTO Instructors VALUES(35, 'C');
INSERT INTO Instructors VALUES(36, 'Java');
INSERT INTO Instructors VALUES(37, 'Tableau');
INSERT INTO Instructors VALUES(38, 'C');
INSERT INTO Instructors VALUES(39, 'Tableau');
INSERT INTO Instructors VALUES(40, 'C++');

INSERT INTO Part_Time_Instructor VALUES(1, 'Python');
INSERT INTO Part_Time_Instructor VALUES(2, 'Java');
INSERT INTO Part_Time_Instructor VALUES(3, 'Python');
INSERT INTO Part_Time_Instructor VALUES(4, 'C++');
INSERT INTO Part_Time_Instructor VALUES(5, 'C');
INSERT INTO Part_Time_Instructor VALUES(6, 'Java');
INSERT INTO Part_Time_Instructor VALUES(7, 'Tableau');
INSERT INTO Part_Time_Instructor VALUES(8, 'C');
INSERT INTO Part_Time_Instructor VALUES(9, 'Tableau');
INSERT INTO Part_Time_Instructor VALUES(10, 'C++');

INSERT INTO Full_Time_Instructor VALUES(31, 'Python');
INSERT INTO Full_Time_Instructor VALUES(32, 'Java');
INSERT INTO Full_Time_Instructor VALUES(33, 'Python');
INSERT INTO Full_Time_Instructor VALUES(34, 'C++');
INSERT INTO Full_Time_Instructor VALUES(35, 'C');
INSERT INTO Full_Time_Instructor VALUES(36, 'Java');
INSERT INTO Full_Time_Instructor VALUES(37, 'Tableau');
INSERT INTO Full_Time_Instructor VALUES(38, 'C');
INSERT INTO Full_Time_Instructor VALUES(39, 'Tableau');
INSERT INTO Full_Time_Instructor VALUES(40, 'C++');

INSERT INTO Courses(title, duration, description, area_name) VALUES('Hackwagon', 1, 'Python for newbies', 'Python');
INSERT INTO Courses(title, duration, description, area_name) VALUES('Java Bootcamp', 2, 'Java for beginners', 'Java');
INSERT INTO Courses(title, duration, description, area_name) VALUES('Data Representation', 1, 'Python for newbies', 'Python');
INSERT INTO Courses(title, duration, description, area_name) VALUES('Capstone', 1, 'Damn hard', 'C++');
INSERT INTO Courses(title, duration, description, area_name) VALUES('Operating System', 2, 'Djorge Tjendra', 'C');
INSERT INTO Courses(title, duration, description, area_name) VALUES('Parellel and Distributed Algorithms', 3, NULL, 'Java');
INSERT INTO Courses(title, duration, description, area_name) VALUES('Hands-On Tableau', 1, 'For BA Students', 'Tableau');
INSERT INTO Courses(title, duration, description, area_name) VALUES('Computer Organisation', 2, NULL, 'C');
INSERT INTO Courses(title, duration, description, area_name) VALUES('For Company Use', 1, NULL, 'Tableau');
INSERT INTO Courses(title, duration, description, area_name) VALUES('Migrating From Java to C', 2, 'Essential Course For Java people', 'C++');

-- add_course_offering(cid, course_fees, launch_date, reg_deadline, target, admin_id, session_array)
--create type session_array as (s_date DATE, s_start INTEGER, rid INTEGER);

CALL add_course_offering_input(1, 99, '2021-03-01', '2021-05-01', 100, 21, array[
    cast(row('2021-05-12', 9, 7) as session_array),
    cast(row('2021-05-13', 14, 7) as session_array)
]);
--duplicate course offering for course_id = 1
CALL add_course_offering_input(1, 99, '2021-01-01', '2021-05-01', 50, 21, array[
    cast(row('2021-05-12', 9, 7) as session_array),
    cast(row('2021-05-13', 14, 7) as session_array)
]);
CALL add_course_offering_input(2, 20, '2021-03-05', '2021-06-15', 5, 22, 
array[
    cast(row('2021-06-28', 10, 1) as session_array),
    cast(row('2021-06-29', 14, 2) as session_array)
]);
CALL add_course_offering_input(3, 20, '2021-03-10', '2021-07-29', 1, 22, 
array[
    cast(row('2021-08-10', 10, 6) as session_array),
    cast(row('2021-08-12', 15, 8) as session_array)
]);
CALL add_course_offering_input(4, 30.99, '2021-02-28', '2021-04-20', 2, 24, 
array[
    cast(row('2021-05-04', 10, 8) as session_array),
    cast(row('2021-05-03', 14, 9) as session_array)
]);
CALL add_course_offering_input(5, 88.88, '2020-12-01', '2021-01-10', 4, 26, 
array[
    cast(row('2021-02-12', 9, 1) as session_array),
    cast(row('2021-03-05', 14, 5) as session_array)
]);
CALL add_course_offering_input(6, 69.69, '2020-04-24', '2020-06-21', 2, 26, 
array[
    cast(row('2020-07-01', 9, 4) as session_array),
    cast(row('2020-07-02', 15, 3) as session_array)
]);
CALL add_course_offering_input(7, 33.33, '2021-01-01', '2021-02-02', 5, 27, 
array[
    cast(row('2021-03-03', 9, 8) as session_array),
    cast(row('2021-04-05', 14, 9) as session_array)
]);
CALL add_course_offering_input(8, 44.41, '2021-01-21', '2021-04-22', 15, 28, 
array[
    cast(row('2021-05-12', 10, 7) as session_array),
    cast(row('2021-05-13', 15, 5) as session_array)
]);
CALL add_course_offering_input(9, 60.60, '2019-02-19', '2019-10-15', 20, 29, 
array[
    cast(row('2019-11-14', 10, 3) as session_array),
    cast(row('2019-11-13', 14, 2) as session_array)
]);
CALL add_course_offering_input(10, 77.10, '2021-04-01', '2021-05-10', 18, 30, 
array[
    cast(row('2021-05-24', 10, 10) as session_array),
    cast(row('2021-05-25', 14, 9) as session_array)
]);
--additional course offering for course_id = 10
CALL add_course_offering_input(10, 99.10, '2021-01-02', '2021-05-10', 18, 30, 
array[
    cast(row('2021-05-24', 10, 10) as session_array),
    cast(row('2021-05-25', 14, 9) as session_array)
]);

-- CREATE OR REPLACE PROCEDURE buy_course_package(
-- _cust_id INTEGER,
-- _package_id INTEGER,
-- _purchase_date DATE) AS $$
CALL buy_course_package_input(1, 1, '2020-04-05');
CALL buy_course_package_input(2, 2, '2020-05-10');
CALL buy_course_package_input(3, 3, '2020-06-22');
CALL buy_course_package_input(4, 4, '2020-07-25');
CALL buy_course_package_input(5, 5, '2020-06-11');
CALL buy_course_package_input(6, 6, '2020-01-06');
CALL buy_course_package_input(7, 7, '2020-02-20');
CALL buy_course_package_input(8, 8, '2020-03-19');
CALL buy_course_package_input(9, 9, '2020-04-12');
CALL buy_course_package_input(10, 10, '2020-02-22');

INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (2, '2019-02-19', 9, '2019-11-01', 1);
INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2020-04-24', 6, '2020-04-24', 1);
INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (2, '2019-02-19', 9, '2018-10-30', 2);
INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-03-01', 1, '2021-03-01', 4);
INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-02-28', 4, '2021-02-28', 5);
INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2020-04-24', 6, '2020-04-24', 6);
INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2019-02-19', 9, '2019-02-19', 7);
INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-04-01', 10, '2021-04-01', 8);
INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (2, '2021-01-21', 8, '2021-01-21', 9);
INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (2, '2021-04-01', 10, '2021-04-01', 10);

INSERT INTO Redeems(redeem_date, buy_date, cust_id, package_id, sid, course_id, launch_date) VALUES('2020-04-06', '2020-04-05', 1, 1, 1, 1, '2021-03-01');
INSERT INTO Redeems(redeem_date, buy_date, cust_id, package_id, sid, course_id, launch_date) VALUES('2020-05-11', '2020-05-10', 2, 2, 1, 1, '2021-03-01');
INSERT INTO Redeems(redeem_date, buy_date, cust_id, package_id, sid, course_id, launch_date) VALUES('2020-06-23', '2020-06-22', 3, 3, 1, 4, '2021-02-28');
INSERT INTO Redeems(redeem_date, buy_date, cust_id, package_id, sid, course_id, launch_date) VALUES('2020-07-26', '2020-07-25', 4, 4, 1, 6, '2020-04-24');
INSERT INTO Redeems(redeem_date, buy_date, cust_id, package_id, sid, course_id, launch_date) VALUES('2020-06-12', '2020-06-11', 5, 5, 1, 9, '2019-02-19');
INSERT INTO Redeems(redeem_date, buy_date, cust_id, package_id, sid, course_id, launch_date) VALUES('2020-02-02', '2020-01-06', 6, 6, 1, 10, '2021-04-01');
INSERT INTO Redeems(redeem_date, buy_date, cust_id, package_id, sid, course_id, launch_date) VALUES('2020-02-21', '2020-02-20', 7, 7, 2, 8, '2021-01-21');
INSERT INTO Redeems(redeem_date, buy_date, cust_id, package_id, sid, course_id, launch_date) VALUES('2020-03-20', '2020-03-19', 8, 8, 2, 10, '2021-04-01');
INSERT INTO Redeems(redeem_date, buy_date, cust_id, package_id, sid, course_id, launch_date) VALUES('2020-04-13', '2020-04-12', 9, 9, 2, 9, '2019-02-19');
INSERT INTO Redeems(redeem_date, buy_date, cust_id, package_id, sid, course_id, launch_date) VALUES('2020-02-23', '2020-02-22', 10, 10, 1, 6, '2020-04-24');

CREATE OR REPLACE PROCEDURE insert_into_cancels_more_than_seven_days(
    target_cancel_cust_id INTEGER,
    target_cancel_sid INTEGER,
    target_cancel_launch_date DATE,
    target_cancel_course_id INTEGER
) AS $$
DECLARE 
    --target_refund_amt NUMERIC;
    target_cancel_date DATE;
BEGIN
    -- SELECT fees INTO target_refund_amt
    -- FROM Offerings
    -- WHERE course_id = target_cancel_course_id AND launch_date = target_cancel_launch_date;
    SELECT s_date - 10 INTO target_cancel_date 
    FROM Sessions
    WHERE sid = target_cancel_sid AND course_id = target_cancel_course_id AND launch_date = target_cancel_launch_date;
    INSERT INTO Cancels(
        cancel_date,
        cust_id,
        sid,
        launch_date,
        course_id,
        refund_amt,
        package_credit
    ) VALUES(
        target_cancel_date,
        target_cancel_cust_id,
        target_cancel_sid,
        target_cancel_launch_date,
        target_cancel_course_id,
        0,
        0
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE insert_into_cancels_less_than_seven_days(
    target_cancel_cust_id INTEGER,
    target_cancel_sid INTEGER,
    target_cancel_launch_date DATE,
    target_cancel_course_id INTEGER
) AS $$
DECLARE 
    target_refund_amt NUMERIC;
    target_cancel_date DATE;
BEGIN
    SELECT ROUND((fees * 0.9)::NUMERIC, 2) INTO target_refund_amt
    FROM Offerings
    WHERE course_id = target_cancel_course_id AND launch_date = target_cancel_launch_date;
    SELECT s_date - 5 INTO target_cancel_date 
    FROM Sessions
    WHERE sid = target_cancel_sid AND course_id = target_cancel_course_id AND launch_date = target_cancel_launch_date;
    INSERT INTO Cancels(
        cancel_date,
        cust_id,
        sid,
        launch_date,
        course_id,
        refund_amt,
        package_credit
    ) VALUES(
        target_cancel_date,
        target_cancel_cust_id,
        target_cancel_sid,
        target_cancel_launch_date,
        target_cancel_course_id,
        target_refund_amt,
        1
    );
END;
$$ LANGUAGE plpgsql;

CALL insert_into_cancels_less_than_seven_days(10, 2, '2021-04-01', 10);
CALL insert_into_cancels_less_than_seven_days(9, 2, '2021-01-21', 8);
CALL insert_into_cancels_less_than_seven_days(1, 2, '2019-02-19', 9);
CALL insert_into_cancels_less_than_seven_days(2, 2, '2019-02-19', 9);
CALL insert_into_cancels_less_than_seven_days(8, 1, '2021-04-01', 10);
CALL insert_into_cancels_more_than_seven_days(4, 1, '2021-03-01', 1);
CALL insert_into_cancels_more_than_seven_days(5, 1, '2021-02-28', 4);
CALL insert_into_cancels_more_than_seven_days(6, 1, '2020-04-24', 6);
CALL insert_into_cancels_more_than_seven_days(1, 1, '2020-04-24', 6);
CALL insert_into_cancels_more_than_seven_days(7, 1, '2019-02-19',9);


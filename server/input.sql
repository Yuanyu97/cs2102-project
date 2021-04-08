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

INSERT INTO Rooms(location, seating_capacity) VALUES('Bishan', 10);
INSERT INTO Rooms(location, seating_capacity) VALUES('Serangoon', 5);
INSERT INTO Rooms(location, seating_capacity) VALUES('Punggol', 20);
INSERT INTO Rooms(location, seating_capacity) VALUES('Whompoa', 17);
INSERT INTO Rooms(location, seating_capacity) VALUES('Lorong Chuan', 30);
INSERT INTO Rooms(location, seating_capacity) VALUES('Tenteram', 13);
INSERT INTO Rooms(location, seating_capacity) VALUES('Ang Mo Kio', 50);
INSERT INTO Rooms(location, seating_capacity) VALUES('Choa Chu Kang', 1);
INSERT INTO Rooms(location, seating_capacity) VALUES('I3', 5);
INSERT INTO Rooms(location, seating_capacity) VALUES('Kent Ridge Hall', 15);

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
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Weng Fai', '4628 4500 8593 8572', 'Sheares Juzz', 'weng@yahoo.com', '91234567');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Dian Hao', '4628 4500 6969 6969', 'Best Chai', 'd@outlook.com', '69696969');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Johnny Tan', '4628 4500 5893 9721', 'USA', 'ph@onz.com', '61234567');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Harrold Tan', '4628 4500 5893 9722', 'USA', 'ph@onz.com', '61234567');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Ng Jun Wei', '4628 4500 5893 9723', 'USA', 'ph@onz.com', '61234567');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Seng Rong Liang', '4628 4500 5893 9724', 'USA', 'ph@onz.com', '61234567');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Lee Sheng Siong', '4628 4500 5893 9725', 'USA', 'ph@onz.com', '61234567');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Peggy Tan', '4628 4500 5893 9726', 'USA', 'ph@onz.com', '61234567');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Demacia Wong', '4628 4500 5893 9727', 'USA', 'ph@onz.com', '61234567');

INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-03-20', '2021-04-20', 10, 'Free Udemy Course', 69.99);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-04-15', '2021-06-30', 25, 'React Course', 29.90);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-02-24', '2022-04-18', 50, 'Ruby Course', 10.90);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2022-06-30', '2022-09-26', 35, 'Rest API Course', 8.88);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-01-24', '2021-11-22', 10, 'Java Course', 109.99);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-09-20', '2021-10-11', 55, 'Excel VBA', 109.99);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-02-15', '2021-07-03', 15, 'Intro To Pysch', 19.99);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-03-11', '2022-04-14', 40, 'Ethics In Computing', 20.80);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2023-07-01', '2023-08-22', 45, 'Competitive Programming', 49.99);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-03-29', '2021-04-15', 69, 'Nano Technology', 55.55);

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
-- insert into Employees (name, address, phone, email, join_date) values ('Donny Joanic', '84 Packers Terrace', '9522013014', 'djoanic11@prlog.org', '2020-08-21');
-- insert into Employees (name, address, phone, email, join_date) values ('Jonis Fluck', '314 Lunder Center', '5685216700', 'jfluck12@google.co.uk', '2020-11-13');
-- insert into Employees (name, address, phone, email, join_date) values ('Yorker O''Hearn', '424 Springview Court', '5932817150', 'yohearn13@berkeley.edu', '2021-04-01');
-- insert into Employees (name, address, phone, email, join_date) values ('Thorpe Linacre', '7 Swallow Circle', '7135495037', 'tlinacre14@independent.co.uk', '2020-05-10');
-- insert into Employees (name, address, phone, email, join_date) values ('Emerson Muff', '2837 Manitowish Crossing', '3344321382', 'emuff15@dmoz.org', '2021-03-08');
-- insert into Employees (name, address, phone, email, join_date) values ('Ignaz Orrill', '14999 Bonner Street', '4955550908', 'iorrill16@yale.edu', '2020-06-21');
-- insert into Employees (name, address, phone, email, join_date) values ('Vicki Barrowcliff', '229 Oak Court', '3285441333', 'vbarrowcliff17@hibu.com', '2020-06-30');
-- insert into Employees (name, address, phone, email, join_date) values ('Dianemarie Broderick', '27 New Castle Plaza', '4345088403', 'dbroderick18@imgur.com', '2020-12-13');
-- insert into Employees (name, address, phone, email, join_date) values ('Cherilynn Kanwell', '804 Pleasure Way', '9409007684', 'ckanwell19@csmonitor.com', '2020-05-01');
-- insert into Employees (name, address, phone, email, join_date) values ('Marita De Winton', '50 Scoville Street', '3491649630', 'mde1a@comcast.net', '2020-09-10');
-- insert into Employees (name, address, phone, email, join_date) values ('Roselia Le Breton De La Vieuville', '6102 Paget Avenue', '9263741201', 'rle1b@cafepress.com', '2021-02-20');
-- insert into Employees (name, address, phone, email, join_date) values ('Lila Sims', '74 Jenna Drive', '3805808721', 'lsims1c@ovh.net', '2020-09-01');
-- insert into Employees (name, address, phone, email, join_date) values ('Rina Leeburn', '1990 Havey Circle', '4151403016', 'rleeburn1d@admin.ch', '2020-07-04');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Gaelan Poat', '215 Portage Place', '9905664047', 'gpoat0@123-reg.co.uk', '2020-12-04', '2021-11-28');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Cleo Rummins', '085 Maywood Lane', '2813477159', 'crummins1@reddit.com', '2020-09-04', '2021-08-13');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Rees Lowdes', '55 South Center', '7374478805', 'rlowdes2@omniture.com', '2021-01-23', '2021-09-24');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Godfrey Clowley', '7 Coolidge Park', '3306812820', 'gclowley3@berkeley.edu', '2020-11-09', '2021-06-29');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Nikola Madison', '2 Cordelia Junction', '3266436490', 'nmadison4@phpbb.com', '2020-11-16', '2021-12-07');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Nancey Danilishin', '4 Prentice Hill', '4728837477', 'ndanilishin5@uol.com.br', '2021-01-24', '2021-11-17');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Ranna Passler', '3695 Aberg Hill', '7133684414', 'rpassler6@opera.com', '2020-05-19', '2021-11-18');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Henrietta Pingston', '973 Vermont Center', '6812878105', 'hpingston7@woothemes.com', '2020-08-27', '2021-06-28');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Tonye Jerson', '8 Almo Lane', '7422320345', 'tjerson8@baidu.com', '2020-09-25', '2021-09-18');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Heriberto Sket', '874 Dwight Place', '1075993495', 'hsket9@artisteer.com', '2020-05-13', '2021-10-27');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Quint Lemmer', '42878 Valley Edge Plaza', '5464251601', 'qlemmera@usa.gov', '2021-03-28', '2021-11-25');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Jeni Febre', '416 Sullivan Plaza', '7519949051', 'jfebreb@telegraph.co.uk', '2020-12-27', '2022-03-11');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Cara Cathie', '499 Bowman Center', '7373678041', 'ccathiec@bravesites.com', '2020-11-27', '2022-01-20');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Hertha Spellissy', '6 Schmedeman Court', '6845834935', 'hspellissyd@mysql.com', '2020-05-24', '2021-10-02');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Letta Quaif', '92479 Pleasure Junction', '7366914519', 'lquaife@parallels.com', '2020-08-30', '2021-08-01');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Fanny Riceards', '54527 Oriole Park', '6081339581', 'friceardsf@sfgate.com', '2020-11-22', '2021-07-02');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Sherman O''Halligan', '376 Badeau Circle', '1118094283', 'sohalligang@blog.com', '2020-08-24', '2021-05-05');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Andrus Greeson', '88 Portage Alley', '2095594114', 'agreesonh@forbes.com', '2020-05-21', '2021-07-21');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Catlee Ickeringill', '87792 Carpenter Way', '4086275176', 'cickeringilli@reference.com', '2020-08-22', '2021-07-23');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Cordelie Longworthy', '37648 Johnson Park', '4331005792', 'clongworthyj@linkedin.com', '2020-04-06', '2021-11-08');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Dewey Dreng', '89981 Kinsman Street', '7887766416', 'ddrengk@chron.com', '2020-12-21', '2022-01-02');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Lenard MacCurley', '57 Badeau Pass', '7574757645', 'lmaccurleyl@soup.io', '2021-01-02', '2021-07-21');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Kendell Whiston', '11324 Holy Cross Road', '8416230649', 'kwhistonm@kickstarter.com', '2020-07-06', '2022-01-13');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Briano Cottage', '08 Autumn Leaf Pass', '2022457471', 'bcottagen@go.com', '2021-03-31', '2021-10-09');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Moria Climie', '14336 Montana Drive', '2005707144', 'mclimieo@reuters.com', '2021-01-16', '2021-08-26');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Delora Knight', '96911 Ridgeview Street', '2359531054', 'dknightp@google.nl', '2021-01-25', '2021-10-25');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Reine Seint', '07 Spohn Place', '8474182484', 'rseintq@usa.gov', '2020-05-01', '2021-08-27');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Walther Spark', '8 Drewry Point', '9928712177', 'wsparkr@bizjournals.com', '2020-06-14', '2021-08-27');
-- insert into Employees (name, address, phone, email, join_date, depart_date) values ('Mattie Blanchard', '8324 Arrowood Park', '4605981130', 'mblanchards@clickbank.net', '2021-01-25', '2022-01-22');


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

-- CREATE OR REPLACE PROCEDURE buy_course_package(
-- _cust_id INTEGER,
-- _package_id INTEGER) AS $$
CALL buy_course_package(1, 1);
CALL buy_course_package(2, 1);
CALL buy_course_package(3, 3);
CALL buy_course_package(4, 3);
CALL buy_course_package(5, 5);
CALL buy_course_package(6, 7);
CALL buy_course_package(7, 7);
CALL buy_course_package(8, 8);
CALL buy_course_package(9, 8);
CALL buy_course_package(10, 10);

-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-04-11', 1, CURRENT_DATE, 1);
-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-04-11', 1, CURRENT_DATE, 1);
-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-04-11', 1, CURRENT_DATE, 3);
-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-04-11', 1, CURRENT_DATE, 4);
-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-04-11', 1, CURRENT_DATE, 5);
-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-04-11', 1, CURRENT_DATE, 5);
-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-04-11', 1, CURRENT_DATE, 7);
-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-04-11', 1, CURRENT_DATE, 8);
-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-04-11', 1, CURRENT_DATE, 9);
-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-04-11', 1, CURRENT_DATE, 10);

-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-04-11', 1, CURRENT_DATE, 1);
-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-04-11', 1, CURRENT_DATE, 2);
-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (2, '2021-04-11', 1, CURRENT_DATE, 4);
-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (2, '2021-04-11', 1, CURRENT_DATE, 3);

-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2022-07-10', 2, '2022-07-15', 3);
-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2022-07-10', 2, '2022-07-15', 4);



-- -- course 4 -3-15
-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-03-15', 4, CURRENT_DATE, 5);

-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-03-16', 4, CURRENT_DATE, 8);
-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-03-16', 4, CURRENT_DATE, 9);
-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-03-16', 4, CURRENT_DATE, 10);
-- INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-03-16', 4, CURRENT_DATE, 11);

-- INSERT INTO Buys(buy_date, cust_id, package_id) VALUES (CURRENT_DATE, 3, 1);

-- INSERT INTO Redeems(redeem_date, buy_date, cust_id, package_id, sid, course_id, launch_date) VALUES(CURRENT_DATE, CURRENT_DATE, 3, 1, 1, 1, '2021-04-11');
-- INSERT INTO Redeems(redeem_date, buy_date, cust_id, package_id, sid, course_id, launch_date) VALUES(CURRENT_DATE, CURRENT_DATE, 3, 1, 1, 2, '2022-07-10');

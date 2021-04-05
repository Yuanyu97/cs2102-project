INSERT INTO Rooms(location, seating_capacity) VALUES('Bishan', 10);
INSERT INTO Rooms(location, seating_capacity) VALUES('Serangoon', 5);
INSERT INTO Rooms(location, seating_capacity) VALUES('Punggol', 20);
INSERT INTO Rooms(location, seating_capacity) VALUES('Whompoa', 17);
INSERT INTO Rooms(location, seating_capacity) VALUES('Lorong Chuan', 30);
INSERT INTO Rooms(location, seating_capacity) VALUES('Tenteram', 13);
INSERT INTO Rooms(location, seating_capacity) VALUES('Ang Mo Kio', 50);

INSERT INTO Credit_cards VALUES('4628 4500 1234 5678', '123', '2021-03-29', '2020-03-29');
INSERT INTO Credit_cards VALUES('4628 4500 9876 5432', '345', '2021-02-15', '2019-07-15');
INSERT INTO Credit_cards VALUES('4628 4500 8593 8572', '678', '2021-01-05', '2010-05-28');
INSERT INTO Credit_cards VALUES('4628 4500 6969 6969', '901', '2025-12-31', '2015-11-09');
INSERT INTO Credit_cards VALUES('4628 4500 5893 9724', '619', '2030-09-08', '2021-02-10');

INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Freddy', '4628 4500 1234 5678', 'Bishan St 11', 'f@yahoo.com', '81234567');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Wei Boon', '4628 4500 9876 5432', 'KR Hall', 'W@gmail.com', '89876543');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Weng Fai', '4628 4500 8593 8572', 'Sheares Juzz', 'weng@yahoo.com', '91234567');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Dian Hao', '4628 4500 6969 6969', 'Best Chai', 'd@outlook.com', '69696969');
INSERT INTO Customers(name, credit_card_number, address, email, phone) VALUES('Johnny Sins', '4628 4500 5893 9724', 'USA', 'ph@onz.com', '61234567');

INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-03-20', '2021-04-20', 10, 'Free Udemy Course', 69.99);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-04-15', '2021-06-30', 25, 'React Course', 29.90);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-02-24', '2022-04-10', 50, 'Ruby Course', 10.90);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-06-30', '2021-09-26', 35, 'Rest API Course', 8.88);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-07-24', '2021-11-22', 10, 'Java Course', 109.99);

INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Freddy', 'Bishan St 11', '81234567', 'f@yahoo.com', '1997-04-26', null);
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Wei Boon', 'KR Hall', '89876543', 'W@gmail.com', '2000-07-21', '2020-12-31');
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Weng Fai', 'Sheares Juzz', '91234567', 'weng@yahoo.com', '2010-02-21', '2011-11-26');
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Dian Hao', 'Best Chai', '69696969', 'd@outlook.com', '2010-06-24', null);
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Johnny Sins', 'USA', '61234567', 'ph@onz.com', '2021-03-29', '2030-07-02');
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Yui Hatano', 'Tokyo Hot', '10281028', 'yuihatano@sex.com', '2021-04-01', null);
insert into Employees (name, address, phone, email, join_date) values ('Wallie Stucke', '3919 Ridgeway Circle', '3427402435', 'wstucke0@xing.com', '2020-04-07');
insert into Employees (name, address, phone, email, join_date) values ('Blinni Alner', '4901 Weeping Birch Plaza', '3821234580', 'balner1@java.com', '2020-09-22');
insert into Employees (name, address, phone, email, join_date) values ('Adan Poytheras', '66064 Sunfield Hill', '7723260537', 'apoytheras2@arstechnica.com', '2020-12-30');
insert into Employees (name, address, phone, email, join_date) values ('Chelsey Geelan', '1866 Pennsylvania Lane', '8148663320', 'cgeelan3@latimes.com', '2020-05-17');
insert into Employees (name, address, phone, email, join_date) values ('Dorene Lippo', '74261 Troy Lane', '7247372538', 'dlippo4@bravesites.com', '2020-10-27');
insert into Employees (name, address, phone, email, join_date) values ('Ardene Thresh', '40701 Kedzie Place', '4876336236', 'athresh5@digg.com', '2020-09-30');
insert into Employees (name, address, phone, email, join_date) values ('Grenville Farr', '955 Carberry Crossing', '9122461070', 'gfarr6@people.com.cn', '2020-09-03');
insert into Employees (name, address, phone, email, join_date) values ('Adelheid Loveman', '10610 Mayfield Hill', '8105884098', 'aloveman7@noaa.gov', '2020-08-19');
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
insert into Employees (name, address, phone, email, join_date) values ('Donny Joanic', '84 Packers Terrace', '9522013014', 'djoanic11@prlog.org', '2020-08-21');
insert into Employees (name, address, phone, email, join_date) values ('Jonis Fluck', '314 Lunder Center', '5685216700', 'jfluck12@google.co.uk', '2020-11-13');
insert into Employees (name, address, phone, email, join_date) values ('Yorker O''Hearn', '424 Springview Court', '5932817150', 'yohearn13@berkeley.edu', '2021-04-01');
insert into Employees (name, address, phone, email, join_date) values ('Thorpe Linacre', '7 Swallow Circle', '7135495037', 'tlinacre14@independent.co.uk', '2020-05-10');
insert into Employees (name, address, phone, email, join_date) values ('Emerson Muff', '2837 Manitowish Crossing', '3344321382', 'emuff15@dmoz.org', '2021-03-08');
insert into Employees (name, address, phone, email, join_date) values ('Ignaz Orrill', '14999 Bonner Street', '4955550908', 'iorrill16@yale.edu', '2020-06-21');
insert into Employees (name, address, phone, email, join_date) values ('Vicki Barrowcliff', '229 Oak Court', '3285441333', 'vbarrowcliff17@hibu.com', '2020-06-30');
insert into Employees (name, address, phone, email, join_date) values ('Dianemarie Broderick', '27 New Castle Plaza', '4345088403', 'dbroderick18@imgur.com', '2020-12-13');
insert into Employees (name, address, phone, email, join_date) values ('Cherilynn Kanwell', '804 Pleasure Way', '9409007684', 'ckanwell19@csmonitor.com', '2020-05-01');
insert into Employees (name, address, phone, email, join_date) values ('Marita De Winton', '50 Scoville Street', '3491649630', 'mde1a@comcast.net', '2020-09-10');
insert into Employees (name, address, phone, email, join_date) values ('Roselia Le Breton De La Vieuville', '6102 Paget Avenue', '9263741201', 'rle1b@cafepress.com', '2021-02-20');
insert into Employees (name, address, phone, email, join_date) values ('Lila Sims', '74 Jenna Drive', '3805808721', 'lsims1c@ovh.net', '2020-09-01');
insert into Employees (name, address, phone, email, join_date) values ('Rina Leeburn', '1990 Havey Circle', '4151403016', 'rleeburn1d@admin.ch', '2020-07-04');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Gaelan Poat', '215 Portage Place', '9905664047', 'gpoat0@123-reg.co.uk', '2020-12-04', '2021-11-28');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Cleo Rummins', '085 Maywood Lane', '2813477159', 'crummins1@reddit.com', '2020-09-04', '2021-08-13');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Rees Lowdes', '55 South Center', '7374478805', 'rlowdes2@omniture.com', '2021-01-23', '2021-09-24');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Godfrey Clowley', '7 Coolidge Park', '3306812820', 'gclowley3@berkeley.edu', '2020-11-09', '2021-06-29');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Nikola Madison', '2 Cordelia Junction', '3266436490', 'nmadison4@phpbb.com', '2020-11-16', '2021-12-07');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Nancey Danilishin', '4 Prentice Hill', '4728837477', 'ndanilishin5@uol.com.br', '2021-01-24', '2021-11-17');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Ranna Passler', '3695 Aberg Hill', '7133684414', 'rpassler6@opera.com', '2020-05-19', '2021-11-18');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Henrietta Pingston', '973 Vermont Center', '6812878105', 'hpingston7@woothemes.com', '2020-08-27', '2021-06-28');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Tonye Jerson', '8 Almo Lane', '7422320345', 'tjerson8@baidu.com', '2020-09-25', '2021-09-18');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Heriberto Sket', '874 Dwight Place', '1075993495', 'hsket9@artisteer.com', '2020-05-13', '2021-10-27');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Quint Lemmer', '42878 Valley Edge Plaza', '5464251601', 'qlemmera@usa.gov', '2021-03-28', '2021-11-25');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Jeni Febre', '416 Sullivan Plaza', '7519949051', 'jfebreb@telegraph.co.uk', '2020-12-27', '2022-03-11');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Cara Cathie', '499 Bowman Center', '7373678041', 'ccathiec@bravesites.com', '2020-11-27', '2022-01-20');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Hertha Spellissy', '6 Schmedeman Court', '6845834935', 'hspellissyd@mysql.com', '2020-05-24', '2021-10-02');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Letta Quaif', '92479 Pleasure Junction', '7366914519', 'lquaife@parallels.com', '2020-08-30', '2021-08-01');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Fanny Riceards', '54527 Oriole Park', '6081339581', 'friceardsf@sfgate.com', '2020-11-22', '2021-07-02');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Sherman O''Halligan', '376 Badeau Circle', '1118094283', 'sohalligang@blog.com', '2020-08-24', '2021-05-05');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Andrus Greeson', '88 Portage Alley', '2095594114', 'agreesonh@forbes.com', '2020-05-21', '2021-07-21');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Catlee Ickeringill', '87792 Carpenter Way', '4086275176', 'cickeringilli@reference.com', '2020-08-22', '2021-07-23');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Cordelie Longworthy', '37648 Johnson Park', '4331005792', 'clongworthyj@linkedin.com', '2020-04-06', '2021-11-08');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Dewey Dreng', '89981 Kinsman Street', '7887766416', 'ddrengk@chron.com', '2020-12-21', '2022-01-02');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Lenard MacCurley', '57 Badeau Pass', '7574757645', 'lmaccurleyl@soup.io', '2021-01-02', '2021-07-21');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Kendell Whiston', '11324 Holy Cross Road', '8416230649', 'kwhistonm@kickstarter.com', '2020-07-06', '2022-01-13');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Briano Cottage', '08 Autumn Leaf Pass', '2022457471', 'bcottagen@go.com', '2021-03-31', '2021-10-09');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Moria Climie', '14336 Montana Drive', '2005707144', 'mclimieo@reuters.com', '2021-01-16', '2021-08-26');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Delora Knight', '96911 Ridgeview Street', '2359531054', 'dknightp@google.nl', '2021-01-25', '2021-10-25');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Reine Seint', '07 Spohn Place', '8474182484', 'rseintq@usa.gov', '2020-05-01', '2021-08-27');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Walther Spark', '8 Drewry Point', '9928712177', 'wsparkr@bizjournals.com', '2020-06-14', '2021-08-27');
insert into Employees (name, address, phone, email, join_date, depart_date) values ('Mattie Blanchard', '8324 Arrowood Park', '4605981130', 'mblanchards@clickbank.net', '2021-01-25', '2022-01-22');


INSERT INTO Part_Time_Emp VALUES(5, 80);
INSERT INTO Part_Time_Emp VALUES(6, 100);

INSERT INTO Full_Time_Emp VALUES(1, 6000);
INSERT INTO Full_Time_Emp VALUES(2, 5050);
INSERT INTO Full_Time_Emp VALUES(3, 10000);
INSERT INTO Full_Time_Emp VALUES(4, 10000);

INSERT INTO Managers VALUES(1);
INSERT INTO Managers VALUES(2);
-- INSERT INTO Managers VALUES(3);
-- INSERT INTO Managers VALUES(4);
-- INSERT INTO Managers VALUES(5);

-- INSERT INTO Administrators VALUES(1);
INSERT INTO Administrators VALUES(3);
INSERT INTO Administrators VALUES(4);
-- INSERT INTO Administrators VALUES(5);

INSERT INTO Course_areas VALUES('Java', 2);
INSERT INTO Course_areas VALUES('Python', 2);
INSERT INTO Course_areas VALUES('C++', 2);
INSERT INTO Course_areas VALUES('Jediscript', 2);
INSERT INTO Course_areas VALUES('R', 2);

INSERT INTO Instructors VALUES(3, 'Python');
INSERT INTO Instructors VALUES(4, 'Java');
INSERT INTO Instructors VALUES(5, 'Python');
INSERT INTO Instructors VALUES(5, 'C++');
INSERT INTO Instructors VALUES(3, 'R');
INSERT INTO Instructors VALUES(6, 'Java');

INSERT INTO Courses(title, duration, description, area_name) VALUES('Java Bootcamp', 2, 'Java for beginners', 'Java');
INSERT INTO Courses(title, duration, description, area_name) VALUES('Hackwagon', 1, 'Python for newbies', 'Python');
INSERT INTO Courses(title, duration, description, area_name) VALUES('Data Structures and Algorithms', 1, 'CS2040S', 'Java');


INSERT INTO Offerings(course_id, launch_date, target_number_registrations, registration_deadline, fees, aid) VALUES (1, '2021-04-11', 60, '2021-04-25', 99.99, 3);
INSERT INTO Offerings(course_id, launch_date, target_number_registrations, registration_deadline, fees, aid) VALUES (2, '2022-07-10', 100, '2022-07-20', 59.99, 4);
INSERT INTO Offerings(course_id, launch_date, target_number_registrations, registration_deadline, fees, aid) VALUES (2, '2022-07-11', 80, '2022-07-20', 89.99, 4);

INSERT INTO Sessions(sid, s_date, start_time, course_id, launch_date) VALUES(1, '2021-05-05', 14, 1, '2021-04-11');
INSERT INTO Sessions(sid, s_date, start_time, course_id, launch_date) VALUES(2, '2021-05-06', 10, 1, '2021-04-11');
INSERT INTO Sessions(sid, s_date, start_time, course_id, launch_date) VALUES(1, '2022-08-05', 9, 2, '2022-07-10');
INSERT INTO Sessions(sid, s_date, start_time, course_id, launch_date) VALUES(2, '2022-08-05', 14, 2, '2022-07-10');
INSERT INTO Sessions(sid, s_date, start_time, course_id, launch_date) VALUES(1, '2022-08-08', 9, 2, '2022-07-11');

INSERT INTO Conducts(iid, area_name, sid, launch_date, course_id, rid) VALUES (4, 'Java', 1, '2021-04-11', 1, 1);
INSERT INTO Conducts(iid, area_name, sid, launch_date, course_id, rid) VALUES (4, 'Java', 2, '2021-04-11', 1, 3);
INSERT INTO Conducts(iid, area_name, sid, launch_date, course_id, rid) VALUES (3, 'Python', 1, '2022-07-10', 2, 4);
INSERT INTO Conducts(iid, area_name, sid, launch_date, course_id, rid) VALUES (3, 'Python', 2, '2022-07-10', 2, 5);
INSERT INTO Conducts(iid, area_name, sid, launch_date, course_id, rid) VALUES (3, 'Python', 1, '2022-07-11', 2, 6);

INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-04-11', 1, CURRENT_DATE, 1);
INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2021-04-11', 1, CURRENT_DATE, 2);
INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (2, '2021-04-11', 1, CURRENT_DATE, 4);
INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (2, '2021-04-11', 1, CURRENT_DATE, 3);
INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2022-07-10', 2, CURRENT_DATE, 3);
INSERT INTO Registers(sid, launch_date, course_id, registration_date, cust_id) VALUES (1, '2022-07-10', 2, CURRENT_DATE, 4);

INSERT INTO Buys(buy_date, cust_id, package_id) VALUES (CURRENT_DATE, 3, 1);

INSERT INTO Redeems VALUES(CURRENT_DATE, CURRENT_DATE, 3, 1, 1, 1, '2021-04-11');
INSERT INTO Redeems VALUES(CURRENT_DATE, CURRENT_DATE, 3, 1, 2, 1, '2021-04-11');
INSERT INTO Redeems VALUES(CURRENT_DATE, CURRENT_DATE, 3, 1, 1, 2, '2022-07-10');

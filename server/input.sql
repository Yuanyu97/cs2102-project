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
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-02-24', '2022-04-01', 50, 'Ruby Course', 10.90);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-06-30', '2021-09-26', 35, 'Rest API Course', 8.88);
INSERT INTO Course_packages(sale_start_date, sale_end_date, num_free_registrations, package_name, price) VALUES('2021-07-24', '2021-11-22', 10, 'Java Course', 109.99);

INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Freddy', 'Bishan St 11', '81234567', 'f@yahoo.com', '1997-04-26', null);
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Wei Boon', 'KR Hall', '89876543', 'W@gmail.com', '2000-07-21', '2020-12-31');
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Weng Fai', 'Sheares Juzz', '91234567', 'weng@yahoo.com', '2010-02-21', '2011-11-26');
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Dian Hao', 'Best Chai', '69696969', 'd@outlook.com', '2010-06-24', null);
INSERT INTO Employees(name, address, phone, email, join_date, depart_date) VALUES('Johnny Sins', 'USA', '61234567', 'ph@onz.com', '2021-03-29', '2030-07-02');

INSERT INTO Part_Time_Emp VALUES(1, 80);
INSERT INTO Part_Time_Emp VALUES(2, 100);

INSERT INTO Full_Time_Emp VALUES(3, 6000);
INSERT INTO Full_Time_Emp VALUES(4, 5050);
INSERT INTO Full_Time_Emp VALUES(5, 10000);

INSERT INTO Managers VALUES(3);
INSERT INTO Managers VALUES(4);
INSERT INTO Managers VALUES(5);
INSERT INTO Administrators VALUES(3);
INSERT INTO Administrators VALUES(4);
INSERT INTO Administrators VALUES(5);

INSERT INTO Course_areas VALUES('Java', 3);
INSERT INTO Course_areas VALUES('Python', 4);
INSERT INTO Course_areas VALUES('C++', 5);
INSERT INTO Course_areas VALUES('Jediscript', 3);
INSERT INTO Course_areas VALUES('R', 3);

INSERT INTO Instructors VALUES(3, 'Python');
INSERT INTO Instructors VALUES(4, 'Java');
INSERT INTO Instructors VALUES(5, 'Python');
INSERT INTO Instructors VALUES(5, 'C++');
INSERT INTO Instructors VALUES(3, 'R');

INSERT INTO Courses(title, duration, description, area_name) VALUES('Java Bootcamp', 30, 'Java for beginners', 'Java');
INSERT INTO Courses(title, duration, description, area_name) VALUES('Hackwagon', 15, 'Python for newbies', 'Python');

INSERT INTO Offerings(course_id, launch_date, start_date, end_date, target_number_registrations, registration_deadline, fees, aid) VALUES (1, '2020-04-04', '2020-05-05', '2020-06-30', 60, '2020-04-10', 99.99, 3);
INSERT INTO Offerings(course_id, launch_date, start_date, end_date, target_number_registrations, registration_deadline, fees, aid) VALUES (2, '2019-04-04', '2019-05-05', '2019-06-30', 100, '2019-04-10', 59.99, 4);

INSERT INTO Sessions(s_date, start_time, end_time, course_id, launch_date, rid) VALUES('2020-05-07', 4, 5, 1, '2020-04-04', 1);
INSERT INTO Sessions(s_date, start_time, end_time, course_id, launch_date, rid) VALUES('2020-11-23', 9, 11, 2, '2019-04-04', 3);

INSERT INTO Conducts(iid, area_name, rid, sid, course_id, launch_date) VALUES (4, 'Java', 3, 1, 1, '2020-04-04');
INSERT INTO Conducts(iid, area_name, rid, sid, course_id, launch_date) VALUES (3, 'Python', 2, 2, 2, '2019-04-04');

/** 10: Add course offering
-- NEGATIVE:
-- [G] Target > seating capacity
-- [?] Invalid administrator id
-- [G] No instructor available
-- POSITIVE:
-- [G] 
**/
-- session
-- add_course_offering(cid, course_fees, launch_date, reg_deadline, target, admin_id, session_array)
CALL add_course_offering(1, 99, '2021-03-01', '2021-05-01', 100, 4, 
array[
    cast(row('2021-05-02', 10, 4) as session_array),
    cast(row('2021-05-03', 14, 4) as session_array)
]);
-- will throw capacity 34 insufficient


CALL add_course_offering(1, 99, '2021-03-01', '2021-05-01', 5, 4, 
array[
    cast(row('2021-05-12', 10, 4) as session_array),
    cast(row('2021-05-13', 14, 4) as session_array)
]);
-- will go through

/** 11: Add course package
-- NEGATIVE:
-- [?] sale_start_date before today
-- [G] sale_start_date after sale_end_date
-- POSITIVE:
-- [G] 
**/
-- add_course_package(package_name, num_free_registrations, sale_start_date, sale_end_date, price)
call add_course_package('Intro to AI Course', 12, '2021-04-12', '2021-04-16', 3);
-- 

/** 12: Get_available_course_package
-- POSITIVE:
-- [?] 
**/
SELECT * FROM get_available_course_packages()

/** 13: Buy course package
-- NEGATIVE:
-- [?] package_id does not exist
-- [?] customer_id does not exist
-- [?] customer still has active package
-- POSITIVE:
-- [G] 
**/
-- buy_course_package(cust_id, packaged_id)
CALL buy_course_package(1, 1);

/** 14: get my course package
-- NEGATIVE:
-- [?] 
-- POSITIVE:
-- [G] 
**/
-- get_my_course_package(cid)
select * from get_my_course_package(1);

/** 15: get available course offerings
-- POSITIVE:
-- [G] 
**/
select * from get_available_course_offerings();

/** 16: get available course offerings 
-- POSITIVE:
-- [G] 
**/
-- get_available_course_sessions(course_id, launch_date );
select * from get_available_course_sessions();

-- 17
-- - credit_card registrations are not explicity recorded. 
-- Testing done:
-- NEGATIVE:
-- [?] Course pacakge not active
-- [?] Session does not exist
-- [?] Payment method does not exist
-- [?] Customer id does not exit
-- [?] Course offering does not exist
-- POSITIVE:
-- [?] Redemption registration
-- register_session(cid, course_id, launch_date, sid, payment_method)
CALL register_session(3, 2, '2022-07-10', 1, 'redemption');
-- Expected
-- Registers cid = 3
-- [?] Credit card registration
CALL register_session(4, 1, '2021-04-11', 1, 'credit_card');
-- Exepcted:
-- Buys.num_package --
-- Registers cid = 4

/** 18: Get all customer registrations
**/
select * from get_my_registrations(1);

/** 19: Customer request to change registed course session to another session
NEGATIVE:
[?] Customer does not exist
[?] Session does not exist
[?] Customer previously not registered to course with another session
POSITIVE:
[?] Get all active registration and sorted in order
**/
-- update_course_session(cid, course_id, launch_date, sid)
call update_course_session(3, 4, '2021-02-28', 2);
-- ROW 3: 1	"2021-04-11"	1	"2021-04-05"	4


/** 20: cancel / refund registration
NEGATIVE:
[?] Customer does not exist
[?] Customer has not registered for target offering
POSITIVE:
[?] Refund credit card payment
[?] Refund redemption 
**/
-- cancel_registrations(cid, course_id, launch_date)
-- NO REFUND
CALL cancel_registration(3, 1, '2021-04-11');
-- REFUND CREDITS
CALL cancel_registration(3, 4, '2021-02-28');
-- REFUND CREDIT CARD
CALL cancel_registration(2, 9, '2019-02-19');



/** 21: Change instructor for a course session
Testing done:
NEGATIVE:
[?] target course session has started
POSITIVE:
[G] Standard insertion
**/
-- update_instructor(course_id, launch_date, sid, iid)
CALL update_instructor(2, '2022-07-10', 1, 6);
-- will throw

CALL update_instructor(1, '2021-03-01', 1, 31);
-- Row 3: 5	"Python"	3	1	"2022-07-10"	2

/** 22: change room for a course session
TODO:
- Check room capacity limitations [if relevant]

Testing done:
NEGATIVE:
[?] 
POSITIVE:
[?] Standard update - TBC with freddy trigger which sets to old rid
**/
-- update_room(course_id, launch_date, sid, rid)
call update_room(1, '2021-01-01', 1, 8);
-- row 3: 5	"Python"	7	1	"2022-07-10"	2

/** 23: remove course session
Testing done:
NEGATIVE:
[?] session has already started
[?] session has at least one customer registered already
[?] session is only session in course offering
POSITIVE:
[?] Standard removal
[?] Only session of course_offering should cascade delete course_offering
**/
-- remove_session(course_id, launch_date, sid)
-- call remove_session(2, '2022-07-10', 1);
-- will throw: have customer registered
call remove_session(10, '2021-01-02', 2);
-- should pass
-- call remove_session(2, '2022-07-11', 3);
-- will throw: only session in course offering

/** 24: Add a new session to course offering
Changes:
- Change end date calculation to count from Courses.duration

Testing done:
NEGATIVE:
[G] instructor specialisation mismatch with course area
[?] same day and time 
[?] invalid start hour
POSITIVE:
[G] Standard insertion
**/ 
-- add_session(course_id, launch_date, sid, s_date, start_hour, iid, rid)
-- call add_session(2, '2022-07-11', 4, '2022-08-06',10, 5, 4);
-- pass
-- call add_session(2, '2022-07-11', 4, '2020-08-06',10, 5, 4);
-- will throw: for 10 days thing

call add_session(8, '2021-01-21', 3, '2022-08-02',10, 5, 4);

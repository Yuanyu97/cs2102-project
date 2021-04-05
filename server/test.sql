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
-- CREATE OR REPLACE PROCEDURE register_session(
--     target_cid INTEGER, 
--     offering_course_id INTEGER,
--     offering_launch_date DATE,
--     target_sid INTEGER,
--     payment_method TEXT
-- ) AS $$
CALL register_session(3, 2, '2022-07-10', 1, 'redemption');
-- Expected
-- Registers cid = 3
-- [?] Credit card registration
CALL register_session(4, 1, '2021-04-11', 1, 'credit_card');
-- Exepcted:
-- Buys.num_package --
-- Registers cid = 4


-- **/
-- CREATE OR REPLACE PROCEDURE register_session(
--     target_cid INTEGER, 
--     offering_course_id INTEGER,
--     offering_launch_date DATE,

--     target_sid INTEGER,
--     payment_method TEXT
-- ) AS $$

/** 18: Get all customer registrations
-- only return active registration sessions
-- sorted in ascending order of session date and session start hour
Testing done:
NEGATIVE:
[?] 
POSITIVE:
[?] Get all active registration and sorted in order
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
-- CREATE OR REPLACE PROCEDURE update_course_session(
--     target_cid INTEGER,
--     target_course_id INTEGER,
--     target_offering_launch_date DATE,
--     new_sid INTEGER
-- ) AS $$

call update_course_session(3, 1, '2022-07-10', 2);
-- ROW 3: 1	"2021-04-11"	1	"2021-04-05"	4


/** 20: cancel / refund registration
NEGATIVE:
[?] Customer does not exist
[?] Customer has not registered for target offering
POSITIVE:
[?] Refund credit card payment
[?] Refund redemption 
**/
-- if request is valid: process the request with necessary update
-- CREATE OR REPLACE PROCEDURE cancel_registration (
--     target_cid INTEGER,
--     target_course_id INTEGER,
--     target_offering_launch_date DATE
-- ) AS $$

-- NO REFUND
CALL cancel_registration(3, 1, '2021-04-11');
-- REFUND CREDITS
CALL cancel_registration(3, 2, '2022-07-10');
-- REFUND CREDIT CARD
CALL cancel_registration(4, 2, '2022-07-10');



/** 21: Change instructor for a course session
Testing done:
NEGATIVE:
[?] target course session has started
POSITIVE:
[G] Standard insertion
**/
-- CREATE OR REPLACE PROCEDURE update_instructor (
--     target_course_id INTEGER,
--     target_offering_launch_date DATE,
--     target_sid INTEGER,
--     new_iid INTEGER -- Conducts
-- ) AS $$
CALL update_instructor(2, '2022-07-10', 1, 6);
-- will throw

CALL update_instructor(2, '2022-07-10', 1, 5);
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
-- CREATE OR REPLACE PROCEDURE update_room (
--     target_course_id INTEGER,
--     target_offering_launch_date DATE,
--     target_sid INTEGER,
--     new_rid INTEGER
-- ) AS $$
call update_room(2, '2022-07-10', 1, 7);
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
-- CREATE OR REPLACE PROCEDURE remove_session(
--     target_course_id INTEGER,
--     target_offering_launch_date DATE,
--     target_sid INTEGER
-- ) AS $$
call remove_session(2, '2022-07-10', 1);
-- will throw: have customer registered
call remove_session(2, '2022-07-10', 2);
-- should pass
call remove_session(2, '2022-07-11', 3);
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
-- CREATE OR REPLACE PROCEDURE add_session(
--     offering_course_id INTEGER,
--     offering_launch_date DATE,
--     new_sid INTEGER,
--     s_date DATE,
--     start_hour INTEGER,
--     iid INTEGER,
--     rid INTEGER
-- ) AS $$
call add_session(2, '2022-07-11', 4, '2022-08-06',10, 5, 4);
-- pass
call add_session(2, '2022-07-11', 4, '2020-08-06',10, 5, 4);
-- will throw: for 10 days thing


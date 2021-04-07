-- view to be used as a summary of all registered / redeemed for a session
CREATE VIEW registers_redeems_view AS (
    SELECT 
        sid,
        launch_date,
        course_id,
        registration_date,
        cust_id
    FROM Registers
    UNION
    SELECT 
        sid,
        launch_date,
        course_id,
        redeem_date,
        cust_id
    FROM Redeems
);

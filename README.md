## Setup
1. Downalod Docker(rmb to sign up with Docker hub) and pgadmin.
2. Open terminal, navigate to server directory.
3. Launch Docker application.
4. Run the command "docker-compose up".
5. Open PGAdmin and enter your master password (if applicable).
6. Right-click the Servers drop-down menu on the left and select Create -> Server....
7. Under the General tab, type cs2102-project in the Name field.
8. Under the Connection tab, type 0 in the Host name/address field and cs2102-project in the Maintenance database and Username fields.
9. Click Save at the bottom-right corner of the pop-up box. The server should now appear as cs2102-project in the Servers drop-down menu on the left.
10. Double-click on the server and enter cs2102-project as the password.
11. To view the contents of a table, go to cs2102-project -> Databases -> cs2102-project -> Schemas -> public -> Tables, right-click on a table, and click on <b>View/Edit Data</b>.
12. When done with project, control c the terminal running the docker, and run the command "docker-compose down"

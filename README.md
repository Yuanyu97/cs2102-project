Downalod Docker(rmb to sign up with Docker hub) and pgadmin.
Open terminal, navigate to server directory.
Launch Docker application.
Run the command "docker-compose down", then "docker-compose up".
Open PGAdmin and enter your master password (if applicable).
Right-click the Servers drop-down menu on the left and select Create -> Server....
Under the General tab, type cs2102-project in the Name field.
Under the Connection tab, type 0 in the Host name/address field and cs2102-project in the Maintenance database and Username fields.
Click Save at the bottom-right corner of the pop-up box. The server should now appear as cs2102-project in the Servers drop-down menu on the left.
Double-click on the server and enter cs2102-project as the password.
To view the contents of a table, go to cs2102-project -> Databases -> cs2102-project -> Schemas -> public -> Tables, right-click on a table, and click on View/Edit Data.
When done with project, control c the terminal running the docker, and run the command "docker-compose down"

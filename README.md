README.remind
=============

send birthday reminder via email using linux service


-) install

 sudo cp -a remind /usr/local
 sudo cp remind.service /etc/systemd/system/multi-user.target.wants

-) enable service

 sudo systemctl daemon-reload
 sudo systemctl start remind
 sudo systemctl enable remind

the remind service scans all /usr/local/?.remind  
database for date match

If a birthday matches the current date, an email will be send 
using the local /bin/mail.

-) customize

edit birthday_sample.remind and replace  $m1:   with your own emial address
 
-) create you own birthday reminder database

copy the structure of birthday_sample.remind and add your personal B-dates


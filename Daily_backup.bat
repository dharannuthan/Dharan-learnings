@echo off

mkdir %date%
cd C:\Users\HP\Desktop\BACKUPS\GIT\Daily-Backup\%date%

md snap_money
cd snap_money

git clone https://github.com/microgridtechsol/snapmoney.git

cd C:\Users\HP\Desktop\BACKUPS\GIT\Daily-Backup\%date%

md micnxt_joget
cd micnxt_joget

git clone https://github.com/microgridtechsol/micnxt_joget.git

cd C:\Users\HP\Desktop\BACKUPS\GIT\Daily-Backup\%date%

md mic-hfh-api
cd mic-hfh-api

git clone https://github.com/microgridtechsol/mic-hfh-api.git

cd C:\Users\HP\Desktop\BACKUPS\GIT\Daily-Backup\%date%

md stat_App-chatbot
cd stat_App-chatbot

git clone https://github.com/microgridtechsol/Stat_App.git

md stat-app-api
cd stat-app-api

git clone https://github.com/microgridtechsol/stat-app-api.git
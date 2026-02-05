@echo off
echo ========================================
echo FairDispatch AI - MySQL Setup
echo ========================================
echo.

echo Step 1: Create MySQL Database
echo ----------------------------------------
echo Please ensure MySQL is running, then execute these commands:
echo.
echo mysql -u root -p
echo CREATE DATABASE fairdispatch;
echo SHOW DATABASES;
echo EXIT;
echo.
echo ----------------------------------------
echo.

echo Step 2: Configure Database Password
echo ----------------------------------------
echo Edit backend/app/database.py and set:
echo MYSQL_PASSWORD = "your_mysql_password"
echo.
echo OR set environment variable:
echo set MYSQL_PASSWORD=your_mysql_password
echo.
echo ----------------------------------------
echo.

echo Step 3: Install MySQL Connector
echo ----------------------------------------
cd backend
pip install mysql-connector-python
echo.

echo Step 4: Start Backend
echo ----------------------------------------
echo Starting backend with MySQL...
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000

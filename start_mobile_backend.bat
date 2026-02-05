@echo off
echo Starting FairDispatch Backend for Mobile Debugging...
echo Detected Local IP: 192.168.112.28
echo.
python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload

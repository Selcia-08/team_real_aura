# 🔧 Troubleshooting Guide - FairDispatch AI

## Common Issues & Solutions

### 1. Flutter Build Errors

#### Issue: Gradle build failed (Android)
```
Error: Gradle task assembleDebug failed with exit code 1
```

**Solution:**
```bash
# Use Windows or Web instead
flutter run -d windows
# OR
flutter run -d chrome
```

#### Issue: Windows build failed
```
Error: Build process failed
```

**Solutions:**
1. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run -d windows
   ```

2. **Try web version:**
   ```bash
   flutter run -d chrome
   ```

3. **Check Visual Studio installation:**
   - Ensure Visual Studio 2022 with C++ tools is installed
   - Run: `flutter doctor -v` to check

#### Issue: Import errors in Dart
```
error: Directives must appear before any declarations
```

**Solution:**
- All `import` statements must be at the TOP of the file
- Check `lib/models/models.dart` - import should be line 1

### 2. Backend Issues

#### Issue: Backend won't start
```
Error: No module named 'fastapi'
```

**Solution:**
```bash
cd backend
pip install -r requirements.txt
```

#### Issue: MySQL connection failed
```
Error: Can't connect to MySQL server
```

**Solution:**
- System automatically falls back to SQLite ✅
- Check console for: `📦 Falling back to SQLite...`
- SQLite works perfectly for demo!

#### Issue: Port already in use
```
Error: Address already in use
```

**Solution:**
```bash
# Kill existing process
# Windows:
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Then restart
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

### 3. API Connection Issues

#### Issue: Frontend can't connect to backend
```
Error: Failed to connect to 127.0.0.1:8000
```

**Solutions:**
1. **Check backend is running:**
   - Visit: http://127.0.0.1:8000
   - Should see: `{"message":"FairDispatch AI API"...}`

2. **Check CORS settings:**
   - Backend `main.py` has CORS middleware
   - Allows all origins for demo

3. **Update API base URL:**
   - In `lib/services/api_service.dart`
   - Change `baseUrl` if needed

### 4. Demo Data Issues

#### Issue: No demo data appears
```
Empty dashboard after clicking "Populate Demo Data"
```

**Solution:**
1. **Check backend logs** for errors
2. **Manually populate via API:**
   - Visit: http://127.0.0.1:8000/docs
   - Use `/demo/populate` endpoint
   - Click "Try it out" → "Execute"

3. **Check database:**
   ```bash
   # For SQLite
   sqlite3 fairdispatch.db
   SELECT * FROM users;
   ```

#### Issue: Dispatch doesn't assign routes
```
No assignments after clicking "Run Dispatch"
```

**Solution:**
1. **Ensure demo data exists:**
   - Check drivers exist
   - Check routes exist
2. **Check backend logs** for errors
3. **Try via API docs:**
   - http://127.0.0.1:8000/docs
   - POST `/dispatch/run`
   - Body: `{"location_id": "LOC001"}`

### 5. UI/Display Issues

#### Issue: Map not loading
```
Blank map or tiles not loading
```

**Solutions:**
1. **Check internet connection** (needs OpenStreetMap tiles)
2. **Wait a few seconds** for tiles to load
3. **Check browser console** for errors

#### Issue: Charts not displaying
```
Blank space where chart should be
```

**Solution:**
- Ensure `fl_chart` package is installed
- Run: `flutter pub get`
- Restart app

#### Issue: Fonts look wrong
```
Default system fonts instead of Outfit
```

**Solution:**
- Ensure `google_fonts` package is installed
- Internet connection required for font download
- Fonts are cached after first load

### 6. Authentication Issues

#### Issue: Admin login fails
```
Invalid credentials
```

**Solution:**
- Use exact demo credentials:
  - Location ID: `LOC001`
  - Year: `2024`
  - DOB: `01011990`
- Ensure demo data is populated

#### Issue: Driver login fails
```
Invalid credentials
```

**Solution:**
- Use exact demo credentials:
  - Employee ID: `EMP001` (or EMP002, EMP003, EMP004)
  - Password: `pass123`
- Ensure demo data is populated

### 7. Performance Issues

#### Issue: App is slow/laggy
```
Slow response times
```

**Solutions:**
1. **Disable auto-refresh temporarily:**
   - Comment out `_refreshTimer` in dashboards
2. **Use release mode:**
   ```bash
   flutter run -d chrome --release
   ```
3. **Check backend performance:**
   - SQLite is slower than MySQL
   - Consider using MySQL for better performance

### 8. Database Issues

#### Issue: Database locked (SQLite)
```
Error: database is locked
```

**Solution:**
```bash
# Close all connections
# Restart backend
cd backend
python -m uvicorn app.main:app --reload
```

#### Issue: Table doesn't exist
```
Error: no such table: users
```

**Solution:**
- Tables are auto-created on first run
- Restart backend to trigger creation
- Check `fairdispatch.db` file exists

### 9. Notification Issues

#### Issue: Notifications don't appear
```
No notifications in Alerts tab
```

**Solution:**
1. **Run dispatch first** to create assignments
2. **Check backend logs** for notification creation
3. **Refresh dashboard** (pull down or wait 30s)

#### Issue: Email notifications not sending
```
Emails not received
```

**Solution:**
- **Demo mode:** Emails are logged to console ✅
- Check backend console for email logs
- To enable real emails:
  - Configure SMTP in `backend/app/email_service.py`
  - Uncomment SMTP code
  - Add credentials to environment variables

### 10. Quick Fixes

#### Nuclear Option: Complete Reset
```bash
# Backend
cd backend
rm fairdispatch.db  # Delete database
pip install -r requirements.txt --force-reinstall
python -m uvicorn app.main:app --reload

# Frontend
cd ..
flutter clean
flutter pub get
flutter run -d chrome
```

#### Check System Health
```bash
# Flutter
flutter doctor -v

# Python
python --version
pip list

# Backend API
curl http://127.0.0.1:8000
```

## 🎯 Demo Day Quick Fixes

### If backend crashes during demo:
1. Have backup screenshots ready
2. Show API documentation at `/docs`
3. Walk through code in IDE
4. Use video recording if available

### If frontend crashes during demo:
1. Restart: `flutter run -d chrome`
2. Show mobile version if available
3. Demo API directly in browser
4. Show code walkthrough

### If everything fails:
1. **Stay calm** 😌
2. Show **architecture diagrams**
3. Walk through **code highlights**
4. Explain **algorithm logic**
5. Show **documentation**
6. Emphasize **design decisions**

## 📞 Emergency Contacts

- Flutter Issues: https://flutter.dev/docs
- FastAPI Docs: https://fastapi.tiangolo.com
- SQLAlchemy: https://docs.sqlalchemy.org

## ✅ Pre-Demo Checklist

- [ ] Backend running on port 8000
- [ ] Frontend running (Windows/Chrome/Mobile)
- [ ] Demo data populated
- [ ] At least one dispatch run completed
- [ ] Screenshots captured
- [ ] Backup plan ready

---

**Remember: The judges care more about your ideas and approach than perfect execution! 🚀**

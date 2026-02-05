<<<<<<< HEAD
# 🚚 FairDispatch AI - Human-Centered Delivery Dispatch System

A comprehensive, fairness-aware delivery dispatch system that prioritizes driver well-being, transparency, and equitable workload distribution using AI/ML.

## 🌟 Key Features

### ✅ Dual Authentication System
- **Admin Login**: Location ID + Year + DOB authentication
- **Driver/Dispatcher Login**: Employee ID + Password authentication

### 🤖 AI-Powered Route Assignment
- **ML Route Grading**: Automatic difficulty classification (Easy/Medium/Hard)
- **Satellite Analysis Simulation**: Terrain difficulty prediction
- **Live Traffic Integration**: Real-time route complexity assessment
- **Fairness Algorithm**: Balances workload across weekly cycles

### 💚 Health & Fatigue Awareness
- Real-time fatigue tracking
- Health status monitoring (Normal/Caution/Restricted)
- Automatic workload adjustment for tired/unwell drivers
- Medical exemption support

### 💳 Credit & Bonus System
- Earn credits for completing routes
- Bonus credits for accepting reassigned routes
- Use credits to request lighter routes
- Transparent reward structure

### 📧 Notification System
- In-app notifications with unread badges
- Email notifications for route assignments
- Real-time updates on route status
- Explanation for every assignment

### 🗺️ Live Map Integration
- Color-coded routes (Green=Easy, Orange=Medium, Red=Hard)
- Start and end point markers
- Interactive map view
- Route visualization

### ✅ Accept/Decline Routes
- Drivers can accept or decline assignments
- Provide reasons for declining
- Automatic reassignment to available drivers
- Bonus credits for taking declined routes

### 📊 Admin Dashboard
- **Overview Tab**: Real-time stats, fatigue charts, quick actions
- **Drivers Tab**: Monitor all drivers, health status, credits
- **Policy Tab**: Update weekly fairness policies
- Run dispatch with one click
- Populate demo data instantly

### 🔄 Weekly Fairness Policy
- Configurable route distribution targets
- Credit reward customization
- Relaxation conditions (max consecutive hard routes, fatigue thresholds)
- Location-specific policies

## 🏗️ Architecture

### Backend (Python/FastAPI)
```
backend/
├── app/
│   ├── main.py              # FastAPI app with all endpoints
│   ├── models.py            # SQLAlchemy database models
│   ├── schemas.py           # Pydantic validation schemas
│   ├── database.py          # Database connection (MySQL/SQLite)
│   ├── logic.py             # Fairness algorithm & ML analysis
│   ├── email_service.py     # Email notification service
│   └── crud.py              # Database operations
└── requirements.txt
```

### Frontend (Flutter/Dart)
```
lib/
├── main.dart                # App entry point
├── models/
│   └── models.dart          # Data models
├── services/
│   └── api_service.dart     # API communication
└── screens/
    ├── splash_screen.dart           # Animated splash
    ├── landing_page.dart            # Role selection
    ├── admin_login_screen.dart      # Admin authentication
    ├── driver_login_screen.dart     # Driver authentication
    ├── admin_dashboard_screen.dart  # Admin control panel
    └── driver_dashboard_screen.dart # Driver interface
```

## 🚀 Setup Instructions

### Prerequisites
- Python 3.8+
- Flutter 3.0+
- MySQL (optional, SQLite fallback available)

### Backend Setup

1. **Install Python Dependencies**
```bash
cd backend
pip install -r requirements.txt
```

2. **Configure Database (Optional)**
   
   For MySQL:
   ```bash
   # Create database
   mysql -u root -p
   CREATE DATABASE fairdispatch;
   
   # Update DATABASE_URL in backend/app/database.py
   DATABASE_URL = "mysql+mysqlconnector://root:YOUR_PASSWORD@localhost:3306/fairdispatch"
   ```
   
   For SQLite (default):
   - No configuration needed, will auto-create `fairdispatch.db`

3. **Start Backend Server**
```bash
# From project root
run_backend.bat

# OR manually
cd backend
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

The API will be available at `http://127.0.0.1:8000`

### Frontend Setup

1. **Install Flutter Dependencies**
```bash
flutter pub get
```

2. **Run the App**
```bash
# For Windows
flutter run -d windows

# For Android Emulator
flutter run -d emulator-5554

# For Web
flutter run -d chrome
```

## 🎮 Demo Walkthrough

### Step 1: Initial Setup
1. Launch the app
2. You'll see the **Splash Screen** with animated logo
3. After 3 seconds, you'll reach the **Landing Page**

### Step 2: Populate Demo Data
1. Choose **Admin Login**
2. Use demo credentials:
   - Location ID: `LOC001`
   - Year: `2024`
   - DOB: `01011990`
3. Click **Populate Demo Data** button
4. This creates:
   - 4 demo drivers (Alex, Sam, Jamie, Taylor)
   - 6 routes with varying difficulties
   - Default fairness policy

### Step 3: Run AI Dispatch
1. In Admin Dashboard, click **Run Dispatch** (lightning bolt button)
2. The AI will:
   - Analyze each driver's fatigue and health
   - Check weekly route balance
   - Assign routes fairly
   - Generate human-friendly explanations
   - Send notifications

### Step 4: Driver Experience
1. Log out and choose **Driver Login**
2. Use credentials:
   - Employee ID: `EMP002` (Sam - the tired driver)
   - Password: `pass123`
3. You'll see:
   - **Home Tab**: Pending route assignment with explanation
   - **Routes Tab**: Live map with color-coded routes
   - **Alerts Tab**: Notifications
4. Notice Sam gets an **Easy** route because:
   - High fatigue score (85%)
   - Health status: Restricted
   - AI explanation: *"Focusing on your health today..."*

### Step 5: Accept/Decline Routes
1. On a pending route, you can:
   - **Accept**: Earn credits, route marked as accepted
   - **Decline**: Provide reason, route reassigned to another driver with bonus
2. Try declining a route:
   - Enter reason: "Not feeling well"
   - Route automatically reassigned to available driver
   - That driver gets +5 bonus credits

### Step 6: Admin Monitoring
1. Switch back to Admin Dashboard
2. **Overview Tab**:
   - See total drivers, active count, routes today
   - View fatigue chart showing all drivers
3. **Drivers Tab**:
   - Monitor each driver's status
   - See fatigue levels, credits, health
4. **Policy Tab**:
   - Update weekly targets (e.g., 2 Easy, 3 Medium, 2 Hard)
   - Modify credit rewards
   - Set relaxation conditions

## 📊 Database Schema

### Key Tables
- **admins**: Admin authentication
- **users**: Drivers/dispatchers with fatigue, health, credits
- **routes**: Delivery routes with ML-analyzed difficulty
- **assignments**: Route-driver mappings with explanations
- **notifications**: In-app alerts
- **credit_logs**: Credit transaction history
- **weekly_policies**: Location-specific fairness rules

## 🎯 Fairness Algorithm

The dispatch engine follows this priority:

1. **Health Restrictions** → Easy/Medium routes only
2. **High Fatigue (>80%)** → Easy routes for recovery
3. **Weekly Balance** → Ensure fair distribution of Hard/Medium/Easy
4. **Credit Usage** → Allow drivers to use credits for preferences
5. **Team Fairness** → Distribute remaining routes equitably

## 🧠 ML/AI Features

### Route Difficulty Calculation
```python
score = (
    package_count / 10 +
    weight_kg / 10 +
    walking_distance_km * 2 +
    traffic_level * 20 +
    apartment_density * 10 +
    (25 if no_elevator else 0) +
    stairs_count * 0.5 +
    parking_difficulty * 15 +
    terrain_difficulty * 10  # From satellite analysis
)
```

### Satellite Analysis (Simulated)
- Analyzes GPS coordinates
- Calculates terrain difficulty (0.0-1.0)
- Predicts delivery time based on multiple factors
- In production: integrate with real satellite imagery API

## 📧 Email Notifications

Configured in `backend/app/email_service.py`:
- Currently logs to console (demo mode)
- Uncomment SMTP code for production
- Supports HTML email templates
- Sends on: route assignment, acceptance, decline

## 🎨 UI/UX Highlights

### Design Principles
- **Premium Dark Theme**: Gradient backgrounds, glassmorphism
- **Vibrant Colors**: Purple (#6C63FF), Cyan (#03DAC6)
- **Smooth Animations**: Splash screen, floating elements
- **Clear Typography**: Google Fonts (Outfit)
- **Intuitive Navigation**: Tab-based dashboards
- **Real-time Updates**: Auto-refresh every 30 seconds

### Color Coding
- 🟢 **Green**: Easy routes, healthy drivers, positive stats
- 🟠 **Orange**: Medium routes, caution status, moderate fatigue
- 🔴 **Red**: Hard routes, restricted health, high fatigue

## 🔐 Security Notes

**For Production:**
1. Hash passwords using bcrypt (currently plain text for demo)
2. Implement JWT tokens for session management
3. Add HTTPS/TLS encryption
4. Configure CORS properly
5. Use environment variables for sensitive data
6. Add rate limiting
7. Implement proper authentication middleware

## 🐛 Troubleshooting

### Backend won't start
```bash
# Check Python version
python --version  # Should be 3.8+

# Reinstall dependencies
pip install -r backend/requirements.txt --force-reinstall
```

### Frontend build errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Database connection issues
- Check MySQL is running: `mysql -u root -p`
- Verify DATABASE_URL in `backend/app/database.py`
- Fallback to SQLite by commenting MySQL URL

### Map not loading
- Check internet connection (needs OpenStreetMap tiles)
- Verify `INTERNET` permission in `AndroidManifest.xml`

## 📈 Future Enhancements

- [ ] Real-time GPS tracking
- [ ] Actual satellite imagery integration
- [ ] Push notifications (FCM)
- [ ] Driver mobile app (iOS/Android)
- [ ] Advanced analytics dashboard
- [ ] Route optimization algorithms
- [ ] Integration with delivery management systems
- [ ] Multi-language support
- [ ] Voice-based route acceptance

## 🏆 Demo Credentials

### Admin
- Location ID: `LOC001`
- Year: `2024`
- DOB: `01011990`

### Drivers
| Employee ID | Password | Name | Status |
|------------|----------|------|--------|
| EMP001 | pass123 | Alex Driver | Normal (Low Fatigue) |
| EMP002 | pass123 | Sam Tired | Restricted (High Fatigue) |
| EMP003 | pass123 | Jamie Fresh | Normal (Very Low Fatigue) |
| EMP004 | pass123 | Taylor Swift | Caution (Medium Fatigue) |

## 📝 License

This project is for demonstration purposes (Hackathon submission).

## 🤝 Contributing

Built for the FairDispatch AI Hackathon 2024.

---

**Built with ❤️ for fairness, transparency, and driver well-being**
=======
# team_real_aura
>>>>>>> 79ffdf9aa478f49c0626c73014913f1309b227cd

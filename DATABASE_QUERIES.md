# 📊 Database Operations Guide - FairDispatch AI

## Quick Setup

### Run the Complete Setup Script

```bash
# On MySQL laptop, run:
mysql -u root -p < database_setup.sql
```

This will:
- ✅ Create database `fairdispatch`
- ✅ Create all 7 tables
- ✅ Insert sample data (1 admin, 5 users, 6 routes, 1 policy)
- ✅ Create views for analytics
- ✅ Create stored procedures
- ✅ Create triggers for notifications

---

## Common SQL Queries

### 1. View All Drivers

```sql
SELECT 
    id, name, employee_id, fatigue_score, 
    health_status, credits, bonus_credits, is_available
FROM users 
WHERE role = 'DRIVER'
ORDER BY fatigue_score DESC;
```

### 2. View All Routes

```sql
SELECT 
    id, area, description, package_count, weight_kg, grade,
    CASE grade
        WHEN 1 THEN 'Easy'
        WHEN 2 THEN 'Medium'
        WHEN 3 THEN 'Hard'
    END as difficulty
FROM routes
ORDER BY grade;
```

### 3. View Pending Assignments

```sql
SELECT 
    a.id, u.name as driver_name, r.area, r.description,
    a.explanation, a.assigned_date
FROM assignments a
JOIN users u ON a.driver_id = u.id
JOIN routes r ON a.route_id = r.id
WHERE a.status = 'Pending'
ORDER BY a.assigned_date DESC;
```

### 4. View Driver Performance

```sql
SELECT * FROM driver_performance
ORDER BY total_assignments DESC;
```

### 5. View Today's Assignments

```sql
SELECT 
    u.name as driver, r.area, a.status, a.assigned_date
FROM assignments a
JOIN users u ON a.driver_id = u.id
JOIN routes r ON a.route_id = r.id
WHERE DATE(a.assigned_date) = CURDATE()
ORDER BY a.assigned_date DESC;
```

---

## Insert New Data

### Add New Driver

```sql
INSERT INTO users (
    name, email, employee_id, password, role, location_id,
    fatigue_score, health_status, credits, is_available
) VALUES (
    'New Driver', 'newdriver@fairdispatch.com', 'EMP006', 'pass123',
    'DRIVER', 'LOC001', 20.00, 'Normal', 10, TRUE
);
```

### Add New Route

```sql
INSERT INTO routes (
    description, area, location_id,
    start_lat, start_lng, end_lat, end_lng,
    package_count, weight_kg, grade, grade_reason,
    predicted_time_minutes, terrain_difficulty
) VALUES (
    'New delivery area', 'New Area', 'LOC001',
    40.7128, -74.0060, 40.7589, -73.9851,
    20, 30.0, 2, 'Moderate difficulty route',
    60, 0.4
);
```

### Create Assignment

```sql
INSERT INTO assignments (
    driver_id, route_id, status, explanation, assignment_reason
) VALUES (
    1, -- driver ID
    1, -- route ID
    'Pending',
    'This route matches your current workload and location.',
    'Balanced workload distribution'
);
```

---

## Update Data

### Update Driver Fatigue

```sql
-- Using stored procedure (recommended)
CALL update_driver_fatigue(1, 10.0); -- driver_id, fatigue_change

-- Or manually
UPDATE users 
SET fatigue_score = GREATEST(0, LEAST(100, fatigue_score + 10))
WHERE id = 1;
```

### Update Driver Credits

```sql
-- Using stored procedure (recommended)
CALL award_credits(1, 5, 'Bonus for good performance', TRUE, NULL);

-- Or manually
UPDATE users 
SET bonus_credits = bonus_credits + 5
WHERE id = 1;
```

### Accept Assignment

```sql
UPDATE assignments
SET status = 'Accepted', response_time = NOW()
WHERE id = 1;
```

### Decline Assignment

```sql
UPDATE assignments
SET status = 'Declined', 
    decline_reason = 'Not feeling well',
    response_time = NOW()
WHERE id = 1;
```

### Complete Assignment

```sql
-- Using stored procedure (awards credits automatically)
CALL complete_assignment(1); -- assignment_id

-- Or manually
UPDATE assignments
SET status = 'Completed', completion_time = NOW()
WHERE id = 1;
```

---

## Analytics Queries

### Driver Workload Summary

```sql
SELECT 
    u.name,
    u.fatigue_score,
    COUNT(CASE WHEN a.status = 'Completed' AND r.grade = 1 THEN 1 END) as easy_routes,
    COUNT(CASE WHEN a.status = 'Completed' AND r.grade = 2 THEN 1 END) as medium_routes,
    COUNT(CASE WHEN a.status = 'Completed' AND r.grade = 3 THEN 1 END) as hard_routes,
    u.credits + u.bonus_credits as total_credits
FROM users u
LEFT JOIN assignments a ON u.id = a.driver_id
LEFT JOIN routes r ON a.route_id = r.id
WHERE u.role = 'DRIVER'
GROUP BY u.id, u.name, u.fatigue_score, u.credits, u.bonus_credits;
```

### Weekly Assignment Distribution

```sql
SELECT 
    u.name,
    DATE(a.assigned_date) as date,
    COUNT(*) as assignments,
    AVG(r.grade) as avg_difficulty
FROM assignments a
JOIN users u ON a.driver_id = u.id
JOIN routes r ON a.route_id = r.id
WHERE a.assigned_date >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY u.name, DATE(a.assigned_date)
ORDER BY date DESC, u.name;
```

### High Fatigue Drivers

```sql
SELECT 
    name, employee_id, fatigue_score, health_status,
    CASE 
        WHEN fatigue_score >= 80 THEN 'Needs rest'
        WHEN fatigue_score >= 60 THEN 'Monitor closely'
        ELSE 'OK'
    END as recommendation
FROM users
WHERE role = 'DRIVER' AND fatigue_score > 50
ORDER BY fatigue_score DESC;
```

### Credit Leaderboard

```sql
SELECT 
    name, employee_id,
    credits, bonus_credits,
    (credits + bonus_credits) as total_credits
FROM users
WHERE role = 'DRIVER'
ORDER BY total_credits DESC
LIMIT 10;
```

---

## Maintenance Queries

### Reset Driver Fatigue (Weekly)

```sql
UPDATE users 
SET fatigue_score = GREATEST(0, fatigue_score - 20)
WHERE role = 'DRIVER';
```

### Archive Old Assignments

```sql
-- Create archive table first
CREATE TABLE IF NOT EXISTS assignments_archive LIKE assignments;

-- Move old assignments
INSERT INTO assignments_archive
SELECT * FROM assignments
WHERE assigned_date < DATE_SUB(NOW(), INTERVAL 30 DAY);

-- Delete from main table
DELETE FROM assignments
WHERE assigned_date < DATE_SUB(NOW(), INTERVAL 30 DAY);
```

### Clear All Assignments (Testing)

```sql
DELETE FROM assignments;
DELETE FROM credit_logs;
DELETE FROM notifications;
```

### Reset Demo Data

```sql
-- Delete all data
DELETE FROM assignments;
DELETE FROM credit_logs;
DELETE FROM notifications;
DELETE FROM routes;
DELETE FROM users WHERE role != 'ADMIN';
DELETE FROM weekly_policies;

-- Re-run inserts from database_setup.sql
```

---

## Backup and Restore

### Backup Database

```bash
# Full backup
mysqldump -u root -p fairdispatch > fairdispatch_backup.sql

# Backup specific tables
mysqldump -u root -p fairdispatch users routes assignments > data_backup.sql

# Backup with timestamp
mysqldump -u root -p fairdispatch > fairdispatch_$(date +%Y%m%d_%H%M%S).sql
```

### Restore Database

```bash
# Restore full database
mysql -u root -p fairdispatch < fairdispatch_backup.sql

# Restore specific tables
mysql -u root -p fairdispatch < data_backup.sql
```

---

## Useful Admin Queries

### Check Database Size

```sql
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb
FROM information_schema.TABLES
WHERE table_schema = 'fairdispatch'
ORDER BY size_mb DESC;
```

### Count Records in All Tables

```sql
SELECT 
    'admins' as table_name, COUNT(*) as count FROM admins
UNION ALL
SELECT 'users', COUNT(*) FROM users
UNION ALL
SELECT 'routes', COUNT(*) FROM routes
UNION ALL
SELECT 'assignments', COUNT(*) FROM assignments
UNION ALL
SELECT 'credit_logs', COUNT(*) FROM credit_logs
UNION ALL
SELECT 'notifications', COUNT(*) FROM notifications
UNION ALL
SELECT 'weekly_policies', COUNT(*) FROM weekly_policies;
```

### View Recent Activity

```sql
SELECT 
    'Assignment' as activity_type,
    CONCAT(u.name, ' assigned to ', r.area) as description,
    a.assigned_date as timestamp
FROM assignments a
JOIN users u ON a.driver_id = u.id
JOIN routes r ON a.route_id = r.id
UNION ALL
SELECT 
    'Credit',
    CONCAT(u.name, ' earned ', c.amount, ' credits: ', c.reason),
    c.timestamp
FROM credit_logs c
JOIN users u ON c.driver_id = u.id
ORDER BY timestamp DESC
LIMIT 20;
```

---

## Quick Reference

### Table Structure

```
fairdispatch/
├── admins (Admin accounts)
├── users (Drivers & Dispatchers)
├── routes (Delivery routes)
├── assignments (Route assignments)
├── credit_logs (Credit transactions)
├── notifications (In-app alerts)
└── weekly_policies (Fairness rules)
```

### Key Relationships

```
users (driver) ←→ assignments ←→ routes
users (driver) ←→ credit_logs
users ←→ notifications
location_id ←→ weekly_policies
```

---

## Next Steps

1. **Run setup script**: `mysql -u root -p < database_setup.sql`
2. **Verify tables**: `SHOW TABLES;`
3. **Check sample data**: `SELECT * FROM users;`
4. **Configure backend**: Update `database.py` with MySQL credentials
5. **Test connection**: Restart backend and check logs

---

**All queries are ready to use! Just copy and paste into MySQL client.** 🚀

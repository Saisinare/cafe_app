# Admin Panel - Cafe App

## Overview
The admin panel provides comprehensive control over the Cafe App, including user management, analytics, and premium subscription control.

## Admin Credentials
- **Email**: `admin@123gmail.com`
- **Password**: `admin@123`

## Features

### 1. Dashboard Overview
- **User Statistics**: Total users, premium users, new users this month, premium percentage
- **Income Overview**: Total income, monthly income, yearly income
- **Monthly Income Trend**: Line chart showing income over the last 12 months

### 2. User Management
- **View All Users**: List of all registered users with their premium status
- **Search Users**: Search functionality to find specific users
- **Premium Control**: 
  - Add premium to any user (monthly/yearly plans)
  - Remove premium from users
  - View user details and subscription information

### 3. Analytics
- **User Growth**: Chart showing user growth over time
- **User Distribution**: Pie chart showing premium vs free users ratio
- **Real-time Data**: All data is fetched from Firestore in real-time

### 4. Premium Subscription Management
- **Add Premium**: Grant premium access to any user
  - Monthly Plan: 30 days
  - Yearly Plan: 365 days
- **Remove Premium**: Revoke premium access from users
- **Monitor Status**: Track active/inactive premium subscriptions

## Technical Implementation

### Files Created/Modified:
1. **`lib/models/admin.dart`** - Admin model class
2. **`lib/services/admin_service.dart`** - Admin service with authentication and data management
3. **`lib/pages/admin/admin_dashboard.dart`** - Main admin dashboard UI
4. **`lib/pages/login_page.dart`** - Modified to handle admin authentication
5. **`lib/main.dart`** - Modified to handle admin routing

### Key Features:
- **Secure Authentication**: Admin credentials are hardcoded for security
- **Firestore Integration**: All data is stored and retrieved from Firestore
- **Real-time Updates**: Dashboard refreshes data automatically
- **Responsive UI**: Modern Material Design with charts and interactive elements
- **User Management**: Complete control over user premium status

## Usage Instructions

### 1. Access Admin Panel
1. Open the app
2. Go to login page
3. Use admin credentials: `admin@123gmail.com` / `admin@123`
4. You'll be redirected to the admin dashboard

### 2. Navigate Dashboard
- **Overview Tab**: View key statistics and income charts
- **Users Tab**: Manage users and their premium status
- **Analytics Tab**: View detailed analytics and charts

### 3. Manage Users
- **Add Premium**: Select user → Add Premium → Choose plan
- **Remove Premium**: Select user → Remove Premium → Confirm
- **View Details**: Select user → View Details

### 4. Monitor Analytics
- **Refresh Data**: Use refresh button in app bar
- **Real-time Updates**: Data updates automatically
- **Export Ready**: All data is available for export

## Security Features
- Admin credentials are hardcoded (not stored in database)
- Admin session is managed locally
- Regular user authentication is separate from admin
- Admin can only access admin-specific features

## Data Sources
- **Users**: `users` collection in Firestore
- **Premium Subscriptions**: `premium_subscriptions` collection
- **Admin Data**: `admins` collection (created automatically)

## Future Enhancements
- User activity logs
- Advanced analytics and reporting
- Bulk user operations
- Email notifications
- Audit trails
- Role-based permissions

## Support
For admin panel issues or feature requests, contact the development team.

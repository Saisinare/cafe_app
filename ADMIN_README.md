# Admin Module Documentation

## Overview
The admin module provides administrative access to the Cafe App with a separate interface and enhanced privileges.

## Admin Credentials
- **Email**: `admin`
- **Password**: `admin`

## Features

### 1. Admin Authentication
- Separate login flow for admin users
- Bypasses Firebase authentication for admin credentials
- Redirects to admin dashboard instead of regular user interface

### 2. Admin Dashboard
- **Overview Tab**: Shows user statistics, income data, and charts
- **Users Tab**: Manage user accounts and premium subscriptions
- **Analytics Tab**: Detailed financial and user analytics

### 3. User Management
- View all registered users
- Toggle premium status for users
- Add/remove premium subscriptions
- Monitor user activity and subscription details

### 4. Financial Analytics
- Total income tracking
- Monthly and yearly revenue analysis
- Premium subscription revenue
- User conversion metrics

## How to Use

### Login as Admin
1. Open the app
2. Enter `admin` as email
3. Enter `admin` as password
4. Click Login
5. You'll be redirected to the admin dashboard

### Navigate Admin Interface
- **Sidebar Navigation**: Use the left sidebar to switch between different admin sections
- **Dashboard**: Overview of key metrics and statistics
- **Users**: Manage user accounts and subscriptions
- **Logout**: Use the logout button in the top-right corner

### Manage Users
1. Go to the "Users" tab
2. View all registered users
3. Use the toggle switch to add/remove premium status
4. Monitor user subscription details

## Technical Details

### Files Structure
```
lib/
├── pages/
│   ├── admin/
│   │   ├── admin_layout.dart      # Main admin interface
│   │   ├── admin_dashboard.dart   # Dashboard with statistics
│   │   └── admin_users_page.dart  # User management
│   └── login_page.dart            # Login with admin detection
├── services/
│   └── admin_service.dart         # Admin business logic
└── models/
    └── admin.dart                 # Admin data model
```

### Admin Service
- Handles admin authentication
- Manages user data and statistics
- Controls premium subscription management
- Provides financial analytics

### Security Notes
- Admin credentials are hardcoded in the service (for development)
- In production, implement proper admin authentication
- Consider using Firebase Admin SDK for production use
- Add role-based access control for different admin levels

## Development

### Adding New Admin Features
1. Create new admin page in `lib/pages/admin/`
2. Add to `AdminLayout` pages list
3. Add menu item to sidebar
4. Implement business logic in `AdminService`

### Customizing Admin Interface
- Modify `AdminLayout` for layout changes
- Update color scheme in theme constants
- Add new navigation items to sidebar
- Customize dashboard widgets

## Production Considerations

### Security
- Implement proper admin authentication
- Use Firebase Admin SDK
- Add role-based permissions
- Secure admin endpoints

### Scalability
- Cache frequently accessed data
- Implement pagination for large user lists
- Add search and filtering capabilities
- Optimize database queries

### Monitoring
- Add admin action logging
- Implement audit trails
- Monitor admin access patterns
- Set up alerts for suspicious activity

## Troubleshooting

### Common Issues
1. **Admin login not working**: Check admin credentials in `AdminService`
2. **Dashboard not loading**: Verify Firestore permissions and rules
3. **User management errors**: Check user data structure and permissions

### Debug Mode
- Enable debug logging in `AdminService`
- Check console for error messages
- Verify Firebase configuration
- Test with sample data

## Support
For admin module issues or feature requests, refer to the main project documentation or contact the development team.

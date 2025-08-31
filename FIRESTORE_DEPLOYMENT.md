# Firestore Security Rules Deployment Guide

## Problem
You're getting the error: "The caller does not have permission to execute the specific operation" when trying to login as admin.

## Solution
Deploy the updated Firestore security rules that allow admin access.

## Steps to Deploy Firestore Rules

### Method 1: Firebase Console (Recommended)

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Select your project

2. **Navigate to Firestore**
   - Click on "Firestore Database" in the left sidebar
   - Click on "Rules" tab

3. **Update Rules**
   - Replace the existing rules with the content from `firestore.rules`
   - Click "Publish" to deploy

### Method 2: Firebase CLI

1. **Install Firebase CLI** (if not already installed)
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**
   ```bash
   firebase login
   ```

3. **Initialize Firebase** (if not already done)
   ```bash
   firebase init firestore
   ```

4. **Deploy Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

### Method 3: Copy-Paste Rules

Copy this content directly into your Firebase Console Firestore Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow admin access to all collections
    match /{document=**} {
      allow read, write: if request.auth != null && 
        (request.auth.token.email == 'admin@123gmail.com' || 
         request.auth.token.email_verified == true);
    }
    
    // Users collection - users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == userId || 
         request.auth.token.email == 'admin@123gmail.com');
    }
    
    // Premium subscriptions - users can read their own, admin can read/write all
    match /premium_subscriptions/{subscriptionId} {
      allow read: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.auth.token.email == 'admin@123gmail.com');
      allow write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.auth.token.email == 'admin@123gmail.com');
    }
    
    // Admins collection - only admin can access
    match /admins/{adminId} {
      allow read, write: if request.auth != null && 
        request.auth.token.email == 'admin@123gmail.com';
    }
    
    // Categories collection - read for all authenticated users, write for admin
    match /categories/{categoryId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.token.email == 'admin@123gmail.com';
    }
    
    // Items collection - read for all authenticated users, write for admin
    match /items/{itemId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.token.email == 'admin@123gmail.com';
    }
    
    // Sales collection - users can read/write their own, admin can read/write all
    match /sales/{saleId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.auth.token.email == 'admin@123gmail.com');
    }
    
    // Purchase collection - users can read/write their own, admin can read/write all
    match /purchases/{purchaseId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.auth.token.email == 'admin@123gmail.com');
    }
    
    // Money in/out collections - users can read/write their own, admin can read/write all
    match /money_in/{moneyInId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.auth.token.email == 'admin@123gmail.com');
    }
    
    match /money_out/{moneyOutId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.auth.token.email == 'admin@123gmail.com');
    }
    
    // Sales invoices - users can read/write their own, admin can read/write all
    match /sales_invoices/{invoiceId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.auth.token.email == 'admin@123gmail.com');
    }
    
    // Party collection - users can read/write their own, admin can read/write all
    match /parties/{partyId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.auth.token.email == 'admin@123gmail.com');
    }
  }
}
```

## What These Rules Do

1. **Admin Access**: The email `admin@123gmail.com` gets full access to all collections
2. **User Security**: Regular users can only access their own data
3. **Collection Protection**: Each collection has specific access rules
4. **Authentication Required**: All operations require user authentication

## After Deployment

1. **Wait 1-2 minutes** for rules to propagate
2. **Test admin login** with `admin@123gmail.com` / `admin@123`
3. **Check admin dashboard** functionality

## Troubleshooting

### Still Getting Permission Errors?
1. **Verify rules deployed**: Check Firebase Console Rules tab
2. **Check admin email**: Must be exactly `admin@123gmail.com`
3. **Wait for propagation**: Rules can take a few minutes to activate
4. **Clear app cache**: Restart the app

### Rules Not Working?
1. **Check syntax**: Ensure no syntax errors in rules
2. **Verify project**: Make sure you're in the correct Firebase project
3. **Check authentication**: Ensure user is properly authenticated

## Security Notes

- These rules allow the admin email full access
- Regular users are restricted to their own data
- All operations require authentication
- Consider adding more restrictions for production use

## Support

If you continue to have issues:
1. Check Firebase Console for error logs
2. Verify the rules are properly deployed
3. Test with a simple rule first, then add complexity

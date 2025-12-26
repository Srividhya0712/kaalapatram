# Firestore Security Rules Setup

## Problem
You're getting a permission denied error when trying to save events to Firestore:
```
Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions., cause=null}
```

## Solution
You need to update your Firestore security rules in the Firebase Console.

## Steps to Fix:

### 1. Open Firebase Console
- Go to https://console.firebase.google.com/
- Select your project (kaalapatram)

### 2. Navigate to Firestore Database
- Click on "Firestore Database" in the left sidebar
- Click on the "Rules" tab

### 3. Replace the existing rules with:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read and write their own events
    match /events/{eventId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.createdBy;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.createdBy;
    }
    
    // Allow users to read and write their own user documents
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Deny all other requests
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### 4. Publish the Rules
- Click "Publish" to deploy the new security rules

### 5. Test the App
- Try creating an event in your calendar app
- The permission error should be resolved

## Alternative (Temporary - NOT RECOMMENDED for production)
If you want to test quickly, you can temporarily use these rules (ONLY for testing):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Security Explanation
The recommended rules ensure that:
- Only authenticated users can access data
- Users can only read/write their own events (where createdBy matches their user ID)
- Users can only access their own user documents
- All other access is denied

This provides proper security while allowing your app to function correctly.

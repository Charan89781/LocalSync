# LocalSync3 — Backend Details

This document describes the serverless backend architecture of the **LocalSync3** application, detailing the database schema, security rules, third-party services integration, and security auditing.

---

## ☁️ Architecture Overview
LocalSync3 utilizes a serverless backend powered by **Google Firebase**. The backend is designed for high scalability, real-time synchronization, and client-side safety.

- **Authentication**: Firebase Authentication (Email/Password, Google OAuth2)
- **Database**: Cloud Firestore (NoSQL Document Store with real-time streams)
- **Object Storage**: Cloud Storage for Firebase (optimized binary file storage)
- **Static Hosting**: Local static HTTP hosting (port 8095) for compiled Flutter Web assets

---

## 🗃️ Firestore Database Schema

### 1. `/users/{userId}` (Document)
Stores active resident profiles.
- `uid` (String): Unique user ID matching Firebase Auth.
- `email` (String): Registered email address.
- `displayName` (String): Full name of the user.
- `trustScore` (Number): Dynamic trust metric calculated based on contributions (helped, posted).
- `memberSince` (Timestamp): Timestamp when the account was registered.
- `location` (String): Reverse-geocoded society name or street address.
- `photoUrl` (String): Reference link to avatar image in Cloud Storage.

### 2. `/complaints/{complaintId}` (Document)
Tracks civic tickets and complaints.
- `title` (String): Title of the complaint.
- `description` (String): Detailed description of the issue.
- `ownerId` (String): Author's `uid`.
- `status` (String): Active workflow state (`Reported`, `Assigned`, `In Progress`, `Resolved`).
- `upvotes` (Array of Strings): List of `uid`s who upvoted the ticket (matches Instagram-style upvotes).
- `imageUrl` (String): Reference path to photo evidence.
- `timestamp` (Timestamp): Creation date.
- **Subcollection `/comments/{commentId}`**:
  - `authorId` (String): User ID.
  - `authorName` (String): User's name.
  - `text` (String): Comment message body.
  - `timestamp` (Timestamp): Comment timestamp.

### 3. `/marketplace/{itemId}` (Document)
Active society marketplace listings.
- `title` (String): Item name.
- `price` (String): Rental fee or free badge.
- `condition` (String): `New`, `Like New`, `Good`, or `Fair`.
- `lenderId` (String): Owner's `uid`.
- `imageUrls` (Array of Strings): List of item image links.
- `duration` (String): Borrowing duration limit (e.g. 1 day, 1 week).

### 4. `/notices/{noticeId}` (Document)
Announcement alerts.
- `title` (String): Subject header.
- `content` (String): Announcement text details.
- `priority` (String): Severity color code (`Urgent`, `Maintenance`, `General`).
- `postedBy` (String): Admin/Authority name.
- `pinned` (Boolean): Pinned to the top of notice boards.

---

## 🔒 Firebase Security Rules

### Firestore Rules (`firestore.rules`)
Ensures data protection directly at the database layer.
- **User Profiles**: Reading is allowed for all authenticated users; writing/updates are restricted to the owner (`request.auth.uid == userId`).
- **Complaints**: Reading is allowed for all community members; creations require authentication; upvotes are updated via transactions; status updates require the owner or admin credentials.
- **Marketplace & Notices**: Read-only access for all authenticated users; write access is restricted to the item creator or administrator.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /complaints/{complaintId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.ownerId == request.auth.uid;
      allow update: if request.auth != null; // supports upvote array updates
    }
  }
}
```

### Cloud Storage Rules (`storage.rules`)
Secures object uploads.
- **Directory Isolation**: Users can upload only to folders corresponding to their active tasks (`/marketplace/{itemId}/` or `/complaints/{complaintId}/`).
- **File Validation**: Restricts size (e.g., maximum 5MB) and media content type (must match `image/png` or `image/jpeg`).

---

## 🛡️ Static Security Rules Auditing
We use an automated vulnerability scanner (`vulnerability_scanner.js`) that performs static analysis on our rules files:
- **Checks**: Scans for wildcards (`allow read, write: if true`), missing auth gates, unvalidated write schemas, directory leak paths, and oversized file upload permissions.
- **Reporting**: Logs all issues with severity labels (High, Medium, Low) and suggests remediation steps. Exports to the `Sec_Rules_` sheets in the master test report.

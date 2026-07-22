# Google Play Data Safety Declaration — AfriRange AI

This document details the exact responses required for the Google Play Console **Data Safety Form**.

## 1. Personal Information

* **Data Types Collected**:
  - Name (Personal Identifiers)
  - Email Address (Personal Identifiers)
* **Collected**: Yes
* **Shared**: No
* **Processed Ephemerally**: No
* **Required / Optional**: Required for Account Creation
* **Purposes**: Account Management, Authentication, Communication (Resend Receipts)
* **Encrypted in Transit**: Yes (HTTPS / TLS 1.3)
* **User Deletion Request Supported**: Yes (via in-app account deletion or API endpoint)

---

## 2. Location Data

* **Data Types Collected**:
  - Approximate Location (Coarse Location)
  - Precise Location (GPS Coordinates)
* **Collected**: Yes (Foreground only)
* **Shared**: No
* **Processed Ephemerally**: No
* **Required / Optional**: Optional / Feature-Dependent
* **Purposes**: Geospatial Farm & Paddock Boundary Mapping, CHIRPS Climate Alignment
* **Encrypted in Transit**: Yes (HTTPS / TLS 1.3)
* **User Deletion Request Supported**: Yes

---

## 3. Photos and Videos

* **Data Types Collected**:
  - Photos (Field botanical scans)
* **Collected**: Yes
* **Shared**: No (processed via OpenRouter AI for plant identification)
* **Processed Ephemerally**: No
* **Required / Optional**: Feature-Dependent (Botanical Identification)
* **Purposes**: Botanical Plant Species Identification & Veld Condition Assessment
* **Encrypted in Transit**: Yes (HTTPS / TLS 1.3)
* **User Deletion Request Supported**: Yes

---

## 4. Financial Information

* **Data Types Collected**:
  - Purchase History (In-App Subscriptions & AI Credit Packs)
* **Collected**: Yes (Billed via Google Play Billing)
* **Shared**: No
* **Purposes**: Account Functionality, Fraud Prevention, Subscription Management
* **Encrypted in Transit**: Yes (HTTPS / TLS 1.3)

---

## 5. App Activity & Performance

* **Data Types Collected**:
  - App Interactions, Diagnostics & Crash Logs
* **Collected**: Yes
* **Shared**: No
* **Purposes**: Analytics & App Quality Optimization
* **Encrypted in Transit**: Yes (HTTPS / TLS 1.3)

---

## 6. Security Practices

* **Data Encrypted in Transit**: Yes, all network traffic uses HTTPS (TLS 1.3).
* **Account Deletion Link**: Fulfills Google Play policy with in-app deletion and `DELETE /api/auth/delete-account`.

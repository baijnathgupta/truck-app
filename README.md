# Truck Trip Management V1

Stack:
- Backend: Node.js + Express + PostgreSQL
- Mobile: Flutter
- Admin: React + Vite

V1 includes:
- Owner/driver login
- Trucks
- Trips
- Driver expense requests
- Owner approval/rejection
- Monthly summary API
- Basic Flutter mobile screens
- Basic React admin dashboard

## Backend
cd backend
npm install
cp .env.example .env
npm run dev

## Database
Create PostgreSQL database `truck_trip` and run:
psql truck_trip < schema.sql

## Mobile
cd mobile
flutter pub get
flutter run

## Admin
cd admin
npm install
npm run dev

The API base URL is configurable in the Flutter app.

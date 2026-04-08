# Deployment Guide

## Backend First Strategy

1. Prepare Supabase schema and policies from migrations.
2. Validate RLS and storage behavior in Supabase dashboard.
3. Configure production frontend environment variables.
4. Deploy frontend only after backend checks pass.

## Required Production Checks

- Auth: sign up / sign in / sign out
- Profile access: own profile only, admin full-read
- Bookings/favorites isolation per user
- Owner-only property management
- Admin-only feedback and global stats access

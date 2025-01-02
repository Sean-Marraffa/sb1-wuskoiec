# BookingVibe - Rental Business Management Platform

## Current State

The project has a working foundation with the following core features implemented:

### Business Management

- Create and manage business profiles
- Update business information and settings
- Configure inventory categories
- Customize reservation status names
- Manage inventory items with quantities and pricing

### Team Management

- Invite team members via email
- Manage team member access
- Remove team members
- Revoke pending team member invites

### Database Migrations

The following migrations establish the core functionality:

1. `001_onboarding.sql`: Sets up business profiles and user authentication
2. `002_settings.sql`: Implements inventory categories and reservation settings
3. `003_team_management.sql`: Handles team member invitations and management
4. `004_inventory_management.sql`: Implements inventory management with items, quantities, and pricing

## Getting Started

1. Clone the repository
2. Install dependencies: `npm install`
3. Start the development server: `npm run dev`
4. Connect to Supabase using the "Connect to Supabase" button

## Tech Stack

- React + TypeScript
- Tailwind CSS
- Supabase (Database + Auth)
- Vite (Build tool)

## Next Steps

The following features are planned for implementation:

- [x] Inventory management
- [ ] Customer management
- [ ] Reservation system
- [ ] Billing and payments
- [ ] Analytics and reporting

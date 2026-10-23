## Product Releases

### v0.0 - Vertical Prototype
**[View release](https://github.com/UMAIA-CLASSROOM/es-development--es-26-cat1/tree/main/releases/v0.0/saude_app)**

Vertical prototype validating the core technology stack. Implements the **Landing Page** and **Login Screen** with the Supabase client initialised (`Supabase.initialize`), proving that Flutter can communicate with Supabase on both Android and Web targets. No real authentication calls are made at this stage - the focus was on confirming that the Flutter <-> Supabase connection was viable before building the full application. Contains 6 Dart files.

---

### v1.0 - Full UI (Frontend Only)
**[View release](https://github.com/UMAIA-CLASSROOM/es-development--es-26-cat1/tree/main/releases/v1.0/saude_app)**

Complete frontend implementation across all four portals (Patient, Doctor, Admin, Reception) and the public authentication flow. All screens are designed and navigable, with the visual templates and layout system in place. Data is mocked at this stage - no real Supabase queries are made. Covers the base UI for the majority of user stories. Contains 54 Dart files.

---

### v2.0 - Backend Integration
**[View release](https://github.com/UMAIA-CLASSROOM/es-development--es-26-cat1/tree/main/releases/v2.0/saude_app)**

Full Supabase backend integration: real authentication, JWT session management, and role-based routing across all four portals. Six user stories are connected to the live PostgreSQL database, with Row-Level Security policies applied. Introduces real appointment scheduling, patient management and document storage. Contains 66 Dart files.

---

### v3.0 - Final Release
**[View release](https://github.com/UMAIA-CLASSROOM/es-development--es-26-cat1/tree/main/releases/v3.0/saude_app)**

Production-ready release completing all Must Have and Should Have user stories. Adds Supabase Edge Functions (Deno) for asynchronous features: appointment cancellation notifications, document upload alerts, newsletter delivery and appointment reminders. All four portals are fully connected to the live database. Includes automated unit tests for the Doctor portal business logic. Contains 70 Dart files.
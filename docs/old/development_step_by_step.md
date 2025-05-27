# Development Plan: Economy Module - OnlyManager Platform

This document outlines a step-by-step plan for developing the Economy Module. It's divided into phases, with actionable tasks and checkboxes for tracking progress. This plan is based on the `project.md` requirements and the `backend_architecture_economy_module.md` design.

## Phase 1: Core Infrastructure & User/Model Management Foundation

**Goal:** Establish the foundational services, authentication, and basic user/model management capabilities necessary for other economy features.

*   **1.1. Project Setup & GCP Configuration:**
    *   ` - [ ] ` Set up a new Django project for the User & Model Management Service.
    *   ` - [ ] ` Configure PostgreSQL database on GCP Cloud SQL.
    *   ` - [ ] ` Set up Firebase project for Authentication.
    *   ` - [ ] ` Configure Cloud Pub/Sub topics for initial inter-service communication.
    *   ` - [ ] ` Set up Google Cloud Run deployment configurations for the first service.
    *   ` - [ ] ` Establish CI/CD pipeline basics.

*   **1.2. User & Model Management Service (Core Functionality):**
    *   ` - [ ] ` **Database Schema (`user_service`):**
        *   ` - [ ] ` Define `users` table (firebase_uid, email, role, name).
        *   ` - [ ] ` Define `models` table (name, associated_users).
        *   ` - [ ] ` Define `user_financial_settings` table (user_id, commission_rate, fixed_salary, manager_tick_rate).
        *   ` - [ ] ` Define `platform_settings` table (global_onlyfans_fee).
        *   ` - [ ] ` Define `model_specific_settings` table (model_id, split_chatting_costs_enabled).
    *   ` - [ ] ` **Authentication & Authorization:**
        *   ` - [ ] ` Integrate Firebase Authentication: Validate JWTs in Django.
            *   **Note for parallel development:** If Firebase Authentication is not yet ready, these complementary strategies allow you to proceed:
                *   **1. Use Local Django Authentication:** Employ Django's built-in session/token authentication for local development. Create dummy users (e.g., `dev_owner`, `dev_manager`) with appropriate roles directly in the Django database. This allows you to test API endpoints as different authenticated users.
                *   **2. Mock Firebase User Identity:** For development, simulate the specific user data (like Firebase User ID, email, and any custom role claims) that would typically come from the Firebase JWT. This can be achieved by having your development environment read mock data, potentially passed via custom HTTP headers (e.g., `X-Mock-Firebase-UID`, `X-Mock-Firebase-Roles`) or configured in a development-only middleware. This mocked identity complements the local Django user.
                *   **3. Abstract User Retrieval Logic:** Create a dedicated function or class (e.g., `get_current_user_profile(request)`) that is responsible for providing the authenticated user's details to the rest of your application. During development, this abstraction would use the mocked identity (from point 2). When Firebase is integrated, only this abstracted component needs to be updated to parse the real JWT, minimizing changes to your core service logic.
        *   ` - [ ] ` Implement basic Role-Based Access Control (RBAC) in Django (Owner, Manager, Chatter, Model roles) based on the user profile obtained via the abstracted retrieval logic (which will be mocked initially, then real).
    *   ` - [ ] ` **API Endpoints (DRF) & OpenAPI Documentation:**
        *   ` - [ ] ` **Setup OpenAPI Generation:** Integrate a library like `drf-spectacular` or `drf-yasg` into the Django project from the start. Configure it to automatically generate OpenAPI 3 documentation.
        *   ` - [ ] ` **Annotate Endpoints:** As API endpoints are developed, ensure developers use appropriate decorators and type hinting (for `drf-spectacular`) or docstrings (for `drf-yasg`) to provide metadata for request/response schemas, parameters, and descriptions. This metadata will be used for the auto-generated OpenAPI specification.
        *   ` - [ ] ` `POST /api/users/` (User creation - linked to Firebase Auth).
        *   ` - [ ] ` `GET /api/users/`, `GET /api/users/{id}/` (Read users).
        *   ` - [ ] ` `PUT /api/users/{id}/` (Update user details, roles).
        *   ` - [ ] ` `POST /api/models/` (Create models).
        *   ` - [ ] ` `GET /api/models/`, `GET /api/models/{id}/` (Read models).
        *   ` - [ ] ` `PUT /api/models/{id}/` (Update models).
        *   ` - [ ] ` API for assigning users to models.
        *   ` - [ ] ` API for Owners to set/update `user_financial_settings`.
        *   ` - [ ] ` API for Owners to set/update `platform_settings` (e.g., `global_onlyfans_fee`).
        *   ` - [ ] ` API for Owners to set/update `model_specific_settings` (e.g., `split_chatting_costs_enabled`).
    *   ` - [ ] ` **Events Published (Cloud Pub/Sub):**
        *   ` - [ ] ` `user.created`, `user.updated`
        *   ` - [ ] ` `model.created`, `model.updated`
        *   ` - [ ] ` `user.settings.updated`
        *   ` - [ ] ` `model.settings.updated`
        *   ` - [ ] ` `platform.settings.updated`
    *   ` - [ ] ` Deploy User & Model Management Service to Cloud Run.

## Phase 2: Income & Expense Management Services

**Goal:** Implement services for recording and managing all income and expenses.
**Reminder:** Continue to use the code-first OpenAPI generation approach (e.g., with `drf-spectacular`/`drf-yasg`) by annotating all new API endpoints, request/response models, and parameters for automatic documentation.

*   **2.1. Income Management Service:**
    *   ` - [ ] ` Set up Django project for Income Management Service.
    *   ` - [ ] ` **Database Schema (`income_service`):**
        *   ` - [ ] ` Define `income_records` table.
        *   ` - [ ] ` Define `income_types` table.
        *   ` - [ ] ` Define `recurring_income_schedules` table.
    *   ` - [ ] ` **API Endpoints (DRF):**
        *   ` - [ ] ` `POST /api/income/register/` (Handle different sale types, user roles, auto-detect registering user).
        *   ` - [ ] ` `GET /api/income/records/`, `GET /api/income/records/{id}/`.
        *   ` - [ ] ` `PUT /api/income/records/{id}/`, `DELETE /api/income/records/{id}/`.
        *   ` - [ ] ` CRUD for `recurring_income_schedules`.
    *   ` - [ ] ` **Business Logic:**
        *   ` - [ ] ` Input validation.
        *   ` - [ ] ` Link to registering user (from JWT).
        *   ` - [ ] ` Link to model (fetch model list from User & Model Service if needed, or rely on frontend to pass ID).
        *   ` - [ ] ` Logic for "other" income type (recurring, splitting).
    *   ` - [ ] ` **Events Published (Cloud Pub/Sub):**
        *   ` - [ ] ` `income.registered`.
    *   ` - [ ] ` Deploy Income Management Service to Cloud Run.

*   **2.2. Expense Management Service:**
    *   ` - [ ] ` Set up Django project for Expense Management Service.
    *   ` - [ ] ` **Database Schema (`expense_service`):**
        *   ` - [ ] ` Define `expenses` table.
        *   ` - [ ] ` Define `recurring_expense_schedules` table.
    *   ` - [ ] ` **API Endpoints (DRF):**
        *   ` - [ ] ` `POST /api/expenses/`.
        *   ` - [ ] ` `GET /api/expenses/`, `GET /api/expenses/{id}/`.
        *   ` - [ ] ` `PUT /api/expenses/{id}/`, `DELETE /api/expenses/{id}/`.
        *   ` - [ ] ` CRUD for `recurring_expense_schedules`.
    *   ` - [ ] ` **Business Logic:**
        *   ` - [ ] ` Input validation.
        *   ` - [ ] ` Recurring expense logic.
    *   ` - [ ] ` **Events Published (Cloud Pub/Sub):**
        *   ` - [ ] ` `expense.recorded`.
    *   ` - [ ] ` Deploy Expense Management Service to Cloud Run.

*   **2.3. Initial Frontend Integration & Testing (Simple UI):**
    *   ` - [ ] ` **Goal:** Develop a minimal frontend interface to interact with the User & Model Management and Income/Expense Management services. This allows for early testing, demonstration of core functionality, and feedback.
    *   ` - [ ] ` Choose a simple frontend stack (e.g., HTML, JavaScript with a library like Vue.js or React, or even a tool like Postman/Insomnia for structured API testing if a full UI is too early).
    *   ` - [ ] ` Implement basic UI for:
        *   ` - [ ] ` User login (mocked or using Firebase if ready).
        *   ` - [ ] ` Listing users and models (from User & Model Management Service).
        *   ` - [ ] ` Creating/viewing income records (from Income Management Service).
        *   ` - [ ] ` Creating/viewing expense records (from Expense Management Service).
    *   ` - [ ] ` Focus on functionality over aesthetics for this initial version.
    *   ` - [ ] ` Gather feedback for future frontend development iterations.

## Phase 3: Financial Calculation & Payout Service

**Goal:** Develop the core engine for calculating net income, commissions, salaries, and agency profit.
**Reminder:** Continue to use the code-first OpenAPI generation approach (e.g., with `drf-spectacular`/`drf-yasg`) by annotating all new API endpoints, request/response models, and parameters for automatic documentation.

*   **3.1. Financial Calculation & Payout Service:**
    *   ` - [ ] ` Set up Django project for Financial Calculation Service.
    *   ` - [ ] ` **Database Schema (`financial_calculations`):**
        *   ` - [ ] ` Define `calculated_payouts_summary` table.
        *   ` - [ ] ` (Optional) Define `transaction_ledger` table.
    *   ` - [ ] ` **Event Subscriptions (Cloud Pub/Sub):**
        *   ` - [ ] ` Subscribe to `income.registered`.
        *   ` - [ ] ` Subscribe to `expense.recorded`.
        *   ` - [ ] ` Subscribe to `user.settings.updated`.
        *   ` - [ ] ` Subscribe to `model.settings.updated`.
        *   ` - [ ] ` Subscribe to `platform.settings.updated`.
    *   ` - [ ] ` **Business Logic (Python/Django Commands or Celery tasks):**
        *   ` - [ ] ` Implement Net Income Calculation (Gross - OF Fee).
        *   ` - [ ] ` Implement Commission Calculation (based on NET, per-employee rates).
        *   ` - [ ] ` Implement Fixed Salary Application.
        *   ` - [ ] ` Implement Combined Salary & Commission Logic.
        *   ` - [ ] ` Implement Passive Manager Tick Calculation.
        *   ` - [ ] ` Implement "Split Chatting Costs" Logic.
        *   ` - [ ] ` Implement Agency Profit Calculation.
        *   ` - [ ] ` Store results in `calculated_payouts_summary`.
    *   ` - [ ] ` **API Endpoints (Optional - for triggering/status):**
        *   ` - [ ] ` `POST /api/financials/calculate/` (manual trigger).
        *   ` - [ ] ` `GET /api/financials/payouts/` (retrieve summaries).
    *   ` - [ ] ` **Events Published (Cloud Pub/Sub):**
        *   ` - [ ] ` `financial_calculation.completed` (Payload: summary or reference to summary).
    *   ` - [ ] ` Deploy Financial Calculation Service to Cloud Run/GKE.

## Phase 4: Statistics & Reporting Service

**Goal:** Create the service to aggregate data and provide financial statistics and trends.
**Reminder:** Continue to use the code-first OpenAPI generation approach (e.g., with `drf-spectacular`/`drf-yasg`) by annotating all new API endpoints, request/response models, and parameters for automatic documentation.

*   **4.1. Statistics & Reporting Service:**
    *   ` - [ ] ` Set up Django project for Statistics & Reporting Service.
    *   ` - [ ] ` **Database Schema (`statistics_service` - can use materialized views or aggregated tables):**
        *   ` - [ ] ` Define `daily_model_stats`, `daily_chatter_stats` (or similar for trend calculations).
    *   ` - [ ] ` **Event Subscriptions (Cloud Pub/Sub):**
        *   ` - [ ] ` Subscribe to `financial_calculation.completed`.
        *   ` - [ ] ` (Future) Subscribe to `model.subscriber_count.updated` (from external scraper via User/Model service).
    *   ` - [ ] ` **API Endpoints (DRF):**
        *   ` - [ ] ` `GET /api/stats/summary/` (Total income, expense, sales for period).
        *   ` - [ ] ` `GET /api/stats/top-earners/`.
        *   ` - [ ] ` `GET /api/stats/afv/` (Requires subscriber count input).
        *   ` - [ ] ` `GET /api/stats/trends/afv/`.
        *   ` - [ ] ` `GET /api/stats/trends/income/`.
    *   ` - [ ] ` **Business Logic:**
        *   ` - [ ] ` Data aggregation for specified periods.
        *   ` - [ ] ` AFV calculation (design for subscriber count input).
        *   ` - [ ] ` Trend calculation logic (daily, weekly, monthly % change).
        *   ` - [ ] ` Logic to fetch necessary data from other services if not event-driven (e.g., user names).
    *   ` - [ ] ` (Optional) API endpoint to receive subscriber count updates from external scraper.
    *   ` - [ ] ` Deploy Statistics & Reporting Service to Cloud Run.

## Phase 5: Time Tracking Service

**Goal:** Implement functionality for tracking employee time and adherence.
**Reminder:** Continue to use the code-first OpenAPI generation approach (e.g., with `drf-spectacular`/`drf-yasg`) by annotating all new API endpoints, request/response models, and parameters for automatic documentation.

*   **5.1. Time Tracking Service:**
    *   ` - [ ] ` Set up Django project for Time Tracking Service.
    *   ` - [ ] ` **Database Schema (`timetracking_service`):**
        *   ` - [ ] ` Define `time_entries` table.
        *   ` - [ ] ` (Future) Define `lateness_deductions_log` table.
    *   ` - [ ] ` **API Endpoints (DRF):**
        *   ` - [ ] ` `POST /api/timetracking/check-in/`.
        *   ` - [ ] ` `POST /api/timetracking/check-out/`.
        *   ` - [ ] ` `GET /api/timetracking/summary/{user_id}/`.
    *   ` - [ ] ` **Business Logic:**
        *   ` - [ ] ` Calculate lateness, missed check-ins/outs, overtime.
        *   ` - [ ] ` (Future) Logic for applying deduction rules (rules configured elsewhere).
    *   ` - [ ] ` **Events Published (Cloud Pub/Sub):**
        *   ` - [ ] ` `employee.time.event` (for significant events).
    *   ` - [ ] ` Deploy Time Tracking Service to Cloud Run.

## Phase 6: Integration, Testing, and Refinement

**Goal:** Ensure all services work together seamlessly, are thoroughly tested, and refined based on feedback.
**Reminder:** Ensure the code-first OpenAPI generation approach (e.g., with `drf-spectacular`/`drf-yasg`) has been consistently applied across all services and that documentation is accurate and complete.

*   **6.1. Inter-Service Communication & Integration Testing:**
    *   ` - [ ] ` Verify all Pub/Sub event publishing and subscriptions are working correctly.
    *   ` - [ ] ` Test end-to-end flows (e.g., income registration -> calculation -> statistics).
    *   ` - [ ] ` Test API integrations between services where direct calls are made.
*   **6.2. Comprehensive Testing:**
    *   ` - [ ] ` Unit tests for all business logic in each service.
    *   ` - [ ] ` Integration tests for API endpoints within each service.
    *   ` - [ ] ` Contract testing for Pub/Sub messages.
*   **6.3. Security Review:**
    *   ` - [ ] ` Ensure RBAC is correctly implemented and enforced across services.
    *   ` - [ ] ` Review data validation and sanitization.
    *   ` - [ ] ` Check for common API vulnerabilities.
*   **6.4. Performance Testing & Optimization:**
    *   ` - [ ] ` Identify and optimize slow database queries.
    *   ` - [ ] ` Test API response times under load.
    *   ` - [ ] ` Optimize calculation processes if necessary.
*   **6.5. Documentation Review & Updates:**
    *   ` - [ ] ` Ensure API documentation (e.g., Swagger/OpenAPI) is up-to-date for each service. This involves verifying that the **code-first approach** is correctly implemented: developers should be using specific decorators or annotations (e.g., with `drf-spectacular` or `drf-yasg` for Django REST Framework) in the Python code to provide metadata about API routes, parameters, and request/response models. The OpenAPI generation tools should then be correctly configured to use this metadata to automatically produce the `openapi.yaml` or `openapi.json` files. The generated documentation should be reviewed for accuracy and completeness.
    *   ` - [ ] ` Update `backend_architecture_economy_module.md` if any design changes occurred.
*   **6.6. Deployment Hardening:**
    *   ` - [ ] ` Configure proper logging and monitoring for all services on GCP.
    *   ` - [ ] ` Set up alerts for critical errors.
*   **6.7. User Acceptance Testing (UAT) Support:**
    *   ` - [ ] ` Provide support for frontend team or testers during UAT.
    *   ` - [ ] ` Address bugs and feedback from UAT.

This step-by-step plan provides a structured approach to developing the Economy Module. Each phase builds upon the previous one, allowing for iterative development and testing.

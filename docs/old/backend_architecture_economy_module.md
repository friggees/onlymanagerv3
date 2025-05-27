# Backend Architecture: Economy Module - OnlyManager Platform

## 1. Introduction

This document outlines the backend architecture for the "Economy Module" of the OnlyManager platform. This module is responsible for managing all financial aspects, including income registration, expense tracking, commission and salary calculations, and financial statistics.

The architecture adheres to the established tech stack:
*   **Core Language:** Python
*   **Framework:** Django REST Framework (DRF)
*   **Database:** PostgreSQL
*   **Cloud Provider:** Google Cloud Platform (GCP)
*   **Deployment:** Primarily Cloud Run for microservices, GKE as an option.
*   **Authentication:** Firebase Authentication with custom RBAC in Django.
*   **Messaging:** Cloud Pub/Sub for inter-service communication.
*   **Storage:** Google Cloud Storage (GCS).

## 2. Guiding Principles

*   **Microservices Architecture:** Each major functional area will be a distinct microservice, promoting scalability, independent development, and fault isolation.
*   **Stateless Services:** Services deployed on Cloud Run will be designed to be stateless where possible.
*   **Event-Driven:** Cloud Pub/Sub will be used for asynchronous communication between services.
*   **RESTful APIs & Documentation:** Django REST Framework will be used to build well-defined RESTful APIs for frontend consumption and inter-service communication. To ensure comprehensive and up-to-date API documentation, we will adopt a **code-first approach** for generating OpenAPI (Swagger) specifications. Developers will utilize specific decorators or annotations (e.g., with libraries like `drf-spectacular` or `drf-yasg` for DRF) directly within the Python code. These annotations will provide metadata about API routes, parameters, request/response models, etc. This metadata will then be used by tools to automatically generate the `openapi.yaml` or `openapi.json` files, keeping the documentation synchronized with the implementation.
*   **Data Integrity:** PostgreSQL will be leveraged for its relational capabilities and data integrity features.

## 3. Backend Microservices & Components

The Economy Module will be composed of several interconnected microservices:

### 3.1. Income Management Service

*   **Purpose:** Handles all aspects of income registration and management.
*   **Technology:** Python, Django REST Framework.
*   **Database (PostgreSQL Schema - `income_service`):**
    *   `income_records`: Stores individual income entries (gross amount, date, customer username, sale type, registered_by_user_id, model_id, notes, etc.).
    *   `income_types`: (e.g., 'message_sale', 'tip_sale', 'other_income').
    *   `recurring_income_schedules`: For "other" income (source, amount, frequency, day_of_month/week, assigned_to_user_id for splits, percentage/fixed_split_amount).
*   **API Endpoints (DRF):**
    *   `POST /api/income/register/`: Create a new income record. Logic to auto-detect registering user. Role-based validation for "other" income type.
    *   `GET /api/income/records/`: List income records with filtering (by user, model, date range, type).
    *   `GET /api/income/records/{id}/`: Retrieve a specific income record.
    *   `PUT /api/income/records/{id}/`: Update an income record.
    *   `DELETE /api/income/records/{id}/`: Delete an income record.
    *   `POST /api/income/recurring/`: Create a recurring income schedule.
    *   `GET /api/income/recurring/`: List recurring income schedules.
*   **Business Logic (Python/Django):**
    *   Validation of input data based on sale type and user role.
    *   Automatic linking of sales to the registering user (via Firebase JWT claims).
    *   Association with models (dropdown data likely fetched from User & Model Management Service).
    *   Handling of recurring income logic and splitting rules for "other" income.
*   **Events Published (Cloud Pub/Sub):**
    *   `income.registered`: When a new income record is successfully created. Payload: income record details.
*   **Deployment:** Google Cloud Run.

### 3.2. Expense Management Service

*   **Purpose:** Manages agency expenses.
*   **Technology:** Python, Django REST Framework.
*   **Database (PostgreSQL Schema - `expense_service`):**
    *   `expenses`: Stores expense records (amount, date, source, notes, is_recurring).
    *   `recurring_expense_schedules`: (source, amount, frequency, day_of_month/week).
*   **API Endpoints (DRF):**
    *   `POST /api/expenses/`: Create a new expense.
    *   `GET /api/expenses/`: List expenses with filtering.
    *   `PUT /api/expenses/{id}/`: Update an expense.
    *   `DELETE /api/expenses/{id}/`: Delete an expense.
    *   `POST /api/expenses/recurring/`: Create a recurring expense schedule.
*   **Business Logic (Python/Django):**
    *   Validation and storage of expense data.
    *   Handling of recurring expense logic.
*   **Events Published (Cloud Pub/Sub):**
    *   `expense.recorded`: When a new expense is recorded. Payload: expense details.
*   **Deployment:** Google Cloud Run.

### 3.3. Financial Calculation & Payout Service

*   **Purpose:** Performs all financial calculations, including net income, commissions, salaries, and agency profit. This service will likely operate based on events or scheduled tasks.
*   **Technology:** Python, Django (potentially using Django commands for batch processing or Celery if more complex background tasks are needed, triggered via Pub/Sub).
*   **Database (PostgreSQL - reads from other services, writes to its own `financial_calculations` schema):**
    *   Reads: `income_records` (Income Service), `user_settings` (User & Model Mgmt Service for commissions, salaries, OF_fee), `model_settings` (User & Model Mgmt for split_chatting_costs).
    *   `calculated_payouts_summary`: Stores aggregated payout information per user per period.
    *   `transaction_ledger` (optional): A detailed ledger of all financial movements for auditability.
*   **API Endpoints (DRF - optional, mainly for triggering or status checks):**
    *   `POST /api/financials/calculate/`: Trigger calculations for a specific period/user (could also be event-driven).
    *   `GET /api/financials/payouts/`: Retrieve payout summaries.
*   **Business Logic (Python):**
    *   **Net Income Calculation:** Gross Sales - (Gross Sales \* OnlyFans Fee %).
    *   **Commission Calculation:** Based on NET sales and per-employee commission rates.
    *   **Fixed Salary Application.**
    *   **Combined Salary & Commission Logic.**
    *   **Passive Manager Tick Calculation.**
    *   **"Split Chatting Costs" Logic:** Adjusts model and agency earnings based on chatter commission.
    *   **Agency Profit Calculation:** Net Income - Total Employee Payouts - Expenses.
*   **Events Subscribed (Cloud Pub/Sub):**
    *   `income.registered`
    *   `expense.recorded`
    *   `user.settings.updated` (from User & Model Management Service)
    *   `model.settings.updated` (from User & Model Management Service)
*   **Deployment:** Google Cloud Run (for simpler, event-driven calculations) or GKE (if complex, long-running batch jobs are required).

### 3.4. User & Model Management Service (Core Service)

*   **Purpose:** Manages user accounts, roles, model profiles, and their associated settings relevant to the economy module (commissions, salaries, OF fee).
*   **Technology:** Python, Django REST Framework.
*   **Database (PostgreSQL Schema - `user_service`):**
    *   `users`: (firebase_uid, email, role, name, etc.).
    *   `models`: (name, associated_users, subscriber_count_last_known - updated by external scraper).
    *   `user_financial_settings`: (user_id, commission_rate, fixed_salary, manager_tick_rate, etc.).
    *   `platform_settings`: (e.g., global_onlyfans_fee - adjustable by Owner).
    *   `model_specific_settings`: (model_id, split_chatting_costs_enabled).
*   **Authentication & Authorization:**
    *   **Firebase Authentication:** Handles user sign-up, sign-in, and issues JWTs.
    *   **Django/DRF:** Custom RBAC (Role-Based Access Control) using Django's permission system to enforce access rules (e.g., Owner can set fees, Manager sees assigned chatters). JWTs from Firebase will be validated.
*   **API Endpoints (DRF):**
    *   CRUD for users, models.
    *   Endpoints for assigning users to models.
    *   Endpoints for Owners to set/update `user_financial_settings`, `platform_settings`, `model_specific_settings`.
*   **Events Published (Cloud Pub/Sub):**
    *   `user.settings.updated`: When financial settings for a user change.
    *   `model.settings.updated`: When settings like `split_chatting_costs` change for a model.
    *   `platform.settings.updated`: When global settings like OF fee change.
*   **Deployment:** Google Cloud Run.

### 3.5. Statistics & Reporting Service

*   **Purpose:** Aggregates data and calculates key performance indicators (KPIs) for display on the statistics page.
*   **Technology:** Python, Django REST Framework.
*   **Database (PostgreSQL - reads from other services, potentially uses materialized views or its own aggregated tables in `statistics_service` schema):**
    *   Reads: `income_records`, `expenses`, `calculated_payouts_summary`, `users`, `models`.
    *   `daily_model_stats`, `daily_chatter_stats`: Pre-aggregated tables for faster trend calculations.
*   **API Endpoints (DRF):**
    *   `GET /api/stats/summary/`: Fetch total income, expenses, sales count for a period.
    *   `GET /api/stats/top-earners/`: Fetch top 5 earners for a period.
    *   `GET /api/stats/afv/`: Fetch Average Fan Value (per model, per chatter) for a period.
    *   `GET /api/stats/trends/afv/`: Fetch AFV trends.
    *   `GET /api/stats/trends/income/`: Fetch income trends.
*   **Business Logic (Python/Django):**
    *   Data aggregation based on specified period ranges.
    *   Calculation of Total Income, Total Expense, Total Sales.
    *   Top Earner identification.
    *   AFV Calculation: (Total Net Earnings / Total Subscriber Count). Subscriber count for models will be ingested (e.g., via an API endpoint this service exposes for the external scraper, or by periodically querying the User & Model service).
    *   Trend Calculation: Daily, weekly, monthly percentage changes based on historical data.
*   **Events Subscribed (Cloud Pub/Sub):**
    *   `financial_calculation.completed` (from Financial Calculation Service)
    *   `model.subscriber_count.updated` (event potentially published by User & Model service when scraper updates count)
*   **Deployment:** Google Cloud Run.

### 3.6. Time Tracking Service

*   **Purpose:** Records employee check-in/out times and calculates adherence metrics.
*   **Technology:** Python, Django REST Framework.
*   **Database (PostgreSQL Schema - `timetracking_service`):**
    *   `time_entries`: (user_id, check_in_time, check_out_time, expected_shift_start, expected_shift_end).
    *   `lateness_deductions_log` (future): To log deductions based on rules.
*   **API Endpoints (DRF):**
    *   `POST /api/timetracking/check-in/`: Record a check-in.
    *   `POST /api/timetracking/check-out/`: Record a check-out.
    *   `GET /api/timetracking/summary/{user_id}/`: Get time tracking summary for a user (total late minutes, missed shifts).
*   **Business Logic (Python/Django):**
    *   Calculate lateness, missed check-ins/outs, overtime.
    *   (Future) Logic for applying deduction rules (rules themselves configured via a settings interface, likely in User & Model Management Service).
*   **Events Published (Cloud Pub/Sub):**
    *   `employee.time.event`: When a significant time event occurs (e.g., missed shift, excessive lateness) that might trigger notifications or affect payroll.
*   **Deployment:** Google Cloud Run.

## 4. Inter-Service Communication

*   **Cloud Pub/Sub:** Will be the primary mechanism for asynchronous, event-driven communication between microservices. This decouples services and improves resilience.
    *   Example Flow: Income Service publishes `income.registered` -> Financial Calculation Service subscribes and processes.
*   **Direct API Calls (Synchronous):** To be used sparingly, only when an immediate response is required and the services are tightly coupled for that specific operation. Prefer asynchronous communication.

## 5. Data Storage

*   **PostgreSQL:** The primary relational database for all services. Each service might have its own schema within a shared PostgreSQL instance, or separate databases if stronger isolation is needed (manageable via GCP Cloud SQL).
*   **Google Cloud Storage (GCS):** For storing any static files, exported reports (e.g., PDFs of financial summaries), or media, though less directly used by the core economy calculations.

## 6. Scalability and Deployment

*   **Google Cloud Run:** Ideal for deploying stateless Django DRF microservices. It offers auto-scaling and pay-per-use, simplifying management.
*   **Google Kubernetes Engine (GKE):** An option for services with more complex stateful requirements, long-running background tasks, or if finer-grained orchestration is needed.
*   **Database Scaling:** GCP Cloud SQL for PostgreSQL offers managed scaling and high availability.

## 7. Future Integration Points

The modular design will facilitate:
*   **Settings Page:** A dedicated frontend/backend component (potentially part of User & Model Management or a separate Admin Service) will interact with various services via their APIs to update configurable parameters (OF fee, commission rates, etc.).
*   **Employee Management:** Broader employee management features will integrate with the User & Model Management Service.
*   **External AFV Scraper:** The scraper will feed subscriber data into the system, likely via an API endpoint exposed by the Statistics & Reporting Service or the User & Model Management Service.

This architecture provides a scalable, maintainable, and robust backend for the OnlyManager platform's economy module, leveraging the strengths of the chosen tech stack.

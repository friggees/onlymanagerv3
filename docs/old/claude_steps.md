# Optimized Development Plan: Economy Module - OnlyManager Platform (Supabase + MCP Tools)

This plan leverages Supabase MCP (Model Context Protocol) tools for seamless development directly in VSCode with Cline AI, enabling rapid iteration cycles and immediate testing with direct Supabase integration.

## Phase 1: Foundation & MVP Income Registration

**Goal:** Establish core infrastructure and implement basic income registration using MCP tools for direct Supabase manipulation.

### 1.1. Project Setup & Infrastructure Analysis

- [x] **Initial Project Assessment:**
  - [x] Use `get_project_url` to confirm project API endpoint
  - [x] Use `get_anon_key` to retrieve anonymous API key for client setup
  - [x] Use `list_tables` to assess current database schema state
  - [x] Use `list_extensions` to verify required PostgreSQL extensions
  - [x] Use `list_migrations` to understand current migration state

- [~] **Development Branch Setup:** 
      **(DO LATER WITH MVP)**
  - [~] Use `create_branch` with name "economy-module-mvp" for isolated development
  - [~] Switch all subsequent MCP operations to the development branch
  - [~] This ensures production safety during development

### 1.2. Core Database Schema Implementation

- [x] **User Management Schema (Using MCP apply_migration):**
  ```sql
  -- Use apply_migration with name: "create_user_profiles_and_rbac"
  ```
  - [x] `apply_migration` to create user_profiles table linked to auth.users
  - [x] `apply_migration` to create models table with proper constraints
  - [x] `apply_migration` to create user_model_assignments with foreign keys
  - [x] `apply_migration` to create user_financial_settings table
  - [x] `apply_migration` to create platform_settings table
  - [x] `apply_migration` to create model_specific_settings table

- [x] **Row Level Security Implementation:**
  ```sql
  -- Use apply_migration with name: "implement_rls_policies"
  ```
  - [x] `apply_migration` to enable RLS on all user-facing tables
  - [x] `apply_migration` to create role-based access policies
  - [x] `apply_migration` to create user assignment filtering policies
  - [~] Use `execute_sql` to test RLS policies with different user contexts

- [ ] **Verification Steps:**
  - [ ] Use `list_tables` to confirm all tables are created
  - [ ] Use `execute_sql` to run test queries verifying RLS policies
  - [ ] Use `generate_typescript_types` to create TypeScript definitions for frontend

### 1.3. Income Registration Database Schema

- [ ] **Income Tables Creation:**
  ```sql
  -- Use apply_migration with name: "create_income_tracking_schema"
  ```
  - [ ] `apply_migration` to create income_records table with proper indexing
  - [ ] `apply_migration` to create income_types lookup table
  - [ ] `apply_migration` to create recurring_income_schedules table
  - [ ] `apply_migration` to add foreign key constraints and triggers

- [ ] **Schema Validation:**
  - [ ] Use `execute_sql` to insert test data for each table
  - [ ] Use `execute_sql` to verify constraints and relationships
  - [ ] Use `list_tables` with schemas parameter to confirm structure

### 1.4. Edge Functions for Income Registration

- [ ] **Core Income Functions Deployment:**
  - [ ] `deploy_edge_function` with name "register-income":
    ```typescript
    // Income registration with auto-user detection and role validation
    ```
  - [ ] `deploy_edge_function` with name "get-income-records":
    ```typescript
    // Income retrieval with RLS filtering and pagination
    ```
  - [ ] `deploy_edge_function` with name "update-income-record":
    ```typescript
    // Income updates with audit logging
    ```
  - [ ] `deploy_edge_function` with name "delete-income-record":
    ```typescript
    // Soft delete with proper authorization
    ```

- [ ] **Function Testing & Debugging:**
  - [ ] Use `list_edge_functions` to verify all functions are deployed
  - [ ] Use `get_logs` with service "edge" to debug function execution
  - [ ] Use `execute_sql` to verify database changes from function calls

### 1.5. Basic Financial Calculations Engine

- [ ] **Calculation Tables Schema:**
  ```sql
  -- Use apply_migration with name: "create_financial_calculation_tables"
  ```
  - [ ] `apply_migration` to create calculated_payouts table
  - [ ] `apply_migration` to create calculation_logs for audit trail
  - [ ] `apply_migration` to add database triggers for auto-calculation

- [ ] **Financial Calculation Functions:**
  - [ ] `deploy_edge_function` with name "calculate-financial-payouts":
    ```typescript
    // Core financial calculation logic
    ```
  - [ ] `deploy_edge_function` with name "get-financial-summary":
    ```typescript
    // Retrieve calculation results with RLS
    ```
  - [ ] `deploy_edge_function` with name "trigger-recalculation":
    ```typescript
    // Manual recalculation trigger for testing
    ```

- [ ] **Integration Testing:**
  - [ ] Use `execute_sql` to insert test income data
  - [ ] Use `get_logs` to verify calculation function execution
  - [ ] Use `execute_sql` to validate calculation results

### 1.6. Minimal Next.js Testing Setup

- [ ] **Type Generation & Basic Client Setup:**
  - [ ] Use `generate_typescript_types` to create database types for frontend dev
  - [ ] Create minimal Next.js test app with Supabase client integration
  - [ ] Set up basic authentication flow (login/logout only)

- [ ] **Essential Backend Validation:**
  - [ ] Create single test page for income registration API validation
  - [ ] Test Edge Function calls with proper authentication headers
  - [ ] Validate RLS policies work correctly with authenticated users
  - [ ] Use `get_logs` with service "api" to debug client-server communication
  - [ ] Use `execute_sql` to verify data flow from test calls to database

- [ ] **Integration Validation (No UI Polish Needed):**
  - [ ] Confirm Supabase auth works with Next.js client
  - [ ] Verify Edge Functions respond correctly to authenticated requests
  - [ ] Test that generated TypeScript types work with frontend calls
  - [ ] Document API patterns for frontend developer handoff

**Phase 1 Deliverable:** Working income registration system with MCP-managed database schema and Edge functions, validated through minimal Next.js testing to ensure frontend developer integration readiness.

## Phase 2: Complete Financial Engine & Expense Management

**Goal:** Implement comprehensive financial calculations and expense tracking with advanced MCP-managed database operations.

### 2.1. Advanced Financial Calculation Schema

- [ ] **Enhanced Calculation Tables:**
  ```sql
  -- Use apply_migration with name: "enhance_financial_calculations"
  ```
  - [ ] `apply_migration` to add advanced calculation fields
  - [ ] `apply_migration` to create commission_calculation_logs table
  - [ ] `apply_migration` to add database functions for complex calculations
  - [ ] `apply_migration` to create materialized views for performance

### 2.2. Expense Management Implementation

- [ ] **Expense Schema Creation:**
  ```sql
  -- Use apply_migration with name: "create_expense_management_schema"
  ```
  - [ ] `apply_migration` to create expenses table with proper categorization
  - [ ] `apply_migration` to create recurring_expense_schedules table
  - [ ] `apply_migration` to add expense approval workflow tables
  - [ ] `apply_migration` to implement expense RLS policies

- [ ] **Expense Management Edge Functions:**
  - [ ] `deploy_edge_function` with name "create-expense":
    ```typescript
    // Expense creation with role-based validation
    ```
  - [ ] `deploy_edge_function` with name "get-expenses":
    ```typescript
    // Expense retrieval with filtering and RLS
    ```
  - [ ] `deploy_edge_function` with name "process-recurring-expenses":
    ```typescript
    // Automated recurring expense processing
    ```

### 2.3. Advanced Edge Functions Deployment

- [ ] **Enhanced Financial Functions:**
  - [ ] `deploy_edge_function` with name "calculate-combined-payouts":
    ```typescript
    // Salary + commission calculations
    ```
  - [ ] `deploy_edge_function` with name "process-manager-ticks":
    ```typescript
    // Passive manager tick calculations
    ```
  - [ ] `deploy_edge_function` with name "split-chatting-costs":
    ```typescript
    // Split chatting cost calculations
    ```

- [ ] **Frontend Integration Validation:**
  - [ ] Use `generate_typescript_types` to update frontend types after schema changes
  - [ ] Test enhanced Edge Functions with minimal Next.js calls
  - [ ] Validate complex calculation results through authenticated API calls
  - [ ] Document new API endpoints for frontend developer

### 2.4. Database Performance Optimization

- [ ] **Performance Enhancements:**
  ```sql
  -- Use apply_migration with name: "optimize_database_performance"
  ```
  - [ ] `apply_migration` to add strategic database indexes
  - [ ] `apply_migration` to create materialized views for reports
  - [ ] `apply_migration` to add database partitioning for large tables
  - [ ] Use `execute_sql` to analyze query performance

**Phase 2 Deliverable:** Complete financial calculation engine with expense management, validated through minimal Next.js testing and optimized for seamless frontend developer integration.

## Phase 3: Statistics & Reporting Engine

**Goal:** Build comprehensive analytics using MCP tools for optimal database design and Edge function deployment.

### 3.1. Statistics Database Architecture

- [ ] **Analytics Schema Implementation:**
  ```sql
  -- Use apply_migration with name: "create_analytics_and_reporting_schema"
  ```
  - [ ] `apply_migration` to create daily_stats table with partitioning
  - [ ] `apply_migration` to create calculated_trends table
  - [ ] `apply_migration` to add time-series optimizations
  - [ ] `apply_migration` to create aggregation triggers

### 3.2. AFV (Average Fan Value) System

- [ ] **AFV Database Schema:**
  ```sql
  -- Use apply_migration with name: "implement_afv_tracking_system"
  ```
  - [ ] `apply_migration` to create model_subscriber_counts table
  - [ ] `apply_migration` to create afv_calculations table
  - [ ] `apply_migration` to add AFV calculation triggers

- [ ] **AFV Edge Functions:**
  - [ ] `deploy_edge_function` with name "update-subscriber-count":
    ```typescript
    // External API integration for subscriber updates
    ```
  - [ ] `deploy_edge_function` with name "calculate-afv-trends":
    ```typescript
    // AFV trend analysis and calculations
    ```

### 3.3. Advanced Analytics Edge Functions

- [ ] **Statistics & Reporting Functions:**
  - [ ] `deploy_edge_function` with name "get-summary-statistics":
    ```typescript
    // Comprehensive summary statistics with RLS
    ```
  - [ ] `deploy_edge_function` with name "get-top-earners":
    ```typescript
    // Top performers analysis
    ```
  - [ ] `deploy_edge_function` with name "calculate-trends":
    ```typescript
    // Trend calculations using PostgreSQL window functions
    ```
  - [ ] `deploy_edge_function` with name "generate-reports":
    ```typescript
    // Custom report generation with export capabilities
    ```

- [ ] **Next.js Integration Testing:**
  - [ ] Test analytics Edge Functions with authenticated Next.js calls
  - [ ] Validate complex reporting data flows work correctly
  - [ ] Use `generate_typescript_types` to ensure frontend gets updated analytics types
  - [ ] Create API documentation and examples for frontend developer

- [ ] **Performance Monitoring:**
  - [ ] Use `get_logs` with service "edge" to monitor analytics function performance
  - [ ] Use `execute_sql` to verify statistical calculation accuracy
  - [ ] Test that large datasets don't break frontend API calls

**Phase 3 Deliverable:** Comprehensive analytics engine with AFV tracking and trend analysis, fully managed through MCP tools.

## Phase 4: Time Tracking System Implementation

**Goal:** Deploy time tracking and adherence monitoring using MCP tools for database schema and Edge function management.

### 4.1. Time Tracking Database Schema

- [ ] **Time Tracking Schema Creation:**
  ```sql
  -- Use apply_migration with name: "create_time_tracking_system"
  ```
  - [ ] `apply_migration` to create time_entries table with proper indexing
  - [ ] `apply_migration` to create shift_schedules table
  - [ ] `apply_migration` to create adherence_metrics table
  - [ ] `apply_migration` to add time tracking constraints and triggers

### 4.2. Time Tracking Edge Functions

- [ ] **Core Time Tracking Functions:**
  - [ ] `deploy_edge_function` with name "check-in-user":
    ```typescript
    // User check-in with geolocation and validation
    ```
  - [ ] `deploy_edge_function` with name "check-out-user":
    ```typescript
    // User check-out with automatic adherence calculation
    ```
  - [ ] `deploy_edge_function` with name "get-time-summary":
    ```typescript
    // Time summary and adherence reporting
    ```

### 4.3. Adherence Monitoring System

- [ ] **Adherence Calculation Functions:**
  - [ ] `deploy_edge_function` with name "calculate-adherence-metrics":
    ```typescript
    // Real-time adherence calculations
    ```
  - [ ] `deploy_edge_function` with name "detect-missing-checkouts":
    ```typescript
    // Automated detection of incomplete time entries
    ```

- [ ] **Integration Testing:**
  - [ ] Use `execute_sql` to create test time entries
  - [ ] Use `get_logs` to verify adherence calculation accuracy
  - [ ] Use `generate_typescript_types` to update frontend types

**Phase 4 Deliverable:** Complete time tracking system with real-time adherence monitoring, deployed via MCP tools.

## Phase 5: Production Optimization & Branch Management

**Goal:** Optimize the system for production and implement proper branch management using MCP tools.

### 5.1. Production Preparation

- [ ] **Database Optimization:**
  ```sql
  -- Use apply_migration with name: "production_optimization"
  ```
  - [ ] `apply_migration` to add production-grade indexes
  - [ ] `apply_migration` to implement database constraints for data integrity
  - [ ] `apply_migration` to add audit logging for all critical operations
  - [ ] Use `execute_sql` to run performance analysis queries

### 5.2. Edge Function Optimization

- [ ] **Function Performance Enhancement:**
  - [ ] `deploy_edge_function` updates for all functions with performance optimizations
  - [ ] Add error handling and retry logic to all Edge functions
  - [ ] Implement caching strategies in Edge functions
  - [ ] Use `get_logs` to monitor production performance metrics

### 5.3. Security & Access Control Enhancement

- [ ] **Advanced Security Implementation:**
  ```sql
  -- Use apply_migration with name: "enhance_security_controls"
  ```
  - [ ] `apply_migration` to strengthen RLS policies
  - [ ] `apply_migration` to add audit trails for sensitive operations
  - [ ] `apply_migration` to implement rate limiting at database level
  - [ ] Use `execute_sql` to test security policies thoroughly

### 5.4. Branch Management & Deployment

- [ ] **Development Branch Testing:**
  - [ ] Use `list_branches` to verify branch status
  - [ ] Complete comprehensive testing on development branch
  - [ ] Use `get_logs` to ensure no errors in branch testing

- [ ] **Production Deployment:**
  - [ ] Use `merge_branch` to deploy tested changes to production
  - [ ] Use `list_migrations` to verify all migrations applied successfully
  - [ ] Use `generate_typescript_types` for final type generation
  - [ ] Monitor production deployment with `get_logs`

**Phase 5 Deliverable:** Production-ready system with optimized performance and secure deployment via branch management.

## Phase 6: Advanced Analytics & Automation

**Goal:** Implement advanced features and automation using MCP tools for comprehensive system management.

### 6.1. Advanced Analytics Database

- [ ] **Enhanced Analytics Schema:**
  ```sql
  -- Use apply_migration with name: "advanced_analytics_features"
  ```
  - [ ] `apply_migration` to create advanced reporting tables
  - [ ] `apply_migration` to implement data warehousing structures
  - [ ] `apply_migration` to add machine learning preparation tables
  - [ ] Use `execute_sql` to validate complex analytical queries

### 6.2. Automation & Scheduled Functions

- [ ] **Automated Processing Functions:**
  - [ ] `deploy_edge_function` with name "automated-month-end-processing":
    ```typescript
    // Automated month-end calculations and reports
    ```
  - [ ] `deploy_edge_function` with name "system-health-monitor":
    ```typescript
    // System monitoring and alerting
    ```
  - [ ] `deploy_edge_function` with name "data-backup-processor":
    ```typescript
    // Automated data backup and archiving
    ```

### 6.3. System Monitoring & Maintenance

- [ ] **Continuous Monitoring Setup:**
  - [ ] Use `get_logs` with all services to establish monitoring baselines
  - [ ] Set up automated health checks using Edge functions
  - [ ] Use `execute_sql` for database health monitoring queries

- [ ] **Maintenance Procedures:**
  - [ ] Create `reset_branch` procedures for development branch refresh
  - [ ] Use `rebase_branch` for keeping development branches current
  - [ ] Establish `delete_branch` procedures for cleanup

**Phase 6 Deliverable:** Fully automated system with advanced analytics and comprehensive monitoring via MCP tools.

---

## MCP Tools Integration Summary:

### Database Management:
- **`list_tables`**: Schema verification and structure analysis
- **`apply_migration`**: All DDL operations and schema changes
- **`execute_sql`**: Testing, validation, and data operations
- **`list_migrations`**: Migration tracking and history

### Edge Function Management:
- **`deploy_edge_function`**: All serverless function deployments
- **`list_edge_functions`**: Function inventory and verification
- **`get_logs`**: Function debugging and performance monitoring

### Development Workflow:
- **`create_branch`**: Isolated development environments
- **`merge_branch`**: Production deployments
- **`reset_branch`**: Development branch maintenance
- **`rebase_branch`**: Keeping branches synchronized
- **`delete_branch`**: Cleanup and maintenance

### Project Management:
- **`generate_typescript_types`**: Frontend integration
- **`get_project_url`** & **`get_anon_key`**: Configuration management
- **`list_extensions`**: Database capability verification

## Key Advantages of MCP Tool Integration:

1. **Direct Supabase Control**: No context switching between tools
2. **Version Control Integration**: Branch-based development workflow
3. **Real-time Debugging**: Immediate log access for troubleshooting
4. **Type Safety**: Automatic TypeScript generation
5. **Safe Deployment**: Branch testing before production merge
6. **Comprehensive Monitoring**: Built-in logging and performance tracking
7. **Automated Workflows**: Seamless CI/CD through MCP commands

## Critical Success Factors with MCP Tools:

- Always use development branches for new features (`create_branch`)
- Verify deployments with `list_edge_functions` and `list_tables`
- Monitor performance with `get_logs` throughout development
- Test thoroughly before `merge_branch` to production
- Use `generate_typescript_types` after schema changes
- Maintain clean migration history with descriptive names
- Leverage `execute_sql` for comprehensive testing scenarios
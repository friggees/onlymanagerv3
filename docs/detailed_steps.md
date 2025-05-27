# OnlyManager: Detailed Phase-by-Phase Implementation Plan

## Pre-Phase: Fresh Start Setup

### P.1 Clean Slate Preparation
- [x] **Reset Supabase Project** (if needed)
  - [x] Backup any important data/configurations
  - [x] Reset database to clean state
  - [x] Verify clean slate with `list_tables`
  - [x] Verify clean migrations with `list_migrations`

- [x] **Project Verification**
  - [x] Run `get_project_url` - Record project URL
  - [x] Run `get_anon_key` - Record anon key for testing
  - [x] Run `list_extensions` - Verify pgcrypto, uuid-ossp available
  - [x] Document all credentials in secure location

**Checkpoint P.1**: ✅ Clean Supabase project ready for development

---

## Phase 1: Foundation & Core User Management

### 1.1 Database Schema Foundation

#### 1.1.1 Core Tables Creation
- [x] **Create `user_profiles` table**
  ```sql
  -- Migration: "01_create_user_profiles"
  CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    role TEXT CHECK (role IN ('owner', 'manager', 'chatter', 'model')) NOT NULL,
    telegram_username TEXT,
    contract_document_path TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```
  - [x] Apply migration with `apply_migration`
  - [x] Verify with `list_tables`
  - [x] Test basic insert with `execute_sql`

#### 1.1.2 Models Management Table
- [x] **Create `models` table**
  ```sql
  -- Migration: "02_create_models"
  CREATE TABLE public.models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES public.user_profiles(id),
    name TEXT NOT NULL,
    platform_fee_percentage DECIMAL(5,2) DEFAULT 20.00,
    split_chatting_costs BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```
  - [x] Apply migration
  - [x] Verify table structure
  - [x] Test foreign key constraints work

#### 1.1.3 User-Model Assignments
- [x] **Create `user_model_assignments` table**
  ```sql
  -- Migration: "03_create_user_model_assignments"
  CREATE TABLE public.user_model_assignments (
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    model_id UUID REFERENCES public.models(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, model_id)
  );
  
  CREATE INDEX idx_user_model_assignments_model_id ON public.user_model_assignments(model_id);
  CREATE INDEX idx_user_model_assignments_user_id ON public.user_model_assignments(user_id);
  ```
  - [x] Apply migration
  - [x] Test many-to-many relationship
  - [x] Verify indexes created

#### 1.1.4 Financial Settings
- [x] **Create salary structure enum and financial settings**
  ```sql
  -- Migration: "04_create_financial_settings"
  CREATE TYPE salary_structure_type AS ENUM (
    'commission_only',
    'fixed_only', 
    'fixed_plus_commission',
    'passive_tick_only'
  );
  
  CREATE TABLE public.user_financial_settings (
    user_id UUID PRIMARY KEY REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    commission_percentage DECIMAL(5,2),
    fixed_salary_amount DECIMAL(10,2),
    salary_type salary_structure_type NOT NULL,
    manager_passive_tick_percentage DECIMAL(5,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraint to ensure financial settings consistency
    CONSTRAINT check_financial_settings_consistency CHECK (
      (salary_type = 'commission_only' AND commission_percentage IS NOT NULL) OR
      (salary_type = 'fixed_only' AND fixed_salary_amount IS NOT NULL) OR
      (salary_type = 'fixed_plus_commission' AND commission_percentage IS NOT NULL AND fixed_salary_amount IS NOT NULL) OR
      (salary_type = 'passive_tick_only' AND manager_passive_tick_percentage IS NOT NULL)
    )
  );
  ```
  - [x] Apply migration
  - [x] Test constraint validation with various scenarios
  - [x] Verify enum type created

#### 1.1.5 Platform Configuration
- [x] **Create platform settings (singleton table)**
  ```sql
  -- Migration: "05_create_platform_settings"
  CREATE TABLE public.platform_settings (
    id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    default_platform_fee_percentage DECIMAL(5,2) DEFAULT 20.00,
    currency_symbol TEXT DEFAULT '$',
    currency_code TEXT DEFAULT 'USD',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
  );
  
  -- Insert default row
  INSERT INTO public.platform_settings DEFAULT VALUES;
  ```
  - [x] Apply migration
  - [x] Verify singleton constraint (try inserting second row - should fail)
  - [x] Test default values are set

#### 1.1.6 Model-Specific Settings
- [x] **Create model-specific overrides**
  ```sql
  -- Migration: "06_create_model_specific_settings"
  CREATE TABLE public.model_specific_settings (
    model_id UUID PRIMARY KEY REFERENCES public.models(id) ON DELETE CASCADE,
    platform_fee_percentage DECIMAL(5,2), -- Override for this model
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```
  - [x] Apply migration
  - [x] Test foreign key relationship
  - [x] Verify optional override behavior

**Checkpoint 1.1**: ✅ All core tables created with proper constraints and relationships

### 1.2 Essential Database Functions and Triggers

#### 1.2.1 Updated Timestamp Triggers
- [x] **Create updated_at trigger function**
  ```sql
  -- Migration: "07_create_updated_at_triggers"
  CREATE OR REPLACE FUNCTION public.update_updated_at_column()
  RETURNS TRIGGER AS $$
  BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
  END;
  $$ language 'plpgsql';
  
  -- Apply to all tables with updated_at
  CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  CREATE TRIGGER update_models_updated_at BEFORE UPDATE ON public.models FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  CREATE TRIGGER update_user_financial_settings_updated_at BEFORE UPDATE ON public.user_financial_settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  CREATE TRIGGER update_platform_settings_updated_at BEFORE UPDATE ON public.platform_settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  CREATE TRIGGER update_model_specific_settings_updated_at BEFORE UPDATE ON public.model_specific_settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  ```
  - [x] Apply migration
  - [x] Test triggers by updating records and checking updated_at changes

#### 1.2.2 Role Escalation Prevention Trigger
- [x] **Create role protection trigger**
  ```sql
  -- Migration: "08_create_role_protection_trigger"
  CREATE OR REPLACE FUNCTION public.prevent_role_escalation()
  RETURNS TRIGGER AS $$
  BEGIN
    -- If role is being changed
    IF OLD.role IS DISTINCT FROM NEW.role THEN
      -- Only owners can change roles
      IF (SELECT role FROM public.user_profiles WHERE id = auth.uid()) != 'owner' THEN
        RAISE EXCEPTION 'Only owners can change user roles';
      END IF;
      
      -- Prevent escalation to owner by non-owners
      IF NEW.role = 'owner' AND (SELECT role FROM public.user_profiles WHERE id = auth.uid()) != 'owner' THEN
        RAISE EXCEPTION 'Cannot escalate to owner role';
      END IF;
    END IF;
    
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;
  
  CREATE TRIGGER user_profiles_role_protection
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.prevent_role_escalation();
  ```
  - [x] Apply migration
  - [x] Test role change attempts (will test properly after RLS setup)

#### 1.2.3 Financial Field Protection Trigger
- [x] **Create financial protection trigger**
  ```sql
  -- Migration: "09_create_financial_protection_trigger"
  CREATE OR REPLACE FUNCTION public.restrict_model_financial_updates()
  RETURNS TRIGGER AS $$
  BEGIN
    -- Check if sensitive financial fields are being changed
    IF OLD.platform_fee_percentage IS DISTINCT FROM NEW.platform_fee_percentage OR
       OLD.split_chatting_costs IS DISTINCT FROM NEW.split_chatting_costs THEN
      
      -- Only owners can change financial settings
      IF (SELECT role FROM public.user_profiles WHERE id = auth.uid()) != 'owner' THEN
        RAISE EXCEPTION 'Only owners can modify financial settings';
      END IF;
    END IF;
    
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;
  
  CREATE TRIGGER models_financial_protection
    BEFORE UPDATE ON public.models
    FOR EACH ROW EXECUTE FUNCTION public.restrict_model_financial_updates();
  ```
  - [x] Apply migration
  - [x] Document for later testing after RLS setup

**Checkpoint 1.2**: ✅ All essential functions and triggers created

### 1.3 Simplified RLS Implementation

#### 1.3.1 Enable RLS on All Tables
- [x] **Enable Row Level Security**
  ```sql
  -- Migration: "10_enable_rls"
  ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.models ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.user_model_assignments ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.user_financial_settings ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.model_specific_settings ENABLE ROW LEVEL SECURITY;
  
  -- Force RLS even for table owners
  ALTER TABLE public.user_profiles FORCE ROW LEVEL SECURITY;
  ALTER TABLE public.models FORCE ROW LEVEL SECURITY;
  ALTER TABLE public.user_model_assignments FORCE ROW LEVEL SECURITY;
  ALTER TABLE public.user_financial_settings FORCE ROW LEVEL SECURITY;
  ALTER TABLE public.platform_settings FORCE ROW LEVEL SECURITY;
  ALTER TABLE public.model_specific_settings FORCE ROW LEVEL SECURITY;
  ```
  - [x] Apply migration
  - [x] Verify RLS enabled on all tables

#### 1.3.2 User Profiles RLS Policies
- [x] **Simple user profiles policies**
  ```sql
  -- Migration: "11_user_profiles_rls_policies"
  
  -- SELECT: Users see own profile, owners see all
  CREATE POLICY "user_profiles_select" ON public.user_profiles
  FOR SELECT USING (
    id = auth.uid() OR 
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  
  -- UPDATE: Users can update own profile, owners can update any
  CREATE POLICY "user_profiles_update" ON public.user_profiles  
  FOR UPDATE USING (
    id = auth.uid() OR
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  
  -- INSERT: Only owners can create user profiles
  CREATE POLICY "user_profiles_insert" ON public.user_profiles
  FOR INSERT WITH CHECK (
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  
  -- DELETE: Only owners can delete user profiles
  CREATE POLICY "user_profiles_delete" ON public.user_profiles
  FOR DELETE USING (
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  ```
  - [x] Apply migration
  - [x] Document for testing phase

#### 1.3.3 Models RLS Policies
- [x] **Simple models policies**
  ```sql
  -- Migration: "12_models_rls_policies"
  
  -- SELECT: Model users see their model, owners see all
  CREATE POLICY "models_select" ON public.models
  FOR SELECT USING (
    user_id = auth.uid() OR
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  
  -- UPDATE: Model users can update their model, owners can update any
  CREATE POLICY "models_update" ON public.models
  FOR UPDATE USING (
    user_id = auth.uid() OR
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  
  -- INSERT: Only owners can create models
  CREATE POLICY "models_insert" ON public.models
  FOR INSERT WITH CHECK (
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  
  -- DELETE: Only owners can delete models
  CREATE POLICY "models_delete" ON public.models
  FOR DELETE USING (
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  ```
  - [x] Apply migration

#### 1.3.4 Business Logic Tables - Owner Only
- [ ] **Owner-only policies for business tables**
  ```sql
  -- Migration: "13_business_tables_owner_only_rls"
  
  -- User Model Assignments - Owner only
  CREATE POLICY "user_model_assignments_owner_only" ON public.user_model_assignments
  FOR ALL USING (
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  
  -- Financial Settings - Owner only  
  CREATE POLICY "user_financial_settings_owner_only" ON public.user_financial_settings
  FOR ALL USING (
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  
  -- Platform Settings - SELECT for all, UPDATE owner only, no INSERT/DELETE
  CREATE POLICY "platform_settings_select_all" ON public.platform_settings
  FOR SELECT USING (true);
  
  CREATE POLICY "platform_settings_update_owner_only" ON public.platform_settings
  FOR UPDATE USING (
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  
  -- Model Specific Settings - Owner only
  CREATE POLICY "model_specific_settings_owner_only" ON public.model_specific_settings
  FOR ALL USING (
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  ```
  - [x] Apply migration

**Checkpoint 1.3**: ✅ Simplified RLS policies applied to all tables

### 1.4 Test Data Creation and Basic Validation

#### 1.4.1 Create Test Users
- [x] **Create and Insert test user profiles**
  ```sql
  -- Use execute_sql for test data
  -- Actual users created with the following details:
  -- Test Owner: ID '74372128-53e6-4fc2-87b8-397d01438b5d'
  -- Test Model: ID 'cb945936-e27c-47f6-b625-fb1e5e30d582'
  -- Test Manager: ID '37988e39-c60c-4ede-ae3f-5be31ca052cd'
  -- Test Chatter: ID '62c22102-e59d-4c48-a54f-1478bdd062a7'
  -- The following INSERT statement is illustrative of the data structure,
  -- but the actual insertion was done by first creating users in auth.users
  -- and then using their UUIDs for public.user_profiles.
  INSERT INTO public.user_profiles (id, full_name, role) VALUES
  ('74372128-53e6-4fc2-87b8-397d01438b5d', 'Test Owner', 'owner'),
  ('cb945936-e27c-47f6-b625-fb1e5e30d582', 'Test Model', 'model'),
  ('37988e39-c60c-4ede-ae3f-5be31ca052cd', 'Test Manager', 'manager'),
  ('62c22102-e59d-4c48-a54f-1478bdd062a7', 'Test Chatter', 'chatter');
  ```
  - [x] Execute with `execute_sql`
  - [x] Verify all users created


#### 1.4.2 Create Test Models
- [x] **Insert test models**
  ```sql
  INSERT INTO public.models (id, user_id, name) VALUES
  ('cb945936-e27c-47f6-b625-fb1e5e30d582', '00000000-0000-0000-0000-000000000002', 'Test Model A'),
  ('10000000-0000-0000-0000-000000000002', NULL, 'Test Model B (No User)');
  ```
  - [x] Execute with `execute_sql`
  - [x] Verify foreign key relationships

#### 1.4.3 Create Test Assignments
- [x] **Insert test assignments**
  ```sql
  INSERT INTO public.user_model_assignments (user_id, model_id) VALUES
  ('00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001'), -- Manager -> Model A
  ('00000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001'); -- Chatter -> Model A
  ```
  - [x] Execute with `execute_sql`
  - [x] Verify assignments created

#### 1.4.4 Basic Trigger Testing
- [x] **Test role escalation prevention**
  ```sql
  -- This should work (as we're simulating owner context)
  UPDATE public.user_profiles SET role = 'manager' WHERE id = '00000000-0000-0000-0000-000000000004';
  
  -- Note: Full RLS testing will be limited due to execute_sql connecting as postgres user
  -- Document this limitation for later frontend testing
  ```
  - [x] Test basic trigger functionality
  - [x] Document RLS testing limitations

#### 1.4.5 Generate TypeScript Types
- [x] **Generate types for frontend**
  - [x] Run `generate_typescript_types`
  - [x] Save output to project documentation
  - [x] Review generated types for completeness

**Checkpoint 1.4**: ✅ Test data created, basic validation complete, types generated

### 1.5 Documentation and Phase 1 Completion

#### 1.5.1 Schema Documentation
- [x] **Document current schema state**
  - [x] Run `list_tables` and document all tables
  - [x] Run `list_migrations` and document migration history
  - [x] Create schema diagram (can be text-based)
  - [x] Document all constraints and relationships

#### 1.5.2 RLS Policy Documentation
- [x] **Document security model**
  - [x] List all RLS policies and their purpose
  - [x] Document the "own data + owner override" pattern
  - [x] Note testing limitations with MCP tools
  - [x] Create testing checklist for frontend integration

#### 1.5.3 API Patterns Documentation
- [x] **Document expected usage patterns**
  - [x] How to query as different user types
  - [x] Expected behavior for each role
  - [x] Security considerations for frontend developers
  - [x] Error handling patterns

**Checkpoint 1.5**: ✅ Phase 1 complete with full documentation

---

## Phase 2: Income Registration System

### 2.1 Income Registration Schema

#### 2.1.1 Income Types Lookup Table
- [ ] **Create income types**
  ```sql
  -- Migration: "14_create_income_types"
  CREATE TABLE public.income_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
  );
  
  -- Insert standard income types
  INSERT INTO public.income_types (name, description) VALUES
  ('subscription', 'Monthly subscription income'),
  ('tip', 'One-time tip from fan'),
  ('private_message', 'Income from private messages'),
  ('live_stream', 'Income from live streaming'),
  ('content_sale', 'Income from content sales'),
  ('other', 'Other income sources');
  ```
  - [ ] Apply migration
  - [ ] Verify default income types created
  - [ ] Test uniqueness constraint

#### 2.1.2 Income Records Table
- [ ] **Create income records table**
  ```sql
  -- Migration: "15_create_income_records"
  CREATE TABLE public.income_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES public.models(id) ON DELETE CASCADE,
    recorded_by UUID NOT NULL REFERENCES public.user_profiles(id),
    income_type_id UUID NOT NULL REFERENCES public.income_types(id),
    gross_amount DECIMAL(10,2) NOT NULL CHECK (gross_amount >= 0),
    platform_fee_amount DECIMAL(10,2) NOT NULL CHECK (platform_fee_amount >= 0),
    net_amount DECIMAL(10,2) NOT NULL CHECK (net_amount >= 0),
    currency_code TEXT DEFAULT 'USD',
    income_date DATE NOT NULL,
    description TEXT,
    external_reference TEXT, -- For tracking external platform IDs
    is_verified BOOLEAN DEFAULT false,
    verified_by UUID REFERENCES public.user_profiles(id),
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure net amount calculation is correct
    CONSTRAINT check_net_amount_calculation CHECK (
      net_amount = gross_amount - platform_fee_amount
    )
  );
  
  -- Indexes for performance
  CREATE INDEX idx_income_records_model_id ON public.income_records(model_id);
  CREATE INDEX idx_income_records_income_date ON public.income_records(income_date);
  CREATE INDEX idx_income_records_recorded_by ON public.income_records(recorded_by);
  CREATE INDEX idx_income_records_type ON public.income_records(income_type_id);
  ```
  - [ ] Apply migration
  - [ ] Test constraint validations
  - [ ] Verify all indexes created

#### 2.1.3 Recurring Income Schedules
- [ ] **Create recurring income table**
  ```sql
  -- Migration: "16_create_recurring_income_schedules"
  CREATE TYPE recurrence_frequency AS ENUM ('daily', 'weekly', 'monthly', 'yearly');
  
  CREATE TABLE public.recurring_income_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES public.models(id) ON DELETE CASCADE,
    income_type_id UUID NOT NULL REFERENCES public.income_types(id),
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    frequency recurrence_frequency NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE, -- NULL means indefinite
    next_due_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_by UUID NOT NULL REFERENCES public.user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- End date must be after start date
    CONSTRAINT check_date_order CHECK (end_date IS NULL OR end_date > start_date)
  );
  
  CREATE INDEX idx_recurring_income_model_id ON public.recurring_income_schedules(model_id);
  CREATE INDEX idx_recurring_income_next_due ON public.recurring_income_schedules(next_due_date) WHERE is_active = true;
  ```
  - [ ] Apply migration
  - [ ] Test enum values
  - [ ] Verify date constraints work

#### 2.1.4 Income Records RLS Policies
- [ ] **Create RLS policies for income tables**
  ```sql
  -- Migration: "17_income_tables_rls"
  
  -- Income Types - Read only for all authenticated users
  ALTER TABLE public.income_types ENABLE ROW LEVEL SECURITY;
  CREATE POLICY "income_types_select_all" ON public.income_types
  FOR SELECT USING (auth.uid() IS NOT NULL);
  
  -- Only owners can modify income types
  CREATE POLICY "income_types_owner_only_modify" ON public.income_types
  FOR ALL USING (
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  
  -- Income Records - Users can see records they created or for models they're assigned to
  ALTER TABLE public.income_records ENABLE ROW LEVEL SECURITY;
  
  CREATE POLICY "income_records_select" ON public.income_records
  FOR SELECT USING (
    recorded_by = auth.uid() OR
    model_id IN (
      SELECT model_id FROM public.user_model_assignments 
      WHERE user_id = auth.uid()
    ) OR
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  
  -- Users can insert records for models they're assigned to
  CREATE POLICY "income_records_insert" ON public.income_records
  FOR INSERT WITH CHECK (
    model_id IN (
      SELECT model_id FROM public.user_model_assignments 
      WHERE user_id = auth.uid()
    ) OR
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  
  -- Users can update records they created, owners can update any
  CREATE POLICY "income_records_update" ON public.income_records
  FOR UPDATE USING (
    recorded_by = auth.uid() OR
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  
  -- Only owners can delete records
  CREATE POLICY "income_records_delete" ON public.income_records
  FOR DELETE USING (
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  
  -- Recurring Income Schedules - Owner only for now (can be refined later)
  ALTER TABLE public.recurring_income_schedules ENABLE ROW LEVEL SECURITY;
  CREATE POLICY "recurring_income_owner_only" ON public.recurring_income_schedules
  FOR ALL USING (
    (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
  );
  ```
  - [ ] Apply migration
  - [ ] Document more complex RLS logic for income records

**Checkpoint 2.1**: ✅ Income registration schema complete with RLS

### 2.2 Income Registration Edge Functions

#### 2.2.1 Register Income Edge Function
- [ ] **Create register-income Edge Function**
  ```typescript
  // Function name: "register-income"
  import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
  
  interface IncomeRegistrationRequest {
    model_id: string;
    income_type_id: string;
    gross_amount: number;
    platform_fee_percentage?: number; // Optional override
    income_date: string; // ISO date string
    description?: string;
    external_reference?: string;
  }
  
  Deno.serve(async (req) => {
    // Handle CORS
    if (req.method === 'OPTIONS') {
      return new Response('ok', {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        },
      });
    }
  
    try {
      // Get Supabase client with user context
      const supabaseClient = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_ANON_KEY') ?? '',
        {
          global: {
            headers: { Authorization: req.headers.get('Authorization')! },
          },
        }
      );
  
      // Get user from JWT
      const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
      if (userError || !user) {
        return new Response(JSON.stringify({ error: 'Unauthorized' }), {
          status: 401,
          headers: { 'Content-Type': 'application/json' },
        });
      }
  
      // Parse request body
      const incomeData: IncomeRegistrationRequest = await req.json();
  
      // Get platform fee percentage (from model-specific settings or platform default)
      const { data: modelSettings } = await supabaseClient
        .from('model_specific_settings')
        .select('platform_fee_percentage')
        .eq('model_id', incomeData.model_id)
        .single();
  
      let platformFeePercentage = incomeData.platform_fee_percentage;
      
      if (!platformFeePercentage) {
        if (modelSettings?.platform_fee_percentage) {
          platformFeePercentage = modelSettings.platform_fee_percentage;
        } else {
          const { data: platformSettings } = await supabaseClient
            .from('platform_settings')
            .select('default_platform_fee_percentage')
            .single();
          platformFeePercentage = platformSettings?.default_platform_fee_percentage || 20;
        }
      }
  
      // Calculate amounts
      const platformFeeAmount = (incomeData.gross_amount * platformFeePercentage) / 100;
      const netAmount = incomeData.gross_amount - platformFeeAmount;
  
      // Insert income record
      const { data, error } = await supabaseClient
        .from('income_records')
        .insert({
          model_id: incomeData.model_id,
          recorded_by: user.id,
          income_type_id: incomeData.income_type_id,
          gross_amount: incomeData.gross_amount,
          platform_fee_amount: platformFeeAmount,
          net_amount: netAmount,
          income_date: incomeData.income_date,
          description: incomeData.description,
          external_reference: incomeData.external_reference,
        })
        .select()
        .single();
  
      if (error) {
        return new Response(JSON.stringify({ error: error.message }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        });
      }
  
      return new Response(JSON.stringify({ data }), {
        headers: { 'Content-Type': 'application/json' },
      });
  
    } catch (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }
  });
  ```
  - [ ] Deploy with `deploy_edge_function`
  - [ ] Test with `get_logs` to check for deployment errors
  - [ ] Document API endpoint usage

#### 2.2.2 Get Income Records Edge Function
- [ ] **Create get-income-records Edge Function**
  ```typescript
  // Function name: "get-income-records"
  // Similar structure but with query parameters for filtering
  // - model_id (optional filter)
  // - date_from, date_to (optional date range)
  // - limit, offset (pagination)
  // - income_type_id (optional filter)
  ```
  - [ ] Deploy edge function
  - [ ] Test filtering and pagination
  - [ ]

# OnlyManager Fresh Start Implementation Plan

## Phase 1: Core Schema (Keep Your Existing Design)
Your table designs were solid - keep the same schema structure:

- `user_profiles`
- `models` 
- `user_model_assignments`
- `user_financial_settings`
- `platform_settings`
- `model_specific_settings`

## Phase 2: Simple RLS from Day 1

### Core Principle: "Own Data + Owner Override"

```sql
-- Template for most tables
CREATE POLICY "table_name_simple_select" ON public.table_name
FOR SELECT USING (
  user_id = auth.uid() OR -- Own records
  (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner' -- Owner sees all
);
```

### Specific Policies by Table:

#### `user_profiles`
```sql
-- Users see own profile, owners see all
CREATE POLICY "user_profiles_select" ON public.user_profiles
FOR SELECT USING (
  id = auth.uid() OR 
  (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
);

-- Users can update own profile, owners can update any
CREATE POLICY "user_profiles_update" ON public.user_profiles  
FOR UPDATE USING (
  id = auth.uid() OR
  (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
);

-- Only owners can insert/delete
CREATE POLICY "user_profiles_insert" ON public.user_profiles
FOR INSERT WITH CHECK (
  (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
);

CREATE POLICY "user_profiles_delete" ON public.user_profiles
FOR DELETE USING (
  (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
);
```

#### `models`
```sql
-- Model users see their model, owners see all
CREATE POLICY "models_select" ON public.models
FOR SELECT USING (
  user_id = auth.uid() OR
  (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
);

-- Model users can update their model, owners can update any
CREATE POLICY "models_update" ON public.models
FOR UPDATE USING (
  user_id = auth.uid() OR
  (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
);

-- Only owners can create/delete models
CREATE POLICY "models_insert" ON public.models
FOR INSERT WITH CHECK (
  (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
);

CREATE POLICY "models_delete" ON public.models
FOR DELETE USING (
  (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
);
```

#### Business Logic Tables (Assignments, Settings)
```sql
-- These are owner-only since regular users don't need direct access
CREATE POLICY "assignments_owner_only" ON public.user_model_assignments
FOR ALL USING (
  (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
);

CREATE POLICY "financial_settings_owner_only" ON public.user_financial_settings  
FOR ALL USING (
  (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
);
```

## Phase 3: Essential Triggers Only

Keep these two critical triggers from your previous work:

```sql
-- 1. Prevent role escalation
CREATE TRIGGER user_profiles_role_protection
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION prevent_role_escalation();

-- 2. Prevent unauthorized financial updates  
CREATE TRIGGER models_financial_protection
  BEFORE UPDATE ON public.models
  FOR EACH ROW EXECUTE FUNCTION restrict_model_financial_updates();
```

## Phase 4: Statistics Tables (Future)

When you add statistics tables, use the same simple pattern:

```sql
-- Example: chat_statistics table
CREATE TABLE public.chat_statistics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id),
  model_id UUID REFERENCES public.models(id),
  messages_sent INTEGER,
  revenue_generated DECIMAL,
  date_recorded DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Simple RLS: Users see own stats, owners see all
CREATE POLICY "chat_stats_select" ON public.chat_statistics
FOR SELECT USING (
  user_id = auth.uid() OR
  (SELECT role FROM public.user_profiles WHERE id = auth.uid()) = 'owner'
);
```

## Phase 5: Application Logic for Complex Permissions

Handle "which models should this chatter see stats for" in your application:

```javascript
// Service function
async function getChatterDashboard(chatterId) {
  // 1. Get chatter's assigned models (owner-only query via API)
  const assignments = await getAssignmentsForUser(chatterId);
  
  // 2. Get chatter's stats (RLS ensures only their own stats)
  const stats = await getStatsForUser(chatterId);
  
  // 3. Filter stats to only assigned models
  const filteredStats = stats.filter(stat => 
    assignments.some(a => a.model_id === stat.model_id)
  );
  
  return { stats: filteredStats, assignments };
}
```

## Benefits of This Approach:

1. **Secure by default**: Can't access others' data
2. **Simple to test**: Each policy has clear, testable logic
3. **Easy to debug**: No complex joins or subqueries
4. **Performant**: Minimal database overhead
5. **Flexible**: Business logic in app code, not database
6. **Maintainable**: Easy to understand and modify

## Testing Strategy:

Test each role with simple scenarios:
- ✅ Owner can see everything
- ✅ Model user can see only their model
- ✅ Chatter can see only their profile/stats
- ✅ Role escalation blocked
- ✅ Financial tampering blocked

No need for complex assignment-based access testing at the database level.
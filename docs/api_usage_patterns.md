# API Usage Patterns and Frontend Considerations

This document provides guidance for frontend developers on how to interact with the Supabase API, considering the implemented Row Level Security (RLS) policies and expected behavior for different user roles.

## 1. Querying as Different User Types

-   **Authentication:** All API requests must be authenticated using a valid Supabase JWT obtained after user login. The Supabase client libraries (e.g., `supabase-js`) handle attaching this token to requests automatically.
-   **RLS Enforcement:** RLS policies are enforced by PostgreSQL on the server-side based on the `auth.uid()` and the user's role (retrieved via `public.get_user_role()`) associated with the JWT. The frontend client does not need to specify the user role explicitly in queries for RLS to work; it's derived from the authenticated session.
-   **Impersonation (for Testing):** During development, Supabase allows service role keys to bypass RLS or to impersonate users for testing. **Never use service role keys in a frontend client.** For local testing of different roles, ensure you log in as a user with the desired role.

## 2. Expected API Behavior for Each Role

The behavior of API calls (SELECT, INSERT, UPDATE, DELETE) will vary significantly based on the authenticated user's role due to RLS. Refer to `docs/rls_policy_documentation.md` for detailed policy logic.

### General Principles:
-   **`public.user_profiles`**:
    -   **SELECT:** Users can select their own profile. Owners can select any.
    -   **UPDATE:** Only 'owner' role can update profiles. (Self-service updates for fields like `full_name` or `telegram_username` for non-owners must be implemented via dedicated `SECURITY DEFINER` functions if needed, which would then be called as RPCs).
    -   **INSERT:** Users can insert their own profile (matching `auth.uid()`). Owners can insert any.
    -   **DELETE:** Only 'owner' role can delete.
-   **`public.models`**:
    -   **SELECT:** Models see their own; assigned managers/chatters see assigned; owners see all.
    -   **UPDATE:** Models update their own (non-financial fields); owners update any (including financial, respecting triggers).
    -   **INSERT/DELETE:** Owner only.
-   **`public.user_model_assignments`**, **`public.user_financial_settings`**, **`public.model_specific_settings`**:
    -   All operations (SELECT, INSERT, UPDATE, DELETE) are generally restricted to 'owner' role only.
-   **`public.platform_settings`**:
    -   **SELECT:** Any authenticated user.
    -   **UPDATE:** Owner only.

### Example Scenarios:
-   **A 'manager' trying to view all models:**
    -   `supabase.from('models').select('*')`
    -   **Expected:** Will only return models they are explicitly assigned to via `user_model_assignments`.
-   **A 'model' trying to update their `full_name` in `user_profiles`:**
    -   `supabase.from('user_profiles').update({ full_name: 'New Name' }).eq('id', user.id)`
    -   **Expected (Post-Migration `14_fix_user_profiles_update_rls`):** This will FAIL due to RLS, as only owners can update `user_profiles`. If this functionality is desired for users, a specific RPC call to a `SECURITY DEFINER` function must be created and used.
-   **A 'chatter' trying to view `user_financial_settings`:**
    -   `supabase.from('user_financial_settings').select('*')`
    -   **Expected:** Will return an empty array or an error indicating no access, as this table is owner-only.

## 3. Security Considerations for Frontend Developers

-   **Never Trust Client Input for Security Logic:** Do not rely on client-side checks for security. All critical security enforcement happens server-side via RLS and database triggers/functions.
-   **Minimize Data Exposure:** Only query for the data necessary for a given view or component. Use `.select('column1, column2')` to fetch specific columns.
-   **RLS is the Source of Truth for Permissions:** The frontend UI should adapt to what data is returned or what operations succeed/fail based on RLS. For example, an "edit" button should ideally only be shown if the user actually has permission to edit (which can be inferred from successful data fetching or specific permission checks if available).
-   **Service Role Key:** **NEVER embed or use the Supabase service role key in frontend code.** This key bypasses RLS and grants full database access.
-   **Data Validation:** While the database has constraints, always perform client-side validation for a better user experience. However, server-side validation (via database constraints, triggers, or functions) is crucial.
-   **RPC Calls for Privileged Operations:** For operations that a user role shouldn't perform directly on a table via RLS but are necessary (e.g., a user updating their own `full_name`), create specific PostgreSQL functions (`SECURITY DEFINER` if they need elevated privileges) and call them using `supabase.rpc('function_name', { args })`. These functions can encapsulate specific business logic and fine-grained checks.

## 4. Error Handling Patterns

-   **RLS Violations:**
    -   **SELECT:** If RLS prevents access to rows, queries will typically return an empty array for the restricted rows, not necessarily an explicit error, unless no rows are accessible at all based on the policy.
    -   **INSERT/UPDATE/DELETE:** If an RLS `WITH CHECK` condition fails for an INSERT/UPDATE, or if a `USING` condition prevents an UPDATE/DELETE on any targeted rows, the database will return an error. Supabase client libraries will typically throw this as a JavaScript error.
        -   Example error message for a `WITH CHECK` failure: `new row violates row-level security policy for table "..."`
    -   The HTTP status code for RLS violations might be `403 Forbidden` or `404 Not Found` if the query targets a specific record that isn't visible/modifiable, or a more generic error if the policy prevents the action broadly.
-   **Catching Errors:** Use `try...catch` blocks or promise `.catch()` handlers when making Supabase API calls.
    ```javascript
    try {
      const { data, error } = await supabase.from('my_table').insert({ some_column: 'value' });
      if (error) {
        console.error('Supabase error:', error.message);
        // Handle specific errors, e.g., RLS violation, constraint violation
        // error.code and error.details might provide more info
        // For RLS, error.message often contains "violates row-level security policy"
      } else {
        // Handle success
      }
    } catch (e) {
      console.error('Network or other error:', e.message);
    }
    ```
-   **Database Constraint Violations:** (e.g., `NOT NULL`, `UNIQUE`, `FOREIGN KEY`, `CHECK`) will also result in errors from the database, typically with specific PostgreSQL error codes and messages that Supabase client will surface.
    -   Example: `duplicate key value violates unique constraint "..."`
    -   Example: `null value in column "..." violates not-null constraint`
-   **Trigger-Raised Exceptions:** Custom exceptions raised by triggers (e.g., from `prevent_role_escalation`) will also be passed back as errors.

Frontend developers should inspect the `error` object returned by Supabase calls to understand the nature of failures and provide appropriate feedback to the user or take corrective action.

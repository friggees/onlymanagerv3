# Row Level Security (RLS) Test Cases

This document outlines test cases for verifying the RLS policies implemented on the database tables. Each test should be performed by authenticating as a user with the specified role.

**Assumed Test Data Setup:**
- `owner_user_id`: User with 'owner' role.
- `model_user_A_id`: User with 'model' role, linked to `model_A_record_id` in `models` table.
- `manager_user_id`: User with 'manager' role, assigned to `model_A_record_id`.
- `chatter_user_A_id`: User with 'chatter' role, assigned to `model_A_record_id`.
- `model_B_record_id`: Another model record, not directly managed by `manager_user_id`.
- `chatter_user_B_id`: Another chatter user, assigned to `model_B_record_id`.
- `other_user_id`: A generic user ID different from the one currently testing.

---

## 1. `user_profiles` Table

### 1.1. As Owner (`owner_user_id`)
- **SELECT**:
    - [ ] Can select own profile.
    - [ ] Can select `manager_user_id`'s profile.
    - [ ] Can select `model_user_A_id`'s profile.
    - [ ] Can select `chatter_user_A_id`'s profile.
    - [ ] Can select all profiles.
- **INSERT**:
    - [ ] Can insert a new user profile (e.g., for a new employee).
- **UPDATE**:
    - [ ] Can update own profile (e.g., `full_name`, `role`).
    - [ ] Can update `manager_user_id`'s profile (e.g., `full_name`, `role`).
- **DELETE**:
    - [ ] Can delete `chatter_user_A_id`'s profile (assuming ON DELETE CASCADE handles related data or it's allowed).

### 1.2. As Manager (`manager_user_id`)
- **SELECT**:
    - [ ] Can select own profile.
    - [ ] Can select `chatter_user_A_id`'s profile (assigned to same model `model_A_record_id`).
    - [ ] Can select `model_user_A_id`'s profile (if model user is assigned to `model_A_record_id`).
    - [ ] Cannot select `owner_user_id`'s profile.
    - [ ] Cannot select `chatter_user_B_id`'s profile (assigned to a different model).
- **INSERT**:
    - [ ] Cannot insert a new user profile.
- **UPDATE**:
    - [ ] Can update own `full_name`.
    - [ ] Cannot update own `role`.
    - [ ] Cannot update `chatter_user_A_id`'s profile.
- **DELETE**:
    - [ ] Cannot delete own profile.
    - [ ] Cannot delete `chatter_user_A_id`'s profile.

### 1.3. As Chatter (`chatter_user_A_id`)
- **SELECT**:
    - [ ] Can select own profile.
    - [ ] Cannot select `manager_user_id`'s profile.
    - [ ] Cannot select `model_user_A_id`'s profile.
    - [ ] Cannot select `owner_user_id`'s profile.
    - [ ] Cannot select `chatter_user_B_id`'s profile.
- **INSERT**:
    - [ ] Cannot insert a new user profile.
- **UPDATE**:
    - [ ] Can update own `full_name`.
    - [ ] Cannot update own `role`.
    - [ ] Cannot update `other_user_id`'s profile.
- **DELETE**:
    - [ ] Cannot delete own profile.

### 1.4. As Model User (`model_user_A_id`)
- **SELECT**:
    - [ ] Can select own profile.
    - [ ] Cannot select `manager_user_id`'s profile.
    - [ ] Cannot select `chatter_user_A_id`'s profile.
- **INSERT**:
    - [ ] Cannot insert a new user profile.
- **UPDATE**:
    - [ ] Can update own `full_name`.
    - [ ] Cannot update own `role`.
- **DELETE**:
    - [ ] Cannot delete own profile.

---

## 2. `models` Table

### 2.1. As Owner (`owner_user_id`)
- **SELECT**:
    - [ ] Can select `model_A_record_id`.
    - [ ] Can select `model_B_record_id`.
    - [ ] Can select all models.
- **INSERT**:
    - [ ] Can insert a new model record.
- **UPDATE**:
    - [ ] Can update `model_A_record_id` (e.g., `name`, `platform_fee_percentage`, `split_chatting_costs`).
- **DELETE**:
    - [ ] Can delete `model_A_record_id`.

### 2.2. As Manager (`manager_user_id`)
- **SELECT**:
    - [ ] Can select `model_A_record_id` (assigned model).
    - [ ] Cannot select `model_B_record_id` (unassigned model).
- **INSERT**:
    - [ ] Cannot insert a new model.
- **UPDATE**:
    - [ ] Cannot update `model_A_record_id`.
- **DELETE**:
    - [ ] Cannot delete `model_A_record_id`.

### 2.3. As Chatter (`chatter_user_A_id`)
- **SELECT**:
    - [ ] Can select `model_A_record_id` (assigned model).
    - [ ] Cannot select `model_B_record_id` (unassigned model).
- **INSERT**:
    - [ ] Cannot insert a new model.
- **UPDATE**:
    - [ ] Cannot update `model_A_record_id`.
- **DELETE**:
    - [ ] Cannot delete `model_A_record_id`.

### 2.4. As Model User (`model_user_A_id`, linked to `model_A_record_id`)
- **SELECT**:
    - [ ] Can select `model_A_record_id` (own model record).
    - [ ] Cannot select `model_B_record_id`.
- **INSERT**:
    - [ ] Cannot insert a new model.
- **UPDATE**:
    - [ ] Can update `model_A_record_id.name`.
    - [ ] Cannot update `model_A_record_id.platform_fee_percentage`.
    - [ ] Cannot update `model_A_record_id.split_chatting_costs`.
- **DELETE**:
    - [ ] Cannot delete `model_A_record_id`.

---

## 3. `user_model_assignments` Table

### 3.1. As Owner (`owner_user_id`)
- **SELECT**:
    - [ ] Can select assignment for (`chatter_user_A_id`, `model_A_record_id`).
    - [ ] Can select all assignments.
- **INSERT**:
    - [ ] Can insert a new assignment (e.g., assign `chatter_user_B_id` to `model_A_record_id`).
- **UPDATE**:
    - [ ] (No updateable fields other than PKs, typically not updated directly).
- **DELETE**:
    - [ ] Can delete an assignment.

### 3.2. As Manager (`manager_user_id`, assigned to `model_A_record_id`)
- **SELECT**:
    - [ ] Can select own assignment to `model_A_record_id`.
    - [ ] Can select `chatter_user_A_id`'s assignment to `model_A_record_id`.
    - [ ] Cannot select `chatter_user_B_id`'s assignment to `model_B_record_id`.
- **INSERT**:
    - [ ] Cannot insert new assignments.
- **DELETE**:
    - [ ] Cannot delete assignments.

### 3.3. As Chatter (`chatter_user_A_id`)
- **SELECT**:
    - [ ] Can select own assignment to `model_A_record_id`.
    - [ ] Cannot select `manager_user_id`'s assignment to `model_A_record_id`.
    - [ ] Cannot select `chatter_user_B_id`'s assignment to `model_B_record_id`.
- **INSERT**:
    - [ ] Cannot insert new assignments.
- **DELETE**:
    - [ ] Cannot delete assignments.

### 3.4. As Model User (`model_user_A_id`)
- **SELECT**:
    - [ ] Can select own assignment (if models can be 'assigned' to themselves, or if they are also a chatter/manager for their own profile).
    - [ ] (Policy might need refinement if models are not directly in `user_model_assignments` unless they also hold another role).
- **INSERT**:
    - [ ] Cannot insert.
- **DELETE**:
    - [ ] Cannot delete.

---

## 4. `user_financial_settings` Table

### 4.1. As Owner (`owner_user_id`)
- **SELECT**:
    - [ ] Can select financial settings for `chatter_user_A_id`.
    - [ ] Can select all financial settings.
- **INSERT**:
    - [ ] Can insert financial settings for `chatter_user_A_id`.
- **UPDATE**:
    - [ ] Can update financial settings for `chatter_user_A_id`.
- **DELETE**:
    - [ ] Can delete financial settings for `chatter_user_A_id`.

### 4.2. As Manager (`manager_user_id`, manages `chatter_user_A_id` via `model_A_record_id`)
- **SELECT**:
    - [ ] Can select own financial settings.
    - [ ] Can select financial settings for `chatter_user_A_id`.
    - [ ] Cannot select financial settings for `chatter_user_B_id`.
    - [ ] Cannot select financial settings for `owner_user_id`.
- **INSERT**:
    - [ ] Cannot insert financial settings.
- **UPDATE**:
    - [ ] Cannot update own financial settings (policy might need to allow self-update if intended).
    - [ ] Cannot update financial settings for `chatter_user_A_id`.
- **DELETE**:
    - [ ] Cannot delete financial settings.

### 4.3. As Chatter (`chatter_user_A_id`)
- **SELECT**:
    - [ ] Can select own financial settings.
    - [ ] Cannot select financial settings for `manager_user_id`.
    - [ ] Cannot select financial settings for `chatter_user_B_id`.
- **INSERT**:
    - [ ] Cannot insert financial settings.
- **UPDATE**:
    - [ ] Cannot update own financial settings.
- **DELETE**:
    - [ ] Cannot delete financial settings.

### 4.4. As Model User (`model_user_A_id`)
- **SELECT**:
    - [ ] Can select own financial settings.
- **INSERT**:
    - [ ] Cannot insert.
- **UPDATE**:
    - [ ] Cannot update.
- **DELETE**:
    - [ ] Cannot delete.

---

## 5. `platform_settings` Table (Singleton)

### 5.1. As Owner (`owner_user_id`)
- **SELECT**:
    - [ ] Can select platform settings.
- **INSERT**:
    - [ ] (Table is singleton, insert only happens once at setup).
- **UPDATE**:
    - [ ] Can update `default_platform_fee_percentage`.
- **DELETE**:
    - [ ] (Row should not be deletable).

### 5.2. As Manager (`manager_user_id`)
- **SELECT**:
    - [ ] Can select platform settings.
- **INSERT**:
    - [ ] Cannot insert.
- **UPDATE**:
    - [ ] Cannot update platform settings.
- **DELETE**:
    - [ ] Cannot delete.

### 5.3. As Chatter (`chatter_user_A_id`)
- **SELECT**:
    - [ ] Can select platform settings.
- **INSERT**:
    - [ ] Cannot insert.
- **UPDATE**:
    - [ ] Cannot update.
- **DELETE**:
    - [ ] Cannot delete.

### 5.4. As Model User (`model_user_A_id`)
- **SELECT**:
    - [ ] Can select platform settings.
- **INSERT**:
    - [ ] Cannot insert.
- **UPDATE**:
    - [ ] Cannot update.
- **DELETE**:
    - [ ] Cannot delete.

---

## 6. `model_specific_settings` Table

### 6.1. As Owner (`owner_user_id`)
- **SELECT**:
    - [ ] Can select settings for `model_A_record_id`.
    - [ ] Can select all model-specific settings.
- **INSERT**:
    - [ ] Can insert settings for `model_A_record_id`.
- **UPDATE**:
    - [ ] Can update settings for `model_A_record_id`.
- **DELETE**:
    - [ ] Can delete settings for `model_A_record_id`.

### 6.2. As Manager (`manager_user_id`, assigned to `model_A_record_id`)
- **SELECT**:
    - [ ] Can select settings for `model_A_record_id`.
    - [ ] Cannot select settings for `model_B_record_id`.
- **INSERT**:
    - [ ] Cannot insert.
- **UPDATE**:
    - [ ] Cannot update.
- **DELETE**:
    - [ ] Cannot delete.

### 6.3. As Chatter (`chatter_user_A_id`, assigned to `model_A_record_id`)
- **SELECT**:
    - [ ] Can select settings for `model_A_record_id`.
    - [ ] Cannot select settings for `model_B_record_id`.
- **INSERT**:
    - [ ] Cannot insert.
- **UPDATE**:
    - [ ] Cannot update.
- **DELETE**:
    - [ ] Cannot delete.

### 6.4. As Model User (`model_user_A_id`, linked to `model_A_record_id`)
- **SELECT**:
    - [ ] Can select settings for `model_A_record_id`.
    - [ ] Cannot select settings for `model_B_record_id`.
- **INSERT**:
    - [ ] Cannot insert.
- **UPDATE**:
    - [ ] Cannot update.
- **DELETE**:
    - [ ] Cannot delete.

---

**Note:** These test cases are based on the RLS policies created. If any test fails unexpectedly, review the corresponding policy. Some policies might need refinement based on more detailed business logic (e.g., if managers should be able to update certain fields for their assigned users/models).

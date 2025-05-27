export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
      model_specific_settings: {
        Row: {
          created_at: string | null
          model_id: string
          platform_fee_percentage: number | null
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          model_id: string
          platform_fee_percentage?: number | null
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          model_id?: string
          platform_fee_percentage?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "model_specific_settings_model_id_fkey"
            columns: ["model_id"]
            isOneToOne: true
            referencedRelation: "models"
            referencedColumns: ["id"]
          },
        ]
      }
      models: {
        Row: {
          created_at: string | null
          id: string
          name: string
          platform_fee_percentage: number | null
          split_chatting_costs: boolean | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          name: string
          platform_fee_percentage?: number | null
          split_chatting_costs?: boolean | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          name?: string
          platform_fee_percentage?: number | null
          split_chatting_costs?: boolean | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "models_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      platform_settings: {
        Row: {
          created_at: string | null
          currency_code: string | null
          currency_symbol: string | null
          default_platform_fee_percentage: number | null
          id: number
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          currency_code?: string | null
          currency_symbol?: string | null
          default_platform_fee_percentage?: number | null
          id?: number
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          currency_code?: string | null
          currency_symbol?: string | null
          default_platform_fee_percentage?: number | null
          id?: number
          updated_at?: string | null
        }
        Relationships: []
      }
      user_financial_settings: {
        Row: {
          commission_percentage: number | null
          created_at: string | null
          fixed_salary_amount: number | null
          manager_passive_tick_percentage: number | null
          salary_type: Database["public"]["Enums"]["salary_structure_type"]
          updated_at: string | null
          user_id: string
        }
        Insert: {
          commission_percentage?: number | null
          created_at?: string | null
          fixed_salary_amount?: number | null
          manager_passive_tick_percentage?: number | null
          salary_type: Database["public"]["Enums"]["salary_structure_type"]
          updated_at?: string | null
          user_id: string
        }
        Update: {
          commission_percentage?: number | null
          created_at?: string | null
          fixed_salary_amount?: number | null
          manager_passive_tick_percentage?: number | null
          salary_type?: Database["public"]["Enums"]["salary_structure_type"]
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_financial_settings_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      user_model_assignments: {
        Row: {
          assigned_at: string | null
          model_id: string
          user_id: string
        }
        Insert: {
          assigned_at?: string | null
          model_id: string
          user_id: string
        }
        Update: {
          assigned_at?: string | null
          model_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_model_assignments_model_id_fkey"
            columns: ["model_id"]
            isOneToOne: false
            referencedRelation: "models"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_model_assignments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "user_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      user_profiles: {
        Row: {
          contract_document_path: string | null
          created_at: string | null
          full_name: string | null
          id: string
          role: string
          telegram_username: string | null
          updated_at: string | null
        }
        Insert: {
          contract_document_path?: string | null
          created_at?: string | null
          full_name?: string | null
          id: string
          role: string
          telegram_username?: string | null
          updated_at?: string | null
        }
        Update: {
          contract_document_path?: string | null
          created_at?: string | null
          full_name?: string | null
          id?: string
          role?: string
          telegram_username?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      salary_structure_type:
        | "commission_only"
        | "fixed_only"
        | "fixed_plus_commission"
        | "passive_tick_only"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DefaultSchema = Database[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof (Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        Database[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? (Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      Database[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof Database },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof Database },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends { schema: keyof Database }
  ? Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      salary_structure_type: [
        "commission_only",
        "fixed_only",
        "fixed_plus_commission",
        "passive_tick_only",
      ],
    },
  },
} as const

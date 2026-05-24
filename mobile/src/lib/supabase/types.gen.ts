Connecting to db 5432
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      blocks: {
        Row: {
          blocked_id: string
          blocker_id: string
          created_at: string
        }
        Insert: {
          blocked_id: string
          blocker_id: string
          created_at?: string
        }
        Update: {
          blocked_id?: string
          blocker_id?: string
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "blocks_blocked_id_fkey"
            columns: ["blocked_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "blocks_blocker_id_fkey"
            columns: ["blocker_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      conversation_mutes: {
        Row: {
          conversation_id: string
          muted_at: string
          user_id: string
        }
        Insert: {
          conversation_id: string
          muted_at?: string
          user_id: string
        }
        Update: {
          conversation_id?: string
          muted_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "conversation_mutes_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conversation_mutes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      conversation_reads: {
        Row: {
          conversation_id: string
          last_read_at: string
          user_id: string
        }
        Insert: {
          conversation_id: string
          last_read_at?: string
          user_id: string
        }
        Update: {
          conversation_id?: string
          last_read_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "conversation_reads_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conversation_reads_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      conversations: {
        Row: {
          created_at: string
          id: string
          last_message_at: string | null
          participant_a_id: string
          participant_b_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          last_message_at?: string | null
          participant_a_id: string
          participant_b_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          last_message_at?: string | null
          participant_a_id?: string
          participant_b_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "conversations_participant_a_id_fkey"
            columns: ["participant_a_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conversations_participant_b_id_fkey"
            columns: ["participant_b_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      daily_matches: {
        Row: {
          created_at: string
          for_date_local: string
          id: string
          match_reason: string
          pick_user_id: string
          user_id: string
          viewed_at: string | null
        }
        Insert: {
          created_at?: string
          for_date_local: string
          id?: string
          match_reason?: string
          pick_user_id: string
          user_id: string
          viewed_at?: string | null
        }
        Update: {
          created_at?: string
          for_date_local?: string
          id?: string
          match_reason?: string
          pick_user_id?: string
          user_id?: string
          viewed_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "daily_matches_pick_user_id_fkey"
            columns: ["pick_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_matches_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      device_tokens: {
        Row: {
          created_at: string
          id: string
          last_seen_at: string
          platform: Database["public"]["Enums"]["device_platform"]
          revoked_at: string | null
          token: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          last_seen_at?: string
          platform: Database["public"]["Enums"]["device_platform"]
          revoked_at?: string | null
          token: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          last_seen_at?: string
          platform?: Database["public"]["Enums"]["device_platform"]
          revoked_at?: string | null
          token?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "device_tokens_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      intros: {
        Row: {
          conversation_id: string | null
          created_at: string
          declined_at: string | null
          expires_at: string
          id: string
          kind: Database["public"]["Enums"]["intro_kind"]
          note: string
          recipient_id: string | null
          sender_id: string | null
          state: Database["public"]["Enums"]["intro_state"]
          updated_at: string
          warm_target_id: string | null
        }
        Insert: {
          conversation_id?: string | null
          created_at?: string
          declined_at?: string | null
          expires_at?: string
          id?: string
          kind?: Database["public"]["Enums"]["intro_kind"]
          note: string
          recipient_id?: string | null
          sender_id?: string | null
          state?: Database["public"]["Enums"]["intro_state"]
          updated_at?: string
          warm_target_id?: string | null
        }
        Update: {
          conversation_id?: string | null
          created_at?: string
          declined_at?: string | null
          expires_at?: string
          id?: string
          kind?: Database["public"]["Enums"]["intro_kind"]
          note?: string
          recipient_id?: string | null
          sender_id?: string | null
          state?: Database["public"]["Enums"]["intro_state"]
          updated_at?: string
          warm_target_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "intros_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "intros_recipient_id_fkey"
            columns: ["recipient_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "intros_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "intros_warm_target_id_fkey"
            columns: ["warm_target_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      meeting_feedback: {
        Row: {
          created_at: string
          id: string
          meeting_id: string
          note: string | null
          rater_id: string
          rating: Database["public"]["Enums"]["meeting_feedback_rating"]
        }
        Insert: {
          created_at?: string
          id?: string
          meeting_id: string
          note?: string | null
          rater_id: string
          rating: Database["public"]["Enums"]["meeting_feedback_rating"]
        }
        Update: {
          created_at?: string
          id?: string
          meeting_id?: string
          note?: string | null
          rater_id?: string
          rating?: Database["public"]["Enums"]["meeting_feedback_rating"]
        }
        Relationships: [
          {
            foreignKeyName: "meeting_feedback_meeting_id_fkey"
            columns: ["meeting_id"]
            isOneToOne: false
            referencedRelation: "meeting_proposals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meeting_feedback_rater_id_fkey"
            columns: ["rater_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      meeting_playbooks: {
        Row: {
          conversation_starters: string[]
          do_notes: string[]
          dont_notes: string[]
          generated_at: string
          generation_input_hash: string
          meeting_id: string
          shared_interests: string[]
          summary: string
          target_id: string
          viewer_id: string
        }
        Insert: {
          conversation_starters?: string[]
          do_notes?: string[]
          dont_notes?: string[]
          generated_at?: string
          generation_input_hash: string
          meeting_id: string
          shared_interests?: string[]
          summary: string
          target_id: string
          viewer_id: string
        }
        Update: {
          conversation_starters?: string[]
          do_notes?: string[]
          dont_notes?: string[]
          generated_at?: string
          generation_input_hash?: string
          meeting_id?: string
          shared_interests?: string[]
          summary?: string
          target_id?: string
          viewer_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "meeting_playbooks_meeting_id_fkey"
            columns: ["meeting_id"]
            isOneToOne: false
            referencedRelation: "meeting_proposals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meeting_playbooks_target_id_fkey"
            columns: ["target_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meeting_playbooks_viewer_id_fkey"
            columns: ["viewer_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      meeting_proposals: {
        Row: {
          confirmed_slot: string | null
          conversation_id: string
          created_at: string
          duration_minutes: number
          id: string
          meeting_url: string | null
          proposed_by_id: string | null
          slots: string[]
          state: Database["public"]["Enums"]["meeting_state"]
          timezone: string | null
          updated_at: string
        }
        Insert: {
          confirmed_slot?: string | null
          conversation_id: string
          created_at?: string
          duration_minutes?: number
          id?: string
          meeting_url?: string | null
          proposed_by_id?: string | null
          slots: string[]
          state?: Database["public"]["Enums"]["meeting_state"]
          timezone?: string | null
          updated_at?: string
        }
        Update: {
          confirmed_slot?: string | null
          conversation_id?: string
          created_at?: string
          duration_minutes?: number
          id?: string
          meeting_url?: string | null
          proposed_by_id?: string | null
          slots?: string[]
          state?: Database["public"]["Enums"]["meeting_state"]
          timezone?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "meeting_proposals_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meeting_proposals_proposed_by_id_fkey"
            columns: ["proposed_by_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      meeting_reviews: {
        Row: {
          created_at: string
          id: string
          meeting_id: string
          note: string | null
          outcome: string
          reviewer_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          meeting_id: string
          note?: string | null
          outcome: string
          reviewer_id: string
        }
        Update: {
          created_at?: string
          id?: string
          meeting_id?: string
          note?: string | null
          outcome?: string
          reviewer_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "meeting_reviews_meeting_id_fkey"
            columns: ["meeting_id"]
            isOneToOne: false
            referencedRelation: "meeting_proposals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meeting_reviews_reviewer_id_fkey"
            columns: ["reviewer_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      messages: {
        Row: {
          body: string | null
          conversation_id: string
          created_at: string
          deleted_at: string | null
          edited_at: string | null
          id: string
          kind: Database["public"]["Enums"]["message_kind"]
          media_duration_ms: number | null
          media_path: string | null
          media_size_bytes: number | null
          meeting_proposal_id: string | null
          sender_id: string
          transcript: string | null
          transcript_status:
            | Database["public"]["Enums"]["transcript_status"]
            | null
        }
        Insert: {
          body?: string | null
          conversation_id: string
          created_at?: string
          deleted_at?: string | null
          edited_at?: string | null
          id?: string
          kind?: Database["public"]["Enums"]["message_kind"]
          media_duration_ms?: number | null
          media_path?: string | null
          media_size_bytes?: number | null
          meeting_proposal_id?: string | null
          sender_id: string
          transcript?: string | null
          transcript_status?:
            | Database["public"]["Enums"]["transcript_status"]
            | null
        }
        Update: {
          body?: string | null
          conversation_id?: string
          created_at?: string
          deleted_at?: string | null
          edited_at?: string | null
          id?: string
          kind?: Database["public"]["Enums"]["message_kind"]
          media_duration_ms?: number | null
          media_path?: string | null
          media_size_bytes?: number | null
          meeting_proposal_id?: string | null
          sender_id?: string
          transcript?: string | null
          transcript_status?:
            | Database["public"]["Enums"]["transcript_status"]
            | null
        }
        Relationships: [
          {
            foreignKeyName: "messages_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "messages_meeting_proposal_id_fkey"
            columns: ["meeting_proposal_id"]
            isOneToOne: false
            referencedRelation: "meeting_proposals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "messages_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_preferences: {
        Row: {
          channel: Database["public"]["Enums"]["notification_channel"]
          enabled: boolean
          kind: Database["public"]["Enums"]["notification_kind"]
          user_id: string
        }
        Insert: {
          channel: Database["public"]["Enums"]["notification_channel"]
          enabled?: boolean
          kind: Database["public"]["Enums"]["notification_kind"]
          user_id: string
        }
        Update: {
          channel?: Database["public"]["Enums"]["notification_channel"]
          enabled?: boolean
          kind?: Database["public"]["Enums"]["notification_kind"]
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notification_preferences_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      office_hours_settings: {
        Row: {
          buffer_minutes: number
          enabled: boolean
          max_bookings_per_week: number
          meeting_link_template: string | null
          notes_template: string | null
          slot_duration_minutes: number
          updated_at: string
          user_id: string
          windows: Json
        }
        Insert: {
          buffer_minutes?: number
          enabled?: boolean
          max_bookings_per_week?: number
          meeting_link_template?: string | null
          notes_template?: string | null
          slot_duration_minutes?: number
          updated_at?: string
          user_id: string
          windows?: Json
        }
        Update: {
          buffer_minutes?: number
          enabled?: boolean
          max_bookings_per_week?: number
          meeting_link_template?: string | null
          notes_template?: string | null
          slot_duration_minutes?: number
          updated_at?: string
          user_id?: string
          windows?: Json
        }
        Relationships: [
          {
            foreignKeyName: "office_hours_settings_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      office_hours_slots: {
        Row: {
          booked_at: string | null
          booked_by: string | null
          ends_at: string
          host_id: string
          id: string
          meeting_proposal_id: string | null
          starts_at: string
          status: string
          topic: string | null
        }
        Insert: {
          booked_at?: string | null
          booked_by?: string | null
          ends_at: string
          host_id: string
          id?: string
          meeting_proposal_id?: string | null
          starts_at: string
          status?: string
          topic?: string | null
        }
        Update: {
          booked_at?: string | null
          booked_by?: string | null
          ends_at?: string
          host_id?: string
          id?: string
          meeting_proposal_id?: string | null
          starts_at?: string
          status?: string
          topic?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "office_hours_slots_booked_by_fkey"
            columns: ["booked_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "office_hours_slots_host_id_fkey"
            columns: ["host_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "office_hours_slots_meeting_proposal_id_fkey"
            columns: ["meeting_proposal_id"]
            isOneToOne: false
            referencedRelation: "meeting_proposals"
            referencedColumns: ["id"]
          },
        ]
      }
      opportunities: {
        Row: {
          author_id: string
          body: string
          closed_at: string | null
          created_at: string
          expires_at: string | null
          id: string
          kind: Database["public"]["Enums"]["opportunity_kind"]
          location_city: string | null
          location_country: string | null
          remote_ok: boolean
          status: Database["public"]["Enums"]["opportunity_status"]
          tags: string[]
          title: string
          updated_at: string
        }
        Insert: {
          author_id: string
          body: string
          closed_at?: string | null
          created_at?: string
          expires_at?: string | null
          id?: string
          kind: Database["public"]["Enums"]["opportunity_kind"]
          location_city?: string | null
          location_country?: string | null
          remote_ok?: boolean
          status?: Database["public"]["Enums"]["opportunity_status"]
          tags?: string[]
          title: string
          updated_at?: string
        }
        Update: {
          author_id?: string
          body?: string
          closed_at?: string | null
          created_at?: string
          expires_at?: string | null
          id?: string
          kind?: Database["public"]["Enums"]["opportunity_kind"]
          location_city?: string | null
          location_country?: string | null
          remote_ok?: boolean
          status?: Database["public"]["Enums"]["opportunity_status"]
          tags?: string[]
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "opportunities_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      opportunity_interests: {
        Row: {
          created_at: string
          note: string | null
          opportunity_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          note?: string | null
          opportunity_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          note?: string | null
          opportunity_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "opportunity_interests_opportunity_id_fkey"
            columns: ["opportunity_id"]
            isOneToOne: false
            referencedRelation: "opportunities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "opportunity_interests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          bio: string | null
          city: string | null
          country: string | null
          created_at: string
          goal_text: string | null
          goal_type: Database["public"]["Enums"]["goal_type"] | null
          goal_updated_at: string | null
          handle: string | null
          headline: string | null
          id: string
          name: string | null
          onboarded: boolean
          photo_url: string | null
          primary_role: Database["public"]["Enums"]["role_kind"] | null
          private_mode: boolean
          public_investor_page: boolean
          read_receipts_enabled: boolean
          roles: Database["public"]["Enums"]["role_kind"][]
          suspended_at: string | null
          updated_at: string
          verified_at: string | null
          verified_github_id: number | null
          verified_github_username: string | null
        }
        Insert: {
          bio?: string | null
          city?: string | null
          country?: string | null
          created_at?: string
          goal_text?: string | null
          goal_type?: Database["public"]["Enums"]["goal_type"] | null
          goal_updated_at?: string | null
          handle?: string | null
          headline?: string | null
          id: string
          name?: string | null
          onboarded?: boolean
          photo_url?: string | null
          primary_role?: Database["public"]["Enums"]["role_kind"] | null
          private_mode?: boolean
          public_investor_page?: boolean
          read_receipts_enabled?: boolean
          roles?: Database["public"]["Enums"]["role_kind"][]
          suspended_at?: string | null
          updated_at?: string
          verified_at?: string | null
          verified_github_id?: number | null
          verified_github_username?: string | null
        }
        Update: {
          bio?: string | null
          city?: string | null
          country?: string | null
          created_at?: string
          goal_text?: string | null
          goal_type?: Database["public"]["Enums"]["goal_type"] | null
          goal_updated_at?: string | null
          handle?: string | null
          headline?: string | null
          id?: string
          name?: string | null
          onboarded?: boolean
          photo_url?: string | null
          primary_role?: Database["public"]["Enums"]["role_kind"] | null
          private_mode?: boolean
          public_investor_page?: boolean
          read_receipts_enabled?: boolean
          roles?: Database["public"]["Enums"]["role_kind"][]
          suspended_at?: string | null
          updated_at?: string
          verified_at?: string | null
          verified_github_id?: number | null
          verified_github_username?: string | null
        }
        Relationships: []
      }
      push_log: {
        Row: {
          created_at: string
          delivered: boolean
          error: string | null
          event_id: string
          event_table: string
          id: string
          payload: Json
          recipient_id: string
        }
        Insert: {
          created_at?: string
          delivered?: boolean
          error?: string | null
          event_id: string
          event_table: string
          id?: string
          payload: Json
          recipient_id: string
        }
        Update: {
          created_at?: string
          delivered?: boolean
          error?: string | null
          event_id?: string
          event_table?: string
          id?: string
          payload?: Json
          recipient_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "push_log_recipient_id_fkey"
            columns: ["recipient_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      reports: {
        Row: {
          created_at: string
          id: string
          note: string | null
          reason: Database["public"]["Enums"]["report_reason"]
          reporter_id: string
          target_id: string
          target_type: Database["public"]["Enums"]["report_target_type"]
        }
        Insert: {
          created_at?: string
          id?: string
          note?: string | null
          reason: Database["public"]["Enums"]["report_reason"]
          reporter_id: string
          target_id: string
          target_type: Database["public"]["Enums"]["report_target_type"]
        }
        Update: {
          created_at?: string
          id?: string
          note?: string | null
          reason?: Database["public"]["Enums"]["report_reason"]
          reporter_id?: string
          target_id?: string
          target_type?: Database["public"]["Enums"]["report_target_type"]
        }
        Relationships: [
          {
            foreignKeyName: "reports_reporter_id_fkey"
            columns: ["reporter_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      _opportunity_validate_input: {
        Args: { p_body: string; p_tags: string[]; p_title: string }
        Returns: undefined
      }
      accept_intro: {
        Args: { p_intro_id: string }
        Returns: {
          conversation_id: string | null
          created_at: string
          declined_at: string | null
          expires_at: string
          id: string
          kind: Database["public"]["Enums"]["intro_kind"]
          note: string
          recipient_id: string | null
          sender_id: string | null
          state: Database["public"]["Enums"]["intro_state"]
          updated_at: string
          warm_target_id: string | null
        }
        SetofOptions: {
          from: "*"
          to: "intros"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      block_user: { Args: { p_target: string }; Returns: undefined }
      book_slot: {
        Args: { p_slot_id: string; p_topic: string }
        Returns: string
      }
      cancel_booking: { Args: { p_slot_id: string }; Returns: undefined }
      cancel_meeting: {
        Args: { p_meeting_id: string }
        Returns: {
          confirmed_slot: string | null
          conversation_id: string
          created_at: string
          duration_minutes: number
          id: string
          meeting_url: string | null
          proposed_by_id: string | null
          slots: string[]
          state: Database["public"]["Enums"]["meeting_state"]
          timezone: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "meeting_proposals"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      check_handle_available: { Args: { p_handle: string }; Returns: boolean }
      clear_github_verification: {
        Args: never
        Returns: {
          bio: string | null
          city: string | null
          country: string | null
          created_at: string
          goal_text: string | null
          goal_type: Database["public"]["Enums"]["goal_type"] | null
          goal_updated_at: string | null
          handle: string | null
          headline: string | null
          id: string
          name: string | null
          onboarded: boolean
          photo_url: string | null
          primary_role: Database["public"]["Enums"]["role_kind"] | null
          private_mode: boolean
          public_investor_page: boolean
          read_receipts_enabled: boolean
          roles: Database["public"]["Enums"]["role_kind"][]
          suspended_at: string | null
          updated_at: string
          verified_at: string | null
          verified_github_id: number | null
          verified_github_username: string | null
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      close_opportunity: { Args: { p_id: string }; Returns: undefined }
      confirm_meeting: {
        Args: { p_meeting_id: string; p_slot: string }
        Returns: {
          confirmed_slot: string | null
          conversation_id: string
          created_at: string
          duration_minutes: number
          id: string
          meeting_url: string | null
          proposed_by_id: string | null
          slots: string[]
          state: Database["public"]["Enums"]["meeting_state"]
          timezone: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "meeting_proposals"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_opportunity: {
        Args: {
          p_body: string
          p_expires_at?: string
          p_kind: Database["public"]["Enums"]["opportunity_kind"]
          p_location_city?: string
          p_location_country?: string
          p_remote_ok?: boolean
          p_tags?: string[]
          p_title: string
        }
        Returns: string
      }
      decline_intro: {
        Args: { p_intro_id: string }
        Returns: {
          conversation_id: string | null
          created_at: string
          declined_at: string | null
          expires_at: string
          id: string
          kind: Database["public"]["Enums"]["intro_kind"]
          note: string
          recipient_id: string | null
          sender_id: string | null
          state: Database["public"]["Enums"]["intro_state"]
          updated_at: string
          warm_target_id: string | null
        }
        SetofOptions: {
          from: "*"
          to: "intros"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      decline_meeting: {
        Args: { p_meeting_id: string }
        Returns: {
          confirmed_slot: string | null
          conversation_id: string
          created_at: string
          duration_minutes: number
          id: string
          meeting_url: string | null
          proposed_by_id: string | null
          slots: string[]
          state: Database["public"]["Enums"]["meeting_state"]
          timezone: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "meeting_proposals"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      delete_message: {
        Args: { p_id: string }
        Returns: {
          body: string | null
          conversation_id: string
          created_at: string
          deleted_at: string | null
          edited_at: string | null
          id: string
          kind: Database["public"]["Enums"]["message_kind"]
          media_duration_ms: number | null
          media_path: string | null
          media_size_bytes: number | null
          meeting_proposal_id: string | null
          sender_id: string
          transcript: string | null
          transcript_status:
            | Database["public"]["Enums"]["transcript_status"]
            | null
        }
        SetofOptions: {
          from: "*"
          to: "messages"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      delete_my_account: { Args: never; Returns: undefined }
      dispatch_push: {
        Args: {
          p_conversation_id?: string
          p_entity_id?: string
          p_event_id: string
          p_event_table: string
          p_kind?: string
          p_payload: Json
          p_recipient_id: string
        }
        Returns: undefined
      }
      dispatch_transcription: {
        Args: { p_message_id: string }
        Returns: undefined
      }
      edit_message: {
        Args: { p_body: string; p_id: string }
        Returns: {
          body: string | null
          conversation_id: string
          created_at: string
          deleted_at: string | null
          edited_at: string | null
          id: string
          kind: Database["public"]["Enums"]["message_kind"]
          media_duration_ms: number | null
          media_path: string | null
          media_size_bytes: number | null
          meeting_proposal_id: string | null
          sender_id: string
          transcript: string | null
          transcript_status:
            | Database["public"]["Enums"]["transcript_status"]
            | null
        }
        SetofOptions: {
          from: "*"
          to: "messages"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      expire_overdue_intros: { Args: never; Returns: number }
      export_my_data: { Args: never; Returns: Json }
      express_interest: {
        Args: { p_note?: string; p_opportunity_id: string }
        Returns: undefined
      }
      forward_warm_intro: {
        Args: { p_intro_id: string; p_note: string }
        Returns: string
      }
      get_daily_matches: {
        Args: { p_for_date?: string }
        Returns: {
          bio: string
          city: string
          country: string
          created_at: string
          for_date_local: string
          goal_type: Database["public"]["Enums"]["goal_type"]
          handle: string
          headline: string
          id: string
          match_reason: string
          name: string
          photo_url: string
          pick_user_id: string
          primary_role: Database["public"]["Enums"]["role_kind"]
          roles: Database["public"]["Enums"]["role_kind"][]
          viewed_at: string
        }[]
      }
      get_meeting_playbook: {
        Args: { p_meeting_id: string }
        Returns: {
          conversation_starters: string[]
          do_notes: string[]
          dont_notes: string[]
          generated_at: string
          shared_interests: string[]
          summary: string
        }[]
      }
      get_opportunity: {
        Args: { p_id: string }
        Returns: {
          author_handle: string
          author_id: string
          author_name: string
          author_photo_url: string
          author_primary_role: Database["public"]["Enums"]["role_kind"]
          body: string
          closed_at: string
          created_at: string
          expires_at: string
          id: string
          interested_count: number
          kind: Database["public"]["Enums"]["opportunity_kind"]
          location_city: string
          location_country: string
          remote_ok: boolean
          status: Database["public"]["Enums"]["opportunity_status"]
          tags: string[]
          title: string
          viewer_has_expressed_interest: boolean
        }[]
      }
      get_profile_signals: {
        Args: { p_target: string }
        Returns: {
          avg_meeting_rating: number
          mutual_connection_count: number
          mutual_top_user_ids: string[]
          total_meeting_reviews: number
        }[]
      }
      get_public_profile: {
        Args: { p_handle: string }
        Returns: {
          bio: string
          city: string
          country: string
          handle: string
          headline: string
          id: string
          name: string
          photo_url: string
          primary_role: Database["public"]["Enums"]["role_kind"]
          roles: Database["public"]["Enums"]["role_kind"][]
          verified_github_username: string
        }[]
      }
      goals_complementary: {
        Args: {
          a: Database["public"]["Enums"]["goal_type"]
          b: Database["public"]["Enums"]["goal_type"]
        }
        Returns: boolean
      }
      intros_today_count: { Args: never; Returns: number }
      is_mutual_match: { Args: { p_other: string }; Returns: boolean }
      list_blocked_users: {
        Args: never
        Returns: {
          blocked_id: string
          created_at: string
          handle: string
          name: string
          photo_url: string
        }[]
      }
      list_connections: {
        Args: never
        Returns: {
          connected_at: string
          conversation_id: string
          handle: string
          name: string
          photo_url: string
          primary_role: Database["public"]["Enums"]["role_kind"]
          user_id: string
        }[]
      }
      list_conversation_overview: {
        Args: { p_user_id?: string }
        Returns: {
          conversation_id: string
          is_muted: boolean
          last_message_at: string
          last_message_body: string
          last_message_kind: Database["public"]["Enums"]["message_kind"]
          peer_handle: string
          peer_id: string
          peer_name: string
          peer_photo_url: string
          unread_count: number
        }[]
      }
      list_conversation_unread: {
        Args: never
        Returns: {
          conversation_id: string
          unread_count: number
        }[]
      }
      list_interested: {
        Args: { p_opportunity_id: string }
        Returns: {
          created_at: string
          handle: string
          name: string
          note: string
          photo_url: string
          primary_role: Database["public"]["Enums"]["role_kind"]
          user_id: string
        }[]
      }
      list_my_opportunities: {
        Args: never
        Returns: {
          author_id: string
          body: string
          closed_at: string
          created_at: string
          expires_at: string
          id: string
          interested_count: number
          kind: Database["public"]["Enums"]["opportunity_kind"]
          location_city: string
          location_country: string
          remote_ok: boolean
          status: Database["public"]["Enums"]["opportunity_status"]
          tags: string[]
          title: string
        }[]
      }
      list_opportunities: {
        Args: {
          p_kinds?: Database["public"]["Enums"]["opportunity_kind"][]
          p_limit?: number
          p_offset?: number
          p_remote_only?: boolean
          p_search?: string
        }
        Returns: {
          author_handle: string
          author_id: string
          author_name: string
          author_photo_url: string
          author_primary_role: Database["public"]["Enums"]["role_kind"]
          body: string
          created_at: string
          expires_at: string
          id: string
          interested_count: number
          kind: Database["public"]["Enums"]["opportunity_kind"]
          location_city: string
          location_country: string
          remote_ok: boolean
          tags: string[]
          title: string
        }[]
      }
      list_upcoming_slots: {
        Args: { p_host: string }
        Returns: {
          ends_at: string
          host_settings_notes_template: string
          id: string
          starts_at: string
        }[]
      }
      lookup_email_by_handle: { Args: { p_handle: string }; Returns: string }
      mark_conversation_read: {
        Args: { p_conversation_id: string }
        Returns: undefined
      }
      mark_match_viewed: { Args: { p_match_id: string }; Returns: undefined }
      match_reason_for: {
        Args: { p_other: string; p_self: string }
        Returns: string
      }
      match_score: {
        Args: { p_other: string; p_self: string }
        Returns: number
      }
      materialize_office_hours_slots: {
        Args: { p_host: string }
        Returns: undefined
      }
      mute_conversation: {
        Args: { p_conversation_id: string }
        Returns: undefined
      }
      my_bookings: {
        Args: never
        Returns: {
          ends_at: string
          host_handle: string
          host_id: string
          host_name: string
          host_photo_url: string
          meeting_proposal_id: string
          slot_id: string
          starts_at: string
          topic: string
        }[]
      }
      my_office_hours_settings: {
        Args: never
        Returns: {
          buffer_minutes: number
          enabled: boolean
          max_bookings_per_week: number
          meeting_link_template: string | null
          notes_template: string | null
          slot_duration_minutes: number
          updated_at: string
          user_id: string
          windows: Json
        }
        SetofOptions: {
          from: "*"
          to: "office_hours_settings"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      pending_meeting_reviews: {
        Args: { p_conversation_id?: string }
        Returns: {
          confirmed_slot: string | null
          conversation_id: string
          created_at: string
          duration_minutes: number
          id: string
          meeting_url: string | null
          proposed_by_id: string | null
          slots: string[]
          state: Database["public"]["Enums"]["meeting_state"]
          timezone: string | null
          updated_at: string
        }[]
        SetofOptions: {
          from: "*"
          to: "meeting_proposals"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      propose_meeting: {
        Args: {
          p_conversation_id: string
          p_duration_minutes?: number
          p_meeting_url?: string
          p_slots: string[]
          p_timezone?: string
        }
        Returns: {
          confirmed_slot: string | null
          conversation_id: string
          created_at: string
          duration_minutes: number
          id: string
          meeting_url: string | null
          proposed_by_id: string | null
          slots: string[]
          state: Database["public"]["Enums"]["meeting_state"]
          timezone: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "meeting_proposals"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      register_device_token: {
        Args: {
          p_platform: Database["public"]["Enums"]["device_platform"]
          p_token: string
        }
        Returns: {
          created_at: string
          id: string
          last_seen_at: string
          platform: Database["public"]["Enums"]["device_platform"]
          revoked_at: string | null
          token: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "device_tokens"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      report_target: {
        Args: {
          p_note: string
          p_reason: string
          p_target_id: string
          p_target_type: string
        }
        Returns: undefined
      }
      search_discoverable_profiles: {
        Args: {
          p_country?: string
          p_cursor?: string
          p_goal_types?: Database["public"]["Enums"]["goal_type"][]
          p_limit?: number
          p_query?: string
          p_roles?: Database["public"]["Enums"]["role_kind"][]
        }
        Returns: {
          bio: string
          city: string
          country: string
          created_at: string
          goal_text: string
          goal_type: Database["public"]["Enums"]["goal_type"]
          handle: string
          headline: string
          id: string
          name: string
          photo_url: string
          primary_role: Database["public"]["Enums"]["role_kind"]
          roles: Database["public"]["Enums"]["role_kind"][]
        }[]
      }
      send_image_message: {
        Args: {
          p_conversation_id: string
          p_media_mime: string
          p_media_path: string
          p_media_size_bytes: number
        }
        Returns: {
          body: string | null
          conversation_id: string
          created_at: string
          deleted_at: string | null
          edited_at: string | null
          id: string
          kind: Database["public"]["Enums"]["message_kind"]
          media_duration_ms: number | null
          media_path: string | null
          media_size_bytes: number | null
          meeting_proposal_id: string | null
          sender_id: string
          transcript: string | null
          transcript_status:
            | Database["public"]["Enums"]["transcript_status"]
            | null
        }
        SetofOptions: {
          from: "*"
          to: "messages"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      send_intro: {
        Args: { p_note: string; p_recipient_id: string }
        Returns: {
          conversation_id: string | null
          created_at: string
          declined_at: string | null
          expires_at: string
          id: string
          kind: Database["public"]["Enums"]["intro_kind"]
          note: string
          recipient_id: string | null
          sender_id: string | null
          state: Database["public"]["Enums"]["intro_state"]
          updated_at: string
          warm_target_id: string | null
        }
        SetofOptions: {
          from: "*"
          to: "intros"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      send_voice_message: {
        Args: {
          p_conversation_id: string
          p_duration_ms: number
          p_media_mime: string
          p_media_path: string
          p_media_size_bytes: number
        }
        Returns: {
          body: string | null
          conversation_id: string
          created_at: string
          deleted_at: string | null
          edited_at: string | null
          id: string
          kind: Database["public"]["Enums"]["message_kind"]
          media_duration_ms: number | null
          media_path: string | null
          media_size_bytes: number | null
          meeting_proposal_id: string | null
          sender_id: string
          transcript: string | null
          transcript_status:
            | Database["public"]["Enums"]["transcript_status"]
            | null
        }
        SetofOptions: {
          from: "*"
          to: "messages"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      send_warm_request: {
        Args: { p_mutual_id: string; p_note: string; p_target_id: string }
        Returns: string
      }
      set_github_verification: {
        Args: { p_github_id: number; p_github_username: string }
        Returns: {
          bio: string | null
          city: string | null
          country: string | null
          created_at: string
          goal_text: string | null
          goal_type: Database["public"]["Enums"]["goal_type"] | null
          goal_updated_at: string | null
          handle: string | null
          headline: string | null
          id: string
          name: string | null
          onboarded: boolean
          photo_url: string | null
          primary_role: Database["public"]["Enums"]["role_kind"] | null
          private_mode: boolean
          public_investor_page: boolean
          read_receipts_enabled: boolean
          roles: Database["public"]["Enums"]["role_kind"][]
          suspended_at: string | null
          updated_at: string
          verified_at: string | null
          verified_github_id: number | null
          verified_github_username: string | null
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      set_office_hours: {
        Args: {
          p_buffer_minutes: number
          p_enabled: boolean
          p_max_bookings_per_week: number
          p_meeting_link_template: string
          p_notes_template: string
          p_slot_duration_minutes: number
          p_windows: Json
        }
        Returns: {
          buffer_minutes: number
          enabled: boolean
          max_bookings_per_week: number
          meeting_link_template: string | null
          notes_template: string | null
          slot_duration_minutes: number
          updated_at: string
          user_id: string
          windows: Json
        }
        SetofOptions: {
          from: "*"
          to: "office_hours_settings"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      set_private_mode: { Args: { p_value: boolean }; Returns: undefined }
      should_notify: {
        Args: {
          p_channel: Database["public"]["Enums"]["notification_channel"]
          p_kind: Database["public"]["Enums"]["notification_kind"]
          p_user_id: string
        }
        Returns: boolean
      }
      submit_meeting_feedback: {
        Args: {
          p_meeting_id: string
          p_note?: string
          p_rating: Database["public"]["Enums"]["meeting_feedback_rating"]
        }
        Returns: {
          created_at: string
          id: string
          meeting_id: string
          note: string | null
          rater_id: string
          rating: Database["public"]["Enums"]["meeting_feedback_rating"]
        }
        SetofOptions: {
          from: "*"
          to: "meeting_feedback"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      submit_meeting_review: {
        Args: { p_meeting_id: string; p_note: string; p_outcome: string }
        Returns: {
          created_at: string
          id: string
          meeting_id: string
          note: string | null
          outcome: string
          reviewer_id: string
        }
        SetofOptions: {
          from: "*"
          to: "meeting_reviews"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      suggest_warm_intros: {
        Args: { p_limit?: number }
        Returns: {
          mutual_count: number
          target_goal_type: Database["public"]["Enums"]["goal_type"]
          target_handle: string
          target_id: string
          target_name: string
          target_photo_url: string
          target_primary_role: Database["public"]["Enums"]["role_kind"]
          top_mutual_handle: string
          top_mutual_id: string
          top_mutual_name: string
        }[]
      }
      unblock_user: { Args: { p_target: string }; Returns: undefined }
      unmute_conversation: {
        Args: { p_conversation_id: string }
        Returns: undefined
      }
      unregister_device_token: { Args: { p_token: string }; Returns: undefined }
      update_opportunity: {
        Args: {
          p_body: string
          p_expires_at?: string
          p_id: string
          p_kind: Database["public"]["Enums"]["opportunity_kind"]
          p_location_city?: string
          p_location_country?: string
          p_remote_ok?: boolean
          p_tags?: string[]
          p_title: string
        }
        Returns: undefined
      }
    }
    Enums: {
      device_platform: "ios" | "android" | "web"
      goal_type:
        | "hire"
        | "be_hired"
        | "co_found"
        | "invest"
        | "take_investment"
        | "advise"
        | "find_advisor"
        | "peer_connect"
      intro_kind: "direct" | "warm_request" | "warm_forward"
      intro_state:
        | "delivered"
        | "accepted"
        | "declined"
        | "expired"
        | "connected"
      meeting_feedback_rating: "positive" | "neutral" | "negative"
      meeting_state: "proposed" | "confirmed" | "declined" | "cancelled"
      message_kind: "text" | "meeting" | "image" | "voice"
      notification_channel: "push" | "email" | "in_app"
      notification_kind:
        | "intro_received"
        | "intro_accepted"
        | "message_received"
        | "voice_received"
        | "meeting_reminder"
        | "daily_matches_ready"
        | "goal_staleness"
        | "meeting_proposal"
        | "meeting_confirmed"
        | "opportunity_interest"
      opportunity_kind:
        | "hiring"
        | "seeking_role"
        | "fundraising"
        | "investing"
        | "cofounder"
        | "advising"
        | "seeking_advisor"
        | "collaboration"
      opportunity_status: "open" | "closed" | "archived"
      report_reason:
        | "spam"
        | "harassment"
        | "impersonation"
        | "inappropriate"
        | "other"
      report_target_type: "profile" | "message" | "intro"
      role_kind: "founder" | "leader" | "builder" | "investor"
      transcript_status:
        | "pending"
        | "ready"
        | "failed"
        | "unsupported"
        | "processing"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
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
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
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
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
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
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {
      device_platform: ["ios", "android", "web"],
      goal_type: [
        "hire",
        "be_hired",
        "co_found",
        "invest",
        "take_investment",
        "advise",
        "find_advisor",
        "peer_connect",
      ],
      intro_kind: ["direct", "warm_request", "warm_forward"],
      intro_state: [
        "delivered",
        "accepted",
        "declined",
        "expired",
        "connected",
      ],
      meeting_feedback_rating: ["positive", "neutral", "negative"],
      meeting_state: ["proposed", "confirmed", "declined", "cancelled"],
      message_kind: ["text", "meeting", "image", "voice"],
      notification_channel: ["push", "email", "in_app"],
      notification_kind: [
        "intro_received",
        "intro_accepted",
        "message_received",
        "voice_received",
        "meeting_reminder",
        "daily_matches_ready",
        "goal_staleness",
        "meeting_proposal",
        "meeting_confirmed",
        "opportunity_interest",
      ],
      opportunity_kind: [
        "hiring",
        "seeking_role",
        "fundraising",
        "investing",
        "cofounder",
        "advising",
        "seeking_advisor",
        "collaboration",
      ],
      opportunity_status: ["open", "closed", "archived"],
      report_reason: [
        "spam",
        "harassment",
        "impersonation",
        "inappropriate",
        "other",
      ],
      report_target_type: ["profile", "message", "intro"],
      role_kind: ["founder", "leader", "builder", "investor"],
      transcript_status: [
        "pending",
        "ready",
        "failed",
        "unsupported",
        "processing",
      ],
    },
  },
} as const

<claude-code-hint v="1" type="plugin" value="supabase@claude-plugins-official" />
A new version of Supabase CLI is available: v2.101.0 (currently installed v2.98.2)
We recommend updating regularly for new features and bug fixes: https://supabase.com/docs/guides/cli/getting-started#updating-the-supabase-cli

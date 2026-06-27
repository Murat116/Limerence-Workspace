-- One-shot apply: run migrations 20260612100000 through 20260622100000 in order.
-- Prefer: supabase db push

\i ../migrations/20260612100000_analytics_schema.sql
\i ../migrations/20260612100001_analytics_rls.sql
\i ../migrations/20260612100006_analytics_helpers.sql
\i ../migrations/20260612100002_analytics_batch_rpc.sql
\i ../migrations/20260612100003_analytics_author_rpc.sql
\i ../migrations/20260612100004_analytics_retention_cron.sql
\i ../migrations/20260612100005_analytics_events_indexes.sql
\i ../migrations/20260614100000_start_read_chapter.sql
\i ../migrations/20260614100001_analytics_events_env_batch.sql
\i ../migrations/20260620100000_analytics_extended_rpc.sql
\i ../migrations/20260620100001_analytics_events_aggregate_rpc.sql
\i ../migrations/20260621100000_analytics_audience_rpc.sql
\i ../migrations/20260622100000_monetization_schema.sql
\i ../migrations/20260623100000_analytics_sandbox_relaxed.sql
\i ../migrations/20260624120000_analytics_access_editable_stories.sql

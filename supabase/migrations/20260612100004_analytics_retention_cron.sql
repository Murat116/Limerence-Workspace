CREATE OR REPLACE FUNCTION public.cleanup_analytics_events_retention()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_deleted integer;
BEGIN
  DELETE FROM public.analytics_events
  WHERE created_at < now() - interval '90 days';

  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$;

-- Schedule via pg_cron when available (optional manual run otherwise).
-- SELECT cron.schedule('cleanup-analytics-events', '0 3 * * *', $$SELECT public.cleanup_analytics_events_retention()$$);

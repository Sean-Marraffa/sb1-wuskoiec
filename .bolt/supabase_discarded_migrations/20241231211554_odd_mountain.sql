/*
  # Add Database Webhook for Team Invites
  
  1. Creates a trigger to call the invite email function when new invites are created
*/

-- Create the webhook trigger function
CREATE OR REPLACE FUNCTION notify_invite_webhook()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Make HTTP request to Edge Function
  PERFORM
    net.http_post(
      url := CONCAT(current_setting('app.settings.edge_function_base_url'), '/send-invite-email'),
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', current_setting('app.settings.service_role_key')
      ),
      body := jsonb_build_object(
        'type', TG_OP,
        'table', TG_TABLE_NAME,
        'schema', TG_TABLE_SCHEMA,
        'record', row_to_json(NEW),
        'old_record', CASE WHEN TG_OP = 'UPDATE' THEN row_to_json(OLD) ELSE NULL END
      )
    );
  
  RETURN NEW;
END;
$$;

-- Create the trigger
DROP TRIGGER IF EXISTS on_invite_created ON team_invites;
CREATE TRIGGER on_invite_created
  AFTER INSERT ON team_invites
  FOR EACH ROW
  EXECUTE FUNCTION notify_invite_webhook();
import { serve } from 'https://deno.fresh.dev/std@v1/http/server.ts';

interface WebhookPayload {
  type: 'INSERT';
  table: string;
  record: {
    id: string;
    email: string;
    invite_token: string;
    business_id: string;
  };
  schema: string;
  old_record: null | Record<string, any>;
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const payload: WebhookPayload = await req.json();

    // Only process new team invites
    if (payload.type === 'INSERT' && payload.table === 'team_invites') {
      const { email, invite_token, business_id } = payload.record;

      // Get business name
      const { data: business } = await supabaseAdmin
        .from('businesses')
        .select('name')
        .eq('id', business_id)
        .single();

      if (!business) {
        throw new Error('Business not found');
      }

      // Construct invite URL
      const inviteUrl = `${Deno.env.get('PUBLIC_SITE_URL')}/accept-invite?token=${invite_token}`;

      // Send email using your preferred email service
      // Here's an example using SendGrid
      const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${Deno.env.get('SENDGRID_API_KEY')}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          personalizations: [{
            to: [{ email }],
          }],
          from: { 
            email: 'noreply@yourdomain.com',
            name: 'BookingVibe'
          },
          subject: `You've been invited to join ${business.name} on BookingVibe`,
          content: [{
            type: 'text/html',
            value: `
              <h2>You've been invited!</h2>
              <p>You've been invited to join ${business.name} on BookingVibe.</p>
              <p>Click the button below to accept your invitation:</p>
              <a href="${inviteUrl}" style="display:inline-block;padding:12px 24px;background:#4F46E5;color:white;text-decoration:none;border-radius:6px;">
                Accept Invitation
              </a>
              <p>This invite will expire in 7 days.</p>
            `
          }]
        })
      });

      if (!response.ok) {
        throw new Error('Failed to send email');
      }
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
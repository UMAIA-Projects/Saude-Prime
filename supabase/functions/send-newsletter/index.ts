import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { subject, html_content } = await req.json()

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { data: subscribers, error: dbError } = await supabaseClient
      .from('user_preferences')
      .select('user_id, users!inner(email)')
      .eq('newsletter_optin', true)

    if (dbError) throw dbError

    const emails: string[] = subscribers.map((sub: any) => sub.users.email)

    if (emails.length === 0) {
      return new Response(
        JSON.stringify({ message: "Nenhum subscritor encontrado." }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    const client = new SMTPClient({
      connection: {
        hostname: "smtp.gmail.com",
        port: 465,
        tls: true,
        auth: {
          username: Deno.env.get('GMAIL_USER') ?? '',
          password: Deno.env.get('GMAIL_PASSWORD') ?? '',
        },
      },
    })

    await client.send({
      from: `"Saúde Prime ++" <${Deno.env.get('GMAIL_USER')}>`,
      to: emails,
      subject: subject,
      html: html_content,
    })

    await client.close()

    return new Response(
      JSON.stringify({ success: true, message: `Newsletter enviada para ${emails.length} subscritores!` }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
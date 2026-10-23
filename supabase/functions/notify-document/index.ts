import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { patient_id, doc_type, doc_name } = await req.json()

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { data: patient, error: dbError } = await supabaseClient
      .from('users')
      .select('name, email, phone') 
      .eq('id', patient_id)
      .single()

    if (dbError || !patient) throw new Error("Paciente não encontrado.")

    const { data: prefs } = await supabaseClient
      .from('user_preferences')
      .select('email_notifications, sms_notifications')
      .eq('user_id', patient_id)
      .maybeSingle()

    const sendEmail = prefs?.email_notifications ?? true;
    const sendSms = prefs?.sms_notifications ?? false;


    if (sendEmail && patient.email) {
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

      const htmlTemplate = `
        <div style="font-family: 'Poppins', sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #E0ECEB; border-radius: 10px;">
          <div style="background-color: #1A8070; padding: 20px; text-align: center;">
            <h1 style="color: white; margin: 0;">Saúde Prime ++</h1>
          </div>
          <div style="padding: 30px; background-color: #FAFAFA; color: #333333;">
            <h2 style="color: #1A8070;">Olá, ${patient.name}</h2>
            <p>O documento <strong>${doc_type}</strong> (${doc_name}) já está no seu portal.</p>
          </div>
        </div>
      `;

      await client.send({
        from: `"Saúde Prime ++" <${Deno.env.get('GMAIL_USER')}>`,
        to: patient.email, 
        subject: `Novo Documento: ${doc_type}`,
        html: htmlTemplate
      })
      await client.close()
    }


    if (sendSms && patient.phone) {
      const twilioSid = Deno.env.get('TWILIO_ACCOUNT_SID');
      const twilioAuth = Deno.env.get('TWILIO_AUTH_TOKEN');
      const twilioPhone = Deno.env.get('TWILIO_PHONE_NUMBER');

      let destPhone = patient.phone;
      if (!destPhone.startsWith('+')) {
        destPhone = '+351' + destPhone;
      }

      const twilioUrl = `https://api.twilio.com/2010-04-01/Accounts/${twilioSid}/Messages.json`;
      
      const twilioData = new URLSearchParams();
      twilioData.append('To', destPhone);
      twilioData.append('From', twilioPhone!);
      twilioData.append('Body', `Saude Prime++: Ola ${patient.name}, um novo documento do tipo ${doc_type} foi adicionado ao seu portal.`);

      await fetch(twilioUrl, {
        method: 'POST',
        headers: {
          'Authorization': 'Basic ' + btoa(`${twilioSid}:${twilioAuth}`),
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: twilioData,
      });
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Notificações processadas!' }), 
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }), 
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
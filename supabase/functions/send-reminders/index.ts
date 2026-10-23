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
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const startOfTomorrow = new Date(tomorrow.setHours(0, 0, 0, 0)).toISOString();
    const endOfTomorrow = new Date(tomorrow.setHours(23, 59, 59, 999)).toISOString();

    //Adicionada a coluna scheduled_time à query
    const { data: appointments, error: apptError } = await supabase
      .from('appointments')
      .select('id, scheduled_date, scheduled_time, patient_id')
      .eq('status', 'scheduled')
      .gte('scheduled_date', startOfTomorrow)
      .lte('scheduled_date', endOfTomorrow);

    if (apptError) throw apptError;

    if (!appointments || appointments.length === 0) {
      return new Response(
        JSON.stringify({ message: 'Nenhuma consulta marcada para amanhã.' }), 
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      );
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

    let emailsEnviados = 0;

    for (const appt of appointments) {
      
      const { data: patient } = await supabase
        .from('users')
        .select('name, email')
        .eq('id', appt.patient_id)
        .single();

      const { data: prefs } = await supabase
        .from('user_preferences')
        .select('reminder_24h')
        .eq('user_id', appt.patient_id)
        .maybeSingle();

      const querLembrete = prefs?.reminder_24h ?? true;

      if (patient && patient.email && querLembrete) {
        
        //CORREÇÃO: O Postgres devolve a hora no formato "16:30:00". 
        const horaStr = appt.scheduled_time.substring(0, 5);

        const htmlTemplate = `
          <div style="font-family: 'Poppins', sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #E0ECEB; border-radius: 10px;">
            <div style="background-color: #1A8070; padding: 20px; text-align: center;">
              <h1 style="color: white; margin: 0;">Saúde Prime ++</h1>
            </div>
            <div style="padding: 30px; background-color: #FAFAFA; color: #333333; line-height: 1.6;">
              <h2 style="color: #1A8070;">Olá, ${patient.name}</h2>
              <p>Este é um lembrete automático da sua Clínica Saúde Prime ++.</p>
              <p>Tem uma consulta marcada para amanhã às <strong>${horaStr}</strong>.</p>
              <br>
              <p>Se não puder comparecer, pedimos que aceda ao seu Portal do Paciente com a maior brevidade possível para reagendar ou cancelar a consulta, permitindo que outro paciente utilize o horário.</p>
            </div>
            <div style="background-color: #D5E2E3; padding: 15px; text-align: center; font-size: 12px; color: #787878;">
              <p>© 2026 Clínica Médica Saúde Prime ++</p>
            </div>
          </div>
        `;

        await client.send({
          from: `"Saúde Prime ++" <${Deno.env.get('GMAIL_USER')}>`,
          to: patient.email, 
          subject: `Lembrete: Consulta amanhã às ${horaStr}`,
          html: htmlTemplate
        });

        emailsEnviados++;
      }
    }

    await client.close();

    return new Response(
      JSON.stringify({ success: true, message: `Processo concluído. Foram enviados ${emailsEnviados} e-mails de lembrete.` }), 
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }), 
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
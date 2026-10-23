import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { patient_email, patient_name, doctor_name, data, hora } = await req.json()

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
        <div style="background-color: #C62828; padding: 20px; text-align: center;">
          <h1 style="color: white; margin: 0;">Saúde Prime ++</h1>
        </div>
        <div style="padding: 30px; background-color: #FAFAFA; color: #333333;">
          <h2 style="color: #C62828;">Olá, ${patient_name}</h2>
          <p>Confirmamos que a sua consulta foi <strong>cancelada com sucesso</strong>, conforme solicitado.</p>
          <div style="background-color: #FFF3CD; padding: 15px; border-left: 4px solid #FFC107; color: #856404; margin-top: 20px;">
            <p style="margin-top: 0;"><strong>Detalhes do Cancelamento:</strong></p>
            <p><strong>Médico:</strong> ${doctor_name}</p>
            <p><strong>Data:</strong> ${data}</p>
            <p><strong>Hora:</strong> ${hora}</p>
          </div>
          <br>
          <p>Agradecemos o aviso prévio. Pode marcar uma nova consulta a qualquer momento através do seu Portal do Paciente.</p>
        </div>
      </div>
    `;

    await client.send({
      from: `"Saúde Prime ++" <${Deno.env.get('GMAIL_USER')}>`,
      to: patient_email,
      subject: `Saúde Prime++ | Cancelamento de Consulta`,
      html: htmlTemplate
    })

    await client.close()

    return new Response(JSON.stringify({ success: true }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 })
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
  }
})
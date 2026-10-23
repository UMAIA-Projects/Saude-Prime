import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"
import { PDFDocument, StandardFonts, rgb } from "https://esm.sh/pdf-lib@1.17.1"
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

const CLINIC_NAME    = Deno.env.get("CLINIC_NAME")    ?? "Saúde Prime ++"
const CLINIC_NIF     = Deno.env.get("CLINIC_NIF")     ?? "500000000"
const CLINIC_ADDRESS = Deno.env.get("CLINIC_ADDRESS") ?? "Rua da Saúde, 1 – 4700-000 Braga"

function typeLabel(t: string): string {
  if (t === "urgent")    return "Urgente"
  if (t === "follow_up") return "Análise / Follow-up"
  return "Normal"
}

function formatDate(d: string): string {
  const [y, m, day] = d.split("-")
  return `${day}/${m}/${y}`
}

function pad2(n: number): string {
  return String(n).padStart(2, "0")
}

function invoiceNumber(appointmentId: string): string {
  const ts = Date.now()
  return `FT${ts.toString().slice(-6)}-${appointmentId.slice(0, 6).toUpperCase()}`
}

async function buildPdf(data: {
  invoiceNum:      string
  issuedAt:        string
  patientName:     string
  patientNif:      string
  patientAddress:  string
  doctorName:      string
  appointmentDate: string
  appointmentTime: string
  appointmentType: string
  amount:          number
}): Promise<Uint8Array> {
  const doc   = await PDFDocument.create()
  const page  = doc.addPage([595, 842])
  const font  = await doc.embedFont(StandardFonts.Helvetica)
  const fontB = await doc.embedFont(StandardFonts.HelveticaBold)

  const { width, height } = page.getSize()
  const green = rgb(0.1, 0.5, 0.44)
  const dark  = rgb(0.1, 0.1, 0.1)
  const grey  = rgb(0.45, 0.45, 0.45)

  page.drawRectangle({ x: 0, y: height - 80, width, height: 80, color: green })
  page.drawText(CLINIC_NAME, {
    x: 40, y: height - 52, size: 22, font: fontB, color: rgb(1, 1, 1),
  })
  page.drawText("FATURA / RECIBO", {
    x: width - 180, y: height - 52, size: 14, font: fontB, color: rgb(1, 1, 1),
  })

  let y = height - 110
  page.drawText(`Nº: ${data.invoiceNum}`, { x: 40, y, size: 11, font: fontB, color: dark })
  page.drawText(`Data de emissão: ${data.issuedAt}`, {
    x: width - 240, y, size: 11, font, color: dark,
  })

  y -= 32
  page.drawText("EMITIDO POR", { x: 40, y, size: 9, font: fontB, color: green })
  y -= 16
  page.drawText(CLINIC_NAME,    { x: 40, y, size: 10, font: fontB, color: dark })
  y -= 14
  page.drawText(`NIF: ${CLINIC_NIF}`, { x: 40, y, size: 10, font, color: dark })
  y -= 14
  page.drawText(CLINIC_ADDRESS, { x: 40, y, size: 10, font, color: grey })

  const colRight = width / 2 + 20
  let yP = height - 142
  page.drawText("FATURADO A", { x: colRight, y: yP, size: 9, font: fontB, color: green })
  yP -= 16
  page.drawText(data.patientName, { x: colRight, y: yP, size: 10, font: fontB, color: dark })
  yP -= 14
  page.drawText(`NIF: ${data.patientNif}`, { x: colRight, y: yP, size: 10, font, color: dark })
  if (data.patientAddress) {
    yP -= 14
    page.drawText(data.patientAddress, { x: colRight, y: yP, size: 10, font, color: grey })
  }

  y = height - 260
  page.drawLine({ start: { x: 40, y }, end: { x: width - 40, y }, thickness: 1, color: green })

  y -= 20
  page.drawText("DESCRIÇÃO",     { x: 40,         y, size: 9, font: fontB, color: green })
  page.drawText("DATA",          { x: 260,        y, size: 9, font: fontB, color: green })
  page.drawText("MÉDICO",        { x: 360,        y, size: 9, font: fontB, color: green })
  page.drawText("VALOR",         { x: width - 80, y, size: 9, font: fontB, color: green })

  y -= 6
  page.drawLine({ start: { x: 40, y }, end: { x: width - 40, y }, thickness: 0.5, color: grey })

  y -= 18
  const descricao = `Consulta ${typeLabel(data.appointmentType)}`
  page.drawText(descricao, { x: 40, y, size: 10, font, color: dark })
  page.drawText(`${data.appointmentDate} ${data.appointmentTime}`, { x: 260, y, size: 10, font, color: dark })
  page.drawText(data.doctorName.length > 18 ? data.doctorName.slice(0, 18) + "…" : data.doctorName, {
    x: 360, y, size: 10, font, color: dark,
  })
  page.drawText(`${data.amount.toFixed(2)} €`, { x: width - 80, y, size: 10, font: fontB, color: dark })

  y -= 24
  page.drawLine({ start: { x: 300, y }, end: { x: width - 40, y }, thickness: 0.5, color: grey })
  y -= 18
  page.drawText("TOTAL", { x: 300, y, size: 11, font: fontB, color: dark })
  page.drawText(`${data.amount.toFixed(2)} €`, { x: width - 80, y, size: 11, font: fontB, color: green })

  y -= 28
  page.drawText("IVA incluído (regime de isenção - art.º 9.º CIVA)",
    { x: 40, y, size: 9, font, color: grey })

  page.drawLine({ start: { x: 40, y: 60 }, end: { x: width - 40, y: 60 }, thickness: 0.5, color: grey })
  page.drawText(CLINIC_NAME,    { x: 40,          y: 44, size: 8, font, color: grey })
  page.drawText(CLINIC_ADDRESS, { x: 40,          y: 32, size: 8, font, color: grey })
  page.drawText(`NIF: ${CLINIC_NIF}`, { x: width - 140, y: 44, size: 8, font, color: grey })
  page.drawText("Documento processado por computador", { x: width - 220, y: 32, size: 8, font, color: grey })

  return doc.save()
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })

  try {
    const { appointment_id } = await req.json()
    if (!appointment_id) throw new Error("appointment_id em falta.")

    const sb = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    )

    const { data: appt, error: apptErr } = await sb
      .from("appointments")
      .select(`
        scheduled_date,
        scheduled_time,
        type,
        amount,
        patients!inner(
          user_id,
          users!inner(name, nif, email, address)
        ),
        doctors!inner(
          users!inner(name)
        )
      `)
      .eq("id", appointment_id)
      .single()

    if (apptErr || !appt) throw new Error("Consulta não encontrada: " + apptErr?.message)

    const patientUserId  = appt.patients.user_id as string
    const patientName    = appt.patients.users.name    as string ?? "Paciente"
    const patientNif     = appt.patients.users.nif     as string ?? "-"
    const patientEmail   = appt.patients.users.email   as string | null
    const patientAddress = appt.patients.users.address as string ?? ""
    const doctorName     = appt.doctors.users.name     as string ?? "Médico"
    const amount         = Number(appt.amount ?? 0)

    const now      = new Date()
    const issuedAt = `${pad2(now.getDate())}/${pad2(now.getMonth() + 1)}/${now.getFullYear()}`
    const invNum   = invoiceNumber(appointment_id)

    const pdfBytes = await buildPdf({
      invoiceNum:      invNum,
      issuedAt,
      patientName,
      patientNif,
      patientAddress,
      doctorName,
      appointmentDate: formatDate(appt.scheduled_date),
      appointmentTime: (appt.scheduled_time as string).substring(0, 5),
      appointmentType: appt.type as string,
      amount,
    })

    const timestamp   = now.getTime()
    const storagePath = `${patientUserId}/${timestamp}_fatura_${appointment_id.slice(0, 8)}.pdf`

    const { error: uploadErr } = await sb.storage
      .from("patient-documents")
      .upload(storagePath, pdfBytes, {
        contentType: "application/pdf",
        upsert: false,
      })

    if (uploadErr) throw new Error("Erro no upload: " + uploadErr.message)

    const { error: docErr } = await sb.from("documents").insert({
      patient_id:      patientUserId,
      appointment_id,
      type:            "invoice",
      name:            `Fatura ${issuedAt} – ${invNum}`,
      file_path:       storagePath,
      file_size_bytes: pdfBytes.length,
      uploaded_by:     null,
      id: crypto.randomUUID(),
    })

    if (docErr) throw new Error("Erro ao registar documento: " + docErr.message)

    const { data: prefs } = await sb
      .from("user_preferences")
      .select("email_notifications")
      .eq("user_id", patientUserId)
      .maybeSingle()

    const sendEmail = prefs?.email_notifications ?? true

    if (sendEmail && patientEmail) {
      const html = `
        <div style="font-family:sans-serif;max-width:600px;margin:0 auto;border:1px solid #E0ECEB;border-radius:10px;">
          <div style="background-color:#1A8070;padding:20px;text-align:center;">
            <h1 style="color:white;margin:0;">${CLINIC_NAME}</h1>
          </div>
          <div style="padding:30px;background-color:#FAFAFA;color:#333;">
            <h2 style="color:#1A8070;">Olá, ${patientName}</h2>
            <p>A sua fatura referente à consulta de <strong>${formatDate(appt.scheduled_date)}</strong> está disponível no portal.</p>
            <p><strong>Nº Fatura:</strong> ${invNum}<br>
               <strong>Valor:</strong> ${amount.toFixed(2)} €</p>
            <p>Pode descarregá-la a qualquer momento na secção <em>Os meus documentos</em>.</p>
          </div>
          <div style="padding:16px;text-align:center;color:#888;font-size:12px;">
            ${CLINIC_NAME} · ${CLINIC_ADDRESS}
          </div>
        </div>
      `

      try {
        const mailer = new SMTPClient({
          connection: {
            hostname: "smtp.gmail.com",
            port: 465,
            tls: true,
            auth: {
              username: Deno.env.get("GMAIL_USER") ?? "",
              password: Deno.env.get("GMAIL_PASSWORD") ?? "",
            },
          },
        })
        await mailer.send({
          from: `"${CLINIC_NAME}" <${Deno.env.get("GMAIL_USER")}>`,
          to: patientEmail,
          subject: `A sua fatura – ${invNum}`,
          html,
        })
        await mailer.close()
      } catch (mailErr) {
        console.warn("Aviso: falha no envio de email:", mailErr)
      }
    }

    return new Response(
      JSON.stringify({ success: true, invoice_number: invNum, storage_path: storagePath }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 },
    )
  } catch (err: any) {
    console.error(err)
    return new Response(
      JSON.stringify({ error: err.message }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 },
    )
  }
})

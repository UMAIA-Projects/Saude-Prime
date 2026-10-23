import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { encode as base64Encode } from "https://deno.land/std@0.168.0/encoding/base64.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"
import { PDFDocument, StandardFonts } from "https://esm.sh/pdf-lib@1.17.1"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

type ReportFormat = "PDF" | "Excel" | "CSV"
type ReportType = "Atos médicos" | "Consultas" | "Urgências"

interface ExportRequest {
  date_start?: string
  date_end?: string
  doctor_id?: string
  report_type?: ReportType
  format?: ReportFormat
}

interface AppointmentRow {
  scheduled_date: string
  scheduled_time: string
  type: string
  status: string
  duration_min: number
  patient_notes: string | null
  diagnosis_notes: string | null
  patients?: { users?: { name?: string } }
  doctors?: { users?: { name?: string } }
}

interface DocumentRow {
  type: string
  name: string
  laboratory_name: string | null
  created_at: string
  file_path: string
  patients?: { users?: { name?: string } }
  doctors?: { users?: { name?: string } }
}

function nestedName(row: { users?: { name?: string } } | undefined): string {
  return row?.users?.name ?? "-"
}

function csvCell(value: string, separator: string): string {
  const text = String(value ?? "").replace(/"/g, '""')
  if (text.includes(separator) || text.includes('"') || text.includes("\n")) {
    return `"${text}"`
  }
  return text
}

function formatTime(value: string): string {
  return value?.substring(0, 5) ?? "-"
}

function typeLabel(value: string): string {
  switch (value) {
    case "normal": return "Consulta"
    case "urgent": return "Urgência"
    case "follow_up": return "Seguimento"
    default: return value
  }
}

function statusLabel(value: string): string {
  switch (value) {
    case "scheduled": return "Agendada"
    case "completed": return "Concluída"
    case "canceled": return "Cancelada"
    case "no_show": return "Falta"
    default: return value
  }
}

function docTypeLabel(value: string): string {
  switch (value) {
    case "analysis": return "Análise"
    case "prescription": return "Receita"
    case "invoice": return "Fatura"
    default: return "Outro"
  }
}

function buildCsv(
  appointments: AppointmentRow[],
  documents: DocumentRow[],
  includeDocuments: boolean,
  separator: string,
): string {
  const lines: string[] = []
  const bom = separator === ";" ? "\uFEFF" : ""

  lines.push(
    [
      "Data", "Hora", "Médico", "Paciente", "Tipo", "Estado", "Duração (min)", "Notas paciente", "Notas diagnóstico"
    ].map((h) => csvCell(h, separator)).join(separator)
  )

  for (const row of appointments) {
    lines.push(
      [
        row.scheduled_date,
        formatTime(row.scheduled_time),
        nestedName(row.doctors),
        nestedName(row.patients),
        typeLabel(row.type),
        statusLabel(row.status),
        String(row.duration_min ?? ""),
        row.patient_notes ?? "",
        row.diagnosis_notes ?? "",
      ].map((c) => csvCell(c, separator)).join(separator)
    )
  }

  if (includeDocuments) {
    lines.push("")
    lines.push(
      [
        "Data documento", "Médico", "Paciente", "Tipo documento", "Nome", "Laboratório", "Ficheiro"
      ].map((h) => csvCell(h, separator)).join(separator)
    )
    for (const doc of documents) {
      const created = doc.created_at?.substring(0, 10) ?? "-"
      lines.push(
        [
          created,
          nestedName(doc.doctors),
          nestedName(doc.patients),
          docTypeLabel(doc.type),
          doc.name,
          doc.laboratory_name ?? "",
          doc.file_path,
        ].map((c) => csvCell(c, separator)).join(separator)
      )
    }
  }
  return bom + lines.join("\n")
}

async function buildPdf(
  title: string,
  appointments: AppointmentRow[],
  documents: DocumentRow[],
  includeDocuments: boolean,
): Promise<Uint8Array> {
  const pdf = await PDFDocument.create()
  const font = await pdf.embedFont(StandardFonts.Helvetica)
  const fontBold = await pdf.embedFont(StandardFonts.HelveticaBold)
  let page = pdf.addPage([595, 842])
  let y = 800
  const left = 40
  const lineHeight = 13

  const drawLine = (text: string, bold = false) => {
    if (y < 50) {
      page = pdf.addPage([595, 842])
      y = 800
    }
    page.drawText(text.substring(0, 95), { x: left, y, size: 9, font: bold ? fontBold : font })
    y -= lineHeight
  }

  drawLine(title, true)
  y -= 6
  drawLine(`Consultas: ${appointments.length}`, true)
  for (const row of appointments) {
    drawLine(`${row.scheduled_date} ${formatTime(row.scheduled_time)} | ${nestedName(row.doctors)} | ${nestedName(row.patients)} | ${typeLabel(row.type)} | ${statusLabel(row.status)}`)
  }

  if (includeDocuments) {
    y -= 8
    drawLine(`Documentos médicos: ${documents.length}`, true)
    for (const doc of documents) {
      drawLine(`${doc.created_at.substring(0, 10)} | ${nestedName(doc.doctors)} | ${nestedName(doc.patients)} | ${docTypeLabel(doc.type)} | ${doc.name}`)
    }
  }
  return pdf.save()
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })

  try {
    const body = (await req.json()) as ExportRequest
    const { date_start, date_end, doctor_id = "todos", report_type = "Atos médicos", format = "CSV" } = body

    if (!date_start || !date_end) throw new Error("Datas de início e fim são obrigatórias.")

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? ""
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    
    // Usamos o cliente admin (service_role) diretamente para ignorar RLS e Auth
    const admin = createClient(supabaseUrl, serviceKey)

    let apptQuery = admin
      .from("appointments")
      .select("scheduled_date, scheduled_time, type, status, duration_min, patient_notes, diagnosis_notes, patients(users(name)), doctors(users(name))")
      .is("deleted_at", null)
      .gte("scheduled_date", date_start)
      .lte("scheduled_date", date_end)
      .order("scheduled_date", { ascending: true })
      .order("scheduled_time", { ascending: true })

    if (report_type === "Consultas") apptQuery = apptQuery.eq("type", "normal")
    else if (report_type === "Urgências") apptQuery = apptQuery.eq("type", "urgent")
    if (doctor_id !== "todos") apptQuery = apptQuery.eq("doctor_id", doctor_id)

    const { data: appointments, error: apptError } = await apptQuery
    if (apptError) throw apptError

    const includeDocuments = report_type === "Atos médicos"
    let documents: DocumentRow[] = []

    if (includeDocuments) {
      let docQuery = admin
        .from("documents")
        .select("type, name, laboratory_name, created_at, file_path, patients(users(name)), doctors(users(name))")
        .is("deleted_at", null)
        .gte("created_at", `${date_start}T00:00:00`)
        .lte("created_at", `${date_end}T23:59:59`)
        .order("created_at", { ascending: true })

      if (doctor_id !== "todos") docQuery = docQuery.eq("doctor_id", doctor_id)
      const { data: docs, error: docError } = await docQuery
      if (docError) throw docError
      documents = (docs ?? []) as DocumentRow[]
    }

    const apptRows = (appointments ?? []) as AppointmentRow[]
    const stamp = `${date_start.replace(/-/g, "")}_${date_end.replace(/-/g, "")}`
    let bytes: Uint8Array
    let filename: string
    let mimeType: string

    if (format === "PDF") {
      bytes = await buildPdf(`Relatório médico (${report_type}) ${date_start} a ${date_end}`, apptRows, documents, includeDocuments)
      filename = `relatorio_medicos_${stamp}.pdf`
      mimeType = "application/pdf"
    } else {
      const separator = format === "Excel" ? ";" : ","
      const csv = buildCsv(apptRows, documents, includeDocuments, separator)
      bytes = new TextEncoder().encode(csv)
      filename = `relatorio_medicos_${stamp}.csv`
      mimeType = "text/csv;charset=utf-8"
    }

    return new Response(
      JSON.stringify({
        success: true,
        filename,
        mime_type: mimeType,
        content_base64: base64Encode(bytes),
        records: apptRows.length,
        documents: documents.length,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    )
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : String(error) }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    })
  }
})

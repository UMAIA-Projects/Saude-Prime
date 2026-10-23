import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:saude_app/core/report_export_io.dart'
    if (dart.library.html) 'package:saude_app/core/report_export_web.dart'
    as platform;
import 'package:saude_app/core/supabase.dart';

class DoctorReportExportParams {
  final String dateStart;
  final String dateEnd;
  final String doctorId;
  final String reportType;
  final String format;

  const DoctorReportExportParams({
    required this.dateStart,
    required this.dateEnd,
    required this.doctorId,
    required this.reportType,
    required this.format,
  });
}

Future<void> exportDoctorReport(
  BuildContext context,
  DoctorReportExportParams params,
) async {
  try {
    final response = await db.functions.invoke(
      'export-doctor-report',
      body: {
        'date_start': params.dateStart,
        'date_end': params.dateEnd,
        'doctor_id': params.doctorId,
        'report_type': params.reportType,
        'format': params.format,
      },
    );

    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error']);
    }
    if (data is! Map) {
      throw Exception('Resposta inválida do servidor.');
    }

    final base64Content = data['content_base64'] as String?;
    final filename = data['filename'] as String?;
    final mimeType = data['mime_type'] as String?;

    if (base64Content == null || filename == null || mimeType == null) {
      throw Exception('Ficheiro de exportação em falta na resposta.');
    }

    final bytes = base64Decode(base64Content);

    if (!context.mounted) return;
    await platform.saveExportedReportImpl(
      context,
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );

    if (!context.mounted) return;
    final records = data['records'] ?? 0;
    final documents = data['documents'] ?? 0;
    showReportExportSnack(
      context,
      'Relatório exportado ($records consultas${documents > 0 ? ', $documents documentos' : ''}).',
    );
  } catch (e) {
    if (context.mounted) {
      showReportExportSnack(context, 'Erro ao exportar: $e');
    }
  }
}

void showReportExportSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

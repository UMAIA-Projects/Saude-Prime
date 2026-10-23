import 'package:flutter/material.dart';
import 'package:saude_app/core/document_download.dart';
import 'package:saude_app/core/supabase.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> downloadPatientDocumentImpl(
  BuildContext context, {
  required String filePath,
  required String displayName,
}) async {
  final url = await db.storage
      .from(patientDocumentsBucket)
      .createSignedUrl(filePath, 3600);
  final ok = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!ok && context.mounted) {
    showDocumentSnack(context, 'Não foi possível abrir o documento.');
  }
}

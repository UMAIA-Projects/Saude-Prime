import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saude_app/core/document_download.dart';
import 'package:saude_app/core/supabase.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> downloadPatientDocumentImpl(
  BuildContext context, {
  required String filePath,
  required String displayName,
}) async {
  final bytes =
      await db.storage.from(patientDocumentsBucket).download(filePath);
  final dir =
      await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  final fileName = localFileNameFromStorage(filePath, displayName);
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes);

  if (!context.mounted) return;
  showDocumentSnack(context, 'Documento guardado em Downloads.');

  final opened = await launchUrl(
    Uri.file(file.path),
    mode: LaunchMode.externalApplication,
  );
  if (!opened && context.mounted) {
    showDocumentSnack(context, file.path);
  }
}

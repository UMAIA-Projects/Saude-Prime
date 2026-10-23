import 'package:flutter/material.dart';
import 'package:saude_app/core/document_download_io.dart'
    if (dart.library.html) 'package:saude_app/core/document_download_web.dart'
    as platform;

const patientDocumentsBucket = 'patient-documents';

Future<void> downloadPatientDocument(
  BuildContext context, {
  required String filePath,
  required String displayName,
}) async {
  if (filePath.isEmpty) {
    showDocumentSnack(context, 'Caminho do ficheiro em falta.');
    return;
  }

  try {
    await platform.downloadPatientDocumentImpl(
      context,
      filePath: filePath,
      displayName: displayName,
    );
  } catch (e) {
    if (context.mounted) {
      showDocumentSnack(context, 'Erro ao descarregar: $e');
    }
  }
}

String localFileNameFromStorage(String storagePath, String displayName) {
  final fromPath = storagePath.split('/').last;
  if (fromPath.isNotEmpty && fromPath.contains('.')) return fromPath;

  final ext = displayName.contains('.') ? '' : '.pdf';
  final safe = displayName
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .replaceAll(RegExp(r'\s+'), '_');
  return '$safe$ext';
}

void showDocumentSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

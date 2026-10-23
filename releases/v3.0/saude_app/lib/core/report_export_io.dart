import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saude_app/core/report_export.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> saveExportedReportImpl(
  BuildContext context, {
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) async {
  final dir =
      await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);

  if (!context.mounted) return;

  final opened = await launchUrl(
    Uri.file(file.path),
    mode: LaunchMode.externalApplication,
  );
  if (!opened && context.mounted) {
    showReportExportSnack(context, file.path);
  }
}

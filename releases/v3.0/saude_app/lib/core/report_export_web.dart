import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';

Future<void> saveExportedReportImpl(
  BuildContext context, {
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

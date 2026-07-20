// Web 端图片导出：用 package:web + dart:js_interop 替代 dart:html（已 deprecated）。
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;
import 'package:unflatten_studio/core/export/export_result.dart';

Future<ExportResult> exportPngBytes(
  Uint8List bytes, {
  required String filename,
}) async {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  await Future<void>.delayed(const Duration(milliseconds: 100));
  web.URL.revokeObjectURL(url);
  return ExportResult(
    method: 'web-blob',
    detail: '浏览器下载触发：$filename（${bytes.length} bytes）',
  );
}

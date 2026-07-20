import 'dart:ui';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart'
    show ShareParams, SharePlus, ShareResultStatus;
import 'package:unflatten_studio/core/export/export_result.dart';

const _pngType = XTypeGroup(
  label: 'PNG 图像',
  extensions: ['png'],
  mimeTypes: ['image/png'],
  uniformTypeIdentifiers: ['public.png'],
);

Future<ExportResult> exportPngBytes(
  Uint8List bytes, {
  required String filename,
}) async {
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    final file = XFile.fromData(bytes, mimeType: 'image/png', name: filename);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: [filename],
        title: '分享 Unflatten 作品',
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
      ),
    );
    return ExportResult(
      method: 'system-share',
      detail: result.status == ShareResultStatus.success
          ? '已交给系统分享'
          : '系统分享面板已打开',
      cancelled: result.status == ShareResultStatus.dismissed,
    );
  }

  final location = await getSaveLocation(
    acceptedTypeGroups: const [_pngType],
    suggestedName: filename,
    confirmButtonText: '导出 PNG',
    canCreateDirectories: true,
  );
  if (location == null) {
    return const ExportResult(
      method: 'native-save',
      detail: '用户取消保存',
      cancelled: true,
    );
  }
  final file = XFile.fromData(bytes, mimeType: 'image/png', name: filename);
  await file.saveTo(location.path);
  return ExportResult(method: 'native-save', detail: location.path);
}

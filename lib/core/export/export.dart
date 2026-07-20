// 跨平台图片导出：web 用 Blob 下载，native/mobile 用文件保存。
// 通过 conditional import 隐藏平台差异。
export 'export_result.dart';
export 'export_stub.dart' if (dart.library.html) 'export_web.dart';

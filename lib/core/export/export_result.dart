class ExportResult {
  const ExportResult({
    required this.method,
    required this.detail,
    this.cancelled = false,
  });

  final String method;
  final String detail;
  final bool cancelled;
}

// Facade that routes to platform-specific implementations
import 'export_service_io.dart'
    if (dart.library.html) 'export_service_web.dart' as impl;

class ExportService {
  static Future<void> exportToPDF() => impl.exportToPDF();
  static Future<void> exportToExcel() => impl.exportToExcel();
}

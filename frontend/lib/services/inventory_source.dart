// Cross-platform inventory fetcher used by DiagnosticService
// Uses SQLite on desktop (IO) and SimpleDatabase on Web

import 'inventory_source_io.dart' if (dart.library.html) 'inventory_source_web.dart' as src;

Future<List<Map<String, dynamic>>> fetchAllInventoryItems() => src.fetchAllInventoryItems();

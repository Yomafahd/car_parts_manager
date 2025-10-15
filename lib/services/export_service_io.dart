import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:ui' as ui show Rect;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'analytics_service.dart';
import '../simple_database.dart';

double _asDouble(Object? v) => (v as num?)?.toDouble() ?? 0.0;

Future<void> exportToPDF() async {
  final analytics = await AnalyticsService.analyzeProfitability();
  final predictions = await AnalyticsService.generatePredictions();
  final items = await SimpleDatabase.getItems();

  final doc = PdfDocument();
  final page = doc.pages.add();
  final g = page.graphics;
  final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 20);
  final contentFont = PdfStandardFont(PdfFontFamily.helvetica, 12);

  g.drawString('تقرير أداء نظام قطع الغيار', titleFont,
    brush: PdfBrushes.black, bounds: const ui.Rect.fromLTWH(50, 50, 500, 30));

  final content = StringBuffer()
    ..writeln('تاريخ التقرير: ${DateTime.now()}')
    ..writeln()
    ..writeln('📊 الأداء المالي:')
    ..writeln('- الإيرادات الكلية: ${_asDouble(analytics['totalRevenue']).toStringAsFixed(2)} ر.س')
    ..writeln('- التكاليف الكلية: ${_asDouble(analytics['totalCost']).toStringAsFixed(2)} ر.س')
    ..writeln('- صافي الربح: ${_asDouble(analytics['netProfit']).toStringAsFixed(2)} ر.س')
    ..writeln('- هامش الربح: ${_asDouble(analytics['profitMargin']).toStringAsFixed(1)}%')
    ..writeln()
    ..writeln('🔮 التنبؤات:')
    ..writeln('- الإيرادات المتوقعة: ${_asDouble(predictions['predictedRevenue']).toStringAsFixed(2)} ر.س')
    ..writeln('- التوصية: ${predictions['recommendation'] ?? 'لا توجد توصيات'}')
    ..writeln()
    ..writeln('📦 إحصائيات المخزون:')
    ..writeln('- عدد القطع: ${items.length}');

  g.drawString(content.toString(), contentFont,
    brush: PdfBrushes.black, bounds: const ui.Rect.fromLTWH(50, 100, 500, 600));

  final dir = await getApplicationDocumentsDirectory();
  final path = '${dir.path}/car_parts_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final file = File(path);
  await file.writeAsBytes(await doc.save());
  doc.dispose();
  await OpenFile.open(path);
}

Future<void> exportToExcel() async {
  final analytics = await AnalyticsService.analyzeProfitability();
  final items = await SimpleDatabase.getItems();

  final workbook = xls.Workbook();
  final sheet = workbook.worksheets[0];

  final header = workbook.styles.add('HeaderStyle');
  header.backColor = '#4472C4';
  header.fontColor = '#FFFFFF';
  header.fontSize = 14;
  header.bold = true;

  sheet.getRangeByName('A1').setText('تقرير أداء نظام قطع الغيار');
  sheet.getRangeByName('A1').cellStyle = header;
  sheet.getRangeByName('A1').columnWidth = 30;

  sheet.getRangeByName('A3').setText('المؤشر');
  sheet.getRangeByName('B3').setText('القيمة');
  sheet.getRangeByName('A3:B3').cellStyle = header;

  var row = 4;
  void add(String k, String v) {
    sheet.getRangeByName('A$row').setText(k);
    sheet.getRangeByName('B$row').setText(v);
    row++;
  }

  add('الإيرادات الكلية', '${_asDouble(analytics['totalRevenue']).toStringAsFixed(2)} ر.س');
  add('التكاليف الكلية', '${_asDouble(analytics['totalCost']).toStringAsFixed(2)} ر.س');
  add('صافي الربح', '${_asDouble(analytics['netProfit']).toStringAsFixed(2)} ر.س');
  add('هامش الربح', '${_asDouble(analytics['profitMargin']).toStringAsFixed(1)}%');
  add('عدد القطع', '${items.length}');

  row += 2;
  sheet.getRangeByName('A$row').setText('قائمة قطع الغيار');
  sheet.getRangeByName('A$row').cellStyle = header;
  row++;
  sheet.getRangeByName('A$row').setText('اسم القطعة');
  sheet.getRangeByName('B$row').setText('السعر');
  sheet.getRangeByName('C$row').setText('الفئة');
  sheet.getRangeByName('A$row:C$row').cellStyle = header;
  row++;

  for (final item in items.take(50)) {
    sheet.getRangeByName('A$row').setText((item['name'] as String?) ?? 'غير معروف');
    sheet.getRangeByName('B$row').setText('${(item['sellingPrice'] as num?) ?? 0}');
    sheet.getRangeByName('C$row').setText((item['category'] as String?) ?? 'أخرى');
    row++;
  }

  final bytes = workbook.saveAsStream();
  workbook.dispose();

  final dir = await getApplicationDocumentsDirectory();
  final path = '${dir.path}/car_parts_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  await OpenFile.open(path);
}

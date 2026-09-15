import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/storage/profile_provider.dart';

Future<void> generatePdfReport(BuildContext context) async {
  final p = ProfileNotifier().state;
  final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
  final ttf = pw.Font.ttf(fontData);
  final doc = pw.Document();
  doc.addPage(pw.Page(build: (ctx){
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('DriveMind — Отчёт', style: pw.TextStyle(font: ttf, fontSize: 24, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 12),
      pw.Text('Всего отвечено: ${p.totalAnswered}', style: pw.TextStyle(font: ttf)),
      pw.Text('Верно: ${p.correctAnswers} (${p.accuracy.toStringAsFixed(1)}%)', style: pw.TextStyle(font: ttf)),
      pw.Text('Streak: ${p.streak} дней', style: pw.TextStyle(font: ttf)),
      pw.Text('Очки: ${p.coins}', style: pw.TextStyle(font: ttf)),
      pw.SizedBox(height: 12),
      pw.Text('Ошибки по темам:', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
      ...p.mistakesByTheme.entries.map((e)=> pw.Text('${e.key}: ${e.value}', style: pw.TextStyle(font: ttf))),
      pw.SizedBox(height: 12),
      pw.Text('Достижения: ${p.achievements.join(', ')}', style: pw.TextStyle(font: ttf)),
    ]);
  }));
  await Printing.sharePdf(bytes: await doc.save(), filename: 'drivemind_report.pdf');
}

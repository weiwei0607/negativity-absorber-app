import 'dart:convert';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/chat_session.dart';

class ExportService {
  static Future<void> exportToText(List<ChatSession> sessions) async {
    final buffer = StringBuffer();
    buffer.writeln('💬 AI 朋友對話紀錄匯出');
    buffer.writeln('匯出時間：${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}');
    buffer.writeln('共 ${sessions.length} 次對話');
    buffer.writeln('=' * 40);
    buffer.writeln();

    for (var i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      buffer.writeln('【對話 ${i + 1}】${DateFormat('yyyy/MM/dd HH:mm').format(s.startedAt)}');
      if (s.taggedEmotion != null) {
        buffer.writeln('情緒：${s.taggedEmotion!.emoji} ${s.taggedEmotion!.label}');
      }
      buffer.writeln('—');
      for (final msg in s.messages) {
        final role = msg.isUser ? '我' : 'AI朋友';
        buffer.writeln('$role：${msg.content}');
      }
      buffer.writeln();
      buffer.writeln('-' * 40);
      buffer.writeln();
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ai_friend_chat_export.txt');
    await file.writeAsString(buffer.toString(), encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/plain')],
      subject: 'AI 朋友對話紀錄匯出',
    );
  }

  /// Returns true if the string contains CJK characters.
  static bool _containsCjk(String text) {
    // CJK Unified Ideographs, CJK Unified Ideographs Extension A,
    // and common CJK punctuation ranges.
    final cjkRegex = RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf\u3000-\u303f]');
    return cjkRegex.hasMatch(text);
  }

  static Future<void> exportToPdf(List<ChatSession> sessions) async {
    // Graceful degradation: if any session contains CJK text, fall back to
    // a plain-text export because the default Helvetica font cannot render
    // CJK characters. Embedding a CJK font via pw.Font.ttf(...) requires
    // bundling a font file, which is not set up in this project.
    final anyCjk = sessions.any((s) {
      if (s.taggedEmotion != null && _containsCjk(s.taggedEmotion!.label)) {
        return true;
      }
      return s.messages.any((m) => _containsCjk(m.content));
    });

    if (anyCjk) {
      return exportToText(sessions);
    }

    final pdf = pw.Document();
    // NOTE: pw.Font.helvetica() does not support CJK (Chinese/Japanese/Korean)
    // characters. For proper CJK support, bundle a CJK-compatible font (e.g.
    // NotoSansSC) and load it via pw.Font.ttf(...).
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Text(
              'AI 朋友對話紀錄',
              style: pw.TextStyle(font: fontBold, fontSize: 24),
            ),
            pw.Text(
              '匯出時間：${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey),
            ),
            pw.SizedBox(height: 20),
            ...sessions.asMap().entries.map((entry) {
              final s = entry.value;
              final index = entry.key;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '對話 ${index + 1} — ${DateFormat('yyyy/MM/dd HH:mm').format(s.startedAt)}',
                    style: pw.TextStyle(font: fontBold, fontSize: 14),
                  ),
                  if (s.taggedEmotion != null)
                    pw.Text(
                      '情緒：${s.taggedEmotion!.label}',
                      style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey),
                    ),
                  pw.SizedBox(height: 8),
                  ...s.messages.map((msg) {
                    final role = msg.isUser ? '我' : 'AI朋友';
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(
                        '$role：${msg.content}',
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                    );
                  }),
                  pw.Divider(),
                  pw.SizedBox(height: 12),
                ],
              );
            }),
          ];
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ai_friend_chat_export.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'AI 朋友對話紀錄 PDF',
    );
  }
}

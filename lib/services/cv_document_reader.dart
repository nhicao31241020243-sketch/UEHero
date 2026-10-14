import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import 'package:xml/xml.dart';

class CvDocumentReader {
  const CvDocumentReader();

  Future<String> read({required File file, required String extension}) async {
    switch (extension.toLowerCase()) {
      case 'txt':
        return readTxt(file);
      case 'docx':
        return readDocx(file);
      case 'pdf':
        return readPdf(file);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return readImage(file);
      default:
        throw const FormatException('Định dạng CV chưa được hỗ trợ.');
    }
  }

  Future<String> readTxt(File file) async =>
      utf8.decode(await file.readAsBytes());

  Future<String> readDocx(File file) async {
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final documentFile = archive.findFile('word/document.xml');
    if (documentFile == null) {
      throw const FormatException('Không tìm thấy nội dung trong file DOCX.');
    }
    final document = XmlDocument.parse(
      utf8.decode(documentFile.content as List<int>),
    );
    return document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'p')
        .map(
          (paragraph) => paragraph.descendants
              .whereType<XmlElement>()
              .where((element) => element.name.local == 't')
              .map((element) => element.innerText)
              .join(),
        )
        .where((paragraph) => paragraph.isNotEmpty)
        .join('\n');
  }

  Future<String> readImage(File file) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(file.path),
      );
      return result.blocks
          .expand((block) => block.lines.map((line) => line.text))
          .join('\n');
    } finally {
      await recognizer.close();
    }
  }

  Future<String> readPdf(File file) async {
    final source = await file.readAsBytes();
    final document = syncfusion.PdfDocument(inputBytes: source);
    String text;
    try {
      text = syncfusion.PdfTextExtractor(document).extractText();
    } finally {
      document.dispose();
    }
    if (text.trim().length >= 200) return text;
    return _readScannedPdf(file);
  }

  Future<String> _readScannedPdf(File file) async {
    final document = await pdfx.PdfDocument.openFile(file.path);
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'uehero_cv_ocr_',
    );
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final pageText = <String>[];
    try {
      final pageCount = document.pagesCount < 3 ? document.pagesCount : 3;
      for (var index = 1; index <= pageCount; index++) {
        final page = await document.getPage(index);
        try {
          final rendered = await page.render(
            width: page.width * 2,
            height: page.height * 2,
            format: pdfx.PdfPageImageFormat.png,
          );
          final bytes = rendered?.bytes;
          if (bytes == null) continue;
          final imageFile = File('${temporaryDirectory.path}/page_$index.png');
          await imageFile.writeAsBytes(bytes, flush: true);
          final recognized = await recognizer.processImage(
            InputImage.fromFilePath(imageFile.path),
          );
          pageText.add(
            recognized.blocks
                .expand((block) => block.lines.map((line) => line.text))
                .join('\n'),
          );
        } finally {
          await page.close();
        }
      }
      return pageText.join('\n');
    } finally {
      await recognizer.close();
      await document.close();
      await temporaryDirectory.delete(recursive: true);
    }
  }
}

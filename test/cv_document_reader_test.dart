import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/services/cv_document_reader.dart';

void main() {
  test('extracts UTF-8 text from a TXT file', () async {
    final file = File('${Directory.systemTemp.path}/uehero_cv_test.txt');
    const expected = 'Nguyen Van A\nKy nang: Flutter, SQL';
    await file.writeAsString(expected, encoding: utf8);

    try {
      expect(await const CvDocumentReader().readTxt(file), expected);
    } finally {
      await file.delete();
    }
  });
}

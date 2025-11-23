import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:money_mirror/core/utils/log_utils.dart';
import 'package:money_mirror/database/dao/account_dao.dart';
import 'package:money_mirror/database/dao/category_dao.dart';
import 'package:money_mirror/database/dao/transaction_dao.dart';
import 'package:money_mirror/database/db_handler.dart';
import 'package:money_mirror/database/schema/transaction_table.dart';

class CsvImportResult {
  final int imported;
  final int skipped;
  final List<String> errors;

  CsvImportResult({
    required this.imported,
    required this.skipped,
    required this.errors,
  });
}

class CsvImporter {
  static final List<DateFormat> _dateFormats = [
    DateFormat('MMM d, yyyy h:mm a'),
    DateFormat('MMM dd, yyyy h:mm a'),
    DateFormat('MMM d, yyyy h:mm:ss a'),
    DateFormat('yyyy-MM-dd HH:mm:ss'),
    DateFormat('yyyy-MM-dd'),
  ];

  static Future<List<List<String>>> getPreview(
    String path, {
    int maxRows = 10,
  }) async {
    appLog('getPreview: Reading file $path');
    final file = File(path);
    if (!await file.exists()) {
      appLog('getPreview: File does not exist');
      throw Exception('File not found: $path');
    }

    final content = await file.readAsString();
    appLog('getPreview: File content length: ${content.length} bytes');

    final lines = content.split('\n');
    appLog('getPreview: Total lines (split by \\n): ${lines.length}');

    final List<List<dynamic>> rows = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(content);

    appLog('getPreview: Total rows parsed: ${rows.length}');

    for (int i = 0; i < rows.length && i < 3; i++) {
      appLog(
        'getPreview: Row $i has ${rows[i].length} columns: ${rows[i].take(3).toList()}',
      );
    }

    final preview = rows.take(maxRows).map((row) {
      return row.map((cell) => cell.toString()).toList();
    }).toList();

    appLog('getPreview: Returning ${preview.length} rows');
    return preview;
  }

  static Future<CsvImportResult> importFromFile(String path) async {
    appLog('========================================');
    appLog('importFromFile: Starting import from $path');
    appLog('========================================');
    final file = File(path);
    if (!await file.exists()) {
      appLog('importFromFile: File not found');
      return CsvImportResult(
        imported: 0,
        skipped: 0,
        errors: ['File not found: $path'],
      );
    }

    final content = await file.readAsString();
    appLog(
      'importFromFile: File read successfully, length: ${content.length} bytes',
    );

    final lineCount = content.split('\n').length;
    appLog('importFromFile: Total lines in file: $lineCount');

    return await importFromString(content);
  }

  static Future<CsvImportResult> importFromString(String csvContent) async {
    appLog('========================================');
    appLog('importFromString: Starting CSV parsing');
    appLog('========================================');

    int imported = 0;
    int skipped = 0;
    final errors = <String>[];

    try {
      appLog(
        'importFromString: Input content length: ${csvContent.length} bytes',
      );
      appLog(
        'importFromString: Content preview: ${csvContent.substring(0, csvContent.length > 300 ? 300 : csvContent.length)}',
      );

      final List<List<dynamic>> rows = const CsvToListConverter(
        shouldParseNumbers: false,
        eol: '\n',
      ).convert(csvContent);

      appLog('importFromString: ✓ PARSED ${rows.length} rows total');

      if (rows.length == 1 && rows[0].length > 100) {
        appLog(
          'importFromString: ⚠️  DETECTED PARSING ISSUE - Got 1 row with ${rows[0].length} columns',
        );
        appLog('importFromString: Attempting manual line-based parsing...');
        return _parseCSVManually(csvContent);
      }

      appLog('importFromString: Row breakdown:');
      for (int i = 0; i < rows.length && i < 10; i++) {
        appLog('  Row $i: ${rows[i].length} columns');
      }

      if (rows.isEmpty) {
        appLog('importFromString: ❌ No rows found in CSV');
        return CsvImportResult(
          imported: 0,
          skipped: 0,
          errors: ['CSV file is empty'],
        );
      }

      // Detect header
      int startRow = 0;
      final first = rows.first
          .map((e) => e.toString().toUpperCase().trim())
          .toList();
      appLog('importFromString: First row (header check): $first');

      if (first.any(
        (col) =>
            col.contains('TIME') ||
            col.contains('DATE') ||
            col.contains('TYPE') ||
            col.contains('AMOUNT'),
      )) {
        startRow = 1;
        appLog(
          'importFromString: ✓ Header detected at row 0, will process from row 1',
        );
      } else {
        appLog(
          'importFromString: ⚠️  No header detected, will process all rows as data',
        );
      }

      final db = await DBHandler().database;
      appLog('importFromString: Database connected');

      await db.execute('BEGIN TRANSACTION');
      appLog('importFromString: Transaction started');

      int rowsToProcess = rows.length - startRow;
      appLog(
        'importFromString: Will process $rowsToProcess rows (rows $startRow to ${rows.length - 1})',
      );

      for (int i = startRow; i < rows.length; i++) {
        final row = rows[i];
        appLog('----------------------------------------');
        appLog('Processing Row ${i + 1}/${rows.length}');
        appLog('  Raw: $row');

        // Skip empty rows
        if (row.isEmpty ||
            row.every((cell) => cell.toString().trim().isEmpty)) {
          appLog('  ⏭️  EMPTY ROW - Skipping');
          skipped++;
          continue;
        }

        // Ensure 6 columns
        final List<dynamic> paddedRow = List.from(row);
        while (paddedRow.length < 6) {
          paddedRow.add('');
        }

        try {
          final timeStr = paddedRow[0].toString().trim();
          final typeStr = paddedRow[1].toString().trim();
          final amountStr = paddedRow[2].toString().trim();
          final categoryStr = paddedRow[3].toString().trim();
          final accountStr = paddedRow[4].toString().trim();
          final noteStr = paddedRow[5].toString().trim();

          appLog(
            '  📋 Fields: time="$timeStr" type="$typeStr" amount="$amountStr" category="$categoryStr" account="$accountStr"',
          );

          // Skip rows with no meaningful data
          if (timeStr.isEmpty && typeStr.isEmpty && amountStr.isEmpty) {
            appLog('  ⏭️  NO DATA - Skipping');
            skipped++;
            continue;
          }

          // Parse date
          DateTime date = DateTime.now();
          bool dateParsed = false;
          for (var format in _dateFormats) {
            try {
              date = format.parse(timeStr);
              dateParsed = true;
              appLog('  ✓ Date parsed: $date');
              break;
            } catch (e) {
              // Try next format
            }
          }

          if (!dateParsed) {
            try {
              date = DateTime.parse(timeStr);
              appLog('  ✓ Date parsed (DateTime.parse): $date');
            } catch (e) {
              throw 'Invalid date: "$timeStr"';
            }
          }

          // Detect type
          final lowType = typeStr.toLowerCase();
          final isTransfer =
              lowType.contains('transfer') || typeStr.contains('*');
          final isIncome = lowType.contains('income') || typeStr.contains('+');

          // Parse amount
          double amount = 0.0;
          try {
            final cleanAmount = amountStr
                .replaceAll(',', '')
                .replaceAll('\$', '')
                .replaceAll('₹', '')
                .replaceAll(' ', '')
                .trim();
            amount = double.parse(cleanAmount);
            appLog('  ✓ Amount parsed: $amount');
          } catch (e) {
            throw 'Invalid amount: "$amountStr"';
          }

          if (amount < 0) amount = amount.abs();
          if (amount == 0) {
            appLog('  ⏭️  ZERO AMOUNT - Skipping');
            skipped++;
            continue;
          }

          if (isTransfer) {
            appLog('  ➡️  TRANSFER: $accountStr');

            if (!accountStr.contains('->')) {
              throw 'Transfer needs "SOURCE->DESTINATION" format, got: "$accountStr"';
            }

            final parts = accountStr.split('->').map((s) => s.trim()).toList();
            if (parts.length != 2) {
              throw 'Transfer must have exactly 2 accounts, got ${parts.length}';
            }

            final srcName = _stripPrefix(parts[0]);
            final dstName = _stripPrefix(parts[1]);

            final srcId = await AccountDao.getOrCreate(srcName);
            final dstId = await AccountDao.getOrCreate(dstName);

            // ✅ NEW: Single transfer transaction with to_account_id
            await TransactionDao.insertTransaction({
              TransactionTable.colAmount: amount,
              TransactionTable.colType: 'TRANSFER',
              TransactionTable.colAccountId: srcId,
              TransactionTable.colToAccountId:
                  dstId, // NEW: Destination account
              TransactionTable.colCategoryId: 0, // 0 for transfers
              TransactionTable.colDate: date.toIso8601String(),
              TransactionTable.colNote: noteStr.isEmpty
                  ? 'Transfer from $srcName to $dstName'
                  : noteStr,
            });

            appLog('  ✅ Transfer: 1 transaction created (new format)');
            imported += 1; // Only count as 1 transaction
          } else {
            final type = isIncome ? 'INCOME' : 'EXPENSE';
            appLog(
              '  ➡️  $type: ${categoryStr.isEmpty ? 'Others' : categoryStr}',
            );

            final accountName = _stripPrefix(
              accountStr.isEmpty ? 'Unknown' : accountStr,
            );
            final categoryName = _stripPrefix(
              categoryStr.isEmpty ? 'Others' : categoryStr,
            );

            final accountId = await AccountDao.getOrCreate(accountName);
            final categoryId = await CategoryDao.getOrCreate(
              categoryName,
              type: type,
            );

            await TransactionDao.insertTransaction({
              TransactionTable.colAmount: amount,
              TransactionTable.colType: type,
              TransactionTable.colAccountId: accountId,
              TransactionTable.colCategoryId: categoryId,
              TransactionTable.colDate: date.toIso8601String(),
              TransactionTable.colNote: noteStr,
            });

            appLog('  ✅ Transaction: 1 created');
            imported++;
          }
        } catch (e) {
          appLog('  ❌ ERROR: $e');
          errors.add('Row ${i + 1}: ${e.toString()}');
          skipped++;
        }
      }

      await db.execute('COMMIT');
      appLog('✓ TRANSACTION COMMITTED');
    } catch (e) {
      appLog('❌ FATAL ERROR: $e');
      errors.add('Fatal: ${e.toString()}');
      try {
        final db = await DBHandler().database;
        await db.execute('ROLLBACK');
      } catch (e) {
        appLog('❌ ROLLBACK FAILED: $e');
      }
    }

    appLog('========================================');
    appLog('FINAL RESULTS:');
    appLog('  ✅ Imported: $imported');
    appLog('  ⏭️  Skipped: $skipped');
    appLog('  ❌ Errors: ${errors.length}');
    for (var err in errors) {
      appLog('     - $err');
    }
    appLog('========================================');

    return CsvImportResult(
      imported: imported,
      skipped: skipped,
      errors: errors,
    );
  }

  static String _stripPrefix(String s) {
    return s.replaceAll(RegExp(r'^\s*\d+\.\s*'), '').trim();
  }

  // Manual CSV parser for handling quoted fields with embedded newlines
  static Future<CsvImportResult> _parseCSVManually(String csvContent) async {
    appLog('========================================');
    appLog('_parseCSVManually: Using manual CSV parser');
    appLog('========================================');

    int imported = 0;
    int skipped = 0;
    final errors = <String>[];

    try {
      final lines = csvContent.split('\n');
      appLog('_parseCSVManually: Total lines: ${lines.length}');

      final List<List<String>> rows = [];
      List<String> currentRow = [];
      bool inQuotes = false;
      String currentField = '';

      for (int lineIdx = 0; lineIdx < lines.length; lineIdx++) {
        String line = lines[lineIdx];

        for (int charIdx = 0; charIdx < line.length; charIdx++) {
          String char = line[charIdx];

          if (char == '"') {
            if (charIdx + 1 < line.length && line[charIdx + 1] == '"') {
              currentField += '"';
              charIdx++;
            } else {
              inQuotes = !inQuotes;
            }
          } else if (char == ',' && !inQuotes) {
            currentRow.add(currentField.trim());
            currentField = '';
          } else {
            currentField += char;
          }
        }

        if (!inQuotes) {
          if (currentField.isNotEmpty || currentRow.isNotEmpty) {
            currentRow.add(currentField.trim());
            if (currentRow.isNotEmpty && currentRow.any((f) => f.isNotEmpty)) {
              rows.add(currentRow);
            }
            currentRow = [];
            currentField = '';
          }
        } else {
          currentField += '\n';
        }
      }

      if (currentField.isNotEmpty || currentRow.isNotEmpty) {
        currentRow.add(currentField.trim());
        if (currentRow.isNotEmpty && currentRow.any((f) => f.isNotEmpty)) {
          rows.add(currentRow);
        }
      }

      appLog('_parseCSVManually: Parsed ${rows.length} rows');

      if (rows.isEmpty) {
        return CsvImportResult(
          imported: 0,
          skipped: 0,
          errors: ['CSV file is empty'],
        );
      }

      int startRow = 0;
      final first = rows.first.map((e) => e.toUpperCase()).toList();

      if (first.any(
        (col) =>
            col.contains('TIME') ||
            col.contains('DATE') ||
            col.contains('TYPE'),
      )) {
        startRow = 1;
        appLog('_parseCSVManually: Header detected');
      }

      final db = await DBHandler().database;
      await db.execute('BEGIN TRANSACTION');

      appLog(
        '_parseCSVManually: Processing ${rows.length - startRow} data rows',
      );

      for (int i = startRow; i < rows.length; i++) {
        final row = rows[i];

        if (row.isEmpty || row.every((cell) => cell.isEmpty)) {
          skipped++;
          continue;
        }

        while (row.length < 6) {
          row.add('');
        }

        try {
          final timeStr = row[0].trim();
          final typeStr = row[1].trim();
          final amountStr = row[2].trim();
          final categoryStr = row.length > 3 ? row[3].trim() : '';
          final accountStr = row.length > 4 ? row[4].trim() : '';
          final noteStr = row.length > 5 ? row[5].trim() : '';

          if (timeStr.isEmpty && typeStr.isEmpty && amountStr.isEmpty) {
            skipped++;
            continue;
          }

          // Parse date
          DateTime date = DateTime.now();
          bool dateParsed = false;
          for (var format in _dateFormats) {
            try {
              date = format.parse(timeStr);
              dateParsed = true;
              break;
            } catch (e) {
              // Try next
            }
          }

          if (!dateParsed) {
            try {
              date = DateTime.parse(timeStr);
            } catch (e) {
              throw 'Invalid date: "$timeStr"';
            }
          }

          // Parse amount
          double amount = 0.0;
          try {
            final cleanAmount = amountStr
                .replaceAll(',', '')
                .replaceAll('₹', '')
                .replaceAll(' ', '')
                .trim();
            amount = double.parse(cleanAmount);
          } catch (e) {
            throw 'Invalid amount: "$amountStr"';
          }

          if (amount <= 0) {
            skipped++;
            continue;
          }

          final lowType = typeStr.toLowerCase();
          final isTransfer =
              lowType.contains('transfer') || typeStr.contains('*');
          final isIncome = lowType.contains('income') || typeStr.contains('+');

          if (isTransfer) {
            if (!accountStr.contains('->')) {
              throw 'Transfer needs SRC->DST format';
            }

            final parts = accountStr.split('->').map((s) => s.trim()).toList();
            if (parts.length != 2) throw 'Invalid transfer format';

            final srcName = _stripPrefix(parts[0]);
            final dstName = _stripPrefix(parts[1]);

            final srcId = await AccountDao.getOrCreate(srcName);
            final dstId = await AccountDao.getOrCreate(dstName);

            // ✅ NEW: Single transfer transaction
            await TransactionDao.insertTransaction({
              TransactionTable.colAmount: amount,
              TransactionTable.colType: 'TRANSFER',
              TransactionTable.colAccountId: srcId,
              TransactionTable.colToAccountId: dstId,
              TransactionTable.colCategoryId: 0,
              TransactionTable.colDate: date.toIso8601String(),
              TransactionTable.colNote: noteStr.isEmpty
                  ? 'Transfer from $srcName to $dstName'
                  : noteStr,
            });

            imported += 1; // Count as 1 transaction
          } else {
            final type = isIncome ? 'INCOME' : 'EXPENSE';
            final accountName = _stripPrefix(
              accountStr.isEmpty ? 'Unknown' : accountStr,
            );
            final categoryName = _stripPrefix(
              categoryStr.isEmpty ? 'Others' : categoryStr,
            );

            final accountId = await AccountDao.getOrCreate(accountName);
            final categoryId = await CategoryDao.getOrCreate(
              categoryName,
              type: type,
            );

            await TransactionDao.insertTransaction({
              TransactionTable.colAmount: amount,
              TransactionTable.colType: type,
              TransactionTable.colAccountId: accountId,
              TransactionTable.colCategoryId: categoryId,
              TransactionTable.colDate: date.toIso8601String(),
              TransactionTable.colNote: noteStr,
            });

            imported++;
          }
        } catch (e) {
          appLog('Row ${i + 1} error: $e');
          errors.add('Row ${i + 1}: ${e.toString()}');
          skipped++;
        }
      }

      await db.execute('COMMIT');
      appLog('_parseCSVManually: ✓ Committed');
    } catch (e) {
      appLog('_parseCSVManually: ❌ Error: $e');
      errors.add('Fatal: ${e.toString()}');
      try {
        final db = await DBHandler().database;
        await db.execute('ROLLBACK');
      } catch (e) {
        appLog('Rollback failed: $e');
      }
    }

    appLog('========================================');
    appLog(
      'Manual parse results: $imported imported, $skipped skipped, ${errors.length} errors',
    );
    appLog('========================================');

    return CsvImportResult(
      imported: imported,
      skipped: skipped,
      errors: errors,
    );
  }
}

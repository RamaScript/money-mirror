import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:money_mirror/core/utils/csv_importer.dart';
import 'package:money_mirror/core/utils/log_utils.dart';

class ImportCsvScreen extends StatefulWidget {
  const ImportCsvScreen({Key? key}) : super(key: key);

  @override
  State<ImportCsvScreen> createState() => _ImportCsvScreenState();
}

class _ImportCsvScreenState extends State<ImportCsvScreen> {
  String? _filePath;
  bool _loading = false;
  CsvImportResult? _result;
  List<List<String>> _csvPreview = [];
  bool _showPreview = false;
  int _totalRowsInFile = 0;

  Future<void> _pickFile() async {
    appLog('Starting file picker...');
    setState(() {
      _result = null;
      _csvPreview = [];
      _showPreview = false;
      _totalRowsInFile = 0;
    });

    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );

    if (res == null || res.files.isEmpty) {
      appLog('No file selected');
      return;
    }

    final path = res.files.first.path;
    if (path == null) {
      appLog('File path is null');
      return;
    }

    appLog('File selected: $path');
    setState(() {
      _filePath = path;
    });

    await _loadPreview(path);
  }

  Future<void> _loadPreview(String path) async {
    appLog('Loading CSV preview from: $path');
    try {
      // Get first 50 data rows (+ header)
      final preview = await CsvImporter.getPreview(path, maxRows: 51);
      appLog('Preview loaded: ${preview.length} rows');

      // Count total rows in file to show user
      // We'll calculate this by showing preview count
      int totalDataRows = preview.length - 1; // -1 for header
      if (totalDataRows > 50) {
        // If we got 51, there are more rows
        totalDataRows = preview.length; // We got more than 50
      }

      setState(() {
        _csvPreview = preview.take(51).toList(); // Show up to 50 data rows
        _showPreview = true;
        _totalRowsInFile = totalDataRows;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Preview loaded: ${_csvPreview.length - 1} transactions will be imported',
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      appLog('Preview error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading preview: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    if (_filePath == null) {
      appLog('No file path available for import');
      return;
    }

    appLog('Starting import from: $_filePath');
    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      final result = await CsvImporter.importFromFile(_filePath!);
      appLog(
        'Import completed: ${result.imported} imported, ${result.skipped} skipped, ${result.errors.length} errors',
      );
      setState(() {
        _result = result;
      });

      if (result.errors.isEmpty && result.imported > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✓ Successfully imported ${result.imported} transactions!',
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      appLog('Import fatal error: $e');
      setState(() {
        _result = CsvImportResult(
          imported: 0,
          skipped: 0,
          errors: [e.toString()],
        );
      });
    } finally {
      setState(() {
        _loading = false;
      });
      appLog('Import process finished');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(CupertinoIcons.back),
        ),
        title: const Text('Import CSV'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Card
            Card(
              elevation: 2,
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CSV Format Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Expected columns:\n'
                      '• TIME - Date and time (MMM d, yyyy h:mm a)\n'
                      '• TYPE - Income/Expense/Transfer\n'
                      '• AMOUNT - Transaction amount\n'
                      '• CATEGORY - Category name\n'
                      '• ACCOUNT - Account name (or SRC->DST for transfers)\n'
                      '• NOTES - Optional notes',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onPrimaryContainer,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pick File Button
            FilledButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Select CSV File'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              onPressed: _loading ? null : _pickFile,
            ),
            const SizedBox(height: 16),

            // File Path Display
            if (_filePath != null)
              Card(
                elevation: 1,
                color: colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected File',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSecondaryContainer
                                    .withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _filePath!.split('/').last,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // CSV Preview
            if (_showPreview && _csvPreview.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Preview - First ${_csvPreview.length - 1} Transactions (Total: ~${_totalRowsInFile} rows)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Header
                    Container(
                      color: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: _csvPreview.first.map((header) {
                          return Expanded(
                            child: Text(
                              header.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: colorScheme.onPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Data rows - scrollable container
                    Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: SingleChildScrollView(
                        child: Column(
                          children: _csvPreview.skip(1).map((row) {
                            final isTransfer =
                                row.length > 1 &&
                                row[1].toLowerCase().contains('transfer');
                            final isIncome =
                                row.length > 1 &&
                                (row[1].toLowerCase().contains('income') ||
                                    row[1].contains('+'));

                            Color rowColor;
                            if (isTransfer) {
                              rowColor = colorScheme.tertiaryContainer
                                  .withOpacity(0.3);
                            } else if (isIncome) {
                              rowColor = Colors.green.shade50;
                            } else {
                              rowColor = Colors.red.shade50;
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color: rowColor,
                                border: Border(
                                  bottom: BorderSide(
                                    color: colorScheme.outline.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              child: Row(
                                children: row.map((cell) {
                                  return Expanded(
                                    child: Text(
                                      cell.length > 20
                                          ? '${cell.substring(0, 20)}...'
                                          : cell,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Import Button
              FilledButton.icon(
                icon: const Icon(Icons.upload_rounded),
                label: Text('Import ${_csvPreview.length - 1} Transactions'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _loading ? null : _importData,
              ),
            ],

            const SizedBox(height: 16),

            // Loading Indicator
            if (_loading)
              Card(
                elevation: 2,
                color: colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Importing transactions...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Results Display
            if (_result != null) ...[
              Card(
                elevation: 3,
                color: _result!.errors.isEmpty
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _result!.errors.isEmpty
                                ? Icons.check_circle_rounded
                                : Icons.warning_rounded,
                            color: _result!.errors.isEmpty
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Import Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _result!.errors.isEmpty
                                  ? Colors.green.shade900
                                  : Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildResultRow(
                        Icons.check_circle_outline_rounded,
                        'Successfully Imported',
                        '${_result!.imported}',
                        Colors.green.shade700,
                      ),
                      const SizedBox(height: 8),
                      _buildResultRow(
                        Icons.skip_next_rounded,
                        'Skipped Rows',
                        '${_result!.skipped}',
                        Colors.orange.shade700,
                      ),
                      const SizedBox(height: 8),
                      _buildResultRow(
                        Icons.error_outline_rounded,
                        'Errors',
                        '${_result!.errors.length}',
                        Colors.red.shade700,
                      ),
                      if (_result!.errors.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade700,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Error Details:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.red.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ..._result!.errors.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          e,
                                          style: TextStyle(
                                            color: Colors.red.shade900,
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

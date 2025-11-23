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

  Future<void> _pickFile() async {
    appLog('Starting file picker...');
    setState(() {
      _result = null;
      _csvPreview = [];
      _showPreview = false;
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
      final preview = await CsvImporter.getPreview(path, maxRows: 51);
      appLog('Preview loaded: ${preview.length} rows');

      setState(() {
        _csvPreview = preview;
        _showPreview = preview.length > 1;
      });

      if (mounted && _showPreview) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV file loaded successfully'),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      appLog('Preview error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading file: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Successfully imported ${result.imported} transaction${result.imported != 1 ? 's' : ''}!',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
        title: const Text(
          'Import CSV',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Beautiful Format Instructions Card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.15),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.description_outlined, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CSV Format Guide',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Your CSV must include these columns',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18.0,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        _buildFormatRow(
                          Icons.access_time_rounded,
                          'TIME',
                          'Date and time (e.g., Jan 15, 2024 10:30 AM)',
                          colorScheme,
                        ),
                        _buildFormatRow(
                          Icons.swap_horiz_rounded,
                          'TYPE',
                          'Income, Expense, or Transfer',
                          colorScheme,
                        ),
                        _buildFormatRow(
                          Icons.payments_outlined,
                          'AMOUNT',
                          'Transaction amount (e.g., 1500.50)',
                          colorScheme,
                        ),
                        _buildFormatRow(
                          Icons.category_outlined,
                          'CATEGORY',
                          'Category name (e.g., Food, Salary)',
                          colorScheme,
                        ),
                        _buildFormatRow(
                          Icons.account_balance_wallet_outlined,
                          'ACCOUNT',
                          'Account name or SRC->DST for transfers',
                          colorScheme,
                        ),
                        _buildFormatRow(
                          Icons.note_outlined,
                          'NOTES',
                          'Optional notes or description',
                          colorScheme,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pick File Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.9),
                    colorScheme.primary.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loading ? null : _pickFile,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file_rounded, size: 26),
                        const SizedBox(width: 12),
                        Text(
                          'Select CSV File',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // File Path Display
            if (_filePath != null)
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.insert_drive_file_rounded,
                          color: colorScheme.secondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
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
                                    .withOpacity(0.6),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _filePath!.split('/').last,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSecondaryContainer,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Import Button - Show right after file selection
            if (_filePath != null && !_loading && _result == null)
              Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.secondary,
                          colorScheme.secondary.withOpacity(0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.secondary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _importData,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_rounded,
                                color: colorScheme.onSecondary,
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Import Transactions',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // CSV Preview
            if (_showPreview && _csvPreview.isNotEmpty) ...[
              const SizedBox(height: 28),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.preview_rounded,
                      color: colorScheme.onTertiaryContainer,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Data Preview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withOpacity(0.9),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
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
                                  letterSpacing: 0.8,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Data rows
                      Container(
                        constraints: const BoxConstraints(maxHeight: 350),
                        color: Colors.white,
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
                                rowColor = Colors.blue.shade50;
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
                                      color: colorScheme.outline.withOpacity(
                                        0.15,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
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
                                          fontWeight: FontWeight.w500,
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
              ),
            ],

            const SizedBox(height: 20),

            // Loading Indicator
            if (_loading)
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                          strokeWidth: 5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Importing Transactions',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This may take a moment...',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Results Display
            if (_result != null) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _result!.errors.isEmpty
                        ? [
                            Colors.green.shade50,
                            Colors.green.shade100.withOpacity(0.5),
                          ]
                        : [
                            Colors.orange.shade50,
                            Colors.orange.shade100.withOpacity(0.5),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _result!.errors.isEmpty
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_result!.errors.isEmpty
                                  ? Colors.green
                                  : Colors.orange)
                              .withOpacity(0.15),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  (_result!.errors.isEmpty
                                          ? Colors.green
                                          : Colors.orange)
                                      .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _result!.errors.isEmpty
                                  ? Icons.check_circle_rounded
                                  : Icons.warning_rounded,
                              color: _result!.errors.isEmpty
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Import Complete',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _result!.errors.isEmpty
                                        ? Colors.green.shade900
                                        : Colors.orange.shade900,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  _result!.errors.isEmpty
                                      ? 'All transactions imported successfully'
                                      : 'Import completed with some issues',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        (_result!.errors.isEmpty
                                                ? Colors.green
                                                : Colors.orange)
                                            .shade700
                                            .withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildResultRow(
                        Icons.check_circle_outline_rounded,
                        'Successfully Imported',
                        '${_result!.imported}',
                        Colors.green.shade700,
                      ),
                      const SizedBox(height: 10),
                      _buildResultRow(
                        Icons.skip_next_rounded,
                        'Skipped Rows',
                        '${_result!.skipped}',
                        Colors.orange.shade700,
                      ),
                      const SizedBox(height: 10),
                      _buildResultRow(
                        Icons.error_outline_rounded,
                        'Errors',
                        '${_result!.errors.length}',
                        Colors.red.shade700,
                      ),
                      if (_result!.errors.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.red.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Error Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.red.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              ..._result!.errors.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(top: 6),
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade600,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          e,
                                          style: TextStyle(
                                            color: Colors.red.shade900,
                                            fontSize: 13,
                                            height: 1.5,
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

  Widget _buildFormatRow(
    IconData icon,
    String column,
    String description,
    ColorScheme colorScheme, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  column,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(description, style: TextStyle(fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import 'permission_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._();

  factory BackupService() {
    return _instance;
  }

  BackupService._();

  /// Create a backup of the entire local SQLite database
  /// Returns the backup file path on success
  Future<String> createBackup({
    String? customName,
    bool includeTimestamp = true,
  }) async {
    try {
      final permService = PermissionService();
      permService.requirePermission(
        Permission.exportBackup,
        'create backup',
      );

      final db = await DatabaseHelper.instance.database;
      final backupDir = await _getBackupDirectory();

      // Create timestamp-based filename
      final timestamp = DateTime.now();
      final dateStr = '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}';
      final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}';
      final filename = customName ?? 'backup_${dateStr}_$timeStr.sqlite';
      final backupPath = '${backupDir.path}/$filename';

      // Copy the database file directly for better integrity
      final dbPath = db.path;
      final sourceFile = File(dbPath);
      final backupFile = File(backupPath);
      
      if (!backupFile.existsSync()) {
        backupFile.createSync(recursive: true);
      }
      
      await sourceFile.copy(backupFile.path);

      // Create metadata file with backup info
      await _createBackupMetadata(backupPath, timestamp);

      return backupPath;
    } catch (e) {
      throw BackupException('Failed to create backup: $e');
    }
  }

  /// Restore a backup from a file path
  /// This is a destructive operation - it replaces the current database
  Future<bool> restoreBackup(String backupPath) async {
    try {
      final permService = PermissionService();
      permService.requirePermission(
        Permission.importData,
        'restore backup',
      );

      final backupFile = File(backupPath);
      if (!backupFile.existsSync()) {
        throw BackupException('Backup file not found: $backupPath');
      }

      // Validate backup integrity before restoring
      if (!await _validateBackupIntegrity(backupPath)) {
        throw BackupException(
          'Backup file is corrupted or invalid. Restore aborted.',
        );
      }

      final db = await DatabaseHelper.instance.database;
      await db.close();

      // Close the database connection before replacing
      DatabaseHelper.instance.closeDatabase();

      final dbPath = db.path;
      final currentDb = File(dbPath);

      // Create a backup of the current database before restoring
      final timestamp = DateTime.now();
      final safetyBackupPath =
          '${currentDb.parent.path}/safety_backup_${timestamp.millisecondsSinceEpoch}.sqlite';
      await currentDb.copy(safetyBackupPath);

      // Replace the database file
      await backupFile.copy(currentDb.path);

      // Verify the restoration
      try {
        // Reopen the database to verify it's valid
        final restoredDb = await DatabaseHelper.instance.database;
        await restoredDb.rawQuery('SELECT COUNT(*) FROM Users LIMIT 1');
      } catch (e) {
        // Restore from safety backup if something went wrong
        await File(safetyBackupPath).copy(currentDb.path);
        await DatabaseHelper.instance.database; // Reopen
        throw BackupException(
          'Failed to restore backup. Current database restored from safety backup.',
        );
      }

      return true;
    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException('Restore failed: $e');
    }
  }

  /// List all available backups in the backup directory
  Future<List<BackupInfo>> listBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      if (!backupDir.existsSync()) {
        return [];
      }

      final backups = <BackupInfo>[];
      for (var file in backupDir.listSync()) {
        if (file is File && file.path.endsWith('.sqlite')) {
          try {
            final metadata = await _loadBackupMetadata(file.path);
            backups.add(BackupInfo(
              name: file.path.split('/').last,
              path: file.path,
              size: file.lengthSync(),
              created: metadata['createdAt'] != null
                  ? DateTime.parse(metadata['createdAt'])
                  : file.statSync().changed,
              hash: metadata['hash'] ?? '',
            ));
          } catch (e) {
            // Skip backups without valid metadata
          }
        }
      }

      // Sort by creation date (newest first)
      backups.sort((a, b) => b.created.compareTo(a.created));
      return backups;
    } catch (e) {
      throw BackupException('Failed to list backups: $e');
    }
  }

  /// Delete a backup file
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final permService = PermissionService();
      permService.requirePermission(
        Permission.manageBackups,
        'delete backup',
      );

      final file = File(backupPath);
      if (file.existsSync()) {
        await file.delete();
        
        // Delete metadata file
        final metadataPath = backupPath.replaceAll('.sqlite', '.json');
        final metadataFile = File(metadataPath);
        if (metadataFile.existsSync()) {
          await metadataFile.delete();
        }
        return true;
      }
      return false;
    } catch (e) {
      throw BackupException('Failed to delete backup: $e');
    }
  }

  /// Validate backup file integrity
  Future<bool> _validateBackupIntegrity(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!file.existsSync() || file.lengthSync() == 0) {
        return false;
      }

      // Try to open it as a SQLite database
      final tempDb = await openDatabase(
        backupPath,
        readOnly: true,
      );

      // Run some basic queries to verify structure
      await tempDb.rawQuery('SELECT COUNT(*) FROM Users LIMIT 1');
      await tempDb.rawQuery('SELECT COUNT(*) FROM Products LIMIT 1');
      await tempDb.rawQuery('SELECT COUNT(*) FROM Sales LIMIT 1');

      await tempDb.close();

      // Verify checksum if available
      final metadata = await _loadBackupMetadata(backupPath);
      if (metadata['hash'] != null) {
        final actualHash = await _calculateFileHash(file);
        if (actualHash != metadata['hash']) {
          return false; // Checksum mismatch
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Create metadata file for backup (JSON format with timestamp and hash)
  Future<void> _createBackupMetadata(String backupPath, DateTime timestamp) async {
    try {
      final backupFile = File(backupPath);
      final hash = await _calculateFileHash(backupFile);

      final metadata = {
        'backupPath': backupPath,
        'createdAt': timestamp.toIso8601String(),
        'hash': hash,
        'version': 1,
        'appVersion': '1.0.0',
      };

      final metadataPath = backupPath.replaceAll('.sqlite', '.json');
      final metadataFile = File(metadataPath);
      await metadataFile.writeAsString(jsonEncode(metadata));
    } catch (e) {
      // Non-critical error - backup still created without metadata
      debugPrint('Warning: Failed to create backup metadata: $e');
    }
  }

  /// Load metadata from backup metadata file
  Future<Map<String, dynamic>> _loadBackupMetadata(String backupPath) async {
    try {
      final metadataPath = backupPath.replaceAll('.sqlite', '.json');
      final metadataFile = File(metadataPath);

      if (!metadataFile.existsSync()) {
        return {};
      }

      final content = await metadataFile.readAsString();
      return jsonDecode(content);
    } catch (e) {
      return {};
    }
  }

  /// Calculate SHA256 hash of a file
  Future<String> _calculateFileHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return sha256.convert(bytes).toString();
    } catch (e) {
      throw BackupException('Failed to calculate file hash: $e');
    }
  }

  /// Get backup directory, creating it if necessary
  Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/backups');
    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }
    return backupDir;
  }

  /// Schedule automatic daily backup (to be called from main.dart)
  Future<void> scheduleAutomaticBackups() async {
    // This uses a simple implementation; for production use
    // consider using background_fetch or workmanager package
    
    final lastBackupTime = await _getLastBackupTime();
    final now = DateTime.now();
    
    // Check if a backup has been created today
    if (lastBackupTime == null || 
        _isDifferentDay(lastBackupTime, now)) {
      try {
        await createBackup(
          customName: 'auto_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.sqlite',
        );
        await _saveLastBackupTime(now);
      } catch (e) {
        debugPrint('Automatic backup failed: $e');
      }
    }
  }

  /// Check if two dates are different days
  bool _isDifferentDay(DateTime date1, DateTime date2) {
    return date1.year != date2.year ||
        date1.month != date2.month ||
        date1.day != date2.day;
  }

  /// Save the timestamp of the last backup
  Future<void> _saveLastBackupTime(DateTime timestamp) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/.last_backup_time');
      await file.writeAsString(timestamp.toIso8601String());
    } catch (e) {
      debugPrint('Failed to save backup timestamp: $e');
    }
  }

  /// Get the last backup time
  Future<DateTime?> _getLastBackupTime() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/.last_backup_time');
      
      if (!file.existsSync()) {
        return null;
      }

      final content = await file.readAsString();
      return DateTime.parse(content);
    } catch (e) {
      return null;
    }
  }

  /// Export database to CSV-like format (for additional safety)
  Future<String> exportBackupAsText() async {
    try {
      final permService = PermissionService();
      permService.requirePermission(
        Permission.exportBackup,
        'export backup as text',
      );

      final db = await DatabaseHelper.instance.database;
      final tables = ['Users', 'Products', 'Sales', 'SaleItems', 'Expenses', 'Bills', 'Payments'];
      
      final buffer = StringBuffer();
      buffer.writeln('=== Byte & Bite Database Export ===');
      buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
      buffer.writeln('');

      for (final table in tables) {
        try {
          final results = await db.query(table);
          buffer.writeln('TABLE: $table');
          buffer.writeln('Records: ${results.length}');
          
          if (results.isNotEmpty) {
            buffer.writeln(results.map((row) => jsonEncode(row)).join('\n'));
          }
          buffer.writeln('');
        } catch (e) {
          // Skip tables that don't exist
        }
      }

      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now();
      final filename = 'export_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}.txt';
      final file = File('${appDir.path}/$filename');
      
      await file.writeAsString(buffer.toString());
      return file.path;
    } catch (e) {
      throw BackupException('Failed to export as text: $e');
    }
  }

  /// Export selected SQLite tables into a single CSV file
  Future<String> exportBackupAsCsv() async {
    try {
      final permService = PermissionService();
      permService.requirePermission(
        Permission.exportBackup,
        'export backup as CSV',
      );

      final db = await DatabaseHelper.instance.database;
      final tables = ['Products', 'Sales', 'SaleItems', 'Payments', 'InventoryLogs'];
      final converter = const ListToCsvConverter();
      final buffer = StringBuffer();

      for (final table in tables) {
        final rows = await db.query(table);
        buffer.writeln('TABLE: $table');

        if (rows.isEmpty) {
          buffer.writeln('No records');
          buffer.writeln();
          continue;
        }

        final headers = rows.first.keys.toList();
        final csvRows = <List<dynamic>>[headers];

        for (final row in rows) {
          csvRows.add(headers.map((column) => row[column] ?? '').toList());
        }

        buffer.writeln(converter.convert(csvRows));
        buffer.writeln();
      }

      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now();
      final filename =
          'byte_bite_export_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}.csv';
      final file = File('${appDir.path}/$filename');
      await file.writeAsString(buffer.toString());
      return file.path;
    } catch (e) {
      throw BackupException('Failed to export backup as CSV: $e');
    }
  }

  /// Export selected SQLite tables into a PDF file
  Future<String> exportBackupAsPdf() async {
    try {
      final permService = PermissionService();
      permService.requirePermission(
        Permission.exportBackup,
        'export backup as PDF',
      );

      final db = await DatabaseHelper.instance.database;
      final tables = ['Products', 'Sales', 'SaleItems', 'Payments', 'InventoryLogs'];
      final tableData = <String, List<Map<String, Object?>>>{};

      for (final table in tables) {
        tableData[table] = await db.query(table);
      }

      final document = pw.Document();
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return tables.map((table) {
              final rows = tableData[table]!;
              final headers = rows.isNotEmpty ? rows.first.keys.toList() : <String>[];
              final data = rows
                  .map((row) => headers.map((column) => row[column]?.toString() ?? '').toList())
                  .toList();

              return <pw.Widget>[
                pw.Text(table, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                if (rows.isEmpty) pw.Text('No records available.'),
                if (rows.isNotEmpty)
                  pw.Table.fromTextArray(
                    headers: headers,
                    data: data,
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                    cellStyle: pw.TextStyle(fontSize: 9),
                    cellAlignment: pw.Alignment.centerLeft,
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  ),
                pw.SizedBox(height: 20),
              ];
            }).expand((widgetList) => widgetList).toList();
          },
        ),
      );

      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now();
      final filename =
          'byte_bite_export_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}.pdf';
      final file = File('${appDir.path}/$filename');
      final bytes = await document.save();
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      throw BackupException('Failed to export backup as PDF: $e');
    }
  }

  /// Close database connection (for cleanup)
  void closeDatabase() {
    try {
      DatabaseHelper.instance.closeDatabase();
    } catch (e) {
      debugPrint('Error closing database: $e');
    }
  }
}

/// Information about a backup file
class BackupInfo {
  final String name;
  final String path;
  final int size; // in bytes
  final DateTime created;
  final String hash;

  BackupInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.created,
    required this.hash,
  });

  String get sizeInMB => (size / (1024 * 1024)).toStringAsFixed(2);

  @override
  String toString() => 'BackupInfo(name: $name, size: $sizeInMB MB, created: $created)';
}

/// Exception thrown during backup operations
class BackupException implements Exception {
  final String message;

  BackupException(this.message);

  @override
  String toString() => 'BackupException: $message';
}

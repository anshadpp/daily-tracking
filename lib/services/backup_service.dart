import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const _dbName = 'daily_tracker.db';
  static const _tables = [
    'categories',
    'blocks',
    'completions',
    'holidays',
    'prayer_completions',
    'expenses',
    'todos',
    'qada',
  ];

  /// Export all data as a single JSON file and open the share sheet.
  Future<String?> exportJson() async {
    try {
      final dbPath = await getDatabasesPath();
      final db = await openDatabase(p.join(dbPath, _dbName));

      final data = <String, dynamic>{
        'app': 'daily_tracker',
        'version': 8,
        'exported_at': DateTime.now().toIso8601String(),
      };

      for (final table in _tables) {
        final rows = await db.query(table);
        data[table] = rows;
      }

      await db.close();

      final json = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final file = File(p.join(dir.path, 'daily_tracker_backup_$ts.json'));
      await file.writeAsString(json);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Daily Tracker Backup',
          text: 'Daily Tracker backup — $ts',
        ),
      );

      return file.path;
    } catch (e) {
      debugPrint('BackupService.exportJson error: $e');
      return null;
    }
  }

  /// Export the raw SQLite .db file (fastest, zero-loss binary copy).
  Future<String?> exportDb() async {
    try {
      final dbPath = await getDatabasesPath();
      final src = File(p.join(dbPath, _dbName));
      if (!await src.exists()) return null;

      final dir = await getTemporaryDirectory();
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final dest = File(p.join(dir.path, 'daily_tracker_$ts.db'));
      await src.copy(dest.path);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(dest.path)],
          subject: 'Daily Tracker Database',
          text: 'Daily Tracker database backup — $ts',
        ),
      );

      return dest.path;
    } catch (e) {
      debugPrint('BackupService.exportDb error: $e');
      return null;
    }
  }

  /// Import from a JSON backup file. Returns (success, rowsImported).
  Future<(bool, int)> importJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return (false, 0);
      final path = result.files.single.path;
      if (path == null) return (false, 0);

      final content = await File(path).readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      if (data['app'] != 'daily_tracker') {
        return (false, 0);
      }

      final dbPath = await getDatabasesPath();
      final db = await openDatabase(p.join(dbPath, _dbName));

      int total = 0;
      // Import in a transaction for atomicity
      await db.transaction((txn) async {
        // Clear existing data
        for (final table in _tables) {
          await txn.delete(table);
        }

        // Insert from backup
        for (final table in _tables) {
          final rows = data[table] as List<dynamic>?;
          if (rows == null) continue;
          for (final row in rows) {
            final map = Map<String, dynamic>.from(row as Map);
            await txn.insert(table, map,
                conflictAlgorithm: ConflictAlgorithm.replace);
            total++;
          }
        }
      });

      await db.close();
      return (true, total);
    } catch (e) {
      debugPrint('BackupService.importJson error: $e');
      return (false, 0);
    }
  }

  /// Import from a raw .db file (replaces the entire database).
  Future<(bool, String)> importDb() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return (false, '');
      final path = result.files.single.path;
      if (path == null) return (false, '');

      // Validate it's a valid SQLite file
      final bytes = await File(path).readAsBytes();
      if (bytes.length < 16 ||
          String.fromCharCodes(bytes.sublist(0, 6)) != 'SQLite') {
        return (false, 'Not a valid SQLite file');
      }

      final dbPath = await getDatabasesPath();
      final destPath = p.join(dbPath, _dbName);

      // Close any open connection
      await deleteDatabase(destPath);

      // Copy the imported file
      await File(path).copy(destPath);

      return (true, 'Database restored');
    } catch (e) {
      debugPrint('BackupService.importDb error: $e');
      return (false, e.toString());
    }
  }
}

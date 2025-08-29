import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/printer.dart';
import '../models/printer_template.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'printers.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE printers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        ipAddress TEXT NOT NULL,
        port INTEGER NOT NULL DEFAULT 8883,
        accessCode TEXT NOT NULL,
        isOnline INTEGER NOT NULL DEFAULT 0,
        model TEXT,
        deviceID TEXT,
        status TEXT,
        lastSeen TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE printer_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        printerName TEXT,
        ipAddress TEXT,
        port INTEGER,
        accessCode TEXT,
        model TEXT,
        deviceID TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create index for faster queries
    await db.execute('CREATE INDEX idx_printer_ip ON printers(ipAddress)');
    await db.execute('CREATE INDEX idx_printer_online ON printers(isOnline)');
    // Create index for faster template queries
    await db
        .execute('CREATE INDEX idx_template_name ON printer_templates(name)');
  }

  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE printer_templates (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          printerName TEXT,
          ipAddress TEXT,
          port INTEGER,
          accessCode TEXT,
          model TEXT,
          deviceID TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');
      await db
          .execute('CREATE INDEX idx_template_name ON printer_templates(name)');
    }
  }

  // CRUD Operations

  Future<int> insertPrinter(Printer printer) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final printerMap = printer.toJson();
    printerMap['createdAt'] = now;
    printerMap['updatedAt'] = now;
    printerMap['isOnline'] = printer.isOnline ? 1 : 0;

    try {
      await db.insert(
        'printers',
        printerMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return 1; // Success
    } catch (e) {
      print('Error inserting printer: $e');
      return 0; // Failure
    }
  }

  Future<List<Printer>> getAllPrinters() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'printers',
        orderBy: 'name ASC',
      );

      return List.generate(maps.length, (i) {
        final map = Map<String, dynamic>.from(maps[i]);
        map['isOnline'] = maps[i]['isOnline'] == 1;
        return Printer.fromJson(map);
      });
    } catch (e) {
      print('Error getting all printers: $e');
      return [];
    }
  }

  Future<Printer?> getPrinterById(String id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'printers',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        final map = Map<String, dynamic>.from(maps.first);
        map['isOnline'] = maps.first['isOnline'] == 1;
        return Printer.fromJson(map);
      }
      return null;
    } catch (e) {
      print('Error getting printer by id: $e');
      return null;
    }
  }

  Future<List<Printer>> getPrintersByStatus(bool isOnline) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'printers',
        where: 'isOnline = ?',
        whereArgs: [isOnline ? 1 : 0],
        orderBy: 'name ASC',
      );

      return List.generate(maps.length, (i) {
        final map = Map<String, dynamic>.from(maps[i]);
        map['isOnline'] = maps[i]['isOnline'] == 1;
        return Printer.fromJson(map);
      });
    } catch (e) {
      print('Error getting printers by status: $e');
      return [];
    }
  }

  Future<int> updatePrinter(Printer printer) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final printerMap = printer.toJson();
    printerMap['updatedAt'] = now;
    printerMap['isOnline'] = printer.isOnline ? 1 : 0;

    try {
      return await db.update(
        'printers',
        printerMap,
        where: 'id = ?',
        whereArgs: [printer.id],
      );
    } catch (e) {
      print('Error updating printer: $e');
      return 0;
    }
  }

  Future<int> updatePrinterStatus(String id, bool isOnline,
      {String? status}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final updateMap = {
      'isOnline': isOnline ? 1 : 0,
      'updatedAt': now,
    };

    if (status != null) {
      updateMap['status'] = status;
    }

    if (isOnline) {
      updateMap['lastSeen'] = now;
    }

    try {
      return await db.update(
        'printers',
        updateMap,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error updating printer status: $e');
      return 0;
    }
  }

  Future<int> deletePrinter(String id) async {
    final db = await database;
    try {
      return await db.delete(
        'printers',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting printer: $e');
      return 0;
    }
  }

  Future<List<Printer>> searchPrinters(String query) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'printers',
        where:
            'name LIKE ? OR ipAddress LIKE ? OR model LIKE ? OR deviceID LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
        orderBy: 'name ASC',
      );

      return List.generate(maps.length, (i) {
        final map = Map<String, dynamic>.from(maps[i]);
        map['isOnline'] = maps[i]['isOnline'] == 1;
        return Printer.fromJson(map);
      });
    } catch (e) {
      print('Error searching printers: $e');
      return [];
    }
  }

  Future<int> getPrintersCount() async {
    final db = await database;
    try {
      final result =
          await db.rawQuery('SELECT COUNT(*) as count FROM printers');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting printers count: $e');
      return 0;
    }
  }

  Future<void> clearAllPrinters() async {
    final db = await database;
    try {
      await db.delete('printers');
    } catch (e) {
      print('Error clearing all printers: $e');
    }
  }

  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // Utility methods for database maintenance
  Future<void> vacuum() async {
    final db = await database;
    try {
      await db.execute('VACUUM');
    } catch (e) {
      print('Error vacuuming database: $e');
    }
  }

  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    try {
      final version = await db.getVersion();
      final path = db.path;
      final printersCount = await getPrintersCount();

      return {
        'version': version,
        'path': path,
        'printersCount': printersCount,
      };
    } catch (e) {
      print('Error getting database info: $e');
      return {};
    }
  }

  // Template CRUD Operations
  Future<int> insertTemplate(PrinterTemplate template) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final templateId =
        template.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    final templateMap = template.toJson();
    templateMap['id'] = templateId;
    templateMap['createdAt'] = now;
    templateMap['updatedAt'] = now;

    try {
      await db.insert(
        'printer_templates',
        templateMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return 1;
    } catch (e) {
      print('Error inserting template: $e');
      return 0;
    }
  }

  Future<List<PrinterTemplate>> getAllTemplates() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'printer_templates',
        orderBy: 'name ASC',
      );

      return List.generate(maps.length, (i) {
        return PrinterTemplate.fromJson(maps[i]);
      });
    } catch (e) {
      print('Error getting all templates: $e');
      return [];
    }
  }

  Future<PrinterTemplate?> getTemplateById(String id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'printer_templates',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return PrinterTemplate.fromJson(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting template by id: $e');
      return null;
    }
  }

  Future<int> updateTemplate(PrinterTemplate template) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final templateMap = template.toJson();
    templateMap['updatedAt'] = now;

    try {
      return await db.update(
        'printer_templates',
        templateMap,
        where: 'id = ?',
        whereArgs: [template.id],
      );
    } catch (e) {
      print('Error updating template: $e');
      return 0;
    }
  }

  Future<int> deleteTemplate(String id) async {
    final db = await database;
    try {
      return await db.delete(
        'printer_templates',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting template: $e');
      return 0;
    }
  }

  Future<List<PrinterTemplate>> searchTemplates(String query) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'printer_templates',
        where: 'name LIKE ? OR printerName LIKE ? OR model LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'name ASC',
      );

      return List.generate(maps.length, (i) {
        return PrinterTemplate.fromJson(maps[i]);
      });
    } catch (e) {
      print('Error searching templates: $e');
      return [];
    }
  }
}

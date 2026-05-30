import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kamina_survey.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_session (
        uid TEXT PRIMARY KEY,
        identifier TEXT NOT NULL,
        fullName TEXT NOT NULL,
        gender TEXT NOT NULL,
        promotion TEXT NOT NULL,
        mention TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE survey_responses (
        id TEXT PRIMARY KEY,
        studentUid TEXT NOT NULL,
        promotion TEXT NOT NULL,
        mention TEXT NOT NULL,
        q1 TEXT NOT NULL,
        q2 TEXT NOT NULL,
        q3 TEXT NOT NULL,
        q4 TEXT NOT NULL,
        q5 TEXT,
        submittedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_registrations (
        tempId TEXT PRIMARY KEY,
        identifier TEXT NOT NULL,
        fullName TEXT NOT NULL,
        gender TEXT NOT NULL,
        promotion TEXT NOT NULL,
        mention TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        role TEXT NOT NULL,
        password TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final columns = await db.rawQuery('PRAGMA table_info(user_session)');
      final hasIdentifier = columns.any(
        (column) => column['name'] == 'identifier',
      );
      if (!hasIdentifier) {
        await db.execute(
          'ALTER TABLE user_session ADD COLUMN identifier TEXT NOT NULL DEFAULT ""',
        );
      }
    }
    if (oldVersion < 3) {
      final columns = await db.rawQuery('PRAGMA table_info(survey_responses)');
      final hasPromotion = columns.any(
        (column) => column['name'] == 'promotion',
      );
      final hasMention = columns.any((column) => column['name'] == 'mention');
      if (!hasPromotion) {
        await db.execute(
          'ALTER TABLE survey_responses ADD COLUMN promotion TEXT NOT NULL DEFAULT ""',
        );
      }
      if (!hasMention) {
        await db.execute(
          'ALTER TABLE survey_responses ADD COLUMN mention TEXT NOT NULL DEFAULT ""',
        );
      }
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pending_registrations (
          tempId TEXT PRIMARY KEY,
          identifier TEXT NOT NULL,
          fullName TEXT NOT NULL,
          gender TEXT NOT NULL,
          promotion TEXT NOT NULL,
          mention TEXT NOT NULL,
          email TEXT NOT NULL,
          phone TEXT NOT NULL,
          role TEXT NOT NULL,
          password TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          isSynced INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
  }

  // --- Méthodes utilitaires pour la Session ---
  Future<void> saveSession(Map<String, dynamic> userRow) async {
    final db = await instance.database;
    await db.insert(
      'user_session',
      userRow,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getSession() async {
    final db = await instance.database;
    final maps = await db.query('user_session');
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<void> clearSession() async {
    final db = await instance.database;
    await db.delete('user_session');
  }

  // --- Méthodes utilitaires pour les Sondages ---
  Future<void> insertSurveyResponse(Map<String, dynamic> responseRow) async {
    final db = await instance.database;
    await db.insert(
      'survey_responses',
      responseRow,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedResponses() async {
    final db = await instance.database;
    return await db.query(
      'survey_responses',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markAsSynced(String id) async {
    final db = await instance.database;
    await db.update(
      'survey_responses',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Méthodes pour les Inscriptions Hors Ligne ---
  Future<void> savePendingRegistration(
    Map<String, dynamic> registrationData,
  ) async {
    final db = await instance.database;
    await db.insert(
      'pending_registrations',
      registrationData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedRegistrations() async {
    final db = await instance.database;
    return await db.query(
      'pending_registrations',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markRegistrationAsSynced(String tempId) async {
    final db = await instance.database;
    await db.update(
      'pending_registrations',
      {'isSynced': 1},
      where: 'tempId = ?',
      whereArgs: [tempId],
    );
  }

  Future<void> deletePendingRegistration(String tempId) async {
    final db = await instance.database;
    await db.delete(
      'pending_registrations',
      where: 'tempId = ?',
      whereArgs: [tempId],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
  }
}

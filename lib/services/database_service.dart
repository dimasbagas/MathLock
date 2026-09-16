import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Model untuk satu sesi unlock.
class UnlockEvent {
  final int?   id;
  final String packageName;
  final String appName;
  final int    timestamp;      // Unix ms
  final bool   success;
  final int    attempts;
  final int    durationMs;     // waktu dari soal muncul → jawaban benar/menyerah
  final String formula;        // teks soal, misal "12 × 5 + 7"
  final int    answer;         // jawaban benar
  final bool   isSynced;       // status sinkronisasi ke Supabase

  const UnlockEvent({
    this.id,
    required this.packageName,
    required this.appName,
    required this.timestamp,
    required this.success,
    required this.attempts,
    required this.durationMs,
    required this.formula,
    required this.answer,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() => {
    'id':           id,
    'packageName':  packageName,
    'appName':      appName,
    'timestamp':    timestamp,
    'success':      success ? 1 : 0,
    'attempts':     attempts,
    'durationMs':   durationMs,
    'formula':      formula,
    'answer':       answer,
    'isSynced':     isSynced ? 1 : 0,
  };

  factory UnlockEvent.fromMap(Map<String, dynamic> m) => UnlockEvent(
    id:          m['id'] as int?,
    packageName: m['packageName'] as String,
    appName:     m['appName']     as String,
    timestamp:   m['timestamp']   as int,
    success:     (m['success']    as int) == 1,
    attempts:    m['attempts']    as int,
    durationMs:  m['durationMs']  as int,
    formula:     m['formula']     as String,
    answer:      m['answer']      as int,
    isSynced:    m['isSynced'] != null ? (m['isSynced'] as int) == 1 : false,
  );
}

/// Ringkasan statistik harian untuk bar chart.
class DailyStat {
  final String dayLabel; // "SEN", "SEL", dst.
  final double avgDurationSec;
  final int    totalSolves;

  const DailyStat({
    required this.dayLabel,
    required this.avgDurationSec,
    required this.totalSolves,
  });
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = join(await getDatabasesPath(), 'cobalt_fortress.db');
    return openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE unlock_events (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            packageName TEXT    NOT NULL,
            appName     TEXT    NOT NULL,
            timestamp   INTEGER NOT NULL,
            success     INTEGER NOT NULL DEFAULT 1,
            attempts    INTEGER NOT NULL DEFAULT 1,
            durationMs  INTEGER NOT NULL DEFAULT 0,
            formula     TEXT    NOT NULL DEFAULT '',
            answer      INTEGER NOT NULL DEFAULT 0,
            isSynced    INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE unlock_events ADD COLUMN isSynced INTEGER NOT NULL DEFAULT 0');
        }
      },
    );
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> insertEvent(UnlockEvent event) async {
    final database = await db;
    await database.insert(
      'unlock_events',
      event.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Ambil N event terbaru.
  Future<List<UnlockEvent>> getRecentEvents({int limit = 50}) async {
    final database = await db;
    final rows = await database.query(
      'unlock_events',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(UnlockEvent.fromMap).toList();
  }

  /// Total semua event.
  Future<int> getTotalEvents() async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as cnt FROM unlock_events',
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// Total event yang gagal (ditolak).
  Future<int> getTotalBlocked() async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as cnt FROM unlock_events WHERE success = 0',
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// Akurasi (persen event berhasil dalam 1 percobaan).
  Future<double> getAccuracy() async {
    final database = await db;
    final total = await getTotalEvents();
    if (total == 0) return 0.0;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as cnt FROM unlock_events WHERE success = 1 AND attempts = 1',
    );
    final firstTry = (result.first['cnt'] as int?) ?? 0;
    return firstTry / total;
  }

  /// Rata-rata waktu penyelesaian (detik) — hanya event yang berhasil.
  Future<double> getAvgDurationSec() async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT AVG(durationMs) as avg FROM unlock_events WHERE success = 1',
    );
    final avg = result.first['avg'];
    if (avg == null) return 0.0;
    return (avg as num).toDouble() / 1000.0;
  }

  /// Statistik 7 hari terakhir untuk bar chart (Senin–Minggu minggu ini).
  Future<List<DailyStat>> getWeeklyStats() async {
    final database = await db;
    final now = DateTime.now();
    // Mulai dari Senin minggu ini
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day)
        .millisecondsSinceEpoch;

    const dayLabels = ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'];
    final List<DailyStat> stats = [];

    for (int i = 0; i < 7; i++) {
      final dayStart = startOfWeek + i * 86400000;
      final dayEnd   = dayStart + 86400000;

      final rows = await database.rawQuery(
        '''SELECT AVG(durationMs) as avg, COUNT(*) as cnt
           FROM unlock_events
           WHERE timestamp >= ? AND timestamp < ? AND success = 1''',
        [dayStart, dayEnd],
      );

      final avg = rows.first['avg'];
      final cnt = (rows.first['cnt'] as int?) ?? 0;
      stats.add(DailyStat(
        dayLabel:       dayLabels[i],
        avgDurationSec: avg != null ? (avg as num).toDouble() / 1000 : 0,
        totalSolves:    cnt,
      ));
    }

    return stats;
  }

  /// Top N aplikasi paling sering dibuka.
  Future<List<Map<String, dynamic>>> getTopApps({int limit = 8}) async {
    final database = await db;
    final rows = await database.rawQuery(
      '''SELECT appName, packageName, COUNT(*) as cnt
         FROM unlock_events
         WHERE success = 1
         GROUP BY packageName
         ORDER BY cnt DESC
         LIMIT ?''',
      [limit],
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  /// Total solve keseluruhan.
  Future<int> getTotalSolves() async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as cnt FROM unlock_events WHERE success = 1',
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// Ambil event yang belum disinkronkan ke Supabase.
  Future<List<UnlockEvent>> getUnsyncedEvents() async {
    final database = await db;
    final rows = await database.query(
      'unlock_events',
      where: 'isSynced = 0',
      orderBy: 'timestamp DESC',
    );
    return rows.map(UnlockEvent.fromMap).toList();
  }

  /// Tandai list event ID sebagai sudah disinkronkan.
  Future<void> markEventsAsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final database = await db;
    await database.update(
      'unlock_events',
      {'isSynced': 1},
      where: 'id IN (${ids.join(',')})',
    );
  }
}

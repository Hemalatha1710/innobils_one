import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Local SQLite storage for reel likes and comments (per user).
class ReelDb {
  static Database? _db;

  static Future<Database> get _database async {
    return _db ??= await openDatabase(
      join(await getDatabasesPath(), 'reels.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reel_likes(
            user TEXT NOT NULL,
            reel_id INTEGER NOT NULL,
            PRIMARY KEY(user, reel_id)
          )''');
        await db.execute('''
          CREATE TABLE reel_comments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reel_id INTEGER NOT NULL,
            user TEXT NOT NULL,
            user_name TEXT NOT NULL,
            text TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )''');
      },
    );
  }

  static Future<Map<int, int>> likeCounts() async {
    final db = await _database;
    final rows = await db.rawQuery(
        'SELECT reel_id, COUNT(*) AS c FROM reel_likes GROUP BY reel_id');
    return {for (final r in rows) r['reel_id'] as int: r['c'] as int};
  }

  static Future<Map<int, int>> commentCounts() async {
    final db = await _database;
    final rows = await db.rawQuery(
        'SELECT reel_id, COUNT(*) AS c FROM reel_comments GROUP BY reel_id');
    return {for (final r in rows) r['reel_id'] as int: r['c'] as int};
  }

  static Future<Set<int>> likedBy(String user) async {
    final db = await _database;
    final rows =
    await db.query('reel_likes', where: 'user = ?', whereArgs: [user]);
    return rows.map((r) => r['reel_id'] as int).toSet();
  }

  static Future<void> setLike(String user, int reelId, bool liked) async {
    final db = await _database;
    if (liked) {
      await db.insert('reel_likes', {'user': user, 'reel_id': reelId},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.delete('reel_likes',
          where: 'user = ? AND reel_id = ?', whereArgs: [user, reelId]);
    }
  }

  static Future<List<Map<String, Object?>>> comments(int reelId) async {
    final db = await _database;
    return db.query('reel_comments',
        where: 'reel_id = ?', whereArgs: [reelId], orderBy: 'created_at DESC');
  }

  static Future<void> addComment(
      int reelId, String user, String userName, String text) async {
    final db = await _database;
    await db.insert('reel_comments', {
      'reel_id': reelId,
      'user': user,
      'user_name': userName,
      'text': text,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }
}

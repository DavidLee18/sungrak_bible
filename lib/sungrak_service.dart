import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sungrak_bible/service_locator.dart';

abstract class Bible {
  static const columnIndex = 'idx', columnBibleKind = 'bible_kind', columnLang = 'bible_language',
    columnBookIndex = 'kwon', columnBookName = 'fullname', columnBookAlias = 'nickname', columnChapter = 'jang', 
    columnVerse = 'jul', columnValue = 'content';

  Map toMap();
}

@immutable
class DbBible extends Bible {
  final int index;
  final String kind;
  final String language;
  final int bookIndex;
  final String bookName;
  final String bookAlias;
  final int chapter;
  final int verse;
  final String value;

  @override
  Map<String, dynamic> toMap() => {
    Bible.columnIndex: index, 
    Bible.columnBibleKind: kind, 
    Bible.columnLang: language, 
    Bible.columnBookIndex: bookIndex, 
    Bible.columnBookName: bookName, 
    Bible.columnBookAlias: bookAlias, 
    Bible.columnChapter: chapter, 
    Bible.columnVerse: verse, 
    Bible.columnValue: value,
  };

  DbBible.fromMap(Map<String, dynamic> map):
    index = map[Bible.columnIndex], 
    kind = map[Bible.columnBibleKind], 
    language = map[Bible.columnLang], 
    bookIndex = map[Bible.columnBookIndex], 
    bookName = map[Bible.columnBookName], 
    bookAlias = map[Bible.columnBookAlias], 
    chapter = map[Bible.columnChapter], 
    verse = map[Bible.columnVerse], 
    value = map[Bible.columnValue];

  static int chapters(Iterable<DbBible> book) => book.fold(1, (previousValue, b) => max(previousValue, b.chapter));
  static int verses(Iterable<DbBible> book, int chapter) => book.where((v) => v.chapter == chapter).fold(1, (previousValue, b) => max(previousValue, b.verse));
}

class SungrakService {
  Logger _logger = Logger(filter: ProductionFilter());
  bool isKorean = true;

  FutureOr<Database> get dataBase async {
    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath/assets_bible.db';

    // Check if the database exists
    final exists = await databaseExists(path);

    if (!exists) {
      // Should happen only the first time you launch your application
      _logger.i("Creating new copy from asset");

      // Make sure the parent directory exists
      try {
        await Directory(databasesPath).create(recursive: true);
      } catch (e, s) { _logger.e('$e: $s', e, s); }
        
      // Copy from asset
      final data = await rootBundle.load('assets/bible.db');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      
      // Write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);

    } else {
      _logger.i("Opening existing database");
    }
    // open the database
    return openDatabase(path, readOnly: true, singleInstance: true);
  }

  Future<Iterable<DbBible>> bibleWhere({Map<String, dynamic>? where}) async {
    if(!locator.isReadySync<Database>()) { await locator.isReady<Database>(); }
    final db = locator<Database>();
    final query = await db.query('bible', where: where?.keys.map((k) => '$k = ?').join(' and '), whereArgs: where?.values.toList());
    return query.map((m) => DbBible.fromMap(m));
  }
}
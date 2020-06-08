import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

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
  final bookNames = const [
    '창세기', '출애굽기', '레위기', '민수기', '신명기', '여호수아',
    '사사기', '룻기', '사무엘상', '사무엘하', '열왕기상', '열왕기하',
    '역대상', '역대하', '에스라', '느헤미야', '에스더', '욥기',
    '시편', '잠언', '전도서', '아가', '이사야', '예레미야',
    '예레미야애가', '에스겔', '다니엘', '호세아', '요엘', '아모스',
    '오바댜', '요나', '미가', '나훔', '하박국', '스바냐',
    '학개', '스가랴', '말라기', '마태복음', '마가복음', '누가복음',
    '요한복음', '사도행전', '로마서', '고린도전서', '고린도후서', '갈라디아서',
    '에베소서', '빌립보서', '골로새서', '데살로니가전서', '데살로니가후서', '디모데전서',
    '디모데후서', '디도서', '빌레몬서', '히브리서', '야고보서', '베드로전서',
    '베드로후서', '요한일서', '요한이서', '요한삼서', '유다서', '요한계시록',
  ];
  Future<Database> dataBase;
  SungrakService() {
    dataBase = Future(loadDatabase);
  }

  FutureOr<Database> loadDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath/assets_bible.db';

    // Check if the database exists
    final exists = await databaseExists(path);

    if (!exists) {
      // Should happen only the first time you launch your application
      print("Creating new copy from asset");

      // Make sure the parent directory exists
      try {
        await Directory(databasesPath).create(recursive: true);
      } catch (e, s) { print('$e: $s'); }
        
      // Copy from asset
      final data = await rootBundle.load('assets/bible.db');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      
      // Write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);

    } else {
      print("Opening existing database");
    }
    // open the database
    return openDatabase(path, readOnly: true, singleInstance: false);
  }

  static Future<Iterable<DbBible>> bibleWhere(Database db, {Map<String, dynamic> where}) async {
    final query = await db.query('bible', where: where.keys.map((k) => '$k = ?').join(' and '), whereArgs: where.values.toList());
    return query.map((m) => DbBible.fromMap(m));
  }
}
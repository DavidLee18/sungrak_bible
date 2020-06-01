import 'package:flutter/services.dart';

class SungrakService {
  static const _books = [
    '1-01창세기', '1-02출애굽기', '1-03레위기', '1-04신명기', '1-05민수기', '1-06여호수아',
    '1-07사사기', '1-08룻기', '1-09사무엘상', '1-10사무엘하', '1-11열왕기상', '1-12열왕기하',
    '1-13역대상', '1-14역대하', '1-15에스라', '1-16느헤미야', '1-17에스더', '1-18욥기',
    '1-19시편', '1-20잠언', '1-21전도서', '1-22아가', '1-23이사야', '1-24예레미야',
    '1-25예레미야애가', '1-26에스겔', '1-27다니엘', '1-28호세아', '1-29요엘', '1-30아모스',
    '1-31오바댜', '1-32요나', '1-33미가', '1-34나훔', '1-35하박국', '1-36스바냐',
    '1-37학개', '1-38스가랴', '1-39말라기', '2-01마태복음', '2-02마가복음', '2-03누가복음',
    '2-04요한복음', '2-05사도행전', '2-06로마서', '2-07고린도전서', '2-08고린도후서', '2-09갈라디아서',
    '2-10에베소서', '2-11빌립보서', '2-12골로새서', '2-13데살로니가전서', '2-14데살로니가후서', '2-15디모데전서',
    '2-16디모데후서', '2-17디도서', '2-18빌레몬서', '2-19히브리서', '2-20야고보서', '2-21베드로전서',
    '2-22베드로후서', '2-23요한일서', '2-24요한이서', '2-25요한삼서', '2-26유다서', '2-27요한계시록',
  ];
  final Iterable<Future<MapEntry<String, Map<int, Map<int, String>>>>> books = _books.map((b) async {
      final res = await rootBundle.loadStructuredData('bible/$b.txt', parse);
      return MapEntry(b.substring(4), res);
    });

  SungrakService();

  static Future<Map<int, Map<int, String>>> parse(String raw) async {
    Map<int, Map<int, String>> res;
    raw.split('\n').forEach((e) {
      final index = e.indexOf(':');
      res[int.parse(e[index-1])][int.parse(e[index+1])] = e.substring(index + 3);
    });
    return res;
  }
}
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:sungrak_bible/service_locator.dart';
import 'package:sungrak_bible/sungrak_service.dart';

void main() {
  setupServiceLocator();
  runApp(MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: ThemeMode.system,
      routes: {
        '/': (_) => HomePage(),
        '/book': (_) => BookPage(),
        '/chapter': (_) => ChapterPage(),
      },
      initialRoute: '/',
    ));
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}
  
class _HomePageState extends State<HomePage> {
  final _service = locator<SungrakService>();
  final _logger = Logger();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('성락교회 성경 β'),),
    body: ListView.builder(itemCount: 66, shrinkWrap: true, itemBuilder: (_, index) => 
      FutureBuilder(future: _service.bibleWhere(where: { Bible.columnLang: 'korea', Bible.columnBookIndex: index + 1 }), 
      builder: (_, AsyncSnapshot<Iterable<DbBible>> snapshot) {
        if(snapshot.hasError) {
          _logger.e('error', snapshot.error, (snapshot.error as Error).stackTrace);
        }
        return snapshot.hasError ? ErrorTile(error: snapshot.error!)
        : snapshot.hasData ? ListTile(
        title: Text(snapshot.data!.first.bookName),
        subtitle: Text('총 ${DbBible.chapters(snapshot.data!)}장'),
        onTap: () => Navigator.pushNamed(context, '/book', arguments: { Bible.columnLang: 'korea', Bible.columnBookIndex: index + 1 }),
        ) : LoadingTile();
      },),
    ),
    backgroundColor: null,
  );
}

class BookPage extends StatefulWidget {
  @override
  State<BookPage> createState() => _BookPageState();
}
  
class _BookPageState extends State<BookPage> {
  final SungrakService _service = locator<SungrakService>();

  final _logger = Logger(filter: ProductionFilter());

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? query = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if(query != null || !query!.containsKey(Bible.columnLang) || !query.containsKey(Bible.columnBookIndex)) {
      _logger.e('no such book in bible');
      return MyErrorWidget(
      message: 'No such book',
      description: 'the book received as argument IS NULL',
    );
    } else return FutureBuilder(future: _service.bibleWhere(where: query), 
    builder: (_, AsyncSnapshot<Iterable<DbBible>> snapshot) => snapshot.hasError
    ? Scaffold(
      appBar: AppBar(title: Text('BookPage.Error'),),
      body: MyErrorWidget(message: 'async error', description: 'async operation got error: ${snapshot.error}',),
    )
    : snapshot.hasData ? Scaffold(
      appBar: AppBar(title: Text(snapshot.data!.first.bookName),),
      body: ListView.builder(itemCount: DbBible.chapters(snapshot.data!), shrinkWrap: true, itemBuilder: (_, index) => 
      ListTile(
        title: Text('${index + 1}장'),
        subtitle: Text('총 ${DbBible.verses(snapshot.data!, index + 1)}절'),
        onTap: () => Navigator.pushNamed(context, '/chapter', arguments: { ...query, Bible.columnChapter: index + 1 }),
      )))
    : Scaffold(
      appBar: AppBar(title: Text('BookPage Loading...')),
      body: LoadingWidget(description: 'loading book...',),
    ));
  }
}

class MyErrorWidget extends StatelessWidget {
  final String message;
  final String description;
  MyErrorWidget({this.message = 'error', this.description = ''});
  @override
  Widget build(BuildContext context) => Center(child: Column(children: [
        Icon(Icons.error, color: Colors.red,),
        Text(message),
        Text(description),
        RaisedButton(
          child: Text('go back'),
          onPressed: () => Navigator.pop(context)
        ),
      ],));
}

class LoadingWidget extends StatelessWidget {
  final String message;
  final String description;
  LoadingWidget({this.message = 'loading...', this.description = ''});
  @override
  Widget build(BuildContext context) => Center(child: Column(children: [
        Icon(Icons.autorenew, color: Colors.yellow,),
        Text(message),
        Text(description),
        RaisedButton(
          child: Text('go back'),
          onPressed: () => Navigator.pop(context)
        ),
      ],));
}

class ErrorTile extends StatelessWidget {
  final Object? error;
  final String errorText;
  final bool dense;
  const ErrorTile({Key? key, @required this.error, this.errorText = 'Error', this.dense = false}) : super(key: key);
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(Icons.error, color: Colors.red),
    title: Text(errorText),
    subtitle: Text(error.toString()),
    dense: dense,
  );
}

class LoadingTile extends StatelessWidget {
  final String? description;

  const LoadingTile({Key? key, this.description}) : super(key: key);
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(Icons.autorenew, color: Colors.yellow,),
    title: Text('로딩중...'),
    subtitle: description == null ? null : Text(description!),
  );
}

class ChapterPage extends StatefulWidget {
  @override
  State<ChapterPage> createState() => _ChapterPageState();
}
  
class _ChapterPageState extends State<ChapterPage> {
  final SungrakService _service = locator<SungrakService>();

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? query = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (query == null || !query.containsKey(Bible.columnLang) || !query.containsKey(Bible.columnBookIndex) || !query.containsKey(Bible.columnChapter)) return MyErrorWidget(
      message: 'No such book and chapter',
      description: 'book and corresponding chapter received as argument IS BOTH NULL',
    );
    else return FutureBuilder(future: _service.bibleWhere(where: query..update(Bible.columnLang, (value) => _service.isKorean ? 'korea' : 'english', ifAbsent: () => null)), 
    builder: (_, AsyncSnapshot<Iterable<DbBible>> snapshot) {
      if(snapshot.hasError) return Scaffold(
        appBar: AppBar(title: Text('ChapterPage.Error'),),
        body: MyErrorWidget(message: 'async error', description: 'async : ${snapshot.error}',),
      );
      else if(snapshot.hasData) {
        final chapter = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text('${chapter.first.bookName} ' + (_service.isKorean ? '${chapter.first.chapter} 장' : 'Chapter ${chapter.first.chapter}')),
            actions: [
              FlatButton(
                onPressed: () => setState(() => _service.isKorean = !_service.isKorean), 
                child: Text(_service.isKorean ? '한국어' : 'English', style: TextStyle(color: Colors.white),)),
            ],
          ),
          body: ListView.builder(itemCount: chapter.length, shrinkWrap: true, itemBuilder: (_, index) {
            final verse = chapter.elementAt(index);
            return ListTile(
              title: SelectableText('${verse.verse} ${verse.value}'),
          );
          }));
      }
      else return Scaffold(
        appBar: AppBar(title: Text('ChapterPage Loading...'),),
        body: LoadingWidget(description: 'loading chapter...',)
      );
    });
  }
}
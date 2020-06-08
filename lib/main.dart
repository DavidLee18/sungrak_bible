import 'package:flutter/material.dart';
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
      themeMode: ThemeMode.system,
      routes: {
        '/': (_) => HomePage(),
        '/book': (_) => BookPage(),
        '/chapter': (_) => ChapterPage(),
      },
      initialRoute: '/',
    ));
}

class HomePage extends StatelessWidget {
  final SungrakService _service = locator<SungrakService>();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('성락교회 성경 beta'),),
    body: ListView.builder(itemCount: _service.bookNames.length, itemBuilder: (_, index) => 
      FutureBuilder(future: _service.dataBase.then((db) => SungrakService.bibleWhere(db, where: { Bible.columnLang: 'korea', Bible.columnBookIndex: index + 1 })), 
      builder: (_, AsyncSnapshot<Iterable<DbBible>> snapshot) => ListTile(
        title: Text(_service.bookNames[index]),
        subtitle: snapshot.hasError ? Text('${snapshot.error is Error ? (snapshot.error as Error).stackTrace : snapshot.error}')
        : snapshot.hasData ? Text('총 ${DbBible.chapters(snapshot.data)}장')
        : Text('로딩중...', style: TextStyle(color: Colors.yellowAccent[700]),),
        onTap: () => Navigator.pushNamed(context, '/book', arguments: { Bible.columnLang: 'korea', Bible.columnBookIndex: index + 1 }),
        ),),
    ),
    backgroundColor: null,
  );
}

class BookPage extends StatelessWidget {
  final SungrakService _service = locator<SungrakService>();

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> query = ModalRoute.of(context).settings.arguments;
    if(query == null || !query.containsKey(Bible.columnLang) || !query.containsKey(Bible.columnBookIndex)) return MyErrorWidget(
      message: 'No such book',
      description: 'the book received as argument IS NULL',
    );
    else return FutureBuilder(future: _service.dataBase.then((db) => SungrakService.bibleWhere(db, where: query)), 
    builder: (_, AsyncSnapshot<Iterable<DbBible>> snapshot) => snapshot.hasError
    ? Scaffold(
      appBar: AppBar(title: Text('BookPage.Error'),),
      body: MyErrorWidget(message: 'async error', description: 'async operation got error: ${snapshot.error}',),
    )
    : snapshot.hasData ? Scaffold(
      appBar: AppBar(title: Text(snapshot.data.first.bookName),),
      body: ListView.builder(itemCount: DbBible.chapters(snapshot.data), itemBuilder: (_, index) => 
      ListTile(
        title: Text('${index + 1}장'),
        subtitle: Text('총 ${DbBible.verses(snapshot.data, index + 1)}절'),
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
  final Object error;
  final String errorText;
  final bool dense;
  const ErrorTile({Key key, @required this.error, this.errorText = 'Error', this.dense = false}) : super(key: key);
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(Icons.error, color: Colors.red),
    title: Text(errorText),
    subtitle: Text(error.toString()),
    dense: dense,
  );
}

class LoadingTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(Icons.autorenew, color: Colors.yellow,),
    title: Text('로딩중...'),
    subtitle: Text('loading from asset and parsing...'),
  );
}

class ChapterPage extends StatelessWidget {
  final SungrakService _service = locator<SungrakService>();

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> query = ModalRoute.of(context).settings.arguments;
    if (query == null || !query.containsKey(Bible.columnLang) || !query.containsKey(Bible.columnBookIndex) || !query.containsKey(Bible.columnChapter)) return MyErrorWidget(
      message: 'No such book and chapter',
      description: 'book and corresponding chapter received as argument IS BOTH NULL',
    );
    else return FutureBuilder(future: _service.dataBase.then((db) => SungrakService.bibleWhere(db, where: query)), 
    builder: (_, AsyncSnapshot<Iterable<DbBible>> snapshot) {
      if(snapshot.hasError) return Scaffold(
        appBar: AppBar(title: Text('ChapterPage.Error'),),
        body: MyErrorWidget(message: 'async error', description: 'async : ${snapshot.error}',),
      );
      else if(snapshot.hasData) {
        final chapter = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: Text('${snapshot.data.first.bookName} ${snapshot.data.first.chapter}장'),),
          body: ListView.builder(itemCount: chapter.length, itemBuilder: (_, index) {
            final verse = chapter.elementAt(index);
            return ListTile(
            title: Text('${verse.verse} ${verse.value}'),
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
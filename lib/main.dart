import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sungrak_bible/service_locator.dart';
import 'package:sungrak_bible/sungrak_service.dart';
import 'package:tuple/tuple.dart';

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
    body: ListView.builder(itemCount: 66, itemBuilder: (_, index) => 
    FutureBuilder(future: _service.books[index], 
    builder: (_, AsyncSnapshot<MapEntry<String, List<Verse>>> snapshot) => snapshot.hasError ? ErrorTile(error: snapshot.error,)
      : snapshot.hasData ? ListTile(
        title: Text(snapshot.data.key),
        subtitle: Text('총 ${Verse.chapters(snapshot.data)}장'),
        onTap: () => Navigator.pushNamed(context, '/book', arguments: index),)
      : LoadingTile())));
}

class BookPage extends StatelessWidget {
  final SungrakService _service = locator<SungrakService>();

  @override
  Widget build(BuildContext context) {
    final int bookIndex = ModalRoute.of(context).settings.arguments;
    if(bookIndex == null) return MyErrorWidget(
      message: 'No such book',
      description: 'the book received as argument IS NULL',
    );
    else return FutureBuilder(future: _service.books[bookIndex], builder: (_, AsyncSnapshot<MapEntry<String, List<Verse>>> snapshot) => snapshot.hasError
    ? Scaffold(
      appBar: AppBar(title: Text('BookPage.Error'),),
      body: MyErrorWidget(message: 'async error', description: 'async operation got error: ${snapshot.error}',),
    )
    : snapshot.hasData ? Scaffold(
      appBar: AppBar(title: Text(snapshot.data.key),),
      body: ListView.builder(itemCount: Verse.chapters(snapshot.data), itemBuilder: (_, index) => 
      ListTile(
        title: Text('${index + 1}장'),
        subtitle: Text('총 ${Verse.verses(snapshot.data, index + 1)}절'),
        onTap: () => Navigator.pushNamed(context, '/chapter', arguments: Tuple2(bookIndex, index + 1)),
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
    final Tuple2<int, int> bookChapter = ModalRoute.of(context).settings.arguments;
    if (bookChapter?.item1 == null && bookChapter?.item2 == null) return MyErrorWidget(
      message: 'No such book and chapter',
      description: 'book and corresponding chapter received as argument IS BOTH NULL',
    );
    else return FutureBuilder(future: _service.books[bookChapter.item1], builder: (_, AsyncSnapshot<MapEntry<String, List<Verse>>> snapshot) {
      if(snapshot.hasError) return Scaffold(
        appBar: AppBar(title: Text('ChapterPage.Error'),),
        body: MyErrorWidget(message: 'async error', description: 'async : ${snapshot.error}',),
      );
      else if(snapshot.hasData) {
        final chapter = snapshot.data.value.where((verse) => verse.chapter == bookChapter.item2).toList();
        return Scaffold(
          appBar: AppBar(title: Text('${snapshot.data.key} ${bookChapter.item2}장'),),
          body: ListView.builder(itemCount: chapter.length, itemBuilder: (_, index) {
            final verse = chapter[index];
            return ListTile(
            title: Text(verse.range != 0 ? '${verse.verse}-${verse.verse + verse.range} ${verse.value}'
            : '${verse.verse} ${verse.value}'),
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
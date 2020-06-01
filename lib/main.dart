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
        '/': (context) => HomePage(),
        '/book': (context) => BookPage(),
        '/chapter': (context) => ChapterPage(),
      },
      initialRoute: '/',
    ));
}


class HomePage extends StatelessWidget {
  final SungrakService _service = locator<SungrakService>();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('성락교회 성경 beta'),),
    body: ListView.builder(itemCount: 66, itemBuilder: (context, index) => 
    FutureBuilder(future: _service.books.elementAt(index), 
    builder: (context, AsyncSnapshot<MapEntry<String, Map<int, Map<int, String>>>> snapshot) {
      Widget widget;
      if(snapshot.hasError) return Center(child: Column(children: [
        Icon(Icons.error, color: Colors.red,),
        Text('no index: error'),
        RaisedButton(
          child: Text('go back'),
          onPressed: () => Navigator.pop(context)
        ),
      ],));
      else switch(snapshot.connectionState) {
        case ConnectionState.active:
        case ConnectionState.done:
          widget = ListTile(
          title: Text(snapshot.data.key),
          subtitle: Text('총 ${snapshot.data.value.length}장'),
          onTap: () => Navigator.pushNamed(context, '/book', arguments: snapshot.data),);
          break;
        case ConnectionState.none:
        case ConnectionState.waiting:
          widget = CircularProgressIndicator();
          break;
      }
      return widget;
    }
    )
    )
  );
}

class BookPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    MapEntry<String, Map<int, Map<int, String>>> book = ModalRoute.of(context).settings.arguments;
    if(book == null) return MyErrorWidget();
    else {
      return Scaffold(
        appBar: AppBar(title: Text(book.key),),
        body: ListView.builder(itemCount: book.value.length, itemBuilder: (context, index) => 
        ListTile(
          title: Text('${book.value.keys.elementAt(index)}장'),
          subtitle: Text('총 ${book.value.values.elementAt(index).length}절'),
          onTap: () => Navigator.pushNamed(context, '/chapter', arguments: Tuple2(book, index)),
        ))
      );
    }
  }
}

class MyErrorWidget extends StatelessWidget {
  final String message;
  MyErrorWidget({this.message});
  @override
  Widget build(BuildContext context) => Center(child: Column(children: [
        Icon(Icons.error, color: Colors.red,),
        Text(message ?? 'error'),
        RaisedButton(
          child: Text('go back'),
          onPressed: () => Navigator.pop(context)
        ),
      ],));
}

class ChapterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Tuple2<MapEntry<String, Map<int, Map<int, String>>>, int> bookChapter = ModalRoute.of(context).settings.arguments;
    if (bookChapter?.item1 == null && bookChapter?.item2 == null) return MyErrorWidget();
    else {
      var chapter = bookChapter.item1.value[bookChapter.item2];
      return Scaffold(
        appBar: AppBar(title: Text('${bookChapter.item1.key} ${bookChapter.item2}장'),),
        body: ListView.builder(itemCount: bookChapter.item1.value.length, itemBuilder: (context, index) => 
        ListTile(
          title: Text('${chapter.keys.elementAt(index)} ${chapter.values.elementAt(index)}'),
        ))
      );
    }
  }
}
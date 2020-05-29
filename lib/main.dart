import 'package:flutter/material.dart';
import 'package:sungrak_bible/service_locator.dart';

void main() {
  setupServiceLocator();
  runApp(MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: {
        '/': (_) => HomePage(),
      },
      initialRoute: '/',
    ));
}


class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
  
}
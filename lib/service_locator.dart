import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';
import 'sungrak_service.dart';

GetIt locator = GetIt.instance;

setupServiceLocator() {
  locator.registerLazySingleton<SungrakService>(() => SungrakService());
  locator.registerLazySingletonAsync<Database>(() => Future(() => SungrakService().dataBase));
}
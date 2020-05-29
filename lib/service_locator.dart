import 'package:get_it/get_it.dart';
import 'sungrak_service.dart';

GetIt locator = GetIt.instance;

setupServiceLocator() {
  locator.registerLazySingleton<SungrakServiceBase>(() => SungrakService());
}
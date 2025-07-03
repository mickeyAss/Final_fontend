import 'package:flutter/material.dart';
import 'package:fontend_pro/pages/choose_categoryPage.dart';
import 'package:fontend_pro/pages/login.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get_storage/get_storage.dart';


void main() async{
   WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.black,
       
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 8,
        ),
      ),
      home: const Loginpage(),
    );
  }
}

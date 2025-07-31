import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:fontend_pro/pages/login.dart';
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/pages/mainPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fontend_pro/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GetStorage.init();
  
  final gs = GetStorage();
  var user = gs.read('user');
  print('user ---> $user');

  String firstPage = (user == null) ? '/login' : '/mainPage'; 

  runApp(MyApp(initialRoute: firstPage));
}  

class MyApp extends StatelessWidget {
  final String initialRoute;  

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialRoute: initialRoute,
      getPages: [
        GetPage(name: '/login', page: () => const Loginpage()),
        GetPage(name: '/mainPage', page: () => const Mainpage()),
      ],
      theme: ThemeData(
        textTheme:GoogleFonts.k2dTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        primaryColor: Colors.black,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 8,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.black,
        ),
      ),
    );
  }
}

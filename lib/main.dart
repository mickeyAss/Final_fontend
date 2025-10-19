import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:fontend_pro/pages/login.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fontend_pro/pages/mainPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fontend_pro/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

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
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      getPages: [
        GetPage(name: '/login', page: () => const Loginpage()),
        GetPage(name: '/mainPage', page: () => const Mainpage()),
      ],
      theme: ThemeData.light().copyWith(
        textTheme: GoogleFonts.k2dTextTheme(ThemeData.light().textTheme),
        scaffoldBackgroundColor: Colors.white, // 🔹 พื้นหลังขาว
        primaryColor: Colors.black, // 🔹 สีหลักของระบบเป็นดำ
        useMaterial3: true,

        // 🔹 AppBar สีขาว ตัวอักษรดำ
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),

        // 🔹 แถบล่างสีขาว ตัวอักษรดำ
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
        ),

        // 🔹 เคอร์เซอร์และ Selection ให้เป็นสีดำ
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: Colors.black12,
          selectionHandleColor: Colors.black,
        ),

        // 🔹 ช่องข้อความ (TextField) กรอบดำ พื้นหลังขาว
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white, // พื้นในช่องเป็นขาว
          hintStyle: TextStyle(color: Colors.grey),
          labelStyle: TextStyle(color: Colors.black),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black, width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black54, width: 1.0),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),

        // 🔹 ปุ่มกดเป็นสีดำ ตัวอักษรขาว
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        // 🔹 TextButton และ IconButton ก็ใช้สีดำ
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
    );
  }
}

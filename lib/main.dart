import 'package:flutter/material.dart';
import 'package:fontend_pro/pages/login.dart';
import 'package:fontend_pro/pages/mainPage.dart';
import 'package:fontend_pro/pages/profilePage.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      title: 'Flutter Demo',
      home: Loginpage()
    );
  }
}

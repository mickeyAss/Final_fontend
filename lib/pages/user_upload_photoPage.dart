import 'package:flutter/material.dart';

class UserUploadPhotopage extends StatefulWidget {
  const UserUploadPhotopage({super.key});

  @override
  State<UserUploadPhotopage> createState() => _UserUploadPhotopageState();
}

class _UserUploadPhotopageState extends State<UserUploadPhotopage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text("upload")
        ],
      ),
    );
  }
}
import 'dart:developer';

import 'package:fontend_pro/models/get_user_uid.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/pages/edit_profile.dart';
import 'package:fontend_pro/pages/mainPage.dart';
import 'package:get/get.dart';

class Profilepage extends StatefulWidget {
  final int uid;
  const Profilepage({super.key, required this.uid});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  int selectedIndex = 0;
  late GetUserUid user;
  late Future<void> loadData_User;

  @override
  void initState() {
    super.initState();
    loadData_User = loadDataUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: loadData_User,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading user data'));
          }
          return Scaffold(
              body: Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Spacer(),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 30),
                        child: Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.settings),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ClipOval(
                      child: Image.network(
                        user.profileImage,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Column(
                      children: const [
                        Text(
                          "10",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          "กำลังติดตาม",
                          style: TextStyle(color: Colors.black54),
                        )
                      ],
                    ),
                    const Text(
                      "|",
                      style: TextStyle(fontSize: 25, color: Colors.black45),
                    ),
                    Column(
                      children: const [
                        Text("20",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          "ผู้ติดตาม",
                          style: TextStyle(color: Colors.black54),
                        )
                      ],
                    ),
                    const Text(
                      "|",
                      style: TextStyle(fontSize: 25, color: Colors.black45),
                    ),
                    Column(
                      children: const [
                        Text("30",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          "ถูกใจ",
                          style: TextStyle(color: Colors.black54),
                        )
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(user.personalDescription),
                  ],
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.only(left: 135, right: 135),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () {
                      Get.to(() => const EditProfilePage());
                    },
                    child: const Text('แก้ไขโปรไฟล์')),
              ],
            ),
          ));
        });
  }

  Future<void> loadDataUser() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    final response = await http.get(Uri.parse("$url/user/get/${widget.uid}"));
    if (response.statusCode == 200) {
      user = getUserUidFromJson(response.body);
      log(response.body);
      setState(() {});
    } else {
      log('Error loading user data: ${response.statusCode}');
    }
    
  }
}

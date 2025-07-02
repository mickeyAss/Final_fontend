import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/get_all_user.dart';
import 'package:fontend_pro/models/get_user_uid.dart';

class UserAddFriendspage extends StatefulWidget {

  const UserAddFriendspage({super.key});

  @override
  State<UserAddFriendspage> createState() => _UserAddFriendspageState();
}

class _UserAddFriendspageState extends State<UserAddFriendspage> {
  List<GetAllUser> user = [];
  late Future<void> loadData_user;

  @override
  void initState() {
    super.initState();
    loadData_user = loadDataUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: SafeArea(
            child: Column(
              children: [
                // ช่องค้นหา
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'ค้นหาเพื่อนของคุณ',
                          hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(width: 1)),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.black, width: 1.5),
                          ),
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'ค้นหา',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // FutureBuilder ที่เลื่อนเฉพาะส่วนล่าง
                Expanded(
                  child: FutureBuilder(
                    future: loadData_user,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(
                            child: Text('Error loading user data'));
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ผู้คนที่แนะนำ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: user.length,
                              itemBuilder: (context, index) {
                                final users = user[index];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipOval(
                                        child: Image.network(
                                          users.profileImage ?? '',
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            width: 80,
                                            height: 80,
                                            alignment: Alignment.center,
                                            color: Colors.grey[300],
                                            child: Text(
                                              'ไม่มีภาพ',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 20),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(users.name),
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: 115,
                                                child: FilledButton(
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.black,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 8),
                                                  ),
                                                  onPressed: () {},
                                                  child: const Text(
                                                    'ติดตาม',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              SizedBox(
                                                width: 115,
                                                child: FilledButton(
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.grey,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 8),
                                                  ),
                                                  onPressed: () {},
                                                  child: const Text(
                                                    'ลบ',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

Future<void> loadDataUser() async {
  var config = await Configuration.getConfig();
  var url = config['apiEndpoint'];

  final response = await http.get(Uri.parse("$url/user/get"));

  if (response.statusCode == 200) {
    user = getAllUserFromJson(response.body);
    log('response : ${response.body}');
    setState(() {});
  } else {
    log('Error loading user data: ${response.statusCode}');
  }
}

// Future<void> loadDataUser() async {
//   var config = await Configuration.getConfig();
//   var url = config['apiEndpoint'];

//   final response = await http.get(Uri.parse("$url/user/list/${widget.uid}"));
//   log('เรียก URL: $url/user/list/${widget.uid}');
//   if (response.statusCode == 200) {
//     user = getAllUserFromJson(response.body);
//     log('response : ${response.body}');
//     setState(() {});
//   } else {
//     log('Error loading user data: ${response.statusCode}');
//   }
// }


}

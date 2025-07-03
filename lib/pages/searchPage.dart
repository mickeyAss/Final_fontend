import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/get_all_user.dart';

class Searchpage extends StatefulWidget {
  const Searchpage({super.key});

  @override
  State<Searchpage> createState() => _SearchpageState();
}

class _SearchpageState extends State<Searchpage> {
  List<GetAllUser> user = [];
  late Future<void> loadData_user;

  @override
  void initState() {
    super.initState();
    loadData_user = loadDataUser();
  }

  Future<void> loadDataUser() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    final response = await http.get(Uri.parse("$url/user/get"));

    if (response.statusCode == 200) {
      setState(() {
        user = getAllUserFromJson(response.body);
      });
      log('response : ${response.body}');
    } else {
      log('Error loading user data: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                SizedBox(height: 10),

                // ส่วนแนะนำ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("แนะนำ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {},
                      child: Text("ดูทั้งหมด",
                          style: TextStyle(color: Colors.black54)),
                    ),
                  ],
                ),
                SizedBox(height: 10),

                // แสดงผู้ใช้แนะนำแนวนอน
                FutureBuilder(
                  future: loadData_user,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error loading user data'));
                    }

                    return SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: user.length,
                        itemBuilder: (context, index) {
                          final users = user[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: Column(
                              children: [
                                ClipOval(
                                  child: Image.network(
                                    users.profileImage ?? '',
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      width: 70,
                                      height: 70,
                                      color: Colors.grey[300],
                                      alignment: Alignment.center,
                                      child: Text(
                                        'ไม่มีภาพ',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Transform.translate(
                          offset: Offset(0, -20), // ขยับรูปขึ้น
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/hastag.png',
                                width: 35,
                                height: 35,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 35,
                                  height: 35,
                                  color: Colors.grey[300],
                                  alignment: Alignment.center,
                                  child: Text(
                                    'ไม่มีภาพ',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Transform.translate(
                          offset:
                              Offset(0, -20), // ขยับข้อความขึ้นให้เท่ากับรูป
                          child: Text(
                            "ติดเทรนด์",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(8), 
                            child: Image.asset(
                              'assets/images/p3.jpg',
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 10),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(8), 
                            child: Image.asset(
                              'assets/images/p4.jpg',
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 10),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(8), 
                            child: Image.asset(
                              'assets/images/p4.jpg',
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

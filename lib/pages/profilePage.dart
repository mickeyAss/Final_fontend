import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/pages/edit_profile.dart';
import 'package:fontend_pro/models/get_user_uid.dart';
import 'package:fontend_pro/pages/user_my_post_tab.dart';
import 'package:fontend_pro/pages/user_my_likes_tab.dart';
import 'package:fontend_pro/pages/user_my_bookmarks_tab.dart';

class Profilepage extends StatefulWidget {
  const Profilepage({super.key});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  int selectedIndex = 0;
  GetUserUid? user;
  final GetStorage gs = GetStorage();
  late Future<void> _loadUserFuture;

  @override
  void initState() {
    super.initState();
    _loadUserFuture = loadDataUser();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (BuildContext context) {
                    return ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.account_circle,
                                      color: Colors.blue, size: 22),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'บัญชี',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              title: const Text('ออกจากระบบ'),
                              onTap: () {
                                Navigator.of(context).pop();
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    elevation: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 18),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.red.shade300,
                                            Colors.red.shade600
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.shade200
                                                .withOpacity(0.5),
                                            offset: const Offset(0, 6),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.logout,
                                              size: 48, color: Colors.white),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'ออกจากระบบ',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(
                                                      color: Colors.white70),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14),
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20,
                                                      vertical: 10),
                                                  foregroundColor:
                                                      Colors.white70,
                                                  textStyle: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                                child: const Text('ยกเลิก'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14),
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20,
                                                      vertical: 10),
                                                  foregroundColor:
                                                      Colors.red.shade700,
                                                  textStyle: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14),
                                                ),
                                                onPressed: () {
                                                  gs.erase().then((_) {
                                                    Navigator.of(context).pop();
                                                    Get.offAllNamed('/login');
                                                  });
                                                },
                                                child: const Text('ออกจากระบบ'),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              title: const Text('ลบบัญชีผู้ใช้'),
                              onTap: () {
                                Navigator.of(context).pop();
                                Get.snackbar(
                                  'ลบบัญชี',
                                  'ยังไม่ได้เชื่อม API สำหรับลบบัญชี',
                                  snackPosition: SnackPosition.TOP,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            FutureBuilder(
              future: _loadUserFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(
                          255, 0, 0, 0), // เปลี่ยนสีตรงนี้ได้ตามต้องการ
                      strokeWidth: 3,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error loading user data'));
                }

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Center(
                                child: Text(
                                  user?.name ?? 'ไม่มีชื่อ',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.black,
                                      width: 2), // กรอบสีดำ
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    user?.profileImage ?? '',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.person,
                                          size: 80, color: Colors.grey);
                                    },
                                  ),
                                ),
                              ),
                              Column(
                                children: const [
                                  Text(
                                    "10",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  Text(
                                    "กำลังติดตาม",
                                    style: TextStyle(color: Colors.black54),
                                  )
                                ],
                              ),
                              const Text("|",
                                  style: TextStyle(
                                      fontSize: 25, color: Colors.black45)),
                              Column(
                                children: const [
                                  Text("20",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  Text(
                                    "ผู้ติดตาม",
                                    style: TextStyle(color: Colors.black54),
                                  )
                                ],
                              ),
                              const Text("|",
                                  style: TextStyle(
                                      fontSize: 25, color: Colors.black45)),
                              Column(
                                children: const [
                                  Text("30",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
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
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  user?.personalDescription ?? '',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 135, vertical: 10),
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
                            child: const Text('แก้ไขโปรไฟล์'),
                          ),
                        ],
                      ),
                    ),

                    // แท็บไอคอน
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              selectedIndex = 0;
                            });
                          },
                          icon: Icon(
                            Icons.grid_view,
                            color:
                                selectedIndex == 0 ? Colors.black : Colors.grey,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              selectedIndex = 1;
                            });
                          },
                          icon: Icon(
                            Icons.bookmark_border_outlined,
                            color:
                                selectedIndex == 1 ? Colors.black : Colors.grey,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              selectedIndex = 2;
                            });
                          },
                          icon: Icon(
                            Icons.favorite_outline_rounded,
                            color:
                                selectedIndex == 2 ? Colors.black : Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    Expanded(
                      child: IndexedStack(
                        index: selectedIndex,
                        children: const [
                          UserMyPostTab(),
                          UserMyBookmarksTab(),
                          UserMyLikesTab()
                        ],
                      ),
                    )
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loadDataUser() async {
    final uid = gs.read('user');
    log("กำลังโหลดข้อมูลของ UID: $uid");

    if (uid == null) {
      throw Exception('ไม่พบ UID ใน GetStorage');
    }

    final config = await Configuration.getConfig();
    final url = config['apiEndpoint'];
    final response = await http.get(Uri.parse("$url/user/get/$uid"));

    if (response.statusCode == 200) {
      setState(() {
        user = getUserUidFromJson(response.body);
      });
      log("โหลดข้อมูลสำเร็จ: ${response.body}");
    } else {
      log('โหลดข้อมูลไม่สำเร็จ: ${response.statusCode}');
      throw Exception('โหลดข้อมูลไม่สำเร็จ');
    }
  }
}

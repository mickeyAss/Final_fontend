import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/get_all_user.dart';
import 'package:fontend_pro/models/get_post_hashtags.dart';

class Searchpage extends StatefulWidget {
  const Searchpage({super.key});

  @override
  State<Searchpage> createState() => _SearchpageState();
}

class _SearchpageState extends State<Searchpage> {
  List<GetAllUser> user = [];
  List<GetAllUser> filteredUsers = [];
  final GetStorage gs = GetStorage();

  List<GetPostHashtags> hashtagsWithPosts = [];
  bool _isLoadingHashtags = true;

  late int loggedInUid;

  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _initializeData();

    _initializeHashtags();
  }

  Future<void> _initializeData() async {
    try {
      await loadDataUser(loggedInUid);
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
      });
    } finally {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  void _initializeUser() {
    dynamic rawUid = gs.read('user');
    if (rawUid is int) {
      loggedInUid = rawUid;
    } else if (rawUid is String) {
      loggedInUid = int.tryParse(rawUid) ?? 0;
    } else {
      loggedInUid = 0;
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      await loadDataUser(loggedInUid);
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
    _initializeHashtags();
  }

  /// ================== API Load Users ==================
  Future<void> loadDataUser(int loggedInUid) async {
    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response =
          await http.get(Uri.parse("$url/user/users-except?uid=$loggedInUid"));

      if (response.statusCode == 200) {
        final newUsers = getAllUserFromJson(response.body);
        setState(() {
          user = newUsers;
          filteredUsers = newUsers;
          _errorMessage = null;
        });
        log('Users loaded successfully: ${newUsers.length} users');
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to load users');
      }
    } catch (e) {
      log('Error loading user data: $e');
      throw e;
    }
  }

  Future<List<GetPostHashtags>> loadHashtagsWithPosts() async {
    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response =
          await http.get(Uri.parse("$url/hashtags/hashtags-with-posts"));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((e) => GetPostHashtags.fromJson(e)).toList();
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to load hashtags');
      }
    } catch (e) {
      log('Error loading hashtags: $e');
      rethrow;
    }
  }

  Future<void> _initializeHashtags() async {
    try {
      final data = await loadHashtagsWithPosts();
      setState(() {
        hashtagsWithPosts = data;
        _isLoadingHashtags = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingHashtags = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.black,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(_errorMessage!),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  // ช่องค้นหา
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'ค้นหาเพื่อนของคุณ',
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                            border: const OutlineInputBorder(
                                borderSide: BorderSide(width: 1)),
                            focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.black, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 12),
                          ),
                          onChanged: (query) {
                            setState(() {
                              filteredUsers = user
                                  .where((u) => (u.name ?? '')
                                      .toLowerCase()
                                      .contains(query.toLowerCase()))
                                  .toList();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
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
                  const SizedBox(height: 10),

                  // ส่วนแนะนำ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("แนะนำ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {},
                        child: const Text("ดูทั้งหมด",
                            style: TextStyle(color: Colors.black54)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // แสดงผู้ใช้แนะนำแนวนอน
                  SizedBox(
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
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.grey[300],
                                    alignment: Alignment.center,
                                    child: const Text(
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
                  ),

                  const SizedBox(height: 10),

                  _isLoadingHashtags
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: hashtagsWithPosts.map((tag) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Transform.translate(
                                      offset: const Offset(0, -20),
                                      child: Container(
                                        width: 35,
                                        height: 35,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.black, width: 2),
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            'assets/images/hastag.png',
                                            width: 35,
                                            height: 35,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Transform.translate(
                                      offset: const Offset(0, -20),
                                      child: Text(
                                        '#${tag.tagName}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: tag.posts.map((post) {
                                      // สมมติ post.images เป็น List<String> ของ URL
                                      final imageUrl = post.images.isNotEmpty
                                          ? post.images[0]
                                          : '';

                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 150,
                                          height: 150,
                                          margin:
                                              const EdgeInsets.only(right: 10),
                                          color: Colors.grey[200],
                                          child: imageUrl.isNotEmpty
                                              ? Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Container(
                                                    color: Colors.grey[300],
                                                    alignment: Alignment.center,
                                                    child: const Text(
                                                      'ไม่มีภาพ',
                                                      style: TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  color: Colors.grey[300],
                                                  alignment: Alignment.center,
                                                  child: const Text(
                                                    'ไม่มีภาพ',
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            );
                          }).toList(),
                        )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

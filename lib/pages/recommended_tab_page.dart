import 'dart:convert';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/get_all_category.dart';
import 'package:fontend_pro/models/get_all_post.dart' as model;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class RecommendedTab extends StatefulWidget {
  final PageController pageController;
  const RecommendedTab({super.key, required this.pageController});

  @override
  State<RecommendedTab> createState() => _RecommendedTabState();
}

class _RecommendedTabState extends State<RecommendedTab> {
  List<GetAllCategory> category = [];
  late Future<void> loadData_Category;
  int selectedIndex = -1;

  GetStorage gs = GetStorage();

  List<model.GetAllPost> post = [];
  late Future<List<model.GetAllPost>?> loadData_Post;

  // เก็บสถานะการแสดงหัวใจตาม index โพสต์
  Map<int, bool> showHeartMap = {};

  Map<int, int> likeCountMap = {};

  Map<int, bool> likedMap = {}; // เก็บสถานะไลก์ของแต่ละโพสต์

  @override
  void initState() {
    super.initState();
    loadData_Category = loadDataCategory();
    loadData_Post = loadDataPost();
    var user = gs.read('user');
    log(user.toString());
  }

  final PageController pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: FutureBuilder(
                future: loadData_Category,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Error loading user data'));
                  }
                  return Row(
                    children: category.asMap().entries.map((entry) {
                      int index = entry.key;
                      var cate = entry.value;

                      bool isSelected = selectedIndex == index;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                isSelected ? Colors.black : Colors.black54,
                          ),
                          child: Text(
                            cate.cname,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            FutureBuilder<List<model.GetAllPost>?>(
              future: loadData_Post, // ✅ ใช้ค่าที่โหลดครั้งเดียวตอน initState
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('ไม่พบข้อมูล'));
                }

                final posts = snapshot.data!;

                // เติมจำนวนไลก์ใน likeCountMap ถ้ายังไม่มี
                for (var p in posts) {
                  likeCountMap[p.post.postId] ??= p.post.amountOfLike ?? 0;
                  likedMap[p.post.postId] ??=
                      false; // 🆕 กำหนดว่าเริ่มต้นยังไม่ไลก์
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final pageController = PageController();

                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: รูปโปรไฟล์ + ชื่อ + ปุ่มติดตาม + เมนู
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  ClipOval(
                                    child: Image.network(
                                      post.user.profileImage ?? '',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Image.asset(
                                        'assets/default_profile.png',
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    post.user.name,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 2),
                                      textStyle: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                      elevation: 10,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      minimumSize: Size(0, 40),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () {},
                                    child: Text("ติดตาม"),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert),
                                    onSelected: (value) {
                                      if (value == 'report') {
                                        // รายงาน
                                      } else if (value == 'block') {
                                        // บล็อก
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                          value: 'report',
                                          child: Text('รายงาน')),
                                      PopupMenuItem(
                                          value: 'block', child: Text('บล็อก')),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 10),

                          // รูปภาพแบบ PageView พร้อมแสดงหัวใจตอนกด double tap
                          if (post.images.isNotEmpty)
                            Center(
                              child: Container(
                                height: 450,
                                width: double.infinity,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PageView(
                                      controller: pageController,
                                      children: post.images.map((image) {
                                        return GestureDetector(
                                          onDoubleTap: () async {
                                            likePost(post.post.postId);
                                            setState(() {
                                              showHeartMap[index] = true;
                                            });
                                            await Future.delayed(
                                                Duration(seconds: 1));
                                            setState(() {
                                              showHeartMap[index] = false;
                                            });
                                          },
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Image.network(
                                              image.image,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),

                                    // ไอคอนหัวใจซ้อนบนภาพ เมื่อ showHeartMap[index] == true
                                    AnimatedOpacity(
                                      opacity: showHeartMap[index] == true
                                          ? 1.0
                                          : 0.0,
                                      duration: Duration(milliseconds: 300),
                                      child: Icon(
                                        Icons.favorite,
                                        color: Colors.red.withOpacity(0.8),
                                        size: 100,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          SizedBox(height: 10),

                          // SmoothPageIndicator
                          if (post.images.length > 1)
                            Center(
                              child: SmoothPageIndicator(
                                controller: pageController,
                                count: post.images.length,
                                effect: ExpandingDotsEffect(
                                  dotWidth: 8,
                                  dotHeight: 8,
                                  spacing: 8,
                                  expansionFactor: 4,
                                  dotColor: Colors.black,
                                  activeDotColor: Colors.black38,
                                ),
                              ),
                            ),

                          SizedBox(height: 10),

                          // แสดงปุ่ม category และไอคอนต่าง ๆ
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // ปุ่ม category เลื่อนซ้าย-ขวาได้
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: BouncingScrollPhysics(),
                                  child: Row(
                                    children: post.categories.map((category) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6.0),
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor:
                                                Colors.grey.shade100,
                                            foregroundColor: Colors.black87,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 6),
                                            textStyle: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            side: BorderSide(
                                                color: Colors.grey.shade400,
                                                width: 1.2),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            elevation: 0,
                                          ),
                                          onPressed: () {},
                                          child: Text(category.cname),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),

                              SizedBox(width: 10),

                              // ไอคอน action ต่าง ๆ รวมกันเลย
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      likePost(post.post.postId);
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Row(
                                      children: [
                                        Icon(
                                          likedMap[post.post.postId] == true
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: 22,
                                          color:
                                              likedMap[post.post.postId] == true
                                                  ? Colors.red
                                                  : Colors.black87,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          likeCountMap[post.post.postId]
                                                  ?.toString() ??
                                              '0',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 15),
                                  GestureDetector(
                                    onTap: () {
                                      // เพิ่มฟังก์ชันคอมเมนต์
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          'assets/images/chat.png',
                                          height: 20,
                                          width: 20,
                                          color: Colors.black87,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          (post.post.amountOfComment ?? 0)
                                              .toString(),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 15),
                                  GestureDetector(
                                    onTap: () {
                                      // เพิ่มฟังก์ชันบันทึก
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Row(
                                      children: [
                                        Icon(Icons.bookmark_outline_rounded,
                                            size: 22, color: Colors.black87),
                                        SizedBox(width: 6),
                                        Text(
                                          (post.post.amountOfSave ?? 0)
                                              .toString(),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // ข้อความเนื้อหาโพสต์
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.post.postTopic,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                if (post.post.postDescription != null)
                                  Text(post.post.postDescription!),
                                Text("#ถ่ายรูปหน้ากระจก #ชุดเล่น",
                                    style: TextStyle(color: Colors.blue)),
                                SizedBox(height: 5),
                                Text(
                                  DateFormat('d MMM yyyy')
                                      .format(post.post.postDate),
                                  style: TextStyle(
                                      color: Colors.black38, fontSize: 10),
                                ),
                              ],  
                            ),
                          ),

                          Divider(thickness: 1),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loadDataCategory() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    final response = await http.get(Uri.parse("$url/category/get"));
    if (response.statusCode == 200) {
      category = getAllCategoryFromJson(response.body);
      log(response.body);
      setState(() {});
    } else {
      log('Error loading category data: ${response.statusCode}');
    }
  }

  Future<List<model.GetAllPost>?> loadDataPost() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final response = await http.get(Uri.parse("$url/image_post/get"));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final posts =
            jsonData.map((item) => model.GetAllPost.fromJson(item)).toList();

        log('Received post data: ${posts.length}');
        return posts;
      } else {
        log('Error loading post data: ${response.statusCode}');
      }
    } catch (e) {
      log('Exception during post loading: $e');
    }
    return null;
  }

  Future<void> likePost(int postId) async {
    final isLikedNow = likedMap[postId] ?? false;

    // Toggle บน UI
    setState(() {
      likedMap[postId] = !isLikedNow;
      if (isLikedNow) {
        likeCountMap[postId] = (likeCountMap[postId] ?? 1) - 1;
      } else {
        likeCountMap[postId] = (likeCountMap[postId] ?? 0) + 1;
      }
    });

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response = await http.post(
        Uri.parse("$url/image_post/like/$postId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"isLiked": isLikedNow}),
      );

      if (response.statusCode == 200) {
        log("🔁 Like toggled: ${response.body}");
      } else {
        log("❌ Failed to toggle like: ${response.statusCode}");
      } 
    } catch (e) {
      log("🚨 Error toggling like: $e");
    }
  }
}
